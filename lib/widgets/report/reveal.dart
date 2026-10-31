import 'package:flutter/widgets.dart';

/// Menandai pohon widget yang sedang ditangkap sebagai gambar/PDF: [Reveal]
/// & [Entrance] di bawahnya tampil di keadaan akhir tanpa animasi, dan
/// petunjuk interaktif (mis. "ketuk untuk...") bisa disembunyikan.
class ExportMode extends InheritedWidget {
  const ExportMode({super.key, required this.exporting, required super.child});
  final bool exporting;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExportMode>()?.exporting ??
      false;

  @override
  bool updateShouldNotify(ExportMode old) => old.exporting != exporting;
}

/// Animasi masuk 0 → 1 sekali saat pertama dibangun, setelah jeda [delay]
/// (ms). Diputar ulang bila widget dibuat ulang (mis. ganti rentang).
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.builder,
    this.delay = 0,
    this.duration = 800,
    this.curve = Curves.easeOutCubic,
  });

  final Widget Function(BuildContext context, double t) builder;
  final int delay, duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    // saat mengekspor gambar/PDF, semua animasi langsung di keadaan akhir
    if (ExportMode.of(context)) return builder(context, 1);
    final total = delay + duration;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, v, _) {
        final t = ((v * total - delay) / duration).clamp(0.0, 1.0);
        return builder(context, curve.transform(t));
      },
    );
  }
}

/// Kartu muncul: memudar & naik sedikit.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => Reveal(
    delay: delay,
    duration: 600,
    builder: (context, t) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
    ),
  );
}
