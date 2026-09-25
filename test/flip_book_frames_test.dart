import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/yasin_kitab.dart';
import 'package:rindu_ramadan/widgets/flip_book.dart';

/// Memotret animasi balik lembar pada beberapa titik waktu (golden) untuk
/// diperiksa mata - mode satu halaman (ponsel) dan dua halaman (tablet
/// mendatar). Gambar halaman dimuat dulu lewat runAsync supaya benar-benar
/// terdekode sebelum dipotret.
void main() {
  Future<void> run(
    WidgetTester tester, {
    required Size size,
    required String name,
    required int startPage,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFFFFAF3),
          body: Center(
            child: FlipBook(
              total: yasinTotalPages,
              ratio: yasinPageRatio,
              asset: yasinPageAsset,
              chapters: yasinChapters,
              title: yasinTitle,
              initialPage: startPage,
              onToggleFullscreen: () {},
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (var p = startPage - 2; p <= startPage + 3; p++) {
        if (p >= 1) {
          await precacheImage(
            AssetImage(yasinPageAsset(p)),
            tester.element(find.byType(FlipBook)),
          );
        }
      }
    });
    await tester.pumpAndSettle();

    // gambar terakhir = halaman kanan (pada tampilan dua halaman) - tepi
    // kanannya adalah zona ketuk "berikutnya"
    final book = find.byType(Image).last;
    final rect = tester.getRect(book);
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    for (final ms in [150, 350, 550, 750]) {
      await tester.pump(Duration(milliseconds: ms == 150 ? 150 : 200));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/frames_${name}_$ms.png'),
      );
    }
    await tester.pumpAndSettle();
  }

  testWidgets('frame balik lembar - satu halaman', (tester) async {
    await run(
      tester,
      size: const Size(400, 760),
      name: 'single',
      startPage: 10,
    );
  });

  testWidgets('frame balik lembar - dua halaman', (tester) async {
    await run(
      tester,
      size: const Size(1100, 760),
      name: 'spread',
      startPage: 11,
    );
  });
}
