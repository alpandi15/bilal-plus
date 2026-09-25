import 'package:flutter/material.dart';

import 'starfield.dart' show triangleWave;
import '../../utils/sky_clock.dart';

/// Bulan sabit lewat "potong lingkaran" - lingkaran penuh digambar lalu
/// sebagian dipotong (BlendMode.clear) oleh lingkaran kedua yang digeser,
/// padanan `<mask>` SVG di komponen `Moon`/`SunPositionArc`'s NightSky.
class CrescentPainter extends CustomPainter {
  const CrescentPainter({
    required this.color,
    this.bodyR = 17,
    this.cutCx = 27.5,
    this.cutCy = 13.5,
    this.cutR = 15,
    this.glowColor,
    this.glowSigma = 3,
  });

  final Color color;
  final double bodyR, cutCx, cutCy, cutR;

  /// Cahaya lembut yang mengikuti bentuk sabit (padanan `drop-shadow` CSS) -
  /// bukan BoxShadow kotak di sekeliling kanvasnya.
  final Color? glowColor;
  final double glowSigma;

  void _crescent(Canvas canvas, Color fill, MaskFilter? blur) {
    // layer dilebihkan supaya blur tidak terpotong di tepi kanvas 40x40
    canvas.saveLayer(const Rect.fromLTWH(-20, -20, 80, 80), Paint());
    canvas.drawCircle(
      const Offset(20, 20),
      bodyR,
      Paint()
        ..color = fill
        ..maskFilter = blur,
    );
    canvas.drawCircle(
      Offset(cutCx, cutCy),
      cutR,
      Paint()
        ..blendMode = BlendMode.clear
        ..maskFilter = blur,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    canvas.save();
    canvas.scale(scale);
    if (glowColor != null) {
      _crescent(
        canvas,
        glowColor!,
        MaskFilter.blur(BlurStyle.normal, glowSigma),
      );
    }
    _crescent(canvas, color, null);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CrescentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glowColor != glowColor;
}

/// Bulan sabit dengan halo berdenyut lembut, di titik pandang tetap.
/// Padanan komponen `Moon` di SkyAtmosphere.tsx.
class Moon extends StatelessWidget {
  const Moon({
    super.key,
    required this.clock,
    required this.size,
    required this.cardSize,
    required this.at,
  });

  final SkyClock clock;
  final double size;
  final Size cardSize;

  /// Posisi (persen lebar/tinggi kartu), titik tengah bulan.
  final Alignment at;

  @override
  Widget build(BuildContext context) {
    final leftPct = (at.x + 1) / 2;
    final topPct = (at.y + 1) / 2;
    final haloSize = size * 2.2;
    final phase = clock.phase(6000);
    final opacity = triangleWave(phase, 0, 0.46);
    final scale = triangleWave(phase, 0.9, 1.06);

    return Positioned(
      left: leftPct * cardSize.width - size / 2,
      top: topPct * cardSize.height - size / 2,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: (size - haloSize) / 2,
              top: (size - haloSize) / 2,
              width: haloSize,
              height: haloSize,
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFDBE8FF).withOpacity(opacity),
                        const Color(0x00DBE8FF),
                      ],
                      stops: const [0, 0.66],
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: Size(size, size),
              painter: const CrescentPainter(
                color: Color(0xFFF7FAFF),
                glowColor: Color(0xBFE2ECFF),
                glowSigma: 2.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
