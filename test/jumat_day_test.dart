import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/sholat_dalil.dart';
import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/services/prayer_calculator.dart' as calc;
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/services/tracker_widget_payload.dart';
import 'package:rindu_ramadan/widgets/ibadah/sholat_log_sheet.dart';

const _lat = 3.59, _long = 98.67;
// 2026-10-30 = Jumat, 2026-10-29 = Kamis
const _jumat = '2026-10-30', _kamis = '2026-10-29';

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

  Future<List<IbadahItem>> sholat() async => [
    for (final i in await db.ibadahDao.watchItems().first)
      if (i.groupKey == sholatWajibGroup) i,
  ];

  group('nama Jumat', () {
    test('laki-laki di hari Jumat: Dzuhur menjadi Jumat', () async {
      final items = await sholat();
      final names = [
        for (final i in jumatAware(items, male: true, date: _jumat)) i.name,
      ];
      expect(names, ['Subuh', 'Jumat', 'Ashar', 'Maghrib', 'Isya']);
      // kuncinya tetap dzuhur - catatan lama tetap terbaca
      expect(
        jumatAware(items, male: true, date: _jumat).map((i) => i.key),
        items.map((i) => i.key),
      );
    });

    test('perempuan & hari lain tetap Dzuhur', () async {
      final items = await sholat();
      expect(jumatAware(items, male: false, date: _jumat), items);
      expect(jumatAware(items, male: true, date: _kamis), items);
      expect(isJumatFor(male: true, date: _kamis), isFalse);
    });

    test('catatan memilih Dzuhur (musafir): tetap Dzuhur', () async {
      final items = await sholat();
      final dzuhur = items.firstWhere((i) => i.key == 'dzuhur');
      await db.ibadahDao.setValue(
        _jumat,
        dzuhur.id,
        1,
        jumat: const Value(false),
      );
      final logs = {
        for (final l in await db.select(db.ibadahLogs).get()) l.itemId: l,
      };
      final names = jumatAware(
        items,
        male: true,
        date: _jumat,
        logs: logs,
      ).map((i) => i.name);
      expect(names, contains('Dzuhur'));
      expect(names, isNot(contains('Jumat')));
    });
  });

  group('penyimpanan', () {
    test('pilihan Jumat/Dzuhur tersimpan & ikut cadangan', () async {
      final items = await sholat();
      final dzuhur = items.firstWhere((i) => i.key == 'dzuhur');
      await db.ibadahDao.setValue(
        _jumat,
        dzuhur.id,
        1,
        jumat: const Value(true),
      );
      expect((await db.select(db.ibadahLogs).getSingle()).jumat, isTrue);

      final data = BackupService.decode(
        jsonEncode(await BackupService(db).export()),
      );
      final other = AppDatabase(NativeDatabase.memory());
      await BackupService(other).import(data, mode: ImportMode.replace);
      expect((await other.select(other.ibadahLogs).getSingle()).jumat, isTrue);
      await other.close();
    });

    test('migrasi v8 -> v9: kolom jumat ditambahkan', () async {
      final dir = Directory.systemTemp.createTempSync('jumat');
      final file = File('${dir.path}/db.sqlite');
      var d = AppDatabase(NativeDatabase(file));
      final subuh = (await d.ibadahDao.watchItems().first).firstWhere(
        (i) => i.key == 'subuh',
      );
      await d.ibadahDao.setValue('2026-10-01', subuh.id, 1);
      await d.customStatement('ALTER TABLE ibadah_logs DROP COLUMN jumat');
      await d.customStatement('PRAGMA user_version = 8');
      await d.close();

      d = AppDatabase(NativeDatabase(file));
      final log = await d.select(d.ibadahLogs).getSingle();
      expect((log.value, log.jumat), (1, null));
      await d.close();
      dir.deleteSync(recursive: true);
    });
  });

  test(
    'widget Ibadah: nama Jumat hanya untuk laki-laki di hari Jumat',
    () async {
      final anchors = HijriConfig.parse('{"anchors": {}}', origin: 't').anchors;
      Future<List<String>> names(String date, bool male) async {
        final day = await ibadahWidgetDay(
          db,
          anchors: anchors,
          date: date,
          latitude: _lat,
          longitude: _long,
          male: male,
        );
        return [
          for (final e in (day['sholat'] as List).cast<Map<String, Object?>>())
            e['name'] as String,
        ];
      }

      expect(await names(_jumat, true), contains('Jumat'));
      expect(await names(_jumat, true), isNot(contains('Dzuhur')));
      expect(await names(_jumat, false), contains('Dzuhur'));
      expect(await names(_kamis, true), contains('Dzuhur'));
    },
  );

  test('dalil Jumat berumber & lengkap', () {
    for (final d in [...segeraKeMasjid, ...peringatanJumat]) {
      expect(d.source, matches(RegExp(r'^(QS\. |HR\. [\w ]+ no\. \d+)')));
    }
    expect(
      segeraKeMasjid.map((d) => d.source),
      contains('HR. Bukhari no. 877'),
    );
    expect(panduanJumat, isNotEmpty);
  });

  group('lembar catat', () {
    final window = SholatWindow(
      DateTime(2026, 10, 30, 12, 10),
      DateTime(2026, 10, 30, 15, 30),
    );

    Future<void> open(
      WidgetTester tester, {
      DateTime? prayedAt,
      bool safar = false,
    }) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSholatLogSheet(
                context,
                name: 'Jumat',
                itemKey: 'dzuhur',
                date: DateTime.utc(2026, 10, 30),
                window: window,
                tz: calc.TimezoneCode.wib,
                onTimeMinutes: 15,
                place: 'masjid',
                jamaah: true,
                done: false,
                prayedAt: prayedAt ?? DateTime(2026, 10, 30, 12, 20),
                safar: safar,
                jumatDay: true,
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
    }

    testWidgets('bawaan sholat Jumat: tanpa pilihan jama\'ah & safar', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Sholat Jumat'), findsWidgets);
      expect(find.text('SHOLAT HARI JUMAT'), findsOneWidget);
      expect(find.text("BERJAMA'AH?"), findsNothing);
      expect(find.text('Sedang safar (musafir)'), findsNothing);
    });

    testWidgets('pilih Dzuhur: pilihan safar & jama\'ah muncul', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Musafir / uzur'));
      await tester.pumpAndSettle();
      expect(find.text('Sholat Dzuhur'), findsOneWidget);
      expect(find.text("BERJAMA'AH?"), findsOneWidget);
      expect(find.text('Sedang safar (musafir)'), findsOneWidget);
    });

    testWidgets('sedang safar: bawaan Dzuhur', (tester) async {
      await open(tester, safar: true);
      expect(find.text('Sholat Dzuhur'), findsOneWidget);
    });

    testWidgets('waktu Jumat habis: otomatis Dzuhur', (tester) async {
      await open(tester, prayedAt: DateTime(2026, 10, 30, 16));
      expect(find.text('Sholat Dzuhur'), findsOneWidget);
      expect(find.textContaining('tidak bisa diqadha'), findsOneWidget);
    });
  });
}
