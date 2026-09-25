import 'package:flutter/material.dart';

import 'beranda_page.dart';
import 'ibadah_page.dart';
import 'more_page.dart';
import 'quran_tracker_page.dart';
import 'report_page.dart';

/// Tab navigasi bawah.
enum HomeTab { beranda, ibadah, quran, laporan, lainnya }

/// Kerangka aplikasi: lima tab dengan navigasi bawah. Tiap tab tetap
/// hidup (IndexedStack) supaya posisi gulir & tanggal yang dibuka tidak
/// hilang saat berpindah tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.beranda;

  /// Pindah tab (dari kartu di beranda atau ketukan widget layar utama).
  void goTo(HomeTab tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return HomeShellScope(
      goTo: goTo,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFAF3),
        body: IndexedStack(
          index: _tab.index,
          children: const [
            BerandaPage(),
            IbadahPage(showBack: false),
            QuranTrackerPage(showBack: false),
            ReportPage(showBack: false),
            MorePage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) =>
              setState(() => _tab = HomeTab.values[i]),
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
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF92400E),
              ),
              label: 'Lainnya',
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
