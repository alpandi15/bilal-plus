import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/sky_clock.dart';

/// Gumpalan penyusun satu awan, dalam persen terhadap kotak awannya.
/// Padanan `PUFFS` di SkyAtmosphere.tsx.
const List<Rect> _puffsPercent = [
  Rect.fromLTWH(0, 44, 54, 56),
  Rect.fromLTWH(19, 4, 47, 82),
  Rect.fromLTWH(45, 26, 45, 68),
  Rect.fromLTWH(8, 50, 82, 50),
];

class _CloudLane {
  final double top, width, duration, delay, blur, scale;
  const _CloudLane(
    this.top,
    this.width,
    this.duration,
    this.delay,
    this.blur,
    this.scale,
  );
}

/// Lajur awan. Padanan `CLOUDS`. `duration`/`delay` dalam detik.
const List<_CloudLane> _lanes = [
  _CloudLane(2, 44, 104, -14, 7, 1),
  _CloudLane(17, 27, 143, -78, 5, 0.72),
  _CloudLane(33, 58, 82, -44, 9, 1),
  _CloudLane(55, 24, 158, -104, 4, 0.6),
  _CloudLane(66, 40, 118, -28, 7, 0.9),
  _CloudLane(84, 31, 96, -66, 6, 0.8),
];

/// Satu gumpalan awan: badan putih/warna + sisi bawah lebih gelap supaya
/// tidak melebur ke langit terang. Padanan komponen `Cloud`.
class CloudShape extends StatelessWidget {
  const CloudShape({
    super.key,
    required this.width,
    required this.body,
    required this.shade,
    required this.opacity,
  });

  final double width;
  final Color body;
  final Color shade;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.4;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final p in _puffsPercent)
            Positioned(
              left: p.left / 100 * width,
              top: (p.top + 10) / 100 * height,
              width: p.width / 100 * width,
              height: p.height / 100 * height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: shade.withOpacity((opacity * 0.45).clamp(0, 1)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          for (final p in _puffsPercent)
            Positioned(
              left: p.left / 100 * width,
              top: p.top / 100 * height,
              width: p.width / 100 * width,
              height: p.height / 100 * height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: body.withOpacity(opacity.clamp(0, 1)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Enam lajur awan berarak. Tiap lajur satu kecepatan, satu titik mula
/// (lewat `delay` negatif) - lapisan depan bergerak lebih cepat daripada yang
/// jauh. Padanan render `CLOUDS.map(...)` di SkyAtmosphere.
class CloudLayer extends StatelessWidget {
  const CloudLayer({
    super.key,
    required this.clock,
    required this.cardSize,
    required this.cloudColor,
    required this.shadeColor,
    required this.baseOpacity,
    required this.cloudWidthMultiplier,
  });

  final SkyClock clock;
  final Size cardSize;
  final Color cloudColor;
  final Color shadeColor;
  final double baseOpacity;

  /// Pengali lebar awan (0.44 di variant layar penuh, 1 di variant kartu).
  final double cloudWidthMultiplier;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final lane in _lanes)
          Builder(
            builder: (context) {
              final phase = clock.phase(
                lane.duration * 1000,
                delayMs: lane.delay * 1000,
              );
              // translate3d(-62%,0,0) -> (114%,0,0), persen dari lebar kartu
              // (lajur ini selebar kartu penuh, sama seperti CSS aslinya).
              final dx = lerpDouble(-62, 114, phase)! / 100 * cardSize.width;
              final cloudWidth =
                  lane.width * cloudWidthMultiplier / 100 * cardSize.width;

              return Positioned(
                top: lane.top / 100 * cardSize.height,
                left: dx,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: lane.blur,
                    sigmaY: lane.blur,
                  ),
                  child: CloudShape(
                    width: cloudWidth,
                    body: cloudColor,
                    shade: shadeColor,
                    opacity: baseOpacity * lane.scale,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
