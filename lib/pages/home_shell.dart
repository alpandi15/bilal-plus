import 'package:flutter/material.dart';

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

  /// Tab yang pernah dibuka - dibangun saat pertama dikunjungi (bukan
  /// semuanya sekaligus saat aplikasi dibuka), lalu tetap hidup.
  final _visited = {HomeTab.beranda};

  void _select(HomeTab tab) => setState(() {
    _tab = tab;
    _visited.add(tab);
  });

  /// Pindah tab (dari kartu di beranda atau ketukan widget layar utama).
  void goTo(HomeTab tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _select(tab);
  }

  static Widget _page(HomeTab tab) => switch (tab) {
    HomeTab.beranda => const BerandaPage(),
    HomeTab.ibadah => const IbadahPage(showBack: false),
    HomeTab.quran => const QuranTrackerPage(showBack: false),
    HomeTab.laporan => const ReportPage(showBack: false),
    HomeTab.ramadan => const RamadanRecapPage(showBack: false),
  };

  @override
  Widget build(BuildContext context) {
    return HomeShellScope(
      goTo: goTo,
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
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF92400E)),
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
