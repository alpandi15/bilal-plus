import 'package:flutter/material.dart';

import '../../utils/keyframes.dart';
import '../../utils/sky_clock.dart';

class _Bird {
  final double x, y, scale, flapS, delayS;
  const _Bird(this.x, this.y, this.scale, this.flapS, this.delayS);
}

// padanan `FLOCK`
const List<_Bird> _flock = [
  _Bird(0, 0, 1, 0.74, 0),
  _Bird(30, -11, 0.82, 0.86, -0.31),
  _Bird(26, 12, 0.86, 0.68, -0.55),
  _Bird(58, -3, 0.7, 0.95, -0.17),
  _Bird(62, 20, 0.66, 0.79, -0.68),
  _Bird(88, 8, 0.58, 1.02, -0.44),
  _Bird(92, -16, 0.6, 0.9, -0.86),
];

/// Menggambar satu kepakan sayap: dua kurva kuadratik yang tepinya
/// (`edgeY`) dan titik kendalinya (`controlY`) berubah tiap frame - padanan
/// morphing atribut `d` pada `sky-flap`.
class _WingPainter extends CustomPainter {
  const _WingPainter({required this.edgeY, required this.controlY});

  final double edgeY, controlY;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 20;
    canvas.scale(scale);
    final path = Path()
      ..moveTo(0, edgeY)
      ..quadraticBezierTo(5, controlY, 10, 6)
      ..quadraticBezierTo(15, controlY, 20, edgeY);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x9E54321C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WingPainter oldDelegate) =>
      oldDelegate.edgeY != edgeY || oldDelegate.controlY != controlY;
}

/// Sekawanan burung pulang sore hari, melayang menyeberangi kartu sambil
/// mengepakkan sayap tidak seirama. Padanan komponen `Birds`.
class Birds extends StatelessWidget {
  const Birds({
    super.key,
    required this.clock,
    required this.cardSize,
    required this.birdBaseWidth,
  });

  final SkyClock clock;
  final Size cardSize;
  final double birdBaseWidth;

  @override
  Widget build(BuildContext context) {
    // sky-glide: 46s linear, delay -8s; translate3d(-28%,0,0) -> (128%,-22px,0)
    final glidePhase = clock.phase(46000, delayMs: -8000);
    final dx = lerpDoubleV(-28, 128, glidePhase) / 100 * cardSize.width;
    final dy = lerpDoubleV(0, -22, glidePhase);
    final wrapperWidth = cardSize.width * 0.34;

    return Positioned(
      top: 0.20 * cardSize.height,
      left: 0,
      width: cardSize.width,
      child: Transform.translate(
        offset: Offset(dx, dy),
        // Tingginya WAJIB dipatok: isi Stack di bawah semuanya `Positioned`,
        // tanpa satu pun anak biasa sebagai acuan ukuran - kalau tingginya
        // dibiarkan tak terbatas (induknya `Positioned` tanpa height),
        // Stack tidak bisa menghitung ukurannya sendiri dan gagal di mode
        // debug. Burung yang melewati batas ini tetap tergambar karena
        // clipBehavior-nya none.
        child: SizedBox(
          width: wrapperWidth,
          height: birdBaseWidth * 2.2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final b in _flock)
                Builder(
                  builder: (context) {
                    final flapMs = b.flapS * 1000;
                    // sky-bob: badan naik-turun, linear, 3 titik efektif
                    final bobPhase = clock.phase(
                      flapMs,
                      delayMs: b.delayS * 1000,
                    );
                    final bobPct = bobPhase <= 0.27
                        ? lerpDoubleV(5, -5, bobPhase / 0.27)
                        : bobPhase <= 0.60
                        ? lerpDoubleV(-5, 5, (bobPhase - 0.27) / 0.33)
                        : 5.0;

                    // sky-flap: dua trek independen (edgeY, controlY) dengan
                    // kurva easing per-segmen sesuai override CSS aslinya -
                    // `Cubic` adalah kelas bawaan Flutter, padanan langsung
                    // `cubic-bezier()` CSS.
                    const cIn = Cubic(0.4, 0, 0.9, 0.4);
                    const cOut = Cubic(0.25, 0.6, 0.4, 1);
                    double edgeY, controlY;
                    if (bobPhase <= 0.14) {
                      final t = cIn.transform(bobPhase / 0.14);
                      edgeY = lerpDoubleV(7, 6, t);
                      controlY = lerpDoubleV(0, 3, t);
                    } else if (bobPhase <= 0.27) {
                      final t = (bobPhase - 0.14) / 0.13; // linear (base)
                      edgeY = lerpDoubleV(6, 3, t);
                      controlY = lerpDoubleV(3, 8, t);
                    } else if (bobPhase <= 0.46) {
                      final t = cOut.transform((bobPhase - 0.27) / 0.19);
                      edgeY = lerpDoubleV(3, 6, t);
                      controlY = lerpDoubleV(8, 3, t);
                    } else if (bobPhase <= 0.60) {
                      final t = (bobPhase - 0.46) / 0.14; // linear (base)
                      edgeY = lerpDoubleV(6, 7, t);
                      controlY = lerpDoubleV(3, 0, t);
                    } else {
                      edgeY = 7;
                      controlY = 0;
                    }

                    final width = birdBaseWidth * b.scale;
                    final height = width * 8 / 20;

                    return Positioned(
                      left: b.x / 100 * wrapperWidth,
                      top: b.y,
                      width: width,
                      height: height,
                      child: Transform.translate(
                        offset: Offset(0, bobPct / 100 * height),
                        child: CustomPaint(
                          size: Size(width, height),
                          painter: _WingPainter(
                            edgeY: edgeY,
                            controlY: controlY,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
