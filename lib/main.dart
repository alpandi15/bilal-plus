import 'package:flutter/material.dart';

import 'services/hijri_config.dart';
import 'services/hijri_config_scope.dart';
import 'services/user_location_controller.dart';
import 'services/user_location_scope.dart';
import 'pages/hijri_calendar_page.dart';
import 'pages/kitab_yasin_page.dart';
import 'widgets/menu_card.dart';
import 'widgets/prayer_times_card.dart';
import 'widgets/ramadan_countdown.dart';

void main() {
  runApp(const RinduRamadanApp());
}

class RinduRamadanApp extends StatefulWidget {
  const RinduRamadanApp({super.key});

  @override
  State<RinduRamadanApp> createState() => _RinduRamadanAppState();
}

class _RinduRamadanAppState extends State<RinduRamadanApp> {
  final _location = UserLocationController();

  // --dart-define=HIJRI_URL=... untuk mengarahkan unduhan konfigurasi ke
  // server lain (mis. `next dev` lokal saat mengembangkan); kosong = bawaan
  final _hijri = HijriConfigController(
    remoteUrl: const String.fromEnvironment('HIJRI_URL').isEmpty
        ? 'https://bilal-tarawih.vercel.app/api/hijri'
        : const String.fromEnvironment('HIJRI_URL'),
  );

  @override
  void initState() {
    super.initState();
    _location.init();
    _hijri.init();
  }

  @override
  void dispose() {
    _location.dispose();
    _hijri.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserLocationScope(
      controller: _location,
      child: HijriConfigScope(
        controller: _hijri,
        child: MaterialApp(
          title: 'Rindu Ramadan',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
          // --dart-define=INITIAL_PAGE=calendar untuk langsung membuka
          // halaman tertentu saat mengembangkan/uji tangkapan layar
          home: switch (const String.fromEnvironment('INITIAL_PAGE')) {
            'calendar' => const HijriCalendarPage(),
            _ => const _DemoPage(),
          },
        ),
      ),
    );
  }
}

/// Halaman percobaan: hitung mundur Ramadan + kartu jadwal sholat, lengkap
/// dengan lokasi GPS/pemilih kabupaten - padanan susunan beranda web
/// (`countdown.tsx` + `PrayerTimesCard.tsx`).
class _DemoPage extends StatelessWidget {
  const _DemoPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const RamadanCountdown(),
                  const SizedBox(height: 24),
                  const PrayerTimesCard(),
                  const SizedBox(height: 24),
                  MenuCard(
                    title: 'Kalender Hijriah',
                    description: 'Masehi & Hijriah berdampingan',
                    icon: Icons.calendar_month_rounded,
                    badge: const [Color(0xFFFBBF24), Color(0xFFEA580C)],
                    wash: const [
                      Color(0xFFFFFBEB),
                      Colors.white,
                      Color(0xFFFFF7ED),
                    ],
                    glow: const Color(0x73FBBF24),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HijriCalendarPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  MenuCard(
                    title: 'Yasin, Tahtim & Tahlil',
                    description: 'Kitab Lengkap',
                    icon: Icons.volunteer_activism_rounded,
                    badge: const [Color(0xFF2DD4BF), Color(0xFF10B981)],
                    wash: const [
                      Color(0xFFF0FDFA),
                      Colors.white,
                      Color(0xFFECFDF5),
                    ],
                    glow: const Color(0x735EEAD4),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KitabYasinPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
