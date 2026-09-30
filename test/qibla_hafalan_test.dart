import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/qibla.dart';

void main() {
  group('kiblat', () {
    test('arah dari kota-kota Indonesia sekitar 292-295°', () {
      // Jakarta ±295,1°, Medan ±292,4°, Makassar ±292,5°
      expect(qiblaBearing(-6.2, 106.816), closeTo(295.1, 0.5));
      expect(qiblaBearing(3.59, 98.67), closeTo(292.4, 0.6));
      expect(qiblaBearing(-5.14, 119.43), closeTo(292.5, 0.8));
      expect(compassPoint(295), 'barat laut');
    });

    test('jarak ke Ka\'bah & selisih sudut', () {
      expect(kaabaDistanceKm(-6.2, 106.816), closeTo(7920, 60));
      expect(kaabaDistanceKm(kaabaLat, kaabaLon), closeTo(0, 0.01));
      expect(angleDelta(350, 10), 20);
      expect(angleDelta(10, 350), -20);
      expect(angleDelta(292, 292), 0);
    });
  });

  group('hafalan', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('tandai & lepas hafal per rentang ayat', () async {
      final dao = db.quranDao;
      await dao.setHafal(6222, 6236, true); // Al-Falaq & An-Nas
      expect(await dao.watchHafalan().first, hasLength(15));
      await dao.setHafal(6222, 6222, true); // dobel: diabaikan
      await dao.setHafal(6231, 6236, false);
      expect(await dao.watchHafalan().first, {
        for (var a = 6222; a <= 6230; a++) a,
      });
    });

    test('ikut cadangan & dipulihkan', () async {
      await db.quranDao.setHafal(1, 7, true);
      final service = BackupService(db);
      final text = service.exportText(await service.export());
      final b = AppDatabase(NativeDatabase.memory());
      addTearDown(b.close);
      await BackupService(
        b,
      ).import(BackupService.decode(text), mode: ImportMode.replace);
      expect(await b.quranDao.watchHafalan().first, {1, 2, 3, 4, 5, 6, 7});
    });

    test('migrasi v6 -> v7 membuat tabel hafalan', () async {
      final dir = Directory.systemTemp.createTempSync('hafalan');
      final file = File('${dir.path}/db.sqlite');
      var d = AppDatabase(NativeDatabase(file));
      await d.quranDao.watchHafalan().first;
      await d.customStatement('DROP TABLE hafalan_ayahs');
      await d.customStatement('PRAGMA user_version = 6');
      await d.close();
      d = AppDatabase(NativeDatabase(file));
      await d.quranDao.setHafal(1, 1, true);
      expect(await d.quranDao.watchHafalan().first, {1});
      await d.close();
      dir.deleteSync(recursive: true);
    });
  });
}
