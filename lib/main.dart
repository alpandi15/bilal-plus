import 'package:flutter/material.dart';

import 'db/app_database.dart';
import 'db/app_database_scope.dart';
import 'services/hijri_config.dart';
import 'services/hijri_config_scope.dart';
import 'services/user_location_controller.dart';
import 'services/user_location_scope.dart';
import 'pages/hijri_calendar_page.dart';
import 'pages/ibadah_page.dart';
import 'pages/kitab_yasin_page.dart';
import 'pages/quran_tracker_page.dart';
import 'widgets/menu_card.dart';
import 'widgets/prayer_times_card.dart';
import 'widgets/ramadan_countdown.dart';

void main() {
  runApp(const RinduRamadanApp());
}

class RinduRamadanApp extends StatefulWidget {
  const RinduRamadanApp({super.key, this.database});

  /// Basis data pengganti (mis. in-memory untuk uji); null = berkas SQLite
  /// aplikasi.
  final AppDatabase? database;

  @override
  State<RinduRamadanApp> createState() => _RinduRamadanAppState();
}

class _RinduRamadanAppState extends State<RinduRamadanApp> {
  final _location = UserLocationController();

  // drift membuka berkasnya secara malas (pada kueri pertama), jadi membuat
  // objeknya di sini tidak memperlambat awal aplikasi
  late final AppDatabase _db = widget.database ?? AppDatabase();

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
    if (widget.database == null) _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDatabaseScope(
      database: _db,
      child: UserLocationScope(
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
              'quran' => const QuranTrackerPage(),
              'ibadah' => const IbadahPage(),
              _ => const _DemoPage(),
            },
          ),
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
                    title: 'Ibadah Harian',
                    description: 'Checklist sholat, puasa & sunnah',
                    icon: Icons.check_circle_rounded,
                    badge: const [Color(0xFF34D399), Color(0xFF059669)],
                    wash: const [
                      Color(0xFFECFDF5),
                      Colors.white,
                      Color(0xFFF0FDF4),
                    ],
                    glow: const Color(0x736EE7B7),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const IbadahPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  MenuCard(
                    title: "Tilawah Al-Qur'an",
                    description: 'Catatan bacaan & target khatam',
                    icon: Icons.menu_book_rounded,
                    badge: const [Color(0xFF818CF8), Color(0xFF6366F1)],
                    wash: const [
                      Color(0xFFEEF2FF),
                      Colors.white,
                      Color(0xFFF5F3FF),
                    ],
                    glow: const Color(0x73A5B4FC),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QuranTrackerPage(),
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
