import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import 'onboarding_page.dart';

/// Warna latar splash = latar ikon adaptif
/// (android/.../values/ic_launcher_background.xml).
const splashBackground = Color(0xFF00503C);
const _gold = Color(0xFFE3BE6A);

/// Medali logo Bilal+ - ukurannya sama dengan ikon splash Android 12+
/// (lingkaran 160dp), jadi splash native berganti ke Flutter tanpa loncatan.
class BilalLogo extends StatelessWidget {
  const BilalLogo({super.key, this.size = 160});
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: OverflowBox(
        maxWidth: size * 1.1,
        maxHeight: size * 1.1,
        child: Image.asset(
          'assets/branding/logo.png',
          width: size * 1.1,
          height: size * 1.1,
          fit: BoxFit.cover,
          semanticLabel: 'Bilal+',
        ),
      ),
    ),
  );
}

/// Layar splash: sambungan splash native sampai pengaturan terbaca.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: splashBackground,
      body: Stack(
        children: [
          Center(child: BilalLogo()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Text(
              'Teman ibadah harian',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: _gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Splash -> setup awal (sekali) -> [home].
class StartGate extends StatelessWidget {
  const StartGate({super.key, required this.home, this.onboarding = true});

  final Widget home;

  /// false: lewati setup awal (uji & `INITIAL_PAGE`).
  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final Widget child;
    if (!settings.ready) {
      child = const SplashView(key: ValueKey('splash'));
    } else if (onboarding && !settings.onboarded) {
      child = const OnboardingPage(key: ValueKey('onboarding'));
    } else {
      child = KeyedSubtree(key: const ValueKey('home'), child: home);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      child: child,
    );
  }
}
