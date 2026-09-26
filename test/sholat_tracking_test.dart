import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/main.dart';
import 'package:rindu_ramadan/pages/ibadah_page.dart';
import 'package:rindu_ramadan/pages/report_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/prayer_calculator.dart' as calc;
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

void main() {
  late AppDatabase db;
  late AppSettingsController settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    settings = AppSettingsController();
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

  Future<void> open(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(411, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: UserLocationScope(
          controller: UserLocationController(),
          child: HijriConfigScope(
            controller: HijriConfigController(remoteUrl: ''),
            child: AppSettingsScope(
              controller: settings,
              child: MaterialApp(home: page),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<IbadahLog?> subuhLog() async {
    final items = await db.ibadahDao.watchItems().first;
    final id = items.firstWhere((i) => i.key == 'subuh').id;
    return (db.select(
      db.ibadahLogs,
    )..where((l) => l.itemId.equals(id))).getSingleOrNull();
  }

  testWidgets('pencatatan aktif: Subuh ditanya jam & tempat', (tester) async {
    await open(tester, const IbadahPage());
    expect(find.text('Awal waktu'), findsOneWidget); // legenda

    await tester.tap(find.text('Subuh'));
    await settle(tester);
    expect(find.text('Sholat Subuh'), findsOneWidget);
    expect(find.text('DI MANA'), findsOneWidget);

    await tester.tap(find.text('Masjid'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await settle(tester);

    final log = (await tester.runAsync(subuhLog))!;
    expect(log.value, 1);
    expect(log.place, 'masjid');
    expect(log.prayedAt, isNotNull);
    expect(settings.lastPlace, 'masjid');
    // titik Subuh kini menampilkan jam sholatnya
    final tz = calc.timezoneFromLongitude(
      UserLocationController().location.long,
    );
    expect(
      find.text(calc.formatInZone(log.prayedAt!.toUtc(), tz)),
      findsWidgets,
    );
  });

  testWidgets('pencatatan dimatikan: centang langsung', (tester) async {
    await settings.setSholatTime(false);
    await open(tester, const IbadahPage());
    expect(find.text('Awal waktu'), findsNothing);

    await tester.tap(find.text('Subuh'));
    await settle(tester);
    expect(find.text('Sholat Subuh'), findsNothing);
    final log = (await tester.runAsync(subuhLog))!;
    expect(log.value, 1);
    expect(log.prayedAt, isNull);
  });

  testWidgets('laporan tampil dengan kalender & konsistensi', (tester) async {
    final today = dateKey(
      calc.todayInZone(
        calc.timezoneFromLongitude(UserLocationController().location.long),
      ),
    );
    await tester.runAsync(() async {
      final items = await db.ibadahDao.watchItems().first;
      for (var d = 1; d <= 10; d++) {
        final date = dateKey(parseDateKey(today).subtract(Duration(days: d)));
        for (final i in items.where((i) => i.groupKey == sholatWajibGroup)) {
          await db.ibadahDao.setValue(date, i.id, 1);
        }
      }
    });
    await open(tester, const ReportPage());

    expect(find.text('KALENDER IBADAH'), findsOneWidget);
    expect(find.text('HARI PALING RAJIN'), findsOneWidget);
    expect(find.text('KONSISTENSI PER IBADAH'), findsOneWidget);
    expect(find.text('KUALITAS SHOLAT WAJIB'), findsOneWidget);
    expect(find.textContaining('streak'), findsOneWidget);
  });

  testWidgets('navigasi bawah berpindah tab', (tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RinduRamadanApp(database: db, homeWidgets: false, onboarding: false),
    );
    await settle(tester);

    expect(find.text('JADWAL SHOLAT'), findsOneWidget);
    for (final (tab, title) in [
      ('Ibadah', 'Ibadah Harian'),
      ("Qur'an", "Tilawah Al-Qur'an"),
      ('Laporan', 'Laporan Ibadah'),
    ]) {
      await tester.tap(find.text(tab));
      await settle(tester);
      expect(find.text(title), findsOneWidget, reason: tab);
    }
    await tester.tap(find.text('Lainnya').last);
    await settle(tester);
    expect(find.text('Bacaan Sholat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pengaturan'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Pengaturan'), findsOneWidget);
  });
}
