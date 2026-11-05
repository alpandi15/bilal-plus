import 'package:flutter/material.dart';

import '../../services/ibadah_report.dart';
import '../../utils/date_key.dart';
import 'reveal.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _grid = Color(0xFFF1E4CF);

const _left = 36.0, _right = 10.0, _top = 8.0, _bottom = 24.0;

/// Grafik garis persentase ibadah tuntas. Sentuh/geser untuk membaca satu
/// titik. Hari yang tidak dihitung memutus garis; hari ini digambar lebih
/// pudar karena masih berjalan.
class IbadahTrendChart extends StatefulWidget {
  const IbadahTrendChart({
    super.key,
    required this.points,
    this.weekly = false,
  });

  final List<TrendPoint> points;

  /// Tiap titik = rata-rata satu pekan.
  final bool weekly;

  @override
  State<IbadahTrendChart> createState() => _IbadahTrendChartState();
}

class _IbadahTrendChartState extends State<IbadahTrendChart> {
  int? _selected;

  void _select(double x, double width) {
    final n = widget.points.length;
    if (n == 0) return;
    final plot = width - _left - _right;
    final t = n == 1 ? 0.0 : (x - _left) / plot;
    final i = (t * (n - 1)).round().clamp(0, n - 1);
    if (i != _selected) setState(() => _selected = i);
  }

  String get _readout {
    final i = _selected;
    if (i == null) {
      return widget.weekly
          ? 'Rata-rata % tuntas per pekan. Sentuh grafik untuk rinciannya.'
          : '% ibadah tuntas per hari. Sentuh grafik untuk rinciannya.';
    }
    final p = widget.points[i];
    final when = widget.weekly
        ? '${formatDayMonth(p.from)} - ${formatDayMonth(p.to)}'
        : formatDateKeyShort(p.to);
    final v = p.value;
    if (v == null) return '$when: tidak dihitung';
    return '$when: ${(v * 100).round()}%${p.partial ? ' (masih berjalan)' : ''}';
  }

  String get _summary {
    final v = [
      for (final p in widget.points)
        if (p.value != null) (p.value! * 100).round(),
    ];
    if (v.isEmpty) return 'Grafik tren ibadah, belum ada data.';
    v.sort();
    return 'Grafik tren ibadah: terendah ${v.first}%, tertinggi ${v.last}%.';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _readout,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: _selected == null ? FontWeight.w400 : FontWeight.w700,
          color: _selected == null ? _muted : _stone,
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        label: _summary,
        child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition.dx, box.maxWidth),
            onHorizontalDragStart: (d) =>
                _select(d.localPosition.dx, box.maxWidth),
            onHorizontalDragUpdate: (d) =>
                _select(d.localPosition.dx, box.maxWidth),
            child: Reveal(
              delay: 100,
              duration: 900,
              builder: (context, t) => CustomPaint(
                size: Size(box.maxWidth, 180),
                painter: _TrendPainter(widget.points, _selected, t),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.selected, this.progress);

  final List<TrendPoint> points;
  final int? selected;
  final double progress;

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    double align = 0, // 0 kiri, 0.5 tengah, 1 kanan
    bool middle = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10.5, color: _muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width * align, middle ? tp.height / 2 : 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final plotW = size.width - _left - _right;
    final plotH = size.height - _top - _bottom;
    final n = points.length;
    double x(int i) => _left + (n == 1 ? plotW / 2 : plotW * i / (n - 1));
    double y(double v) => _top + plotH * (1 - v);

    final grid = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (final v in const [0.0, 0.5, 1.0]) {
      canvas.drawLine(
        Offset(_left, y(v)),
        Offset(size.width - _right, y(v)),
        grid,
      );
      _text(
        canvas,
        '${(v * 100).round()}%',
        Offset(_left - 6, y(v)),
        align: 1,
        middle: true,
      );
    }

    final labelY = size.height - _bottom + 7;
    _text(canvas, formatDayMonth(points.first.to), Offset(_left, labelY));
    if (n > 2) {
      _text(
        canvas,
        formatDayMonth(points[n ~/ 2].to),
        Offset(x(n ~/ 2), labelY),
        align: 0.5,
      );
    }
    if (n > 1) {
      _text(
        canvas,
        formatDayMonth(points.last.to),
        Offset(size.width - _right, labelY),
        align: 1,
      );
    }

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, _left + (plotW + _right) * progress, size.height),
    );
    final line = Paint()
      ..color = _amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final faded = Paint.from(line)..color = _amber.withValues(alpha: 0.4);
    final fill = Paint()..color = _amber.withValues(alpha: 0.08);
    final dot = Paint()..color = _amber;

    // satu bagian = titik-titik berurutan tanpa celah
    var i = 0;
    while (i < n) {
      if (points[i].value == null) {
        i++;
        continue;
      }
      final start = i;
      while (i + 1 < n && points[i + 1].value != null) {
        i++;
      }
      final end = i;
      i++;
      if (start == end) {
        canvas.drawCircle(Offset(x(start), y(points[start].value!)), 3, dot);
        continue;
      }
      // segmen menuju hari ini digambar terpisah (pudar)
      final solidEnd = points[end].partial ? end - 1 : end;
      final path = Path()..moveTo(x(start), y(points[start].value!));
      for (var k = start + 1; k <= solidEnd; k++) {
        path.lineTo(x(k), y(points[k].value!));
      }
      final area = Path.from(path)
        ..lineTo(x(solidEnd), y(0))
        ..lineTo(x(start), y(0))
        ..close();
      canvas.drawPath(area, fill);
      canvas.drawPath(path, line);
      if (solidEnd != end) {
        canvas.drawLine(
          Offset(x(solidEnd), y(points[solidEnd].value!)),
          Offset(x(end), y(points[end].value!)),
          faded,
        );
      }
    }
    canvas.restore();

    final s = selected;
    if (s != null && s < n) {
      canvas.drawLine(
        Offset(x(s), _top),
        Offset(x(s), y(0)),
        Paint()
          ..color = _muted
          ..strokeWidth = 1,
      );
      final v = points[s].value;
      if (v != null) {
        final c = Offset(x(s), y(v));
        canvas.drawCircle(c, 6, Paint()..color = Colors.white);
        canvas.drawCircle(c, 4.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.progress != progress;
}
