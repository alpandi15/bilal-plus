import 'package:flutter/material.dart';

import '../pages/asmaul_husna_page.dart';
import '../pages/backup_page.dart';
import '../pages/bilal_tarawih_page.dart';
import '../pages/doa_page.dart';
import '../pages/dzikir_page.dart';
import '../pages/hadits_page.dart';
import '../pages/hijri_calendar_page.dart';
import '../pages/kitab_yasin_page.dart';
import '../pages/quran/hafalan_page.dart';
import '../pages/qibla_page.dart';
import '../pages/settings_page.dart';
import '../pages/silsilah_page.dart';
import '../pages/sholat_guide_page.dart';
import '../pages/takbiran_page.dart';
import '../pages/tasbih_page.dart';
import '../pages/widgets_page.dart';
import '../pages/zakat_fitrah_page.dart';
import '../services/dzikir.dart';

/// Satu menu fitur (grid Beranda & lembar "Lainnya").
class FeatureMenu {
  const FeatureMenu(this.title, this.icon, this.colors, this.page);
  final String title;
  final IconData icon;

  /// Gradien ikon (atas-kiri -> bawah-kanan).
  final List<Color> colors;
  final Widget Function() page;
}

/// Kelompok menu di lembar "Lainnya".
final featureGroups = <(String, List<FeatureMenu>)>[
  (
    'IBADAH & BACAAN',
    [
      _kiblat,
      _hafalan,
      _dzikir,
      _usaiSholat,
      _asmaulHusna,
      _silsilah,
      _tasbih,
      _sholat,
      _hadits,
      _doa,
      _yasin,
    ],
  ),
  ('RAMADAN & HARI RAYA', [_bilal, _takbiran, _zakat]),
  ('ALAT', [_kalender, _widgets, _backup, _settings]),
];

/// Tujuh menu yang langsung tampil di Beranda (menu kedelapan "Lainnya").
final homeFeatures = [
  _kiblat,
  _dzikir,
  _tasbih,
  _hadits,
  _doa,
  _sholat,
  _bilal,
];

final _kiblat = FeatureMenu('Kiblat', Icons.explore_rounded, const [
  Color(0xFF4ADE80),
  Color(0xFF00503C),
], () => const QiblaPage());
final _hafalan = FeatureMenu('Hafalan', Icons.psychology_rounded, const [
  Color(0xFFA3E635),
  Color(0xFF047857),
], () => const HafalanPage());
final _usaiSholat = FeatureMenu(
  'Usai Sholat',
  Icons.mosque_rounded,
  const [Color(0xFF6EE7B7), Color(0xFF0F766E)],
  () => const DzikirPage(session: DzikirSession.sholat),
);
final _asmaulHusna = FeatureMenu(
  'Asmaul Husna',
  Icons.auto_awesome_rounded,
  const [Color(0xFFF2D38A), Color(0xFFB45309)],
  () => const AsmaulHusnaPage(),
);
final _silsilah = FeatureMenu(
  'Silsilah Nabi',
  Icons.account_tree_rounded,
  const [Color(0xFF34D399), Color(0xFF065F46)],
  () => const SilsilahPage(),
);
final _dzikir = FeatureMenu('Dzikir', Icons.auto_stories_rounded, const [
  Color(0xFF34D399),
  Color(0xFF059669),
], () => const DzikirPage());
final _tasbih = FeatureMenu(
  'Tasbih',
  Icons.touch_app_rounded,
  const [Color(0xFF14B8A6), Color(0xFF0C3A33)],
  () => const TasbihPage(
    title: 'Subhanallah',
    target: 33,
    presets: tasbihPresets,
  ),
);
final _sholat = FeatureMenu('Bacaan Sholat', Icons.menu_book_rounded, const [
  Color(0xFFF59E0B),
  Color(0xFFB45309),
], () => const SholatGuidePage());
final _hadits = FeatureMenu('Hadits', Icons.format_quote_rounded, const [
  Color(0xFF38BDF8),
  Color(0xFF0369A1),
], () => const HaditsPage());
final _doa = FeatureMenu("Do'a", Icons.volunteer_activism_rounded, const [
  Color(0xFFF472B6),
  Color(0xFFDB2777),
], () => const DoaPage());
final _yasin = FeatureMenu(
  'Yasin & Tahlil',
  Icons.import_contacts_rounded,
  const [Color(0xFF2DD4BF), Color(0xFF10B981)],
  () => const KitabYasinPage(),
);
final _bilal = FeatureMenu(
  'Bilal Tarawih',
  Icons.record_voice_over_rounded,
  const [Color(0xFF818CF8), Color(0xFF4F46E5)],
  () => const BilalTarawihPage(),
);
final _takbiran = FeatureMenu('Takbiran', Icons.campaign_rounded, const [
  Color(0xFFA78BFA),
  Color(0xFF6D28D9),
], () => const TakbiranPage());
final _zakat = FeatureMenu('Zakat Fitrah', Icons.rice_bowl_rounded, const [
  Color(0xFFFBBF24),
  Color(0xFFD97706),
], () => const ZakatFitrahPage());
final _kalender = FeatureMenu(
  'Kalender Hijriah',
  Icons.calendar_month_rounded,
  const [Color(0xFFFB923C), Color(0xFFEA580C)],
  () => const HijriCalendarPage(),
);
final _widgets = FeatureMenu('Widget', Icons.widgets_rounded, const [
  Color(0xFF2DD4BF),
  Color(0xFF0C3A33),
], () => const WidgetsPage());
final _backup = FeatureMenu('Cadangan Data', Icons.backup_rounded, const [
  Color(0xFF94A3B8),
  Color(0xFF475569),
], () => const BackupPage());
final _settings = FeatureMenu('Pengaturan', Icons.settings_rounded, const [
  Color(0xFF78716C),
  Color(0xFF44403C),
], () => const SettingsPage());

void openFeature(BuildContext context, FeatureMenu m) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => m.page()));

/// Ikon menu: kotak gradien + label (2 baris maksimal).
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  factory FeatureTile.of(BuildContext context, FeatureMenu m) => FeatureTile(
    title: m.title,
    icon: m.icon,
    colors: m.colors,
    onTap: () => openFeature(context, m),
  );

  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF44403C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid 4 kolom yang rapi - lebar kolom tetap, tinggi baris mengikuti
/// isinya (tidak meluap walau ukuran huruf sistem diperbesar).
class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key, required this.children});
  final List<Widget> children;

  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = (c.maxWidth - _gap * 3) / 4;
      return Wrap(
        spacing: _gap,
        runSpacing: 6,
        children: [
          for (final child in children) SizedBox(width: w, child: child),
        ],
      );
    },
  );
}

/// Lembar "Lainnya": semua menu, dikelompokkan.
Future<void> showAllFeatures(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (sheet) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.72,
    maxChildSize: 0.92,
    minChildSize: 0.4,
    builder: (_, controller) => ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24 + MediaQuery.paddingOf(sheet).bottom,
      ),
      children: [
        const Text(
          'Semua menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF44403C),
          ),
        ),
        for (final (title, menus) in featureGroups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
                color: Color(0xCCB45309),
              ),
            ),
          ),
          FeatureGrid(
            children: [
              for (final m in menus)
                FeatureTile(
                  title: m.title,
                  icon: m.icon,
                  colors: m.colors,
                  onTap: () {
                    Navigator.pop(sheet);
                    openFeature(context, m);
                  },
                ),
            ],
          ),
        ],
      ],
    ),
  ),
);
