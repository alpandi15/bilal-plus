import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/data/bilal_data.dart';
import 'package:rindu_ramadan/pages/bilal_tarawih_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/bilal_tarawih.dart';

void main() {
  test('data: 7 bagian, 82 bacaan, sama dengan web', () {
    expect(bilalSections, hasLength(7));
    expect(bilalSections.expand((s) => s.items), hasLength(82));
    expect(bilalSections.first.title, 'Sebelum Rakaat ke - 1&2');
    expect(bilalSections.last.title, "Dzikir & Do'a");
    expect(
      bilalSections.last.items.where((i) => i.kind == BilalKind.niat),
      hasLength(1),
    );
    for (final i in bilalSections.expand((s) => s.items)) {
      expect(i.arabic, isNotEmpty);
      expect(i.arabic, isNot(contains('ٱ')));
      // salah ketik yang sudah diperbaiki (tool/fix_bilal.py)
      expect(i.arabic, isNot(contains(',')), reason: i.arabic);
      expect(i.arabic, isNot(contains('  ')), reason: i.arabic);
      expect(i.arabic, isNot(contains('بِاا')), reason: i.arabic);
      expect(i.latin, isNot(contains('mailik')));
    }
  });

  testWidgets('pembaca: pindah bagian & ukuran teks tersimpan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsController();
    tester.view.physicalSize = const Size(411, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: settings,
        child: const MaterialApp(home: BilalTarawihPage()),
      ),
    );
    expect(
      find.text('Bagian 1 dari 7 · Sebelum Rakaat ke - 1&2'),
      findsOneWidget,
    );
    expect(find.text('Subhaanal-malikil-ma’buud'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bagian 2 dari 7 · Sebelum Rakaat ke - 3&4'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text("Dzikir & Do'a"),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text("Dzikir & Do'a"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Dzikir & Do'a"));
    await tester.pumpAndSettle();
    expect(find.text('7 / 7'), findsOneWidget);

    await tester.tap(find.byTooltip('Perbesar teks'));
    await tester.pump();
    expect(settings.readerSize, readerSizeDefault + 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(AppSettings.readerSizeKey), readerSizeDefault + 2);
  });
}
