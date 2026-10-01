import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/widgets/quran/mushaf_bookmark.dart';

void main() {
  Future<({List<String> log})> pump(WidgetTester tester) async {
    final log = <String>[];
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => log.add('halaman'),
                ),
              ),
              Positioned.fill(
                child: MushafBookmark(onRemoved: () => log.add('dilepas')),
              ),
            ],
          ),
        ),
      ),
    );
    // pembatas terjulur turun setelah jeda singkat
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    return (log: log);
  }

  double topOf(WidgetTester tester) =>
      tester.getTopLeft(find.byType(Image)).dy;

  testWidgets('ketuk: sembunyi lalu turun lagi; halaman tetap bisa diketuk', (
    tester,
  ) async {
    final r = await pump(tester);
    final shown = topOf(tester);
    expect(shown, lessThanOrEqualTo(0));
    expect(shown, greaterThan(-10));

    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    final hidden = topOf(tester);
    expect(hidden, lessThan(shown - 200), reason: 'naik, hanya ujungnya');

    // ujung yang mengintip: ketuk untuk menurunkan
    final tip = tester.getBottomLeft(find.byType(Image));
    await tester.tapAt(Offset(200, tip.dy - 8));
    await tester.pumpAndSettle();
    expect(topOf(tester), closeTo(shown, 1));

    // di luar pembatas sentuhan sampai ke halaman
    await tester.tapAt(const Offset(20, 700));
    expect(r.log, ['halaman']);
  });

  testWidgets('geser ke atas: pembatas dibuka', (tester) async {
    final r = await pump(tester);
    await tester.fling(find.byType(Image), const Offset(0, -300), 1200);
    await tester.pumpAndSettle();
    expect(r.log, ['dilepas']);
  });

  testWidgets('geser sedikit: kembali ke tempatnya', (tester) async {
    final r = await pump(tester);
    final shown = topOf(tester);
    await tester.timedDrag(
      find.byType(Image),
      const Offset(0, -20),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(r.log, isEmpty);
    expect(topOf(tester), closeTo(shown, 1));
  });
}
