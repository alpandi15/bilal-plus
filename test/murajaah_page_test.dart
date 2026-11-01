import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/quran/murajaah_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/murajaah.dart';
import 'package:rindu_ramadan/services/prayer_calculator.dart' as calc;
import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

void main() {
  late AppDatabase db;
  late String today;
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    File('assets/quran/uthmani.json').readAsStringSync(),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    today = dateKey(calc.todayInZone(calc.TimezoneCode.wib));
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Widget app(Widget home) => AppDatabaseScope(
    database: db,
    child: UserLocationScope(
      controller: UserLocationController(),
      child: AppSettingsScope(
        controller: AppSettingsController(),
        child: MaterialApp(home: home),
      ),
    ),
  );

  testWidgets('sesi: tampilkan ayat, nilai Lancar, jadwal maju', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await db.quranDao.setHafal(6232, 6236, true); // An-Nas 1-5
    await db.quranDao.syncReviews(today);
    // jatuhkan tempo ke hari ini agar masuk sesi
    await db.customStatement("UPDATE hafalan_reviews SET due_date = '$today'");
    final units = await db.quranDao.reviewsAll();
    expect(units, hasLength(1));

    await tester.pumpWidget(
      app(MurajaahSessionPage(units: units, text: quran, today: today)),
    );
    await settle(tester);
    expect(find.text('Unit 1 dari 1'), findsOneWidget);
    expect(find.text('Lancar'), findsNothing); // belum ditampilkan

    await tester.tap(find.text('Tampilkan ayat'));
    await tester.pump();
    expect(find.text('Lancar'), findsOneWidget);
    await tester.tap(find.text('Lancar'));
    await settle(tester);

    expect(find.text("Muraja'ah hari ini selesai"), findsOneWidget);
    final r = (await db.quranDao.reviewsAll()).single;
    expect((r.stage, r.lastDate), (1, today));
    expect(
      r.dueDate,
      dateKey(parseDateKey(today).add(Duration(days: murajaahIntervals[1]))),
    );
  });

  testWidgets('halaman: kosong menjelaskan, ada hafalan menampilkan unit', (
    tester,
  ) async {
    await tester.pumpWidget(app(const MurajaahPage()));
    await settle(tester);
    expect(find.text('Belum ada hafalan untuk diulang'), findsOneWidget);

    await db.quranDao.setHafal(6232, 6236, true);
    await tester.pumpWidget(app(const MurajaahPage(key: ValueKey('baru'))));
    await settle(tester);
    expect(find.textContaining('terjadwal'), findsOneWidget);
    // unit baru jatuh tempo besok -> belum ada yang diulang hari ini
    expect(find.text('Semua sudah diulang'), findsOneWidget);
  });
}
