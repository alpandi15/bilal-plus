import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/auto_backup.dart';
import 'package:rindu_ramadan/services/backup_service.dart';

/// Folder palsu di memori.
class _FakeFolder implements BackupFolderApi {
  final files = <String, (String, Uint8List, DateTime)>{}; // uri -> berkas
  bool access = true;
  Object? failWrite;
  var _n = 0;

  @override
  Future<(String, String)?> pick() async =>
      ('content://tree/1', 'Documents/Bilal');

  @override
  Future<String> write(String tree, String name, Uint8List bytes) async {
    if (failWrite != null) throw failWrite!;
    final uri = '$tree/doc${_n++}';
    files[uri] = (name, bytes, DateTime(2026));
    return uri;
  }

  @override
  Future<List<BackupCopy>> list(String tree) async => [
    for (final e in files.entries)
      BackupCopy(
        uri: e.key,
        name: e.value.$1,
        modified: e.value.$3,
        size: e.value.$2.length,
      ),
  ];

  @override
  Future<Uint8List> read(String doc) async => files[doc]!.$2;

  @override
  Future<bool> delete(String doc) async => files.remove(doc) != null;

  @override
  Future<bool> hasAccess(String tree) async => access;

  @override
  Future<void> release(String tree) async {}
}

void main() {
  late AppDatabase db;
  late _FakeFolder folder;
  late AutoBackup auto;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    folder = _FakeFolder();
    auto = AutoBackup(folder, BackupService(db));
  });
  tearDown(() => db.close());

  test('jadwal: pertama kali & sesudah 7 hari', () {
    final now = DateTime(2026, 11, 8);
    expect(autoBackupDue(null, now), isTrue);
    expect(autoBackupDue(DateTime(2026, 11, 2), now), isFalse); // 6 hari
    expect(autoBackupDue(DateTime(2026, 11, 1), now), isTrue); // 7 hari
  });

  test('nama berkas urut menurut waktu & hanya lima terbaru disimpan', () {
    expect(
      autoBackupName(DateTime(2026, 11, 1, 9, 5, 7)),
      'bilalplus-cadangan-20261101-090507.json',
    );
    final copies = [
      for (var d = 1; d <= 8; d++)
        BackupCopy(
          uri: 'u$d',
          name: autoBackupName(DateTime(2026, 11, d)),
          modified: DateTime(2026),
          size: 1,
        ),
      BackupCopy(
        uri: 'x',
        name: 'catatan-pribadi.json',
        modified: DateTime(2026),
        size: 1,
      ),
    ];
    final prune = autoBackupPrune(copies);
    expect([for (final c in prune) c.uri], ['u3', 'u2', 'u1']);
    // berkas lain tidak pernah disentuh
    expect(prune.any((c) => c.uri == 'x'), isFalse);
  });

  test('tanpa folder: tidak melakukan apa-apa', () async {
    expect(await auto.run(force: true), AutoBackupResult.noFolder);
    expect(folder.files, isEmpty);
  });

  test('cadangan tertulis, lalu tidak diulang sebelum 7 hari', () async {
    await db.ibadahDao.addSholatQadha('subuh', 4);
    await auto.setFolder('content://tree/1', 'Documents/Bilal');
    final t0 = DateTime(2026, 11, 1, 8);
    expect(await auto.run(now: t0), AutoBackupResult.done);
    expect(folder.files.length, 1);
    expect((await AutoBackup.state()).last, t0);
    expect(
      await auto.run(now: t0.add(const Duration(days: 3))),
      AutoBackupResult.notDue,
    );
    expect(folder.files.length, 1);
    expect(
      await auto.run(now: t0.add(const Duration(days: 7))),
      AutoBackupResult.done,
    );
    expect(folder.files.length, 2);
  });

  test('simpan lima salinan terakhir sepanjang berminggu-minggu', () async {
    await auto.setFolder('content://tree/1', 'Bilal');
    var t = DateTime(2026, 11, 1, 8);
    for (var w = 0; w < 9; w++) {
      expect(await auto.run(now: t), AutoBackupResult.done);
      t = t.add(const Duration(days: 7));
    }
    final names = folder.files.values.map((f) => f.$1).toList()..sort();
    expect(names.length, autoBackupKeep);
    expect(names.first, autoBackupName(DateTime(2026, 11, 29, 8)));
  });

  test(
    'dimatikan: jadwal tidak jalan, tapi "Cadangkan sekarang" tetap',
    () async {
      await auto.setFolder('content://tree/1', 'Bilal');
      await AutoBackup.setEnabled(false);
      expect(
        await auto.run(now: DateTime(2026, 11, 1)),
        AutoBackupResult.notDue,
      );
      expect(
        await auto.run(now: DateTime(2026, 11, 1), force: true),
        AutoBackupResult.done,
      );
    },
  );

  test('izin hilang: gagal dengan pesan jelas, tidak melempar', () async {
    await auto.setFolder('content://tree/1', 'Bilal');
    folder.access = false;
    expect(await auto.run(now: DateTime(2026, 11, 1)), AutoBackupResult.failed);
    final s = await AutoBackup.state();
    expect(s.error, contains('Pilih folder lagi'));
    expect(s.last, isNull);
    // setelah memilih ulang, pesan hilang & cadangan jalan
    folder.access = true;
    await auto.setFolder('content://tree/2', 'Baru');
    expect((await AutoBackup.state()).error, isNull);
    expect(await auto.run(now: DateTime(2026, 11, 1)), AutoBackupResult.done);
  });

  test(
    'gagal menulis: pesan tersimpan, cadangan terakhir tidak berubah',
    () async {
      await auto.setFolder('content://tree/1', 'Bilal');
      folder.failWrite = PlatformException(
        code: 'backup_folder',
        message: 'Folder penuh',
      );
      expect(
        await auto.run(now: DateTime(2026, 11, 1)),
        AutoBackupResult.failed,
      );
      final s = await AutoBackup.state();
      expect(s.error, contains('Folder penuh'));
      expect(s.last, isNull);
    },
  );

  test('salinan dipulihkan di perangkat lain (lintas isi cadangan)', () async {
    await db.ibadahDao.addSholatQadha('isya', 3);
    await db.quranDao.setHafal(6232, 6236, true);
    await db.quranDao.syncReviews('2026-11-01');
    await auto.setFolder('content://tree/1', 'Bilal');
    await auto.run(now: DateTime(2026, 11, 1));

    final copy = (await auto.copies()).single;
    final data = BackupService.decode(utf8.decode(await folder.read(copy.uri)));

    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await BackupService(other).import(data, mode: ImportMode.replace);
    expect(await other.ibadahDao.sholatQadhaRemaining(), {'isya': 3});
    expect((await other.quranDao.reviewsAll()).length, 1);
    expect((await other.quranDao.watchHafalan().first).length, 5);
  });
}
