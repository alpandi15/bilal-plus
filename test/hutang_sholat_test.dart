import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/hutang_sholat.dart';

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  setUp(() => db = _db());
  tearDown(() => db.close());

  test('tambah & bayar: sisa per waktu, tidak bisa membayar lebih', () async {
    final dao = db.ibadahDao;
    await dao.addSholatQadha('subuh', 10);
    await dao.addSholatQadha('isya', 3);
    expect(await dao.paySholatQadha('subuh', 4, date: '2026-10-31'), 4);
    // hanya 3 sisa isya
    expect(await dao.paySholatQadha('isya', 9, date: '2026-10-31'), 3);
    expect(await dao.paySholatQadha('isya', 1, date: '2026-10-31'), 0);
    expect(await dao.sholatQadhaRemaining(), {'subuh': 6, 'isya': 0});
  });

  test('ringkasan: progres, kecepatan & perkiraan lunas', () async {
    final dao = db.ibadahDao;
    await dao.addSholatQadha('subuh', 30);
    await dao.paySholatQadha('subuh', 14, date: '2026-10-31');
    final d = sholatDebt(
      await dao.sholatQadhaEntriesAll(),
      today: '2026-10-31',
    );
    expect((d.added, d.paid, d.left), (30, 14, 16));
    expect(d.paidPerDay, closeTo(1, 1e-9)); // 14 dalam 14 hari
    expect(d.daysToSettle, 16);
    expect(d.fraction, closeTo(14 / 30, 1e-9));
    // terlalu sedikit pembayaran: tanpa perkiraan
    await dao.addSholatQadha('isya', 1);
    final few = sholatDebt(
      (await dao.sholatQadhaEntriesAll())
          .where((e) => e.count > 0 || e.count == -14)
          .map((e) => e.count == -14 ? e.copyWith(count: -2) : e)
          .toList(),
      today: '2026-10-31',
    );
    expect(few.daysToSettle, isNull);
    // pembayaran lama tidak menghitung kecepatan
    final old = sholatDebt(
      await dao.sholatQadhaEntriesAll(),
      today: '2026-12-31',
    );
    expect(old.daysToSettle, isNull);
  });

  test('hapus entri membatalkan', () async {
    final dao = db.ibadahDao;
    await dao.addSholatQadha('ashar', 2);
    final e = (await dao.sholatQadhaEntriesAll()).single;
    await dao.deleteSholatQadha(e.id);
    expect(await dao.sholatQadhaRemaining(), isEmpty);
  });

  test(
    'dari catatan: hanya yang belum tercatat, bukan hari berhalangan',
    () async {
      final dao = db.ibadahDao;
      final items = await dao.watchItems().first;
      int id(String k) => items.firstWhere((i) => i.key == k).id;
      // 10-01 tercatat lengkap kecuali isya; 10-02 berhalangan; 10-03 kosong
      for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib']) {
        await dao.setValue('2026-10-01', id(k), 1);
      }
      await dao.setExcused('2026-10-02', true);
      final data = await dao.loadRange('2026-09-01', '2026-10-04');
      final missed = missedFromRecords(
        data,
        today: '2026-10-04',
        already: {'2026-10-03|subuh'},
      );
      final got = {for (final m in missed) '${m.date}|${m.prayer}'};
      expect(got, contains('2026-10-01|isya'));
      expect(got, isNot(contains('2026-10-01|subuh')));
      expect(got.where((g) => g.startsWith('2026-10-02')), isEmpty);
      expect(got, isNot(contains('2026-10-03|subuh'))); // sudah pernah dipilih
      expect(got, contains('2026-10-03|dzuhur'));
      // sebelum catatan pertama tidak dianggap terlewat
      expect(got.where((g) => g.compareTo('2026-10-01') < 0), isEmpty);
    },
  );

  test('cadangan: bulat-balik & gabung tanpa ganda', () async {
    final dao = db.ibadahDao;
    await dao.addSholatQadha('subuh', 5, note: 'tahun lalu');
    await dao.paySholatQadha('subuh', 2, date: '2026-10-30');
    final data = await BackupService(db).export();
    expect((data['sholatQadha'] as List), hasLength(2));

    final other = _db();
    await BackupService(other).import(data, mode: ImportMode.replace);
    expect(await other.ibadahDao.sholatQadhaRemaining(), {'subuh': 3});
    // gabung dua kali: tidak menggandakan
    await BackupService(other).import(data, mode: ImportMode.merge);
    expect(await other.ibadahDao.sholatQadhaRemaining(), {'subuh': 3});
    await other.close();
  });

  test('cadangan lama tanpa hutang sholat tetap terbaca', () async {
    final data = await BackupService(db).export();
    data.remove('sholatQadha');
    final other = _db();
    await other.ibadahDao.addSholatQadha('isya', 1);
    await BackupService(other).import(data, mode: ImportMode.merge);
    expect(await other.ibadahDao.sholatQadhaRemaining(), {'isya': 1});
    await BackupService(other).import(data, mode: ImportMode.replace);
    expect(await other.ibadahDao.sholatQadhaRemaining(), isEmpty);
    await other.close();
  });

  test('migrasi v9 -> v10: tabel dibuat, data lama utuh', () async {
    final dir = Directory.systemTemp.createTempSync('hutang');
    final file = File('${dir.path}/db.sqlite');
    var d = AppDatabase(NativeDatabase(file));
    final subuh = (await d.ibadahDao.watchItems().first).firstWhere(
      (i) => i.key == 'subuh',
    );
    await d.ibadahDao.setValue('2026-10-01', subuh.id, 1);
    await d.customStatement('DROP TABLE sholat_qadha_entries');
    await d.customStatement('PRAGMA user_version = 9');
    await d.close();

    d = AppDatabase(NativeDatabase(file));
    expect((await d.select(d.ibadahLogs).getSingle()).value, 1);
    await d.ibadahDao.addSholatQadha('subuh', 2);
    expect(await d.ibadahDao.sholatQadhaRemaining(), {'subuh': 2});
    await d.close();
    dir.deleteSync(recursive: true);
  });
}
