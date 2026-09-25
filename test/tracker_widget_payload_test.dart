import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/services/quran_target.dart';
import 'package:rindu_ramadan/services/tracker_widget_payload.dart';

// 1 Ramadan 1448 = 8 Feb 2027, 1 Syawal = 9 Mar 2027
final _anchors = HijriConfig.parse(
  '{"anchors": {"1448-09": "2027-02-08", "1448-10": "2027-03-09"}}',
  origin: 'test',
).anchors;

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> idOf(String key) async =>
      (await db.ibadahDao.watchItems(includeInactive: true).first)
          .firstWhere((i) => i.key == key)
          .id;

  Future<Map<String, Object?>> ibadah(String today) async =>
      // lewat JSON, sama seperti yang dibaca Kotlin
      (jsonDecode(
                jsonEncode(
                  await ibadahWidgetPayload(
                    db,
                    anchors: _anchors,
                    today: today,
                    latitude: 3.5952,
                    longitude: 98.6722,
                  ),
                ),
              )
              as Map)
          .cast<String, Object?>();

  test('hari ini & besok, lima waktu lengkap dengan jam', () async {
    await db.ibadahDao.setValue('2027-02-07', await idOf('subuh'), 1);
    final p = await ibadah('2027-02-07');
    expect(p['tzId'], 'Asia/Jakarta');
    final days = (p['days'] as List).cast<Map>();
    expect(days.map((d) => d['date']), ['2027-02-07', '2027-02-08']);

    final today = days.first;
    expect(today['kicker'], 'MINGGU · 7 FEB');
    final sholat = (today['sholat'] as List).cast<Map>();
    expect(sholat.map((s) => s['name']), [
      'Subuh',
      'Dzuhur',
      'Ashar',
      'Maghrib',
      'Isya',
    ]);
    expect(sholat.first['done'], isTrue);
    expect(sholat.first['time'], matches(RegExp(r'^\d\d:\d\d$')));
    expect(sholat.first['at'], isA<int>());
    // malam 7 Feb = malam tarawih pertama
    final items = (today['items'] as List).cast<Map>();
    expect(items.map((i) => i['name']), contains('Tarawih'));
    expect(
      items.firstWhere((i) => i['name'] == 'Istighfar')['kind'],
      'counter',
    );
    expect(
      items.firstWhere((i) => i['name'] == "Tilawah Al-Qur'an")['kind'],
      'tilawah',
    );

    // besok: hari pertama Ramadan, checklist kosong
    final tomorrow = days.last;
    expect(tomorrow['kicker'], 'RAMADAN · HARI 1');
    expect(tomorrow['done'], 0);
    expect(
      (tomorrow['items'] as List).cast<Map>().map((i) => i['name']),
      containsAll(['Puasa Ramadan', 'Sahur']),
    );
  });

  test(
    'centang dari widget: payload diperbarui tanpa jangkar/lokasi',
    () async {
      final before = await ibadah('2027-02-07');
      final day = (before['days'] as List).cast<Map>().first;
      expect(day['done'], 0);

      // callback latar: tulis lima waktu lalu tambal payload lama
      for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
        await db.ibadahDao.setValue('2027-02-07', await idOf(k), 1);
      }
      final patched = await patchIbadahPayload(db, before, '2027-02-07');
      final d = (patched['days'] as List).cast<Map>().first;
      expect(d['done'], 5);
      expect(d['total'], day['total']);
      expect(d['streak'], 1);
      expect(
        (d['sholat'] as List).cast<Map>().every((s) => s['done'] == true),
        isTrue,
      );
      expect(
        patched['generatedAt'] as int,
        greaterThanOrEqualTo(before['generatedAt'] as int),
      );
    },
  );

  test('berhalangan: sholat & puasa tidak dihitung', () async {
    await db.ibadahDao.setExcused('2027-02-10', true);
    final p = await ibadah('2027-02-10');
    final day = (p['days'] as List).cast<Map>().first;
    expect(day['excused'], isTrue);
    expect(
      (day['sholat'] as List).cast<Map>().every((s) => s['excused'] == true),
      isTrue,
    );
    final items = (day['items'] as List).cast<Map>();
    expect(
      items.firstWhere((i) => i['name'] == 'Puasa Ramadan')['excused'],
      isTrue,
    );
    expect(items.firstWhere((i) => i['name'] == 'Sedekah')['excused'], isFalse);
  });

  test('Al-Qur\'an: posisi, target hari ini & besok, grafik 7 hari', () async {
    await db.quranDao.setTargetDate(targetDateFor('2027-02-08', 30));
    await db.quranDao.logReading(date: '2027-02-06', toAyah: juzRange(1).$2);
    await db.quranDao.logReading(date: '2027-02-08', toAyah: juzRange(2).$2);

    final p = await quranWidgetPayload(
      db,
      today: '2027-02-08',
      tzId: 'Asia/Jakarta',
    );
    expect(p['round'], 1);
    expect(p['juz'], 2);
    expect(p['position'], 'Al-Baqarah 252');
    expect(p['percent'], 6);
    final week = (p['week'] as List).cast<double>();
    expect(week, hasLength(7));
    expect(week[4], closeTo(21, 1e-9)); // 6 Feb
    expect(week[6], closeTo(20, 1e-9)); // hari ini
    expect(p['weekLabels'], ['S', 'R', 'K', 'J', 'S', 'M', 'S']); // Sel..Sen

    final days = (p['days'] as List).cast<Map>();
    expect(days.map((d) => d['date']), ['2027-02-08', '2027-02-09']);
    expect(days.first['hasTarget'], isTrue);
    expect(days.first['target'], startsWith('s/d '));
    expect(days.last['hasTarget'], isTrue);
  });

  test('Al-Qur\'an: sesudah khatam, putaran baru kosong', () async {
    await db.quranDao.logReading(date: '2027-02-08', toAyah: totalAyahs);
    final p = await quranWidgetPayload(
      db,
      today: '2027-02-08',
      tzId: 'Asia/Jakarta',
    );
    expect(p['justKhatam'], isTrue);
    expect(p['round'], 1); // khatam ke-1
    expect(p['lastAyah'], 0);
    expect((p['days'] as List).cast<Map>().first['hasTarget'], isFalse);
  });
}
