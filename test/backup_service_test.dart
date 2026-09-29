import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

Future<int> _idOf(AppDatabase db, String key) async =>
    (await db.ibadahDao.watchItems(includeInactive: true).first)
        .firstWhere((i) => i.key == key)
        .id;

/// Isi basis data yang bisa dibandingkan antar-perangkat (tanpa id).
Future<Map<String, Object?>> _snapshot(AppDatabase db) async {
  final data = await BackupService(db).export();
  data.remove('exportedAt');
  final cycles = (data['quranCycles'] as List).cast<Map<String, Object?>>();
  final refToStart = {for (final c in cycles) c['ref']: c['startedAt']};
  for (final c in cycles) {
    c.remove('ref');
  }
  for (final l in (data['quranLogs'] as List).cast<Map<String, Object?>>()) {
    l['cycle'] = refToStart[l['cycle']];
  }
  int byKey(Object? a, Object? b) => jsonEncode(a).compareTo(jsonEncode(b));
  for (final k in data.keys.toList()) {
    if (data[k] is List) (data[k] as List).sort(byKey);
  }
  return data;
}

Future<void> _fill(AppDatabase db) async {
  final dao = db.ibadahDao;
  await dao.setValue(
    '2027-02-08',
    await _idOf(db, 'subuh'),
    1,
    prayedAt: DateTime(2027, 2, 8, 5, 12),
    place: 'masjid',
  );
  await dao.setValue('2027-02-08', await _idOf(db, 'istighfar'), 70);
  final custom = await dao.addCustomItem(
    name: 'Sholawat',
    kind: IbadahKind.counter,
    target: 33,
  );
  await dao.setValue('2027-02-09', custom, 33);
  await dao.setActive(await _idOf(db, 'sedekah'), false);
  await dao.setWeekdays(await _idOf(db, 'dhuha'), 1 << 4); // Jumat saja
  await dao.setExcused('2027-02-10', true);
  await dao.saveRecap(
    RamadanRecapsCompanion.insert(
      hijriYear: const Value(1446),
      days: 4,
      fasted: 0,
      excused: 0,
      manual: const Value(true),
      lockedAt: DateTime(2027, 1, 1),
    ),
  );
  await db.quranDao.logReading(date: '2027-02-08', toAyah: 6000);
  await db.quranDao.logReading(date: '2027-02-09', toAyah: 6236); // khatam
  await db.quranDao.startNewCycle(targetDate: '2027-03-09');
  await db.quranDao.logReading(date: '2027-02-10', toAyah: 148);
}

void main() {
  test('pulih utuh ke perangkat baru (ganti semua)', () async {
    final a = _db();
    final b = _db();
    await _fill(a);

    final service = BackupService(a);
    final text = service.exportText(await service.export());
    final data = BackupService.decode(text);
    final info = BackupService.info(data);
    expect(info.ibadahLogs, 3);
    expect(info.quranLogs, 3);
    expect((info.firstDate, info.lastDate), ('2027-02-08', '2027-02-10'));

    final result = await BackupService(
      b,
    ).import(data, mode: ImportMode.replace);
    expect(result.ibadahLogs, 3);
    expect(result.quranLogs, 3);

    expect(await _snapshot(b), await _snapshot(a));
    final p = await b.quranDao.progress();
    expect(p.lastAyah, 148);
    expect(p.completedCycles, 1);
    expect(p.cycle.targetDate, '2027-03-09');
    expect((await b.ibadahDao.qadhaStatus()).remaining, 4);

    await a.close();
    await b.close();
  });

  test('gabung: catatan terbaru menang, catatan lokal lain tetap', () async {
    final a = _db();
    final b = _db();
    await _fill(a);
    final data = BackupService.decode(
      jsonEncode(await BackupService(a).export()),
    );

    // perangkat b: subuh 8 Feb dibatalkan LEBIH BARU, dzuhur hanya di b
    final subuhB = await _idOf(b, 'subuh');
    await b
        .into(b.ibadahLogs)
        .insert(
          IbadahLogsCompanion.insert(
            date: '2027-02-08',
            itemId: await _idOf(b, 'istighfar'),
            value: 10,
            updatedAt: DateTime(2000), // lebih lama dari berkas
          ),
        );
    await b.ibadahDao.setValue('2027-02-11', subuhB, 1);
    await b.ibadahDao.setValue('2027-02-08', await _idOf(b, 'dzuhur'), 1);
    await b.quranDao.logReading(date: '2027-02-11', toAyah: 20);

    await BackupService(b).import(data, mode: ImportMode.merge);

    final day8 = await b.ibadahDao.loadDay(
      '2027-02-08',
      summariesFrom: '2027-01-01',
      summariesTo: '2027-12-31',
    );
    expect(day8.values[await _idOf(b, 'istighfar')], 70); // berkas lebih baru
    expect(day8.values[await _idOf(b, 'dzuhur')], 1); // hanya lokal
    expect(day8.values[subuhB], 1);
    expect(
      (await b.ibadahDao.watchItems(includeInactive: true).first).map(
        (i) => i.name,
      ),
      contains('Sholawat'),
    );

    // hanya satu putaran yang terbuka sesudah digabung
    final open = (await b.quranDao.cycles()).where((c) => c.finishedAt == null);
    expect(open, hasLength(1));

    // menggabung dua kali tidak menggandakan apa pun
    final before = await _snapshot(b);
    await BackupService(b).import(data, mode: ImportMode.merge);
    expect(await _snapshot(b), before);

    await a.close();
    await b.close();
  });

  test('berkas yang bukan cadangan ditolak dengan pesan jelas', () {
    expect(
      () => BackupService.decode('bukan json'),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => BackupService.decode('{"app": "lain", "version": 1}'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('bukan cadangan'),
        ),
      ),
    );
    expect(
      () => BackupService.decode('{"app": "rindu_ramadan", "version": 99}'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('lebih baru'),
        ),
      ),
    );
  });

  test('berkas rusak di tengah: data di perangkat tidak berubah', () async {
    final a = _db();
    final b = _db();
    await _fill(a);
    await b.ibadahDao.setValue('2027-01-01', await _idOf(b, 'subuh'), 1);
    final before = await _snapshot(b);

    final data = BackupService.decode(
      jsonEncode(await BackupService(a).export()),
    );
    (data['quranLogs'] as List).add({'cycle': 1, 'date': 5}); // rusak

    await expectLater(
      BackupService(b).import(data, mode: ImportMode.replace),
      throwsA(isA<BackupException>()),
    );
    expect(await _snapshot(b), before);

    await a.close();
    await b.close();
  });

  test('pengaturan kalender hijriah ikut dicadangkan', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final a = HijriConfigController(remoteUrl: '');
    await a.init();
    // disesuaikan saat masih mengikuti Pemerintah (1 Syawal resmi 9 Mar)
    await a.setOverride(1448, 10, DateTime.utc(2027, 3, 10));
    await a.setMethod('muhammadiyah');
    final settings = jsonDecode(jsonEncode(a.exportSettings()));

    SharedPreferences.setMockInitialValues({});
    final b = HijriConfigController(remoteUrl: '');
    await b.init();
    await b.importSettings(settings, replace: false);
    expect(b.method, 'pemerintah'); // gabung: pilihan lokal dipertahankan
    expect(b.overrideFor(1448, 10), DateTime.utc(2027, 3, 10));

    await b.importSettings(settings, replace: true);
    expect(b.method, 'muhammadiyah');
  });
}
