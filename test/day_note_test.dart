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
import 'package:rindu_ramadan/services/day_note.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/ibadah_insight.dart';
import 'package:rindu_ramadan/services/tracker_widget_payload.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';

final _anchors = HijriConfig.parse(
  '{"anchors": {"1448-09": "2027-02-08", "1448-10": "2027-03-09"}}',
  origin: 'test',
).anchors;

void main() {
  late AppDatabase db;
  setUp(
    () => db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
  tearDown(() => db.close());

  Future<int> idOf(String key) async =>
      (await db.ibadahDao.watchItems(includeInactive: true).first)
          .firstWhere((i) => i.key == key)
          .id;

  DayNote noteOf(IbadahDayData d) => d.note;
  Future<IbadahDayData> day(String date) => db.ibadahDao.loadDay(
    date,
    summariesFrom: '2026-01-01',
    summariesTo: date,
  );

  test('catatan harian: simpan, tidak mengubah berhalangan, hapus', () async {
    final dao = db.ibadahDao;
    await dao.setExcused('2026-11-09', true);
    await dao.setDayNote('2026-11-09', DayReason.sakit, '  demam  ');
    var d = await day('2026-11-09');
    expect(d.excused, isTrue);
    expect(noteOf(d).reason, DayReason.sakit);
    expect(noteOf(d).summary, '🤒 Sakit · demam');

    // berhalangan dimatikan: catatan tetap
    await dao.setExcused('2026-11-09', false);
    d = await day('2026-11-09');
    expect(noteOf(d).text, 'demam');

    final range = await dao.loadRange('2026-11-01', '2026-11-30');
    expect(range.notes.keys, ['2026-11-09']);

    await dao.setDayNote('2026-11-09', null, ' ');
    expect(noteOf(await day('2026-11-09')).isEmpty, isTrue);
    expect((await dao.loadRange('2026-11-01', '2026-11-30')).notes, isEmpty);
  });

  test('migrasi v11 -> v12 menambah kolom alasan', () async {
    final dir = Directory.systemTemp.createTempSync('daynote');
    final file = File('${dir.path}/db.sqlite');
    var d = AppDatabase(NativeDatabase(file));
    await d.ibadahDao.setExcused('2026-11-01', true);
    await d.customStatement('ALTER TABLE day_statuses DROP COLUMN reason');
    await d.customStatement('PRAGMA user_version = 11');
    await d.close();

    d = AppDatabase(NativeDatabase(file));
    await d.ibadahDao.setDayNote('2026-11-01', DayReason.safar, null);
    final row = await (d.select(d.dayStatuses)).getSingle();
    expect(row.excused, isTrue);
    expect(row.reason, 'safar');
    await d.close();
    dir.deleteSync(recursive: true);
  });

  test('widget: alasan hari ini & rata-rata 7 hari sebelumnya', () async {
    final subuh = await idOf('subuh');
    // 3 hari sebelumnya: hanya Subuh tercentang
    for (final date in ['2027-01-04', '2027-01-05', '2027-01-06']) {
      await db.ibadahDao.setValue(date, subuh, 1);
    }
    await db.ibadahDao.setDayNote('2027-01-07', DayReason.lelah, null);
    final p =
        (jsonDecode(
                  jsonEncode(
                    await ibadahWidgetPayload(
                      db,
                      anchors: _anchors,
                      today: '2027-01-07',
                      latitude: 3.5952,
                      longitude: 98.6722,
                    ),
                  ),
                )
                as Map)
            .cast<String, Object?>();
    expect(p['recentRate'], isA<double>());
    expect(p['recentRate'] as double, greaterThan(0));
    final today = (p['days'] as List).cast<Map>().first;
    expect(today['reason'], 'lelah');
    expect(today['note'], isTrue);

    // kurang dari 3 hari pembanding: tidak dikirim
    final early = await ibadahWidgetPayload(
      db,
      anchors: _anchors,
      today: '2027-01-05',
      latitude: 3.5952,
      longitude: 98.6722,
    );
    expect(early.containsKey('recentRate'), isFalse);
  });

  test('laporan harian: sakit dijawab dalil, catatan ikut', () async {
    await db.ibadahDao.setValue('2026-11-09', await idOf('subuh'), 1);
    await db.ibadahDao.setDayNote('2026-11-09', DayReason.sakit, 'flu');
    final r = buildDailyReport(
      await db.ibadahDao.loadRange('2026-11-02', '2026-11-09'),
      date: '2026-11-09',
      today: '2026-11-09',
      anchors: _anchors,
      latitude: 3.5952,
      longitude: 98.6722,
      onTimeMinutes: 15,
      soloWeight: 1,
      male: false,
    );
    expect(r.note.summary, '🤒 Sakit · flu');
    expect(r.good.first.ref, 'HR. Bukhari no. 2774');
  });

  testWidgets('halaman Ibadah: isi catatan lewat lembar', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
              controller: AppSettingsController(),
              child: const MaterialApp(home: IbadahPage()),
            ),
          ),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    await settle();
    expect(find.text('Catatan hari ini'), findsOneWidget);
    await tester.tap(find.text('Catatan hari ini'));
    await settle();
    await tester.tap(find.text('💼 Sibuk'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'lembur');
    await tester.tap(find.text('Simpan'));
    await settle();
    expect(find.text('💼 Sibuk · lembur'), findsOneWidget);
    final rows = await tester.runAsync(
      () => db.select(db.dayStatuses).get(),
    );
    expect(rows!.single.reason, 'sibuk');
    expect(rows.single.note, 'lembur');
  });
}
