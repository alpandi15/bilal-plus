import 'package:flutter/material.dart';

import '../../utils/keyframes.dart';
import '../../utils/sky_clock.dart';

/// Nilai A->B->A dengan pola keyframe 0%/50%/100% yang lazim dipakai animasi
/// "berdenyut" (twinkle, halo). `curve` berlaku untuk kedua separuh, sama
/// seperti CSS yang timing-function-nya dideklarasikan di level `animation`
/// (bukan dioverride per-keyframe).
double triangleWave(
  double phase,
  double a,
  double b, {
  Curve curve = Curves.easeInOut,
}) {
  if (phase <= 0.5) {
    final t = curve.transform((phase / 0.5).clamp(0.0, 1.0));
    return lerpDoubleV(a, b, t);
  }
  final t = curve.transform(((phase - 0.5) / 0.5).clamp(0.0, 1.0));
  return lerpDoubleV(b, a, t);
}

class _Star {
  final double x, y, r, delay;
  const _Star(this.x, this.y, this.r, this.delay);
}

// posisi tetap, padanan `STARS` di SkyAtmosphere.tsx
const List<_Star> _stars = [
  _Star(6, 12, 1.5, 0),
  _Star(15, 34, 1.1, 1.4),
  _Star(23, 8, 1.8, 2.6),
  _Star(31, 52, 1.2, 0.7),
  _Star(38, 21, 1.4, 3.1),
  _Star(45, 68, 1.0, 1.9),
  _Star(52, 14, 1.7, 0.4),
  _Star(59, 41, 1.2, 2.3),
  _Star(66, 6, 1.3, 1.1),
  _Star(72, 58, 1.1, 3.4),
  _Star(79, 26, 1.6, 0.9),
  _Star(86, 48, 1.2, 2.8),
  _Star(93, 16, 1.4, 1.6),
  _Star(10, 72, 1.0, 2.1),
  _Star(27, 88, 1.2, 0.6),
  _Star(63, 82, 1.0, 3.7),
  _Star(88, 76, 1.3, 1.3),
  _Star(48, 33, 0.9, 4.2),
  _Star(3, 44, 0.9, 2.5),
  _Star(19, 61, 1.1, 0.2),
  _Star(35, 5, 1.0, 3.9),
  _Star(43, 79, 0.9, 1.7),
  _Star(56, 50, 1.2, 4.6),
  _Star(70, 30, 0.9, 2.0),
  _Star(82, 62, 1.1, 3.2),
  _Star(96, 34, 1.0, 0.8),
];

class _Meteor {
  final double top, left, durationS, delayS;
  const _Meteor(this.top, this.left, this.durationS, this.delayS);
}

// padanan `METEORS`
const List<_Meteor> _meteors = [_Meteor(9, 58, 11, 3), _Meteor(27, 22, 17, 9)];

/// Bintang berkelip + sesekali bintang jatuh. Padanan `Starfield`.
class Starfield extends StatelessWidget {
  const Starfield({
    super.key,
    required this.clock,
    required this.cardSize,
    required this.starDiameter,
    required this.meteorWidth,
    this.meteors = true,
  });

  final SkyClock clock;
  final Size cardSize;

  /// Diameter dasar bintang (dikali `r` masing-masing bintang).
  final double starDiameter;
  final double meteorWidth;

  /// Bintang jatuh bisa dimatikan (frame widget layar utama: kilasan sesaat
  /// tidak cocok disilangkan pelan antar frame).
  final bool meteors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final s in _stars)
          Builder(
            builder: (context) {
              final phase = clock.phase(3400, delayMs: s.delay * 1000);
              final opacity = triangleWave(phase, 0.18, 1.0);
              final scale = triangleWave(phase, 0.8, 1.18);
              final d = starDiameter * s.r;
              return Positioned(
                left: s.x / 100 * cardSize.width - d / 2,
                top: s.y / 100 * cardSize.height - d / 2,
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
                          color: Color(0xA6E2E8F0),
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
        if (meteors)
          for (final m in _meteors)
            Builder(
              builder: (context) {
                final periodMs = m.durationS * 1000;
                final phase = clock.phase(periodMs, delayMs: m.delayS * 1000);
                // posisi: 0%->16% bergerak lurus dari (0,0) ke (150,67), lalu diam
                // di sana sampai putaran berikutnya (persis keyframe CSS-nya).
                // opacity: 0%=0, 4%=1, 16%..100%=0 - dua segmen linear terpisah.
                final offset = Offset.lerp(
                  Offset.zero,
                  const Offset(150, 67),
                  (phase / 0.16).clamp(0.0, 1.0),
                )!;
                final double opacity = phase <= 0.04
                    ? lerpDoubleV(0, 1, phase / 0.04)
                    : lerpDoubleV(
                        1,
                        0,
                        ((phase - 0.04) / 0.12).clamp(0.0, 1.0),
                      );
                return Positioned(
                  top: m.top / 100 * cardSize.height,
                  left: m.left / 100 * cardSize.width,
                  child: Transform.translate(
                    offset: offset,
                    child: Transform.rotate(
                      angle: 24 * 3.1415926535 / 180,
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Container(
                          height: 1,
                          width: meteorWidth,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x00FFFFFF),
                                Color(0xF2FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: [0, 0.62, 1],
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
