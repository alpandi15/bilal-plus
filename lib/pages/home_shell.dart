import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings.dart';
import '../services/update_checker.dart';
import '../widgets/update_sheet.dart';
import 'beranda_page.dart';
import 'ibadah_page.dart';
import 'quran_tracker_page.dart';
import 'ramadan_recap_page.dart';
import 'report_page.dart';

/// Tab navigasi bawah.
enum HomeTab { beranda, ibadah, quran, laporan, ramadan }

/// Kerangka aplikasi: lima tab dengan navigasi bawah. Tiap tab yang pernah
/// dibuka tetap hidup (IndexedStack) supaya posisi gulir & tanggal yang
/// dibuka tidak hilang saat berpindah tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.beranda;

  @override
  void initState() {
    super.initState();
    // cek versi baru sesudah beranda tampil (paling sering sekali sehari,
    // diam bila offline) - lihat UpdateChecker.checkAutomatically
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    if (!mounted) return;
    final settings = AppSettingsScope.maybeOf(context);
    if (settings == null || !settings.autoUpdate) return;
    final update = await UpdateChecker().checkAutomatically();
    if (update != null && mounted) await showUpdateSheet(context, update);
  }

  /// Tab yang pernah dibuka - dibangun saat pertama dikunjungi (bukan
  /// semuanya sekaligus saat aplikasi dibuka), lalu tetap hidup.
  final _visited = {HomeTab.beranda};

  /// Waktu tombol kembali terakhir ditekan - tekan dua kali dalam
  /// [_exitWindow] untuk menutup aplikasi.
  DateTime? _lastBack;
  static const _exitWindow = Duration(seconds: 2);

  void _onBack() {
    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Tekan kembali sekali lagi untuk keluar'),
          duration: _exitWindow,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Naik setiap kali tab Laporan dibuka dari tab lain - animasi grafiknya
  /// diputar ulang (tab tetap hidup di IndexedStack).
  int _reportReplay = 0;

  void _select(HomeTab tab) => setState(() {
    if (tab == HomeTab.laporan && _tab != tab) _reportReplay++;
    _tab = tab;
    _visited.add(tab);
  });

  /// Pindah tab (dari kartu di beranda atau ketukan widget layar utama).
  void goTo(HomeTab tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _select(tab);
  }

  Widget _page(HomeTab tab) => switch (tab) {
    HomeTab.beranda => const BerandaPage(),
    HomeTab.ibadah => const IbadahPage(showBack: false),
    HomeTab.quran => const QuranTrackerPage(showBack: false),
    HomeTab.laporan => ReportPage(showBack: false, replay: _reportReplay),
    HomeTab.ramadan => const RamadanRecapPage(showBack: false),
  };

  @override
  Widget build(BuildContext context) {
    return HomeShellScope(
      goTo: goTo,
      // halaman lain di atas tab ini tetap kembali seperti biasa; di tab
      // utama tekan kembali dua kali untuk keluar
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFAF3),
          body: IndexedStack(
            index: _tab.index,
            children: [
              for (final t in HomeTab.values)
                _visited.contains(t) ? _page(t) : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (i) => _select(HomeTab.values[i]),
            backgroundColor: const Color(0xFFFFFBF3),
            indicatorColor: const Color(0xFFFDE68A),
            surfaceTintColor: Colors.transparent,
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: Color(0xFF92400E),
                ),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline_rounded),
                selectedIcon: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF92400E),
                ),
                label: 'Ibadah',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF92400E),
                ),
                label: "Qur'an",
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF92400E),
                ),
                label: 'Laporan',
              ),
              NavigationDestination(
                icon: Icon(Icons.nightlight_outlined),
                selectedIcon: Icon(
                  Icons.nightlight_round,
                  color: Color(0xFF92400E),
                ),
                label: 'Ramadan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Memberi kartu-kartu di dalam tab cara berpindah tab.
class HomeShellScope extends InheritedWidget {
  const HomeShellScope({super.key, required this.goTo, required super.child});

  final void Function(HomeTab tab) goTo;

  static HomeShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>();

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) => false;
}
