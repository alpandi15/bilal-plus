import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../services/system_channel.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Satu widget layar utama yang bisa dipasang dari aplikasi.
class HomeWidgetInfo {
  const HomeWidgetInfo(this.provider, this.title, this.size, this.detail);

  /// Nama kelas AppWidgetProvider (paket com.rinduramadan.app).
  final String provider;
  final String title, size, detail;

  String get preview =>
      'assets/widgets/${const {'PrayerWidgetProvider': 'jadwal-sholat', 'IbadahWidgetProvider': 'ibadah', 'QuranWidgetProvider': 'quran', 'SemangatWidgetProvider': 'semangat', 'RamadanWidgetProvider': 'ramadan'}[provider]}.webp';
}

const homeWidgets = [
  HomeWidgetInfo(
    'PrayerWidgetProvider',
    'Jadwal Sholat',
    '4x2',
    'Jam berjalan, hitung mundur waktu sholat berikutnya, langit sesuai waktu.',
  ),
  HomeWidgetInfo(
    'IbadahWidgetProvider',
    'Ibadah Harian',
    '2x3',
    'Centang sholat lima waktu & ibadah lainnya langsung dari layar utama.',
  ),
  HomeWidgetInfo(
    'QuranWidgetProvider',
    "Tilawah Al-Qur'an",
    '2x3',
    'Progres khatam, target hari ini, dan tombol lanjut baca.',
  ),
  HomeWidgetInfo(
    'SemangatWidgetProvider',
    'Semangat Sholat',
    '3x2',
    'Pesan santai sesuai waktu sholat sekarang, plus lima waktu.',
  ),
  HomeWidgetInfo(
    'RamadanWidgetProvider',
    'Hitung Mundur Ramadan',
    '2x2',
    'Sisa hari menuju Ramadan, hari ke-n Ramadan, dan Idulfitri.',
  ),
];

/// Daftar widget dengan tombol "Pasang": meminta launcher menambahkan widget
/// langsung ke layar utama (Android 8+) - berguna bila widget pihak ketiga
/// tidak muncul di daftar widget launcher (mis. sebagian HP Xiaomi).
class WidgetsPage extends StatefulWidget {
  const WidgetsPage({super.key});

  @override
  State<WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<WidgetsPage> {
  /// null = belum diketahui; false = launcher tidak mendukung pasang langsung.
  bool? _supported;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    var ok = false;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        ok = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      } on Exception {
        ok = false;
      }
    }
    if (mounted) setState(() => _supported = ok);
  }

  Future<void> _pin(HomeWidgetInfo w) async {
    try {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: 'com.rinduramadan.app.${w.provider}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konfirmasi "Tambahkan" untuk memasang widget ${w.title}. '
            'Bila tidak muncul, izinkan "Pintasan layar utama" untuk Bilal+.',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Izin',
            onPressed: SystemChannel.openAppSettings,
          ),
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Launcher menolak - tambahkan lewat daftar widget.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(title: 'Widget', subtitle: 'Pasang di layar utama'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (_supported == false) const _Unsupported(),
                for (final w in homeWidgets)
                  _WidgetCard(
                    info: w,
                    onPin: _supported == true ? () => _pin(w) : null,
                  ),
                const _Tips(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({required this.info, required this.onPin});
  final HomeWidgetInfo info;
  final VoidCallback? onPin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // pratinjau di atas latar gelap mirip wallpaper
          Container(
            height: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E3A5F), Color(0xFF0C3A33)],
              ),
            ),
            child: Image.asset(info.preview, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info.title}  ·  ${info.size}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.detail,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _amber),
                onPressed: onPin,
                icon: const Icon(Icons.add_to_home_screen_rounded, size: 18),
                label: const Text('Pasang'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFDE68A)),
    ),
    child: const Text(
      'Launcher HP ini tidak mendukung pasang widget langsung dari aplikasi. '
      'Tekan lama layar utama → Widget → cari "Bilal+".',
      style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF92400E)),
    ),
  );
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFA7F3D0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Widget tidak muncul?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF065F46),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '• Xiaomi/Redmi/POCO: izinkan "Pintasan layar utama" & "Mulai '
          'otomatis" untuk Bilal+, lalu coba Pasang lagi.\n'
          '• Tema launcher kustom kadang menyembunyikan widget aplikasi lain '
          '- kembalikan ke tema bawaan.\n'
          '• Buka Bilal+ sekali sesudah memasang supaya data widget terisi.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF065F46)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: SystemChannel.openAppSettings,
          icon: const Icon(Icons.settings_applications_rounded, size: 18),
          label: const Text('Buka izin aplikasi'),
        ),
      ],
    ),
  );
}
