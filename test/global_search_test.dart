import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/hadits_database.dart';
import 'package:rindu_ramadan/pages/doa_page.dart';
import 'package:rindu_ramadan/services/global_search.dart';
import 'package:rindu_ramadan/services/quran_text.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    File('assets/quran/uthmani.json').readAsStringSync(),
  );
  const doa = [
    Doa(
      title: 'Doa Sebelum Makan',
      tema: 'umum',
      readings: [
        DoaReading(
          arabic: 'x',
          latin: 'Allahumma baarik lanaa',
          arti: 'Ya Allah, berkahilah kami',
        ),
      ],
    ),
    Doa(
      title: 'Doa Berbuka Puasa',
      tema: 'ramadan',
      readings: [
        DoaReading(
          arabic: 'y',
          latin: 'Dzahabaz zhama-u',
          arti: 'Telah hilang dahaga',
        ),
      ],
    ),
  ];

  late HaditsDatabase db;
  setUp(() => db = HaditsDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addHadiths() => db.insertPage('bukhari', [
    Hadith(
      book: 'bukhari',
      number: 1,
      arab: 'a',
      translation: 'Sesungguhnya amal itu tergantung niat',
    ),
    Hadith(
      book: 'bukhari',
      number: 2,
      arab: 'b',
      translation: 'Sabar itu pada pukulan pertama',
    ),
    Hadith(
      book: 'muslim',
      number: 7,
      arab: 'c',
      translation: 'Barangsiapa bersabar maka Allah menguatkannya',
    ),
  ]);

  test('terlalu pendek: tidak dicari', () async {
    expect(searchable('a'), isFalse);
    expect(searchable('  '), isFalse);
    expect(searchable('ab'), isTrue);
    expect(searchable('2'), isTrue); // angka boleh
    final r = await globalSearch('a', quran: quran, doa: doa, hadits: db);
    expect(r.isEmpty, isTrue);
  });

  test(
    'kata kunci ditemukan di semua sumber & hadits dihitung total',
    () async {
      await addHadiths();
      final r = await globalSearch('sabar', quran: quran, doa: doa, hadits: db);
      expect(r.ayat, isNotEmpty);
      expect(r.ayat.length, lessThanOrEqualTo(globalSearchLimit));
      // substring seperti pencarian hadits yang ada ('bersabar' ikut
      // cocok), urut menurut kitab lalu nomor
      expect(r.hadits.map((h) => h.number), [2, 7]);
      expect(r.haditsTotal, 2);
      expect(r.words, contains('sabar'));
    },
  );

  test('semua kata harus ada', () async {
    await addHadiths();
    final r = await globalSearch(
      'amal niat',
      quran: quran,
      doa: doa,
      hadits: db,
    );
    expect(r.hadits.single.number, 1);
    expect(r.haditsTotal, 1);
    expect(
      (await globalSearch(
        'amal pukulan',
        quran: quran,
        doa: doa,
        hadits: db,
      )).hadits,
      isEmpty,
    );
  });

  test('belum ada kitab hadits: ditandai, bukan kosong', () async {
    final r = await globalSearch('sabar', quran: quran, doa: doa, hadits: db);
    expect(r.haditsAvailable, isFalse);
    expect(r.ayat, isNotEmpty);
  });

  test('rujukan 2:255 langsung ke ayat, tanpa hadits/doa', () async {
    await addHadiths();
    final r = await globalSearch('2:255', quran: quran, doa: doa, hadits: db);
    expect(r.ayat.single.ayah.number, 255);
    expect(r.ayat.single.surah.number, 2);
    expect(r.hadits, isEmpty);
    expect(r.doa, isEmpty);
    expect(r.words, isEmpty);
  });

  test('nama surah & Asmaul Husna', () async {
    final r = await globalSearch('ikhlas', quran: quran, doa: doa);
    expect(r.surahs.map((s) => s.number), contains(112));
    final a = await globalSearch('rahman', quran: quran, doa: doa);
    expect(a.asmaulHusna.map((x) => x.latin), contains('Ar-Rahman'));
    // tanpa strip & apostrof juga cocok
    expect(
      searchAsmaulHusna('ar rahim').map((x) => x.latin),
      contains('Ar-Rahim'),
    );
    // angka = nomor
    expect(searchAsmaulHusna('1').first.number, 1);
  });

  test("do'a: cocok di judul, latin, atau arti", () async {
    expect(searchDoa(doa, 'berbuka').single.doa.title, 'Doa Berbuka Puasa');
    expect(searchDoa(doa, 'berkahilah').single.doa.title, 'Doa Sebelum Makan');
    expect(searchDoa(doa, 'dzahabaz').single.excerpt, contains('Dzahabaz'));
    expect(searchDoa(doa, 'tidak ada'), isEmpty);
  });
}
