import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/ibadah_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/services/tracker_widget_payload.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() => db.close());

  Future<List<IbadahItem>> sholatItems() async => [
    for (final i in await db.ibadahDao.watchItems().first)
      if (i.groupKey == sholatWajibGroup) i,
  ];

  Future<IbadahLog?> logOf(String key) async {
    final id = (await sholatItems()).firstWhere((i) => i.key == key).id;
    return (db.select(
      db.ibadahLogs,
    )..where((l) => l.itemId.equals(id))).getSingleOrNull();
  }

  group('bobot', () {
    test("berjama'ah penuh, sendiri 1/27, belum dicatat penuh", () {
      expect(sholatWeight(true, hadithSoloWeight), 1);
      expect(sholatWeight(false, hadithSoloWeight), closeTo(1 / 27, 1e-9));
      expect(sholatWeight(null, hadithSoloWeight), 1);
      expect(soloWeightLabel(hadithSoloWeight), '1/27 (≈4%)');
      expect(soloWeightLabel(0.5), '50%');
    });

    test('persentase harian memakai bobot sholat', () async {
      final sholat = await sholatItems();
      final date = '2026-09-26';
      // 5 waktu: 3 berjama'ah, 1 sendiri, 1 belum
      for (final (i, j) in [(0, true), (1, true), (2, true), (3, false)]) {
        await db.ibadahDao.setValue(date, sholat[i].id, 1, jamaah: j);
      }
      final day = await db.ibadahDao.loadDay(
        date,
        summariesFrom: date,
        summariesTo: date,
      );
      IbadahProgress p(double w) => ibadahProgress(
        sholat,
        day.values,
        excused: false,
        hasTilawah: false,
        logs: day.logs,
        soloWeight: w,
      );
      expect(p(1).done, 4);
      expect(p(1).score, 4);
      expect(p(hadithSoloWeight).score, closeTo(3 + 1 / 27, 1e-9));
      expect(p(hadithSoloWeight).percent, 60); // (3 + 1/27) / 5
      expect(p(0.5).percent, 70);
    });

    test('perempuan: sholat sendiri tetap penuh', () async {
      final s = AppSettingsController();
      await s.init();
      expect(s.soloWeight, hadithSoloWeight);
      expect(s.effectiveSoloWeight, hadithSoloWeight);
      await s.setGender(Gender.female);
      expect(s.effectiveSoloWeight, 1);
      await s.setSoloWeight(0.5);
      expect(s.effectiveSoloWeight, 1);
      await s.setGender(Gender.male);
      expect(s.effectiveSoloWeight, 0.5);
    });
  });

  group('data', () {
    test('setValue tanpa jamaah mempertahankan catatan', () async {
      final subuh = (await sholatItems()).first;
      await db.ibadahDao.setValue('2026-09-26', subuh.id, 1, jamaah: true);
      await db.ibadahDao.setValue('2026-09-26', subuh.id, 1);
      expect((await logOf('subuh'))!.jamaah, isTrue);
    });

    test('cadangan membawa status jama\'ah', () async {
      final subuh = (await sholatItems()).first;
      await db.ibadahDao.setValue('2026-09-26', subuh.id, 1, jamaah: false);
      final data = BackupService.decode(
        jsonEncode(await BackupService(db).export()),
      );
      final other = AppDatabase(NativeDatabase.memory());
      await BackupService(other).import(data, mode: ImportMode.replace);
      final log = await other.select(other.ibadahLogs).getSingle();
      expect(log.jamaah, isFalse);
      await other.close();
    });

    test('migrasi v3 -> v4: catatan lama tanpa status jama\'ah', () async {
      final dir = Directory.systemTemp.createTempSync('jamaah');
      final file = File('${dir.path}/db.sqlite');
      var d = AppDatabase(NativeDatabase(file));
      final subuh = (await d.ibadahDao.watchItems().first).firstWhere(
        (i) => i.key == 'subuh',
      );
      await d.ibadahDao.setValue('2026-09-01', subuh.id, 1);
      await d.customStatement('ALTER TABLE ibadah_logs DROP COLUMN jamaah');
      await d.customStatement('PRAGMA user_version = 3');
      await d.close();

      d = AppDatabase(NativeDatabase(file));
      final log = await d.select(d.ibadahLogs).getSingle();
      expect(log.value, 1);
      expect(log.jamaah, isNull); // dihitung penuh
      await d.ibadahDao.setValue('2026-09-02', subuh.id, 1, jamaah: true);
      await d.close();
      dir.deleteSync(recursive: true);
    });

    test('widget: skor tertimbang ikut diperbarui', () async {
      final sholat = await sholatItems();
      final anchors = HijriConfig.parse('{"anchors": {}}', origin: 't').anchors;
      final day = await ibadahWidgetDay(
        db,
        anchors: anchors,
        date: '2026-09-26',
        latitude: 3.59,
        longitude: 98.67,
        soloWeight: hadithSoloWeight,
      );
      expect(day['score'], 0);
      // bobot sholat yang belum dicentang = pilihan terakhir (sendiri)
      final entries = (day['sholat'] as List).cast<Map<String, Object?>>();
      expect(entries.first['w'], closeTo(1 / 27, 1e-9));

      await db.ibadahDao.setValue('2026-09-26', sholat[0].id, 1, jamaah: true);
      await db.ibadahDao.setValue('2026-09-26', sholat[1].id, 1, jamaah: false);
      final payload = <String, Object?>{
        'soloWeight': hadithSoloWeight,
        'days': [day],
      };
      await patchIbadahPayload(db, payload, '2026-09-26');
      expect(day['done'], 2);
      expect(day['score'] as double, closeTo(1 + 1 / 27, 1e-9));
      expect(entries.first['w'], 1);
    });
  });

  group('halaman ibadah', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<AppSettingsController> open(WidgetTester tester) async {
      final settings = AppSettingsController();
      await tester.runAsync(settings.init);
      await tester.runAsync(() => settings.setSholatTime(false));
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
                child: const MaterialApp(home: IbadahPage()),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      return settings;
    }

    testWidgets("centang = pilihan terakhir, pil mengganti jama'ah", (
      tester,
    ) async {
      final settings = await open(tester);
      await tester.tap(find.text('Subuh'));
      await settle(tester);
      expect((await tester.runAsync(() => logOf('subuh')))!.jamaah, isFalse);
      expect(find.text('Sendiri'), findsOneWidget);

      await tester.tap(find.text('Sendiri'));
      await settle(tester);
      expect((await tester.runAsync(() => logOf('subuh')))!.jamaah, isTrue);
      expect(find.text("Jama'ah"), findsOneWidget);
      expect(settings.lastJamaah, isTrue);

      // centang berikutnya ikut pilihan terakhir
      await tester.tap(find.text('Dzuhur'));
      await settle(tester);
      expect((await tester.runAsync(() => logOf('dzuhur')))!.jamaah, isTrue);
    });

    testWidgets('panduan cara memilih bisa dibuka', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip("Berjama'ah atau sendiri?"));
      await tester.pumpAndSettle();
      expect(find.text("Berjama'ah atau sendiri?"), findsWidgets);
      expect(find.textContaining('masbuq'), findsOneWidget);
      expect(find.textContaining('1/27'), findsOneWidget);
    });
  });
}
