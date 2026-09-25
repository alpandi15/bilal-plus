import 'package:flutter/material.dart';

import '../../services/ibadah_report.dart';
import '../../utils/date_key.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Skala warna tuntas ibadah: kosong -> amber pekat.
const heatShades = [
  Color(0xFFFFFFFF),
  Color(0xFFFEF3C7),
  Color(0xFFFDE68A),
  Color(0xFFFCD34D),
  Color(0xFFF59E0B),
  Color(0xFFD97706),
];
const heatExcused = Color(0xFFE7E5E4);
const heatNoData = Color(0xFFFFFAF3);

Color heatColor(DayScore? s) {
  if (s == null || !s.hasData) return heatNoData;
  if (s.excused) return heatExcused;
  if (s.total == 0 || s.done == 0) return heatShades[0];
  if (s.done >= s.total) return heatShades[5];
  return heatShades[1 + (s.fraction * 4).floor().clamp(0, 3)];
}

String _tooltip(DayScore s) => !s.hasData
    ? formatDateKeyShort(s.date)
    : s.excused
    ? '${formatDateKeyShort(s.date)} · berhalangan'
    : '${formatDateKeyShort(s.date)} · ${s.done}/${s.total} ibadah';

/// Kalender kontribusi ala GitHub: satu kolom per pekan (Senin di atas),
/// warna = persen ibadah aktif yang tuntas hari itu. Digulir ke kanan
/// (pekan terbaru) sejak awal.
class ContributionCalendar extends StatelessWidget {
  const ContributionCalendar({
    super.key,
    required this.days,
    this.cell = 14,
    this.gap = 3,
  });

  /// Hari berurutan (lihat [IbadahReport.days]).
  final List<DayScore> days;
  final double cell;
  final double gap;

  static const _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final first = parseDateKey(days.first.date);
    final lead = first.weekday - 1;
    final slots = <DayScore?>[for (var i = 0; i < lead; i++) null, ...days];
    final weeks = (slots.length / 7).ceil();

    Widget column(int w) {
      // label bulan di pekan pertama bulan itu
      final firstInColumn = [
        for (var d = 0; d < 7; d++) slots.elementAtOrNull(w * 7 + d),
      ].nonNulls.firstOrNull;
      final firstDay = firstInColumn == null
          ? null
          : parseDateKey(firstInColumn.date);
      final monthLabel = firstDay != null && firstDay.day <= 7
          ? _bulan[firstDay.month - 1]
          : '';
      return Padding(
        padding: EdgeInsets.only(right: gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 14,
              child: Text(
                monthLabel,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(fontSize: 9, color: _muted),
              ),
            ),
            for (var d = 0; d < 7; d++)
              Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: switch (slots.elementAtOrNull(w * 7 + d)) {
                  null => SizedBox.square(dimension: cell),
                  final s => Tooltip(
                    message: _tooltip(s),
                    child: Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: heatColor(s),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: s.hasData ? _line : const Color(0x00000000),
                        ),
                      ),
                    ),
                  ),
                },
              ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, right: 6),
          child: Column(
            children: [
              for (final h in const ['Sen', '', 'Rab', '', 'Jum', '', 'Min'])
                SizedBox(
                  height: cell + gap,
                  child: Text(
                    h,
                    style: const TextStyle(fontSize: 9, color: _muted),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (var w = 0; w < weeks; w++) column(w)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kalender satu bulan (Senin di kolom pertama) berwarna sama dengan
/// [ContributionCalendar], angka tanggal di tiap sel.
class MonthHeatmap extends StatelessWidget {
  const MonthHeatmap({
    super.key,
    required this.month,
    required this.today,
    required this.days,
  });

  /// Tanggal 1 bulan yang ditampilkan.
  final DateTime month;
  final String today;
  final Map<String, DayScore> days;

  @override
  Widget build(BuildContext context) {
    final count = DateTime.utc(month.year, month.month + 1, 0).day;
    final leading = month.weekday - 1;
    return Column(
      children: [
        Row(
          children: [
            for (final h in const ['S', 'S', 'R', 'K', 'J', 'S', 'M'])
              Expanded(
                child: Text(
                  h,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          children: [
            for (var i = 0; i < leading; i++) const SizedBox(),
            for (var d = 1; d <= count; d++)
              _cell(dateKey(DateTime.utc(month.year, month.month, d)), d),
          ],
        ),
      ],
    );
  }

  Widget _cell(String key, int day) {
    final s = days[key];
    final future = key.compareTo(today) > 0;
    final color = future ? heatNoData : heatColor(s);
    final dark = !future && s != null && s.hasData && s.fraction >= 0.75;
    final cell = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: key == today ? const Color(0xFFB45309) : _line,
          width: key == today ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: future
              ? const Color(0xFFD6D3D1)
              : dark && !(s.excused)
              ? Colors.white
              : _stone,
        ),
      ),
    );
    return s == null ? cell : Tooltip(message: _tooltip(s), child: cell);
  }
}

/// Keterangan skala warna.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key, this.showExcused = true});
  final bool showExcused;

  @override
  Widget build(BuildContext context) {
    Widget box(Color c) => Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _line),
      ),
    );
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('0%', style: TextStyle(fontSize: 10, color: _muted)),
            for (final c in heatShades) box(c),
            const Text('tuntas', style: TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
        if (showExcused)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              box(heatExcused),
              const Text(
                'berhalangan',
                style: TextStyle(fontSize: 10, color: _muted),
              ),
            ],
          ),
      ],
    );
  }
}
