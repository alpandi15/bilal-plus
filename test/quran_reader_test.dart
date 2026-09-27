import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/data/quran_meta.dart';
import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/db/hadits_database.dart';
import 'package:rindu_ramadan/pages/doa_page.dart';
import 'package:rindu_ramadan/pages/quran/quran_notes_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/backup_service.dart';
import 'package:rindu_ramadan/services/hadits_download.dart';
import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/widgets/quran/quran_note_sheet.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
  );

  group("teks Al-Qur'an", () {
    test('114 surah, jumlah ayat sama dengan metadata Tanzil', () {
      expect(quran.surahs, hasLength(114));
      for (final s in quran.surahs) {
        expect(s.ayahCount, surahAyahCounts[s.number - 1], reason: s.name);
      }
      expect(quran.ayah(totalAyahs).surah, 114);
      final kursi = quran.ayah(ayahIndex(2, 255));
      expect((kursi.surah, kursi.number, kursi.juz), (2, 255, 3));
      expect(kursi.translation, startsWith('Allah, tidak ada tuhan'));
      expect(quran.surah(1).hasBasmalah, isFalse);
      expect(quran.surah(9).hasBasmalah, isFalse);
      expect(quran.surah(2).hasBasmalah, isTrue);
      // sisa penanda sumber sudah dibuang
      for (var i = 1; i <= totalAyahs; i++) {
        expect(quran.ayah(i).arabic, isNot(contains('؉')));
      }
    });

    test('cari: surah:ayat, kata di terjemahan, nama surah', () {
      expect(quran.search('2:255').single.ayah.number, 255);
      expect(quran.search('2 255').single.surah.number, 2);
      expect(quran.search('999:1'), isEmpty);
      final hits = quran.search('sabar shalat');
      expect(hits, isNotEmpty);
      expect(
        hits.every((h) {
          final t = h.ayah.translation.toLowerCase();
          // "shalat" dicari sebagai ejaan Kemenag "salat"
          return t.contains('sabar') && t.contains('salat');
        }),
        isTrue,
      );
      expect(quran.findSurah('baqarah').first.number, 2);
      expect(quran.findSurah('al baqarah').first.number, 2);
      expect(quran.findSurah('36').single.name, 'Yasin');
    });
  });

  group('catatan ayat', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('simpan, ubah, hapus, per surah', () async {
      final dao = db.quranDao;
      final id = await dao.saveNote(
        fromAyah: ayahIndex(2, 1),
        toAyah: ayahIndex(2, 5),
        body: 'Sifat orang bertakwa',
      );
      await dao.saveNote(
        fromAyah: ayahIndex(3, 1),
        toAyah: ayahIndex(3, 1),
        body: 'lain surah',
      );
      var inBaqarah = await dao
          .watchNotesBetween(ayahIndex(2, 1), ayahIndex(2, 286))
          .first;
      expect(inBaqarah.single.body, 'Sifat orang bertakwa');
      expect(
        formatAyahRange(inBaqarah.single.fromAyah, inBaqarah.single.toAyah),
        'Al-Baqarah 1–5',
      );

      await dao.saveNote(
        id: id,
        fromAyah: ayahIndex(2, 2),
        toAyah: ayahIndex(2, 5),
        body: 'diubah',
      );
      inBaqarah = await dao
          .watchNotesBetween(ayahIndex(2, 1), ayahIndex(2, 286))
          .first;
      expect(inBaqarah.single.body, 'diubah');
      await dao.deleteNote(id);
      expect(await dao.watchNotes().first, hasLength(1));
    });

    test('ikut cadangan & pulih ke perangkat lain', () async {
      await db.quranDao.saveNote(
        fromAyah: ayahIndex(1, 1),
        toAyah: ayahIndex(1, 7),
        body: 'Ummul Kitab',
      );
      final data = BackupService.decode(
        jsonEncode(await BackupService(db).export()),
      );
      final other = AppDatabase(NativeDatabase.memory());
      await BackupService(other).import(data, mode: ImportMode.merge);
      // digabung dua kali: tidak dobel
      await BackupService(other).import(data, mode: ImportMode.merge);
      final notes = await other.quranDao.watchNotes().first;
      expect(notes.single.body, 'Ummul Kitab');
      expect(notes.single.toAyah, 7);
      await other.close();
    });

    test('migrasi v4 -> v5: tabel catatan dibuat', () async {
      final dir = Directory.systemTemp.createTempSync('notes');
      final file = File('${dir.path}/db.sqlite');
      var d = AppDatabase(NativeDatabase(file));
      await d.customStatement('SELECT 1');
      await d.customStatement('DROP TABLE quran_notes');
      await d.customStatement('PRAGMA user_version = 4');
      await d.close();

      d = AppDatabase(NativeDatabase(file));
      await d.quranDao.saveNote(fromAyah: 1, toAyah: 1, body: 'ok');
      expect(await d.quranDao.watchNotes().first, hasLength(1));
      await d.close();
      dir.deleteSync(recursive: true);
    });
  });

  group('hadits', () {
    late HaditsDatabase db;
    setUp(() => db = HaditsDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    // server palsu: kitab 'malik' dengan [total] hadits, [failAt] = halaman
    // yang gagal (sekali)
    MockClient server(int total, {int? failAt}) {
      var failed = false;
      return MockClient((req) async {
        final page = int.parse(req.url.queryParameters['page']!);
        final limit = int.parse(req.url.queryParameters['limit']!);
        if (page == failAt && !failed) {
          failed = true;
          return http.Response('down', 500);
        }
        final from = (page - 1) * limit + 1;
        final to = (from + limit - 1).clamp(0, total);
        final last = (total / limit).ceil();
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'meta': {
                'pagination': {'nextPage': page < last ? page + 1 : null},
              },
              'data': [
                for (var n = from; n <= to; n++)
                  {
                    'number': n,
                    'arab': 'حَدَّثَنَا $n',
                    'translate': n == 7 ? 'tentang sholat subuh' : 'hadits $n',
                  },
              ],
            }),
          ),
          200,
        );
      });
    }

    test('unduh per halaman, bisa dilanjutkan sesudah gagal', () async {
      final dl = HaditsDownloader(db, client: server(2500, failAt: 2));
      await dl.download('malik', 2500);
      expect(dl.stateOf('malik')?.error, isNotNull);
      expect(await db.storedCount('malik'), 1000); // halaman 1 tersimpan

      await dl.download('malik', 2500); // lanjut dari halaman 2
      expect(dl.stateOf('malik'), isNull);
      expect(await db.storedCount('malik'), 2500);
      final books = await db.watchBooks().first;
      final malik = books.firstWhere((b) => b.$1.key == 'malik');
      expect(malik.$1.completedAt, isNotNull);
      expect(malik.$2, 2500);

      // cari kata & nomor
      expect(await db.countMatching('malik', 'sholat subuh'), 1);
      expect(
        (await db.page('malik', '42', offset: 0, limit: 10)).single.number,
        42,
      );

      await db.deleteBook('malik');
      expect(await db.storedCount('malik'), 0);
    });
  });

  test("do'a: 19 do'a dari web, bacaan lengkap", () {
    final doa = Doa.parse(File('assets/doa/doa.json').readAsStringSync());
    expect(doa, hasLength(19));
    expect(doa.map((d) => d.tema).toSet(), {'umum', 'ramadan', 'rajab'});
    for (final d in doa) {
      expect(d.readings, isNotEmpty);
      expect(d.readings.first.arabic, isNotEmpty, reason: d.title);
    }
  });

  testWidgets('halaman catatan: kosong lalu terisi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: UserLocationScope(
          controller: UserLocationController(),
          child: AppSettingsScope(
            controller: AppSettingsController(),
            child: const MaterialApp(home: QuranNotesPage()),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Belum ada catatan'), findsOneWidget);

    await tester.runAsync(
      () => db.quranDao.saveNote(
        fromAyah: ayahIndex(2, 255),
        toAyah: ayahIndex(2, 255),
        body: 'Ayat Kursi - dibaca sebelum tidur',
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Al-Baqarah 255'), findsOneWidget);
    expect(find.text('Ayat Kursi - dibaca sebelum tidur'), findsOneWidget);
    expect(find.text('2. AL-BAQARAH'), findsOneWidget);
  });
}
