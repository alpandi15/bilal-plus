import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/keyframes.dart';
import '../../utils/sky_clock.dart';

class KitePalette {
  final Color body, accent;
  const KitePalette(this.body, this.accent);
}

const Map<String, KitePalette> kitePalette = {
  'noon': KitePalette(Color(0xFFE6484F), Color(0xFFFFD166)),
  'dusk': KitePalette(Color(0xFFE2703A), Color(0xFFFFCF8A)),
};

double _deg(double d) => d * math.pi / 180;

// --- padanan @keyframes sky-kite-drift (11s, ease-in-out semua segmen) ---
final List<KeyStop<Offset>> _driftStops = const [
  KeyStop(0.00, Offset(0, 0), curve: Curves.easeInOut),
  KeyStop(0.21, Offset(7, -9), curve: Curves.easeInOut),
  KeyStop(0.39, Offset(-4, -3), curve: Curves.easeInOut),
  KeyStop(0.57, Offset(9, -13), curve: Curves.easeInOut),
  KeyStop(0.78, Offset(-2, -5), curve: Curves.easeInOut),
  KeyStop(1.00, Offset(0, 0)),
];

// --- sky-kite-sway (7s), base linear + override kubik di 0%/17%/46% ---
final List<KeyStop<double>> _swayStops = const [
  KeyStop(0.00, -5, curve: Cubic(0.3, 0, 0.4, 1)),
  KeyStop(0.17, 3, curve: Cubic(0.4, 0, 0.6, 1)),
  KeyStop(0.31, -1, curve: Curves.linear),
  KeyStop(0.46, 6, curve: Cubic(0.5, 0, 0.5, 1)),
  KeyStop(0.63, 2, curve: Curves.linear),
  KeyStop(0.81, -4, curve: Curves.linear),
  KeyStop(1.00, -5),
];

class BankValue {
  final double scaleX, rotateDeg;
  const BankValue(this.scaleX, this.rotateDeg);
  static BankValue lerp(BankValue a, BankValue b, double t) => BankValue(
    lerpDoubleV(a.scaleX, b.scaleX, t),
    lerpDoubleV(a.rotateDeg, b.rotateDeg, t),
  );
}

// --- sky-kite-bank (9s, ease-in-out semua segmen) ---
final List<KeyStop<BankValue>> _bankStops = const [
  KeyStop(0.00, BankValue(1, 0), curve: Curves.easeInOut),
  KeyStop(0.26, BankValue(0.86, 2), curve: Curves.easeInOut),
  KeyStop(0.44, BankValue(0.98, -1.5), curve: Curves.easeInOut),
  KeyStop(0.68, BankValue(0.90, 2.5), curve: Curves.easeInOut),
  KeyStop(0.86, BankValue(0.97, -0.5), curve: Curves.easeInOut),
  KeyStop(1.00, BankValue(1, 0)),
];

// --- sky-kite-tail (1.5s, ease-in-out semua segmen) ---
final List<KeyStop<double>> _tailStops = const [
  KeyStop(0.00, -9, curve: Curves.easeInOut),
  KeyStop(0.19, 6, curve: Curves.easeInOut),
  KeyStop(0.36, -3, curve: Curves.easeInOut),
  KeyStop(0.54, 10, curve: Curves.easeInOut),
  KeyStop(0.71, -6, curve: Curves.easeInOut),
  KeyStop(0.88, 4, curve: Curves.easeInOut),
  KeyStop(1.00, -9),
];

/// Badan belah ketupat + rangka bambu + tali. Tali digambar di sistem
/// koordinat yang sama dengan badan (viewBox 0-40, memanjang ke y=132) supaya
/// pangkalnya tidak mungkin terlepas - padanan `<svg viewBox="0 0 40 40">`
/// pada komponen `Kite`.
class _KiteBodyPainter extends CustomPainter {
  const _KiteBodyPainter(this.palette);
  final KitePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    canvas.save();
    canvas.scale(scale);

    final stringPath = Path()
      ..moveTo(20, 33)
      ..quadraticBezierTo(9, 68, 2, 100)
      ..quadraticBezierTo(-3, 120, -1, 132);
    final stringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        const Offset(0, 34),
        const Offset(0, 132),
        [
          const Color(0xFF5C4428).withOpacity(0.26),
          const Color(0xFF5C4428).withOpacity(0.12),
          const Color(0xFF5C4428).withOpacity(0),
        ],
        const [0, 0.35, 1],
      );
    canvas.drawPath(stringPath, stringPaint);

    final right = Path()
      ..moveTo(20, 2)
      ..lineTo(36, 20)
      ..lineTo(20, 34)
      ..close();
    canvas.drawPath(right, Paint()..color = palette.body);

    final left = Path()
      ..moveTo(20, 2)
      ..lineTo(4, 20)
      ..lineTo(20, 34)
      ..close();
    canvas.drawPath(left, Paint()..color = palette.body.withOpacity(0.82));

    final framePaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(20, 2), const Offset(20, 34), framePaint);
    canvas.drawLine(const Offset(4, 20), const Offset(36, 20), framePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KiteBodyPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Ekor berpita, tiga bendera warna berselang-seling. Padanan SVG ekor
/// (viewBox 0 0 40 46).
class _TailPainter extends CustomPainter {
  const _TailPainter(this.palette);
  final KitePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    canvas.save();
    canvas.scale(scale);

    final spine = Path()
      ..moveTo(20, 0)
      ..quadraticBezierTo(16, 10, 20, 20)
      ..quadraticBezierTo(24, 30, 20, 40);
    canvas.drawPath(
      spine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFF543C20).withOpacity(0.55),
    );

    const ys = [7.0, 18.0, 29.0];
    for (var i = 0; i < ys.length; i++) {
      final y = ys[i];
      final flag = Path()
        ..moveTo(17, y)
        ..lineTo(23, y)
        ..lineTo(20, y + 6)
        ..close();
      canvas.drawPath(
        flag,
        Paint()..color = i % 2 == 0 ? palette.accent : palette.body,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Layang-layang belah ketupat: empat lapis gerakan (hanyut, ayun, miring,
/// kibasan ekor) dengan periode 11/7/9/1.5 detik yang tidak saling kelipatan,
/// supaya kombinasinya terasa seperti tertiup angin sungguhan. Padanan
/// komponen `Kite` di SkyAtmosphere.tsx.
class Kite extends StatelessWidget {
  const Kite({
    super.key,
    required this.clock,
    required this.size,
    required this.tone,
  });

  final SkyClock clock;
  final double size;

  /// 'noon' atau 'dusk'.
  final String tone;

  @override
  Widget build(BuildContext context) {
    final palette = kitePalette[tone]!;

    final drift = sampleKeyframes(
      _driftStops,
      clock.phase(11000),
      (a, b, t) => Offset.lerp(a, b, t)!,
    );
    final swayDeg = sampleKeyframes(_swayStops, clock.phase(7000), lerpDoubleV);
    final bank = sampleKeyframes(_bankStops, clock.phase(9000), BankValue.lerp);
    final tailDeg = sampleKeyframes(_tailStops, clock.phase(1500), lerpDoubleV);

    Widget body = SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _KiteBodyPainter(palette),
          ),
          Transform.translate(
            offset: Offset(0, -size * 0.06),
            child: Transform.rotate(
              angle: _deg(tailDeg),
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: size,
                height: size * 46 / 40,
                child: CustomPaint(painter: _TailPainter(palette)),
              ),
            ),
          ),
        ],
      ),
    );

    // lapisan 3: memiring/menyerong (scaleX lalu rotate, berporos ~tengah)
    body = Transform(
      transform: Matrix4.identity()
        ..scale(bank.scaleX, 1.0, 1.0)
        ..rotateZ(_deg(bank.rotateDeg)),
      alignment: const Alignment(0, -0.1), // 45% dari atas
      child: body,
    );

    // lapisan 2: ayunan pada tali, berporos di titik ikat atas
    body = Transform.rotate(
      angle: _deg(swayDeg),
      alignment: const Alignment(0, -0.84), // 8% dari atas
      child: body,
    );

    // lapisan 1: hanyut pelan naik-turun, persen dari ukurannya sendiri
    body = Transform.translate(
      offset: Offset(drift.dx / 100 * size, drift.dy / 100 * size),
      child: body,
    );

    return body;
  }
}
