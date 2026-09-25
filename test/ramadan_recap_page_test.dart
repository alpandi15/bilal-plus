import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/ramadan_recap_page.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/ramadan_recap.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

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
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('rekap Ramadan lampau terkunci otomatis, hutang tampil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // tanpa jangkar (kalender tabular), Ramadan 1447 yang sudah lewat
    final r = ramadanOfYear(1447, HijriAnchors.none);
    await tester.runAsync(() async {
      final items = await db.ibadahDao.watchItems().first;
      final puasa = items.firstWhere((i) => i.key == 'puasa').id;
      for (var i = 0; i < r.days - 3; i++) {
        await db.ibadahDao.setValue(
          dateKey(r.start.add(Duration(days: i))),
          puasa,
          1,
        );
      }
    });

    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: UserLocationScope(
          controller: UserLocationController(),
          child: HijriConfigScope(
            controller: HijriConfigController(remoteUrl: ''),
            child: const MaterialApp(home: RamadanRecapPage(hijriYear: 1447)),
          ),
        ),
      ),
    );
    await settle(tester);

    // judul + baris di daftar hutang puasa
    expect(find.text('Ramadan 1447 H'), findsNWidgets(2));
    expect(find.text('Rekap terkunci · hutang 3 hari'), findsOneWidget);
    expect(find.text('puasa ${r.days - 3}/${r.days} hari'), findsOneWidget);
    expect(find.textContaining('0 dari 3 sudah diganti'), findsOneWidget);
    expect(find.text('IBADAH HARIAN PER BULAN'), findsOneWidget);
  });
}
