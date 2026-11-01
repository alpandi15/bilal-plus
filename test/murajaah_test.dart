import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/murajaah.dart';
import 'package:rindu_ramadan/services/murajaah_quiz.dart';
import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/services/quran_index.dart';

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

int _a(int s, int a) => ayahIndex(s, a);

void main() {
  group('penjadwalan', () {
    test('lancar naik tahap: 3, 7, 14, 30, lalu tetap 30 hari', () {
      var s = const MurajaahState(stage: 0, due: '2026-11-01');
      final dues = <String>[];
      var day = DateTime(2026, 11, 1);
      for (var i = 0; i < 6; i++) {
        final today =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
        s = murajaahGraded(s, MurajaahGrade.lancar, today);
        dues.add(s.due);
        day = DateTime.parse(s.due);
      }
      expect(s.stage, 4);
      expect(dues, [
        '2026-11-04', // +3
        '2026-11-11', // +7
        '2026-11-25', // +14
        '2026-12-25', // +30
        '2027-01-24', // tetap 30
        '2027-02-23',
      ]);
    });

    test('ragu turun satu tahap, lupa kembali ke awal & dihitung', () {
      const s = MurajaahState(stage: 3, due: '2026-11-01', lapses: 1);
      final ragu = murajaahGraded(s, MurajaahGrade.ragu, '2026-11-01');
      expect((ragu.stage, ragu.due), (2, '2026-11-08'));
      final lupa = murajaahGraded(s, MurajaahGrade.lupa, '2026-11-01');
      expect((lupa.stage, lupa.due, lupa.lapses), (0, '2026-11-02', 2));
      // ragu di tahap awal tidak negatif
      final r0 = murajaahGraded(
        const MurajaahState(stage: 0, due: 'x'),
        MurajaahGrade.ragu,
        '2026-11-01',
      );
      expect(r0.stage, 0);
    });

    test('jatuh tempo & terlambat', () {
      const s = MurajaahState(stage: 1, due: '2026-11-01');
      expect(s.isDue('2026-10-31'), isFalse);
      expect(s.isDue('2026-11-01'), isTrue);
      expect(s.overdueDays('2026-11-04'), 3);
      expect(s.overdueDays('2026-10-30'), 0);
    });
  });

  group('unit', () {
    test('berurutan dikelompokkan, putus surah memutus unit', () {
      final ayahs = [
        for (var i = 1; i <= 4; i++) _a(112, i), // Al-Ikhlas 1-4
        _a(113, 1), _a(113, 2), // Al-Falaq (surah berikut, berurutan global)
        _a(114, 5),
      ];
      expect(murajaahChunks(ayahs), [
        (_a(112, 1), _a(112, 4)),
        (_a(113, 1), _a(113, 2)),
        (_a(114, 5), _a(114, 5)),
      ]);
    });

    test('lebih dari 10 ayat dipecah rata', () {
      final ayahs = [for (var i = 1; i <= 23; i++) _a(2, i)];
      final c = murajaahChunks(ayahs);
      expect(c.length, 3);
      expect([for (final (s, e) in c) e - s + 1], [8, 8, 7]);
      expect(c.first.$1, _a(2, 1));
      expect(c.last.$2, _a(2, 23));
    });

    test('rencana: unit utuh dipertahankan, yang rusak diganti', () {
      final memorized = {
        for (var i = 1; i <= 5; i++) _a(1, i),
        _a(2, 1),
        _a(2, 2),
      };
      final plan = planMurajaah(memorized, {
        1: (_a(1, 1), _a(1, 3)), // utuh
        2: (_a(2, 1), _a(2, 4)), // 2:3-4 tidak hafal -> hapus
      });
      expect(plan.remove, [2]);
      expect(plan.create, [(_a(1, 4), _a(1, 5)), (_a(2, 1), _a(2, 2))]);
    });

    test('label', () {
      expect(murajaahLabel(_a(112, 1), _a(112, 4)), 'Al-Ikhlas 1-4');
      expect(murajaahLabel(_a(108, 2), _a(108, 2)), 'Al-Kausar 2');
    });
  });

  group('basis data', () {
    late AppDatabase db;
    setUp(() => db = _db());
    tearDown(() => db.close());

    test('sync membuat unit, bertahap, idempoten', () async {
      final q = db.quranDao;
      await q.setHafal(_a(2, 1), _a(2, 40), true); // 4 unit @10
      expect(await q.syncReviews('2026-11-01'), isTrue);
      final r = await q.reviewsAll();
      expect(r.length, 4);
      // 3 per hari: tiga jatuh tempo besok, satu lusa
      expect(r.map((e) => e.dueDate).toList()..sort(), [
        '2026-11-02',
        '2026-11-02',
        '2026-11-02',
        '2026-11-03',
      ]);
      expect(await q.syncReviews('2026-11-01'), isFalse);
    });

    test(
      'menambah hafalan tidak mengacak jadwal; melepas menghapus unit',
      () async {
        final q = db.quranDao;
        await q.setHafal(_a(1, 1), _a(1, 7), true);
        await q.syncReviews('2026-11-01');
        final first = (await q.reviewsAll()).single;
        await q.gradeReview(first.id, MurajaahGrade.lancar, '2026-11-02');
        await q.setHafal(_a(2, 1), _a(2, 3), true);
        await q.syncReviews('2026-11-03');
        final all = await q.reviewsAll();
        expect(all.length, 2);
        final kept = all.firstWhere((e) => e.id == first.id);
        expect(
          (kept.stage, kept.dueDate, kept.lastDate),
          (1, '2026-11-05', '2026-11-02'),
        );
        await q.setHafal(_a(1, 3), _a(1, 3), false);
        await q.syncReviews('2026-11-03');
        final after = await q.reviewsAll();
        expect(after.any((e) => e.id == first.id), isFalse);
        // sisa 1:1-2 & 1:4-7 jadi unit baru
        expect(after.length, 1 + 2);
      },
    );

    test(
      'cadangan: bulat-balik, gabung tanpa ganda, yang terbaru menang',
      () async {
        final q = db.quranDao;
        await q.setHafal(_a(112, 1), _a(112, 4), true);
        await q.syncReviews('2026-11-01');
        final id = (await q.reviewsAll()).single.id;
        await q.gradeReview(id, MurajaahGrade.lancar, '2026-11-02');
        final data = await BackupService(db).export();

        final other = _db();
        await BackupService(other).import(data, mode: ImportMode.replace);
        var got = (await other.quranDao.reviewsAll()).single;
        expect(
          (got.stage, got.dueDate, got.lastDate),
          (1, '2026-11-05', '2026-11-02'),
        );
        // gabung lagi: tetap satu
        await BackupService(other).import(data, mode: ImportMode.merge);
        expect((await other.quranDao.reviewsAll()).length, 1);
        // perangkat lain lebih baru -> tidak ditimpa cadangan lama
        await other.quranDao.gradeReview(
          got.id,
          MurajaahGrade.lancar,
          '2026-11-05',
        );
        await BackupService(other).import(data, mode: ImportMode.merge);
        got = (await other.quranDao.reviewsAll()).single;
        expect(got.lastDate, '2026-11-05');
        await other.close();
      },
    );

    test(
      'simulasi 70 hari: diulang tepat di hari jatuh tempo, tanpa ganda',
      () async {
        final q = db.quranDao;
        await q.setHafal(_a(112, 1), _a(112, 4), true);
        final start = DateTime(2026, 11, 1);
        String key(int d) {
          final x = start.add(Duration(days: d));
          return '${x.year}-${x.month.toString().padLeft(2, '0')}-'
              '${x.day.toString().padLeft(2, '0')}';
        }

        final reviewed = <int>[];
        for (var d = 0; d <= 70; d++) {
          final today = key(d);
          await q.syncReviews(today); // berkali-kali tidak menggandakan
          await q.syncReviews(today);
          final due = [
            for (final r in await q.reviewsAll())
              if (r.dueDate.compareTo(today) <= 0) r,
          ];
          expect(due.length, lessThanOrEqualTo(1));
          for (final r in due) {
            await q.gradeReview(r.id, MurajaahGrade.lancar, today);
            reviewed.add(d);
          }
        }
        expect((await q.reviewsAll()).length, 1);
        // hari ke-1, lalu +3, +7, +14, +30
        expect(reviewed, [1, 4, 11, 25, 55]);
      },
    );

    test('migrasi v10 -> v11', () async {
      final dir = Directory.systemTemp.createTempSync('murajaah');
      final file = File('${dir.path}/db.sqlite');
      var d = AppDatabase(NativeDatabase(file));
      await d.quranDao.setHafal(5, 6, true);
      await d.customStatement('DROP TABLE hafalan_reviews');
      await d.customStatement('PRAGMA user_version = 10');
      await d.close();

      d = AppDatabase(NativeDatabase(file));
      expect((await d.select(d.hafalanAyahs).get()).length, 2);
      await d.quranDao.syncReviews('2026-11-01');
      expect((await d.quranDao.reviewsAll()).length, 1);
      await d.close();
      dir.deleteSync(recursive: true);
    });
  });

  group('kuis sambung ayat', () {
    final quran = QuranText.parse(
      File('assets/quran/quran.json').readAsStringSync(),
      File('assets/quran/uthmani.json').readAsStringSync(),
    );

    test('soal dari ayat hafal yang cukup panjang; satu jawaban benar', () {
      final memorized = {for (var i = 1; i <= 7; i++) _a(1, i), _a(2, 255)};
      final qs = buildQuiz(quran, memorized, Random(7), count: 5);
      expect(qs, isNotEmpty);
      for (final q in qs) {
        expect(memorized, contains(q.ayah));
        expect(q.options.toSet().length, q.options.length); // tanpa kembar
        expect(q.options.length, inInclusiveRange(2, 4));
        expect(q.full, startsWith(q.prompt));
        expect(q.full, contains(q.options[q.correct]));
        // pengecoh bukan lanjutan yang benar
        for (var i = 0; i < q.options.length; i++) {
          if (i != q.correct) expect(q.options[i], isNot(q.options[q.correct]));
        }
      }
    });

    test('tanpa ayat hafal yang cocok: kosong', () {
      expect(buildQuiz(quran, {}, Random(1)), isEmpty);
      // Al-Ikhlas 1 hanya 4-5 kata
      expect(buildQuiz(quran, {_a(112, 1)}, Random(1)), isEmpty);
    });

    test('deterministik untuk seed yang sama', () {
      final m = {for (var i = 1; i <= 40; i++) _a(2, i)};
      final a = buildQuiz(quran, m, Random(3));
      final b = buildQuiz(quran, m, Random(3));
      expect([for (final q in a) q.ayah], [for (final q in b) q.ayah]);
    });
  });
}
