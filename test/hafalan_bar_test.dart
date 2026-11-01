import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/quran/hafalan_page.dart';
import 'package:rindu_ramadan/services/quran_text.dart';

void main() {
  testWidgets('sakelar sembunyikan ayat tetap terjangkau setelah menggulir', (
    tester,
  ) async {
    final quran = QuranText.parse(
      File('assets/quran/quran.json').readAsStringSync(),
    );
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: MaterialApp(
          home: HafalanSurahPage(text: quran, surah: quran.surah(67)),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    // gulir jauh ke tengah surah
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Tutup'), findsOneWidget);

    await tester.tap(find.text('Tutup'));
    await tester.pump();
    expect(find.text('Tertutup'), findsOneWidget);

    await tester.tap(find.text('Tertutup'));
    await tester.pump();
    expect(find.text('Tutup'), findsOneWidget);
  });
}
