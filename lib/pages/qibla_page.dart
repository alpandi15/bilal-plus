import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/haptics.dart';
import '../services/qibla.dart';
import '../services/system_channel.dart';
import '../services/user_location_scope.dart';
import '../widgets/sub_header.dart';

const _gold = Color(0xFFF2D38A);
const _green = Color(0xFF34D399);

/// Selisih (derajat) yang dianggap sudah menghadap kiblat.
const _aligned = 3.0;

/// Kompas kiblat: piringan berputar mengikuti sensor HP, ikon Ka'bah di
/// arah kiblat. Saat ujung HP tepat menghadap kiblat, penanda berubah hijau
/// & HP bergetar sekali. Tanpa sensor kompas, tampil sudut kiblat saja.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<Heading>? _sub;
  Heading? _heading;
  bool _noSensor = false;
  double _declination = 0;
  bool _wasAligned = false;

  /// Arah tampilan yang dihaluskan (derajat), supaya piringan tidak gemetar.
  double? _smooth;

  @override
  void initState() {
    super.initState();
    _sub = headingStream().listen(
      (h) {
        if (!mounted) return;
        final prev = _smooth;
        setState(() {
          _heading = h;
          _smooth = prev == null
              ? h.heading
              : (prev + angleDelta(prev, h.heading) * 0.25 + 360) % 360;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = UserLocationScope.of(context).location;
    SystemChannel.declination(loc.lat, loc.long).then((d) {
      if (mounted) setState(() => _declination = d);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = UserLocationScope.of(context).location;
    final bearing = qiblaBearing(loc.lat, loc.long);
    final km = kaabaDistanceKm(loc.lat, loc.long);
    // arah ujung HP terhadap utara SEJATI
    final heading = _smooth == null ? null : (_smooth! + _declination) % 360;
    final delta = heading == null ? null : angleDelta(heading, bearing);
    final aligned = delta != null && delta.abs() <= _aligned;
    if (aligned && !_wasAligned) Haptics.play(HapticKind.target);
    _wasAligned = aligned;
    final lowAccuracy = (_heading?.accuracy ?? 3) <= 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0C3A33),
      body: Column(
        children: [
          SubHeader(
            title: 'Arah Kiblat',
            subtitle: '${loc.name} · ${km.round()} km ke Ka\'bah',
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
                      _Status(
                        noSensor: _noSensor,
                        waiting: heading == null && !_noSensor,
                        aligned: aligned,
                        delta: delta,
                      ),
                      const Spacer(),
                      AspectRatio(
                        aspectRatio: 1,
                        child: _Dial(
                          heading: heading ?? 0,
                          bearing: bearing,
                          aligned: aligned,
                          live: heading != null,
                        ),
                      ),
                      const Spacer(),
                      _Info(bearing: bearing, declination: _declination),
                      if (lowAccuracy && !_noSensor) ...[
                        const SizedBox(height: 10),
                        const _Calibrate(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.noSensor,
    required this.waiting,
    required this.aligned,
    required this.delta,
  });

  final bool noSensor, waiting, aligned;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final (title, sub) = noSensor
        ? (
            'HP ini tidak punya sensor kompas',
            'Gunakan sudut di bawah dengan kompas biasa atau patokan '
                'matahari.',
          )
        : waiting
        ? ('Membaca kompas…', 'Letakkan HP mendatar')
        : aligned
        ? ('Sudah menghadap kiblat', 'Pertahankan posisi HP')
        : (
            'Putar ${delta! > 0 ? 'ke kanan' : 'ke kiri'} '
                '${delta!.abs().round()}°',
            'Hadapkan ujung atas HP ke ikon Ka\'bah',
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: aligned ? _green.withValues(alpha: 0.18) : Colors.white12,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: aligned ? _green : Colors.white24,
          width: aligned ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: aligned ? _green : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Piringan kompas berputar (-heading) dengan ikon Ka'bah di [bearing];
/// jarum tetap menunjuk ujung atas HP.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.live,
  });

  final double heading, bearing;
  final bool aligned, live;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest.shortestSide;
        final r = size / 2;
        final rot = -heading * math.pi / 180;
        final kaabaAngle = bearing * math.pi / 180;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: rot,
              child: CustomPaint(
                size: Size.square(size),
                painter: _DialPainter(aligned: aligned),
              ),
            ),
            // Ka'bah di tepi piringan, ikut berputar bersama piringan
            Transform.rotate(
              angle: rot + kaabaAngle,
              child: SizedBox.square(
                dimension: size,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: r * 0.14),
                    child: Transform.rotate(
                      angle: -(rot + kaabaAngle),
                      child: _Kaaba(size: r * 0.3, glow: aligned),
                    ),
                  ),
                ),
              ),
            ),
            // jarum tetap = arah ujung atas HP
            CustomPaint(
              size: Size.square(size),
              painter: _NeedlePainter(
                color: aligned ? _green : _gold,
                dim: !live,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Kaaba extends StatelessWidget {
  const _Kaaba({required this.size, required this.glow});
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF1C1917),
      borderRadius: BorderRadius.circular(size * 0.12),
      border: Border.all(color: _gold, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: (glow ? _green : _gold).withValues(alpha: glow ? 0.8 : 0.35),
          blurRadius: glow ? 22 : 10,
        ),
      ],
    ),
    child: Column(
      children: [
        SizedBox(height: size * 0.22),
        // kiswah: pita emas
        Container(height: size * 0.12, color: _gold),
        const Spacer(),
        Container(
          width: size * 0.22,
          height: size * 0.34,
          margin: EdgeInsets.only(left: size * 0.4),
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(size * 0.06),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.aligned});
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x33FFFFFF), Color(0x0FFFFFFF)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = aligned ? _green : _gold.withValues(alpha: 0.7),
    );
    // garis derajat
    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      final a = d * math.pi / 180 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * (r - 4),
        c + dir * (r - (major ? 18 : 10)),
        Paint()
          ..strokeWidth = major ? 2 : 1
          ..color = Colors.white.withValues(alpha: major ? 0.8 : 0.35),
      );
    }
    // mata angin
    const labels = {0: 'U', 90: 'T', 180: 'S', 270: 'B'};
    for (final MapEntry(key: d, value: t) in labels.entries) {
      final a = d * math.pi / 180 - math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * (r - 36);
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: d == 0 ? const Color(0xFFF87171) : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // huruf tetap tegak relatif piringan
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(d * math.pi / 180);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.aligned != aligned;
}

class _NeedlePainter extends CustomPainter {
  _NeedlePainter({required this.color, required this.dim});
  final Color color;
  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()..color = color.withValues(alpha: dim ? 0.35 : 1);
    final tip = Path()
      ..moveTo(c.dx, c.dy - r * 0.62)
      ..lineTo(c.dx - r * 0.07, c.dy)
      ..lineTo(c.dx + r * 0.07, c.dy)
      ..close();
    canvas.drawPath(tip, paint);
    canvas.drawCircle(c, r * 0.07, paint);
    canvas.drawCircle(c, r * 0.03, Paint()..color = const Color(0xFF0C3A33));
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.color != color || old.dim != dim;
}

class _Info extends StatelessWidget {
  const _Info({required this.bearing, required this.declination});
  final double bearing, declination;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _InfoBox(
          label: 'ARAH KIBLAT',
          value: '${bearing.toStringAsFixed(1)}°',
          sub: 'dari utara sejati · ${compassPoint(bearing)}',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _InfoBox(
          label: 'KOREKSI MAGNETIK',
          value:
              '${declination >= 0 ? '+' : ''}${declination.toStringAsFixed(1)}°',
          sub: 'sudah diperhitungkan otomatis',
        ),
      ),
    ],
  );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value, required this.sub});
  final String label, value, sub;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _gold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    ),
  );
}

class _Calibrate extends StatelessWidget {
  const _Calibrate();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0x33F59E0B),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        Icon(Icons.all_inclusive_rounded, color: Color(0xFFFDE68A)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Kompas kurang akurat - gerakkan HP membentuk angka 8 beberapa '
            'kali, dan jauhkan dari magnet/logam.',
            style: TextStyle(fontSize: 12, color: Color(0xFFFDE68A)),
          ),
        ),
      ],
    ),
  );
}
