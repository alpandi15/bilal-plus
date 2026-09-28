import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cincin progress bergradasi amber dengan ujung membulat; [child] di
/// tengahnya. Nilainya beranimasi halus saat [value] berubah.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 168,
    this.stroke = 14,
    this.child,
    this.color,
    this.track,
  });

  /// Warna busur (null = gradasi kuning-oranye) & lintasannya.
  final Color? color;
  final Color? track;

  /// 0.0..1.0
  final double value;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(v, stroke, color, track),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.track);
  final double value;
  final double stroke;
  final Color? color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track ?? const Color(0xFFF6E7CC),
    );
    if (value <= 0) return;

    const start = -math.pi / 2;
    final sweep = math.pi * 2 * value;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (color != null) {
      canvas.drawArc(arcRect, start, sweep, false, arc..color = color!);
      return;
    }
    canvas.drawArc(
      arcRect,
      start,
      sweep,
      false,
      arc
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [Color(0xFFFBBF24), Color(0xFFEA580C), Color(0xFFFBBF24)],
          transform: GradientRotation(start),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.stroke != stroke ||
      old.color != color ||
      old.track != track;
}
