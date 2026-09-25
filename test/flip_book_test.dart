import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/pages/kitab_yasin_page.dart';

void main() {
  testWidgets('Kitab Yasin: balik halaman, daftar isi, layar penuh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: KitabYasinPage()));
    await tester.pumpAndSettle();

    expect(find.text('Surat Yasin, Tahtim & Tahlil'), findsOneWidget);
    expect(find.textContaining('Halaman 1 '), findsOneWidget);

    // ketuk tepi kanan buku -> lembar dibalik ke halaman 2
    final book = find.byType(Image).first;
    final rect = tester.getRect(book);
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(KitabYasinPage),
      matchesGoldenFile('goldens/flip_mid.png'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Halaman 2 '), findsOneWidget);

    // geser ke kiri -> halaman 3
    await tester.fling(book, const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.textContaining('Halaman 3 '), findsOneWidget);

    // daftar isi -> lompat ke Tahlil (hal. 91)
    await tester.ensureVisible(find.text('Daftar Isi'));
    await tester.tap(find.text('Daftar Isi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tahlil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Halaman 91 '), findsOneWidget);
    await expectLater(
      find.byType(KitabYasinPage),
      matchesGoldenFile('goldens/page_91.png'),
    );

    // layar penuh membawa halaman yang sama, keluar mengembalikannya
    await tester.ensureVisible(find.text('Layar Penuh'));
    await tester.tap(find.text('Layar Penuh'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.textContaining('Halaman 91 '), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/fullscreen.png'),
    );
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Layar Penuh'), findsOneWidget);
    expect(find.textContaining('Halaman 92 '), findsOneWidget);
  });
}
