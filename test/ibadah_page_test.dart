import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/ibadah_page.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
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
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: UserLocationScope(
          controller: UserLocationController(),
          child: HijriConfigScope(
            controller: HijriConfigController(remoteUrl: ''),
            child: const MaterialApp(home: IbadahPage()),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<int> valueOf(String key) async {
    final items = await db.ibadahDao.watchItems().first;
    final id = items.firstWhere((i) => i.key == key).id;
    final rows = await (db.select(
      db.ibadahLogs,
    )..where((l) => l.itemId.equals(id))).get();
    return rows.isEmpty ? 0 : rows.single.value;
  }

  testWidgets('centang sholat & ibadah lain, hitungan bertambah', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('SHOLAT LIMA WAKTU'), findsOneWidget);
    // lima waktu 0/5 & sunnah rawatib 0/5
    expect(find.text('0/5'), findsNWidgets(2));

    await tester.tap(find.text('Subuh'));
    await settle(tester);
    expect(find.text('1/5'), findsOneWidget); // lima waktu
    expect(await tester.runAsync(() => valueOf('subuh')), 1);

    await tester.ensureVisible(find.text('Sedekah'));
    await tester.tap(find.text('Sedekah'));
    await settle(tester);
    expect(await tester.runAsync(() => valueOf('sedekah')), 1);

    await tester.ensureVisible(find.text('0/100'));
    await tester.tap(find.byTooltip('Tambah'));
    await settle(tester);
    expect(find.text('1/100'), findsOneWidget);
  });

  testWidgets('berhalangan: sholat tidak bisa dicentang, tidak dihitung', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Sedang berhalangan'));
    await settle(tester);
    expect(find.text('berhalangan'), findsOneWidget);

    await tester.tap(find.text('Subuh'));
    await settle(tester);
    expect(await tester.runAsync(() => valueOf('subuh')), 0);
    expect(find.text('🔥 1 hari terjaga'), findsOneWidget);
  });

  testWidgets('atur daftar: tambah ibadah sendiri', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Atur daftar ibadah'));
    await settle(tester);
    await tester.tap(find.text('Tambah').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Sholawat');
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah').last);
    await settle(tester);

    final items = await tester.runAsync(() => db.ibadahDao.watchItems().first);
    expect(items!.last.name, 'Sholawat');
  });
}
