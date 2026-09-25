import 'package:flutter/material.dart';

import '../widgets/menu_card.dart';
import '../widgets/sub_header.dart';
import 'backup_page.dart';
import 'bilal_tarawih_page.dart';
import 'dzikir_page.dart';
import 'hijri_calendar_page.dart';
import 'kitab_yasin_page.dart';
import 'ramadan_recap_page.dart';
import 'settings_page.dart';
import 'sholat_guide_page.dart';
import 'tasbih_page.dart';

/// Tab Lainnya: fitur pendukung yang tidak dibuka setiap hari.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        'Bilal Tarawih 11 Rakaat',
        'Bacaan bilal per bagian, sampai witir',
        Icons.record_voice_over_rounded,
        const [Color(0xFF818CF8), Color(0xFF4F46E5)],
        const [Color(0xFFEEF2FF), Colors.white, Color(0xFFF5F3FF)],
        const Color(0x73A5B4FC),
        const BilalTarawihPage(),
      ),
      (
        'Dzikir Pagi & Petang',
        'Bacaan Hisnul Muslim + penghitung',
        Icons.auto_stories_rounded,
        const [Color(0xFF34D399), Color(0xFF059669)],
        const [Color(0xFFECFDF5), Colors.white, Color(0xFFF0FDF4)],
        const Color(0x736EE7B7),
        const DzikirPage(),
      ),
      (
        'Bacaan Sholat',
        'Niat sampai salam · versi madzhab',
        Icons.menu_book_rounded,
        const [Color(0xFFF59E0B), Color(0xFFB45309)],
        const [Color(0xFFFFFBEB), Colors.white, Color(0xFFFFF7ED)],
        const Color(0x73F59E0B),
        const SholatGuidePage(),
      ),
      (
        'Tasbih Digital',
        'Hitung dzikir layar penuh',
        Icons.touch_app_rounded,
        const [Color(0xFF0F766E), Color(0xFF0C3A33)],
        const [Color(0xFFF0FDFA), Colors.white, Color(0xFFECFDF5)],
        const Color(0x7314B8A6),
        const TasbihPage(
          title: 'Subhanallah',
          target: 33,
          presets: tasbihPresets,
        ),
      ),
      (
        'Kalender Hijriah',
        'Masehi & Hijriah berdampingan',
        Icons.calendar_month_rounded,
        const [Color(0xFFFBBF24), Color(0xFFEA580C)],
        const [Color(0xFFFFFBEB), Colors.white, Color(0xFFFFF7ED)],
        const Color(0x73FBBF24),
        const HijriCalendarPage(),
      ),
      (
        'Rekap Ramadan',
        'Puasa, tarawih & hutang qadha',
        Icons.nightlight_round,
        const [Color(0xFF818CF8), Color(0xFF6366F1)],
        const [Color(0xFFEEF2FF), Colors.white, Color(0xFFF5F3FF)],
        const Color(0x73A5B4FC),
        const RamadanRecapPage(),
      ),
      (
        'Yasin, Tahtim & Tahlil',
        'Kitab Lengkap',
        Icons.volunteer_activism_rounded,
        const [Color(0xFF2DD4BF), Color(0xFF10B981)],
        const [Color(0xFFF0FDFA), Colors.white, Color(0xFFECFDF5)],
        const Color(0x735EEAD4),
        const KitabYasinPage(),
      ),
      (
        'Cadangan Data',
        'Backup & pulihkan catatan',
        Icons.backup_rounded,
        const [Color(0xFF94A3B8), Color(0xFF475569)],
        const [Color(0xFFF8FAFC), Colors.white, Color(0xFFF1F5F9)],
        const Color(0x73CBD5E1),
        const BackupPage(),
      ),
      (
        'Pengaturan',
        'Waktu sholat, kalender, daftar ibadah',
        Icons.settings_rounded,
        const [Color(0xFFF59E0B), Color(0xFFB45309)],
        const [Color(0xFFFFFBEB), Colors.white, Color(0xFFFFF7ED)],
        const Color(0x73FCD34D),
        const SettingsPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(title: 'Lainnya', showBack: false),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                for (final (title, desc, icon, badge, wash, glow, page)
                    in entries) ...[
                  MenuCard(
                    title: title,
                    description: desc,
                    icon: icon,
                    badge: badge,
                    wash: wash,
                    glow: glow,
                    onTap: () => _open(context, page),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
