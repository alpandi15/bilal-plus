import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';

void main() {
  late AppDatabase db;
  late IbadahDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.ibadahDao;
  });
  tearDown(() => db.close());

  Future<IbadahDayData> day(String date) =>
      dao.loadDay(date, summariesFrom: '2027-01-01', summariesTo: '2027-12-31');

  Future<int> idOf(String key) async =>
      (await dao.watchItems(includeInactive: true).first)
          .firstWhere((i) => i.key == key)
          .id;

  test('item bawaan terisi sekali, lima waktu sekelompok', () async {
    final items = await dao.watchItems().first;
    expect(items.length, defaultIbadahItems.length);
    expect(
      items.where((i) => i.groupKey == sholatWajibGroup).map((i) => i.key),
      ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'],
    );
    // dibuka ulang: tidak dobel
    await db.customStatement('SELECT 1');
    expect((await dao.watchItems().first).length, items.length);
  });

  test('centang, hitungan, dan hapus', () async {
    final subuh = await idOf('subuh');
    final istighfar = await idOf('istighfar');
    await dao.setValue('2027-02-08', subuh, 1);
    await dao.setValue('2027-02-08', istighfar, 40);
    await dao.setValue('2027-02-08', istighfar, 41);
    var d = await day('2027-02-08');
    expect(d.values, {subuh: 1, istighfar: 41});

    await dao.setValue('2027-02-08', subuh, 0);
    d = await day('2027-02-08');
    expect(d.values, {istighfar: 41});
  });

  test('ringkasan: jumlah sholat & berhalangan per tanggal', () async {
    for (final key in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
      await dao.setValue('2027-02-08', await idOf(key), 1);
    }
    await dao.setValue('2027-02-09', await idOf('subuh'), 1);
    await dao.setValue('2027-02-09', await idOf('sedekah'), 1);
    await dao.setExcused('2027-02-10', true);

    final s = (await day('2027-02-10')).summaries;
    expect(s['2027-02-08']!.sholat, 5);
    expect(s['2027-02-08']!.complete, isTrue);
    expect(s['2027-02-09']!.sholat, 1);
    expect(s['2027-02-10']!.excused, isTrue);
    expect(s['2027-02-10']!.complete, isTrue);
    expect((await day('2027-02-10')).excused, isTrue);

    await dao.setExcused('2027-02-10', false);
    expect((await day('2027-02-10')).excused, isFalse);
  });

  test('tilawah otomatis dari catatan Al-Qur\'an', () async {
    expect((await day('2027-02-08')).hasTilawah, isFalse);
    await db.quranDao.logReading(date: '2027-02-08', toAyah: 7);
    expect((await day('2027-02-08')).hasTilawah, isTrue);
    expect((await day('2027-02-09')).hasTilawah, isFalse);
  });

  test('item sendiri: tambah, urutkan, sembunyikan, hapus', () async {
    final id = await dao.addCustomItem(
      name: 'Sholawat',
      kind: IbadahKind.counter,
      target: 33,
    );
    var items = await dao.watchItems(includeInactive: true).first;
    expect(items.last.id, id);
    expect(items.last.target, 33);
    expect(items.last.builtIn, isFalse);

    await dao.reorder([id, ...items.map((i) => i.id).where((i) => i != id)]);
    items = await dao.watchItems().first;
    expect(items.first.id, id);

    await dao.setActive(id, false);
    expect((await dao.watchItems().first).any((i) => i.id == id), isFalse);

    // item bawaan tidak bisa dihapus
    final subuh = await idOf('subuh');
    await dao.deleteCustomItem(subuh);
    await dao.setValue('2027-02-08', id, 5);
    await dao.deleteCustomItem(id);
    items = await dao.watchItems(includeInactive: true).first;
    expect(items.any((i) => i.id == subuh), isTrue);
    expect(items.any((i) => i.id == id), isFalse);
    expect((await day('2027-02-08')).values, isEmpty);
  });

  test('watchDay memancarkan perubahan', () async {
    final subuh = await idOf('subuh');
    final seen = <int>[];
    final sub = dao
        .watchDay(
          '2027-02-08',
          summariesFrom: '2027-01-01',
          summariesTo: '2027-02-08',
        )
        .listen((d) => seen.add(d.values[subuh] ?? 0));
    await pumpEventQueue();
    await dao.setValue('2027-02-08', subuh, 1);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });
}
