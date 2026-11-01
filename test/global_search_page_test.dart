import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/hadits_database.dart';
import 'package:rindu_ramadan/pages/doa_page.dart';
import 'package:rindu_ramadan/pages/global_search_page.dart';
import 'package:rindu_ramadan/services/quran_text.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    File('assets/quran/uthmani.json').readAsStringSync(),
  );
  const doa = [
    Doa(
      title: 'Doa Sebelum Makan',
      tema: 'umum',
      readings: [
        DoaReading(
          arabic: 'x',
          latin: 'Allahumma baarik',
          arti: 'Ya Allah, berkahilah kami',
        ),
      ],
    ),
  ];
  late HaditsDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = HaditsDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Widget app() => MaterialApp(
    home: GlobalSearchPage(
      quran: Future.value(quran),
      doa: Future.value(doa),
      hadits: db,
    ),
  );

  testWidgets('awal: petunjuk; ketik: hasil terkelompok & jumlah', (
    tester,
  ) async {
    await db.insertPage('bukhari', [
      Hadith(
        book: 'bukhari',
        number: 2,
        arab: 'b',
        translation: 'Sabar itu pada pukulan pertama',
      ),
    ]);
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.textContaining('Ketik kata kunci'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sabar');
    await settle(tester);
    expect(find.textContaining("Al-Qur'an ·"), findsOneWidget);
    expect(find.textContaining('Hadits ·'), findsOneWidget);
    expect(find.textContaining('Shahih Bukhari · No. 2'), findsOneWidget);
  });

  testWidgets('tanpa hasil & belum ada kitab hadits', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'qwertyzzz');
    await settle(tester);
    // hadits belum diunduh -> ajakan unduh, bukan "tidak ada hasil"
    expect(find.textContaining('belum diunduh'), findsOneWidget);
  });

  testWidgets('Asmaul Husna & do\'a muncul; ketuk hasil menyimpan riwayat', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'berkahilah');
    await settle(tester);
    expect(find.text('Doa Sebelum Makan'), findsOneWidget);
    await tester.tap(find.text('Doa Sebelum Makan'));
    await settle(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('search_recent'), ['berkahilah']);
  });

  testWidgets('riwayat tampil lagi saat kolom kosong & bisa dihapus', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'search_recent': ['niat', 'sabar'],
    });
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('niat'), findsOneWidget);
    expect(find.text('sabar'), findsOneWidget);
    await tester.tap(find.text('Hapus'));
    await settle(tester);
    expect(find.text('niat'), findsNothing);
    expect(find.textContaining('Ketik kata kunci'), findsOneWidget);
  });
}
