import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/quran_tracker_page.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    // kueri drift berjalan di luar waktu palsu pengujian
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: UserLocationScope(
          controller: UserLocationController(),
          child: const MaterialApp(home: QuranTrackerPage()),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('catat bacaan lewat pemilih Juz -> Surah -> Ayat', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Belum ada bacaan di putaran ini'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.text('Mulai catat bacaan'));
    await settle(tester);
    expect(find.text('Sudah baca sampai mana?'), findsOneWidget);
    // Juz 1 berisi Al-Fatihah & Al-Baqarah 1-141 saja
    expect(find.text('1. Al-Fatihah'), findsOneWidget);
    expect(find.text('2. Al-Baqarah'), findsOneWidget);
    expect(find.text('ayat 1-141'), findsOneWidget);
    expect(find.text('3. Ali \'Imran'), findsNothing);

    await tester.tap(find.text('Akhir juz'));
    await tester.pump();
    expect(find.text('Al-Baqarah ayat 141'), findsOneWidget);
    expect(find.textContaining('+21 halaman'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await settle(tester);

    expect(find.text('Al-Baqarah 141'), findsOneWidget);
    expect(find.text('Juz 1 · Halaman 21'), findsOneWidget);
    expect(find.text('3%'), findsOneWidget);
    expect(find.text('Lanjut dari Al-Baqarah 142'), findsOneWidget);
    expect(await db.quranDao.progress().then((p) => p.lastAyah), 148);
  });

  testWidgets('atur target khatam 30 hari', (tester) async {
    await open(tester);
    await tester.tap(find.textContaining('Atur target khatam'));
    await settle(tester);
    await tester.tap(find.textContaining('30 hari'));
    await settle(tester);

    expect(find.text('TARGET HARI INI'), findsOneWidget);
    expect(find.text('Sampai Al-Baqarah 141'), findsOneWidget);
    expect(find.textContaining('sisa 30 hari'), findsOneWidget);
  });

  testWidgets('ketuk juz di peta membuka pemilih di juz itu', (tester) async {
    await open(tester);
    await tester.ensureVisible(find.text('30').last);
    await tester.tap(find.text('30').last);
    await settle(tester);
    expect(find.text("78. An-Naba'"), findsOneWidget);
    expect(find.text("An-Nas ayat 6"), findsOneWidget);
  });
}
