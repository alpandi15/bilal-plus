import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/yasin_kitab.dart';
import '../widgets/flip_book.dart';
import '../widgets/sub_header.dart';

/// Halaman kitab "Surat Yasin, Tahtim & Tahlil" - padanan
/// `src/app/bacaan/yasin/main.tsx` di web.
class KitabYasinPage extends StatefulWidget {
  const KitabYasinPage({super.key});

  @override
  State<KitabYasinPage> createState() => _KitabYasinPageState();
}

class _KitabYasinPageState extends State<KitabYasinPage> {
  int _page = 1;

  Future<void> _openFullscreen() async {
    // tidak di-await: di platform tanpa dukungan (web/desktop/uji) panggilan
    // ini bisa tak pernah selesai, dan bukunya tetap harus terbuka
    unawaited(_setSystemUi(SystemUiMode.immersiveSticky));
    final result = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondary) =>
            _KitabFullscreenPage(initialPage: _page),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    unawaited(_setSystemUi(SystemUiMode.edgeToEdge));
    if (result != null && mounted) setState(() => _page = result);
  }

  static Future<void> _setSystemUi(SystemUiMode mode) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(mode);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(
            title: 'Yasin, Tahtim & Tahlil',
            subtitle: 'Arab, Latin & Terjemah',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      const _InfoCard(),
                      const SizedBox(height: 20),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xCCFEF3C7)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x21785624),
                              blurRadius: 44,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: FlipBook(
                            // dibangun ulang dengan halaman terakhir sepulang dari layar penuh
                            key: ValueKey('book-$_page'),
                            total: yasinTotalPages,
                            ratio: yasinPageRatio,
                            asset: yasinPageAsset,
                            chapters: yasinChapters,
                            title: yasinTitle,
                            initialPage: _page,
                            onPageChanged: (p) => _page = p,
                            onToggleFullscreen: _openFullscreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Geser atau ketuk tepi halaman untuk membalik.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          color: Color(0xFFA8A29E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xCCFEF3C7)),
        gradient: const LinearGradient(
          begin: Alignment(-1, -0.6),
          end: Alignment(1, 0.6),
          colors: [Colors.white, Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F785624),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'KITAB',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Color(0xCCB45309),
            ),
          ),
          SizedBox(height: 6),
          Text(
            yasinTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: Color(0xFF1C1917),
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Doa & Shalat Jenazah · Drs. Abu Zulfa · Penerbit Su'udiyah, Medan · $yasinTotalPages halaman",
            style: TextStyle(fontSize: 12, color: Color(0xFF78716C)),
          ),
        ],
      ),
    );
  }
}

/// Mode layar penuh: latar gelap, buku memenuhi sisa layar. Mengembalikan
/// nomor halaman terakhir saat ditutup.
class _KitabFullscreenPage extends StatefulWidget {
  const _KitabFullscreenPage({required this.initialPage});
  final int initialPage;

  @override
  State<_KitabFullscreenPage> createState() => _KitabFullscreenPageState();
}

class _KitabFullscreenPageState extends State<_KitabFullscreenPage> {
  late int _page = widget.initialPage;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_page);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF191410),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1),
              radius: 1.3,
              colors: [Color(0xFF33281C), Color(0xFF191410), Color(0xFF100C09)],
              stops: [0, 0.65, 1],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: FlipBook(
              total: yasinTotalPages,
              ratio: yasinPageRatio,
              asset: yasinPageAsset,
              chapters: yasinChapters,
              title: yasinTitle,
              initialPage: widget.initialPage,
              fullscreen: true,
              onPageChanged: (p) => _page = p,
              onToggleFullscreen: () => Navigator.of(context).pop(_page),
            ),
          ),
        ),
      ),
    );
  }
}
