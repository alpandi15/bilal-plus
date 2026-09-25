import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sky/moon.dart';
import 'sky/starfield.dart' show triangleWave;
import '../utils/keyframes.dart';
import '../utils/sky_clock.dart';

/* -------------------------------------------------------------------------- */
/*  Geometri - padanan persis konstanta di SunPositionArc.tsx                 */
/* -------------------------------------------------------------------------- */

const double _xMin = 4, _xMax = 96;
const double _cx = (_xMin + _xMax) / 2;
const double _rx = (_xMax - _xMin) / 2;
const double _horizon = 84;
const double _ry = 60;
const double _taperHalf = 1.9;

class _ArcPoint {
  final double x, y, elevation;
  const _ArcPoint(this.x, this.y, this.elevation);
}

_ArcPoint _pointAt(double progress) {
  final t = math.pi * (1 - progress);
  return _ArcPoint(
    _cx + _rx * math.cos(t),
    _horizon - _ry * math.sin(t),
    math.sin(t),
  );
}

/// Warna matahari mengikuti ketinggian: rendah = oranye pekat, tinggi =
/// kekuningan. Padanan `sunRgb`.
Color _sunColor(double elevation) {
  const low = Color(0xFFFF5A00);
  const mid = Color(0xFFFF9A1F);
  const high = Color(0xFFFFCE3A);
  return elevation < 0.5
      ? Color.lerp(low, mid, elevation / 0.5)!
      : Color.lerp(mid, high, (elevation - 0.5) / 0.5)!;
}

/* -------------------------------------------------------------------------- */

class SunPositionArc extends StatefulWidget {
  const SunPositionArc({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.current,
    this.bodySize = 22,
    this.hideAtNight = false,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime current;
  final double bodySize;
  final bool hideAtNight;

  @override
  State<SunPositionArc> createState() => _SunPositionArcState();
}

class _SunPositionArcState extends State<SunPositionArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this);
  double _current = 0;

  (double, bool) _computeTarget() {
    final rise = widget.sunrise.millisecondsSinceEpoch;
    final set = widget.sunset.millisecondsSinceEpoch;
    final t = widget.current.millisecondsSinceEpoch;
    const day = 86400000;

    if (set <= rise) return (0, false);
    if (t >= rise && t <= set) return ((t - rise) / (set - rise), true);

    final from = t > set ? set : set - day;
    final to = t > set ? rise + day : rise;
    final span = to - from;
    final p = span > 0 ? ((t - from) / span).clamp(0.0, 1.0) : 0.0;
    return (p, false);
  }

  late bool _isDaytime;

  @override
  void initState() {
    super.initState();
    final (target, isDaytime) = _computeTarget();
    _isDaytime = isDaytime;
    _retarget(
      target,
      duration: const Duration(milliseconds: 1800),
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
  }

  @override
  void didUpdateWidget(covariant SunPositionArc oldWidget) {
    super.didUpdateWidget(oldWidget);
    final (target, isDaytime) = _computeTarget();
    _isDaytime = isDaytime;
    _retarget(
      target,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.linear,
    );
  }

  void _retarget(
    double target, {
    required Duration duration,
    required Curve curve,
  }) {
    _ctrl.stop();
    _ctrl.duration = duration;
    final tween = Tween(
      begin: _current,
      end: target,
    ).chain(CurveTween(curve: curve)).animate(_ctrl);
    tween.addListener(() => setState(() => _current = tween.value));
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDaytime && widget.hideAtNight) return const SizedBox.shrink();

    final point = _pointAt(_current);
    final rgb = _sunColor(point.elevation);
    final arcStroke = _isDaytime
        ? const Color(0x57D97706)
        : const Color(0x6694A3B8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return SkyClockProvider(
          builder: (context, clock) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArcPainter(
                      isDaytime: _isDaytime,
                      arcStroke: arcStroke,
                    ),
                  ),
                ),
                if (!_isDaytime) _NightSky(clock: clock, cardSize: size),
                Positioned(
                  left: point.x / 100 * size.width,
                  top: point.y / 100 * size.height,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: SizedBox(
                      width: widget.bodySize * 3,
                      height: widget.bodySize * 3,
                      child: Center(
                        child: _isDaytime
                            ? _SunBody(
                                clock: clock,
                                bodySize: widget.bodySize,
                                rgb: rgb,
                              )
                            : _MoonBody(
                                clock: clock,
                                bodySize: widget.bodySize,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Pita oval (haze isi + pita meruncing). Padanan gambar SVG `ARC_PATH` +
/// `ARC_RIBBON`.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.isDaytime, required this.arcStroke});
  final bool isDaytime;
  final Color arcStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    canvas.save();
    canvas.scale(sx, sy);

    const steps = 96;
    final fill = Path()..moveTo(_pointAt(0).x, _pointAt(0).y);
    for (var i = 1; i <= steps; i++) {
      final p = _pointAt(i / steps);
      fill.lineTo(p.x, p.y);
    }
    fill.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        isDaytime ? const Color(0x73FFECB4) : const Color(0x4D334155),
        const Color(0x00FFFFFF),
      ],
    );
    canvas.drawPath(
      fill,
      Paint()
        ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );

    final top = <Offset>[];
    final bottom = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = _pointAt(t);
      final half = _taperHalf * math.sin(math.pi * t);
      top.add(Offset(p.x, p.y - half));
      bottom.add(Offset(p.x, p.y + half));
    }
    final ribbon = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      ribbon.lineTo(p.dx, p.dy);
    }
    for (final p in bottom.reversed) {
      ribbon.lineTo(p.dx, p.dy);
    }
    ribbon.close();
    canvas.drawPath(ribbon, Paint()..color = arcStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.isDaytime != isDaytime || oldDelegate.arcStroke != arcStroke;
}

/// Matahari: halo berdenyut + sinar berputar + inti. Padanan cabang
/// `isDaytime` di SunPositionArc.tsx.
class _SunBody extends StatelessWidget {
  const _SunBody({
    required this.clock,
    required this.bodySize,
    required this.rgb,
  });
  final SkyClock clock;
  final double bodySize;
  final Color rgb;

  @override
  Widget build(BuildContext context) {
    final haloPhase = clock.phase(3400);
    final haloScale = triangleWave(haloPhase, 0.92, 1.12);
    final haloOpacity = triangleWave(haloPhase, 0.75, 1);
    final rayRotation = clock.phase(44000) * 2 * math.pi;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.scale(
          scale: haloScale,
          child: Opacity(
            opacity: haloOpacity,
            child: SizedBox(
              width: bodySize * 3,
              height: bodySize * 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [rgb.withOpacity(0.52), rgb.withOpacity(0)],
                    stops: const [0, 0.68],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: bodySize * 2.1,
          height: bodySize * 2.1,
          child: CustomPaint(
            painter: _RayPainter(
              color: rgb.withOpacity(0.45),
              rotation: rayRotation,
            ),
          ),
        ),
        Container(
          width: bodySize,
          height: bodySize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.36),
              colors: [Colors.white.withOpacity(0.95), rgb],
              stops: const [0, 0.62],
            ),
            boxShadow: [
              BoxShadow(color: rgb.withOpacity(0.85), blurRadius: bodySize),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sinar matahari: irisan conic berulang, dipotong jadi cincin lewat
/// gradasi radial (dstIn). Padanan `repeating-conic-gradient` + mask CSS.
class _RayPainter extends CustomPainter {
  const _RayPainter({required this.color, required this.rotation});
  final Color color;
  final double rotation;

  static const _period = 27.0; // derajat
  static const _lit = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r);

    canvas.save();
    canvas.translate(r, r);
    canvas.rotate(rotation);
    canvas.translate(-r, -r);

    canvas.saveLayer(rect, Paint());
    final wedgePaint = Paint()..color = color;
    for (double a = 0; a < 360; a += _period) {
      canvas.drawArc(
        rect,
        a * math.pi / 180,
        _lit * math.pi / 180,
        true,
        wedgePaint,
      );
    }
    final maskPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
          Colors.transparent,
        ],
        stops: [0, 0.34, 0.44, 0.72, 0.82, 1],
      ).createShader(rect)
      ..blendMode = BlendMode.dstIn;
    canvas.drawRect(rect, maskPaint);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RayPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}

/// Bulan sabit pengganti matahari saat malam.
class _MoonBody extends StatelessWidget {
  const _MoonBody({required this.clock, required this.bodySize});
  final SkyClock clock;
  final double bodySize;

  @override
  Widget build(BuildContext context) {
    final phase = clock.phase(4500);
    final scale = triangleWave(phase, 0.94, 1.08);
    final opacity = triangleWave(phase, 0.7, 1);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: bodySize * 3,
              height: bodySize * 3,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x4DE2E8F0), Color(0x00E2E8F0)],
                    stops: [0, 0.66],
                  ),
                ),
              ),
            ),
          ),
        ),
        CustomPaint(
          size: Size(bodySize, bodySize),
          painter: const CrescentPainter(
            color: Color(0xFFE8EEF9),
            cutCx: 27,
            cutCy: 14,
          ),
        ),
      ],
    );
  }
}

/// Bintang & bintang jatuh versi busur malam (dengan jeda antar bintang
/// jatuh yang lebih jarang). Padanan `NightSky` di SunPositionArc.tsx.
class _NightSky extends StatelessWidget {
  const _NightSky({required this.clock, required this.cardSize});
  final SkyClock clock;
  final Size cardSize;

  static const List<List<double>> _stars = [
    [8, 26, 1.6, 0],
    [19, 52, 1.1, 1.1],
    [27, 18, 1.9, 2.2],
    [38, 40, 1.2, 0.6],
    [46, 14, 1.5, 1.7],
    [57, 33, 1.1, 2.6],
    [66, 20, 1.7, 0.9],
    [74, 47, 1.2, 1.9],
    [83, 24, 1.5, 0.3],
    [91, 44, 1.1, 2.4],
    [13, 66, 1.0, 1.4],
    [52, 60, 1.0, 3.0],
  ];

  static const List<List<double>> _meteors = [
    [14, 62, 2.5, 9], // top%, left%, delay, repeatGap
    [30, 28, 7.5, 13],
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final s in _stars)
          Builder(
            builder: (context) {
              final phase = clock.phase(3200, delayMs: s[3] * 1000);
              final opacity = triangleWave(phase, 0.2, 1);
              final scale = triangleWave(phase, 0.85, 1.15);
              final d = s[2] * 2;
              return Positioned(
                left: s[0] / 100 * cardSize.width - d / 2,
                top: s[1] / 100 * cardSize.height - d / 2,
                width: d,
                height: d,
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(opacity),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xB3E2E8F0),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        for (final m in _meteors)
          Builder(
            builder: (context) {
              const activeS = 1.1;
              final periodMs = (activeS + m[3]) * 1000;
              final phase = clock.phase(periodMs, delayMs: m[2] * 1000);
              final activeFraction = activeS * 1000 / periodMs;
              if (phase > activeFraction) return const SizedBox.shrink();
              final p = phase / activeFraction;
              final eased = Curves.easeIn.transform(p.clamp(0.0, 1.0));
              final opacity = triangleWave(p, 0, 1, curve: Curves.easeIn);
              final dx = lerpDoubleV(-30, 90, eased);
              final dy = lerpDoubleV(-14, 40, eased);
              return Positioned(
                top: m[0] / 100 * cardSize.height,
                left: m[1] / 100 * cardSize.width,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.rotate(
                    angle: 22 * math.pi / 180,
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        height: 1,
                        width: 70,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xF2FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                            stops: [0, 0.6, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
