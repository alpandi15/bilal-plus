import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/sholat_dalil.dart';
import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/widgets/ibadah/sholat_dalil_sheet.dart';

void main() {
  // Dzuhur 12:00 - Ashar 15:00
  final w = SholatWindow(
    DateTime(2026, 10, 20, 12),
    DateTime(2026, 10, 20, 15),
  );

  group('status sholat', () {
    test('qadha tanpa alasan / tanpa uzur tetap qadha', () {
      final at = DateTime(2026, 10, 20, 16);
      expect(sholatStatus(at, w), SholatStatus.qadha);
      expect(sholatStatus(at, w, qadhaReason: 'tanpa'), SholatStatus.qadha);
    });

    test('qadha karena uzur', () {
      final at = DateTime(2026, 10, 20, 16);
      for (final r in qadhaReasons.keys.where((k) => k != 'tanpa')) {
        expect(sholatStatus(at, w, qadhaReason: r), SholatStatus.uzur);
      }
    });

    test("jamak ta'khir & taqdim bukan qadha", () {
      // Dzuhur dikerjakan di waktu Ashar
      expect(
        sholatStatus(DateTime(2026, 10, 20, 15, 30), w, jamak: true),
        SholatStatus.jamak,
      );
      // Ashar dikerjakan di waktu Dzuhur (sebelum waktunya)
      expect(
        sholatStatus(DateTime(2026, 10, 20, 11), w, jamak: true),
        SholatStatus.jamak,
      );
      // dijamak tapi masih di waktunya sendiri: status biasa
      expect(
        sholatStatus(DateTime(2026, 10, 20, 12, 5), w, jamak: true),
        SholatStatus.onTime,
      );
    });

    test('nilai: uzur penuh, tanpa uzur setengah', () {
      expect(sholatWeight(true, 1, qadhaReason: 'tertidur'), 1);
      expect(sholatWeight(true, 1, qadhaReason: 'tanpa'), qadhaNoUzurWeight);
      expect(
        sholatWeight(false, 0.5, qadhaReason: 'tanpa'),
        0.5 * qadhaNoUzurWeight,
      );
    });

    test('qashar hanya Dzuhur, Ashar, Isya; Subuh tak bisa dijamak', () {
      expect(qasharPrayers, {'dzuhur', 'ashar', 'isya'});
      expect(jamakPair.containsKey('subuh'), isFalse);
      expect(jamakPair['dzuhur'], 'ashar');
      expect(jamakPair['isya'], 'maghrib');
    });
  });

  group('penyimpanan', () {
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
        (await db.ibadahDao.watchItems().first)
            .firstWhere((i) => i.key == key)
            .id;

    test(
      'alasan, qashar & jamak tersimpan, bisa dihapus & ikut cadangan',
      () async {
        final dzuhur = await idOf('dzuhur');
        await db.ibadahDao.setValue(
          '2026-10-20',
          dzuhur,
          1,
          prayedAt: DateTime(2026, 10, 20, 16),
          qadhaReason: const Value('tertidur'),
          qashar: const Value(true),
          jamak: const Value(true),
        );
        var log = await db.select(db.ibadahLogs).getSingle();
        expect(
          (log.qadhaReason, log.qashar, log.jamak),
          ('tertidur', true, true),
        );

        final data = BackupService.decode(
          jsonEncode(await BackupService(db).export()),
        );
        final other = AppDatabase(NativeDatabase.memory());
        await BackupService(other).import(data, mode: ImportMode.replace);
        final copy = await other.select(other.ibadahLogs).getSingle();
        expect(
          (copy.qadhaReason, copy.qashar, copy.jamak),
          ('tertidur', true, true),
        );
        await other.close();

        // jam diganti jadi tepat waktu: alasan & safar dikosongkan
        await db.ibadahDao.setValue(
          '2026-10-20',
          dzuhur,
          1,
          prayedAt: DateTime(2026, 10, 20, 12),
          qadhaReason: const Value(null),
          qashar: const Value(null),
          jamak: const Value(null),
        );
        log = await db.select(db.ibadahLogs).getSingle();
        expect((log.qadhaReason, log.qashar, log.jamak), (null, null, null));
      },
    );

    test('skor harian: qadha tanpa uzur bernilai setengah', () async {
      final items = await db.ibadahDao.watchItems().first;
      final subuh = items.firstWhere((i) => i.key == 'subuh');
      await db.ibadahDao.setValue(
        '2026-10-20',
        subuh.id,
        1,
        jamaah: true,
        qadhaReason: const Value('tanpa'),
      );
      final logs = {
        for (final l in await db.select(db.ibadahLogs).get()) l.itemId: l,
      };
      final p = ibadahProgress(
        [subuh],
        {subuh.id: 1},
        excused: false,
        hasTilawah: false,
        logs: logs,
      );
      expect(p.score, qadhaNoUzurWeight);
    });

    test('migrasi v7 -> v8: kolom baru ditambahkan', () async {
      final dir = Directory.systemTemp.createTempSync('qadha');
      final file = File('${dir.path}/db.sqlite');
      var d = AppDatabase(NativeDatabase(file));
      final subuh = (await d.ibadahDao.watchItems().first).firstWhere(
        (i) => i.key == 'subuh',
      );
      await d.ibadahDao.setValue('2026-10-01', subuh.id, 1);
      for (final c in ['qadha_reason', 'qashar', 'jamak']) {
        await d.customStatement('ALTER TABLE ibadah_logs DROP COLUMN $c');
      }
      await d.customStatement('PRAGMA user_version = 7');
      await d.close();

      d = AppDatabase(NativeDatabase(file));
      final log = await d.select(d.ibadahLogs).getSingle();
      expect((log.value, log.qadhaReason, log.qashar), (1, null, null));
      await d.close();
      dir.deleteSync(recursive: true);
    });
  });

  group('dalil', () {
    test('setiap waktu sholat punya peringatan; rujukan lengkap', () {
      for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
        expect(peringatanKhusus[k], isNotEmpty, reason: k);
      }
      final all = [
        ...peringatanUmum,
        ...peringatanKhusus.values.expand((l) => l),
        ...pintuTaubat,
        for (final b in panduanQashar) ...b.dalil,
      ];
      for (final d in all) {
        expect(d.source, matches(RegExp(r'^(QS\. |HR\. \w+ no\. \d+)')));
      }
    });

    testWidgets('lembar peringatan & panduan qashar tampil', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () =>
                      showSholatWarningSheet(context, prayerKey: 'ashar'),
                  child: const Text('peringatan'),
                ),
                TextButton(
                  onPressed: () => showQasharGuideSheet(context),
                  child: const Text('qashar'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('peringatan'));
      await tester.pumpAndSettle();
      expect(find.text('Peringatan meninggalkan Ashar'), findsOneWidget);
      expect(find.textContaining('hapuslah amalnya'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('qashar'));
      await tester.pumpAndSettle();
      expect(find.text('Qashar & jamak saat safar'), findsOneWidget);
    });
  });
}
