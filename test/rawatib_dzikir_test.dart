import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/dzikir_data.dart';
import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/dzikir.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/tracker_widget_payload.dart';

void main() {
  group('rawatib', () {
    test('kunci rawatib -> (sholat, qabliyah?)', () {
      expect(rawatibOf('qabliyah_subuh'), ('subuh', true));
      expect(rawatibOf('badiyah_isya'), ('isya', false));
      expect(rawatibOf('subuh'), isNull);
      expect(rawatibOf('rawatib'), isNull);
    });

    test('bawaan: muakkadah aktif, ghairu muakkadah tersembunyi', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final items = await db.ibadahDao.watchItems(includeInactive: true).first;
      final rawatib = {
        for (final i in items)
          if (i.groupKey == rawatibGroup) i.key: i.active,
      };
      expect(rawatib, {
        'qabliyah_subuh': true,
        'qabliyah_dzuhur': true,
        'badiyah_dzuhur': true,
        'qabliyah_ashar': false,
        'qabliyah_maghrib': false,
        'badiyah_maghrib': true,
        'qabliyah_isya': false,
        'badiyah_isya': true,
      });
      expect(items.any((i) => i.key == 'rawatib'), isFalse);
      await db.close();
    });

    test('migrasi v2 -> v3: "Sholat rawatib" lama disembunyikan', () async {
      final dir = Directory.systemTemp.createTempSync('rawatib');
      final file = File('${dir.path}/db.sqlite');

      // basis data lama: item 'rawatib' aktif + satu catatan
      var db = AppDatabase(NativeDatabase(file));
      await db.customStatement(
        "INSERT INTO ibadah_items (key, name, kind, target, scope, active, "
        "sort, built_in) VALUES ('rawatib', 'Sholat rawatib', 'check', 1, "
        "'daily', 1, 32, 1)",
      );
      final old = (await db.ibadahDao.watchItems().first).firstWhere(
        (i) => i.key == 'rawatib',
      );
      await db.ibadahDao.setValue('2026-09-01', old.id, 1);
      // kembalikan ke bentuk v2: kolom jama'ah (v4) belum ada
      await db.customStatement('ALTER TABLE ibadah_logs DROP COLUMN jamaah');
      await db.customStatement('PRAGMA user_version = 2');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      final items = await db.ibadahDao.watchItems(includeInactive: true).first;
      final rawatib = items.firstWhere((i) => i.key == 'rawatib');
      expect(rawatib.active, isFalse);
      // catatan lama tetap ada
      final logs = await (db.select(
        db.ibadahLogs,
      )..where((l) => l.itemId.equals(rawatib.id))).get();
      expect(logs, hasLength(1));
      await db.close();
      dir.deleteSync(recursive: true);
    });

    test('widget: rawatib diringkas jadi satu baris', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final items = await db.ibadahDao.watchItems().first;
      final qs = items.firstWhere((i) => i.key == 'qabliyah_subuh');
      await db.ibadahDao.setValue('2026-09-25', qs.id, 1);
      final anchors = HijriConfig.parse('{"anchors": {}}', origin: 't').anchors;

      final day = await ibadahWidgetDay(
        db,
        anchors: anchors,
        date: '2026-09-25',
        latitude: 3.59,
        longitude: 98.67,
      );
      final rows = (day['items'] as List).cast<Map<String, Object?>>();
      final summary = rows.firstWhere((r) => r['id'] == rawatibSummaryId);
      expect(summary['value'], 1);
      expect(summary['target'], 5);
      expect(rows.where((r) => '${r['name']}'.contains('Qabliyah')), isEmpty);

      // centang lagi lalu tambal payload (jalur widget di latar)
      final bd = items.firstWhere((i) => i.key == 'badiyah_dzuhur');
      await db.ibadahDao.setValue('2026-09-25', bd.id, 1);
      final payload = <String, Object?>{
        'days': [day],
      };
      await patchIbadahPayload(db, payload, '2026-09-25');
      expect(summary['value'], 2);
      await db.close();
    });
  });

  group('dzikir pagi & petang', () {
    test('24 bacaan Hisnul Muslim, pagi & petang', () {
      expect(dzikirList, hasLength(24));
      final pagi = dzikirFor(DzikirSession.pagi);
      final petang = dzikirFor(DzikirSession.petang);
      expect(pagi.map((d) => d.id), containsAll([93, 94, 95, 96]));
      expect(pagi.map((d) => d.id), isNot(contains(97)));
      expect(petang.map((d) => d.id), contains(97));
      expect(petang.map((d) => d.id), isNot(contains(93)));
      expect(dzikirList.firstWhere((d) => d.id == 83).repeat, 7);
      expect(dzikirList.firstWhere((d) => d.id == 80).repeat, 4);
      for (final d in dzikirList) {
        expect(d.arabic, isNotEmpty);
        expect(d.latin, isNotEmpty);
        expect(d.arti, isNotEmpty);
        expect(d.arabic, isNot(contains('((')));
      }
    });

    test('versi petang berbeda dari versi pagi', () {
      final d = dzikirList.firstWhere((d) => d.id == 77);
      expect(d.arabicFor(DzikirSession.petang), isNot(d.arabic));
      expect(d.latinFor(DzikirSession.petang), startsWith('Amsainaa'));
      expect(d.artiFor(DzikirSession.petang), contains('malam ini'));
      // yang tidak punya versi petang memakai teks yang sama
      final kursi = dzikirList.firstWhere((d) => d.id == 75);
      expect(kursi.arabicFor(DzikirSession.petang), kursi.arabic);
    });

    test('item checklist <-> sesi', () {
      expect(dzikirSession('dzikir_pagi'), DzikirSession.pagi);
      expect(dzikirSession('dzikir_petang'), DzikirSession.petang);
      expect(dzikirSession('sedekah'), isNull);
      expect(DzikirSession.pagi.itemKey, 'dzikir_pagi');
    });
  });
}
