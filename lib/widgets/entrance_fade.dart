import 'package:flutter/widgets.dart';

/// Muncul pertama kali dengan memudar masuk sambil naik sedikit - untuk
/// kartu pesan yang datang belakangan (data dimuat asinkron) supaya tidak
/// "meloncat" masuk. Hanya saat pertama dipasang; pembaruan isi sesudahnya
/// tidak dianimasikan ulang.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
    ),
    child: child,
  );
}
