import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/quran_meta.dart';
import 'package:rindu_ramadan/services/quran_index.dart';

void main() {
  group('metadata', () {
    test('114 surah, 6236 ayat, 30 juz, 604 halaman', () {
      expect(surahNames, hasLength(114));
      expect(surahArabicNames, hasLength(114));
      expect(surahAyahCounts.fold<int>(0, (a, b) => a + b), totalAyahs);
      expect(juzStarts, hasLength(totalJuz));
      expect(pageStarts, hasLength(totalPages));
      expect(surahName(36), 'Yasin');
      expect(ayahCount(2), 286);
    });
  });

  group('konversi posisi', () {
    test('ayat global bolak-balik untuk seluruh mushaf', () {
      for (var i = 1; i <= totalAyahs; i++) {
        final (s, a) = surahAyahOf(i);
        expect(ayahIndex(s, a), i);
      }
      expect(ayahIndex(1, 1), 1);
      expect(ayahIndex(2, 1), 8);
      expect(ayahIndex(114, 6), totalAyahs);
    });

    test('juz', () {
      expect(juzOf(ayahIndex(2, 141)), 1);
      expect(juzOf(ayahIndex(2, 142)), 2);
      expect(juzOf(ayahIndex(78, 1)), 30);
      expect(juzOf(totalAyahs), 30);
      expect(juzRange(1), (1, ayahIndex(2, 141)));
      expect(juzRange(30), (ayahIndex(78, 1), totalAyahs));
    });

    test('halaman mushaf Madinah', () {
      expect(pageOf(ayahIndex(1, 7)), 1);
      expect(pageOf(ayahIndex(2, 1)), 2);
      expect(pageOf(ayahIndex(36, 1)), 440);
      expect(pageOf(ayahIndex(78, 1)), 582);
      expect(pageOf(ayahIndex(112, 1)), 604);
      expect(pageOf(totalAyahs), 604);
    });

    test('surah di dalam juz untuk pemilih Juz -> Surah -> Ayat', () {
      expect(surahsInJuz(1), const [
        SurahInJuz(1, 1, 7),
        SurahInJuz(2, 1, 141),
      ]);
      expect(surahsInJuz(2).single, const SurahInJuz(2, 142, 252));
      final juz30 = surahsInJuz(30);
      expect(juz30, hasLength(37));
      expect(juz30.first, const SurahInJuz(78, 1, 40));
      expect(juz30.last, const SurahInJuz(114, 1, 6));
      // semua ayat tercakup tepat sekali
      var total = 0;
      for (var j = 1; j <= totalJuz; j++) {
        for (final s in surahsInJuz(j)) {
          total += s.lastAyah - s.firstAyah + 1;
        }
      }
      expect(total, totalAyahs);
    });
  });

  group('progress berbobot halaman', () {
    test('0 sebelum mulai, 1 di akhir, naik terus', () {
      expect(progressAfter(0), 0);
      expect(progressAfter(totalAyahs), 1);
      var prev = 0.0;
      for (var i = 1; i <= totalAyahs; i++) {
        final p = progressAfter(i);
        expect(p, greaterThan(prev));
        prev = p;
      }
    });

    test('akhir halaman tepat di kelipatan halaman', () {
      final (_, endOfPage1) = pageRange(1);
      expect(progressAfter(endOfPage1), closeTo(1 / totalPages, 1e-12));
      final (_, endOfJuz1) = juzRange(1);
      expect(pagesBetween(1, endOfJuz1), closeTo(21, 1e-9));
    });

    test('Juz 30 ~ 23 halaman meski berisi 564 ayat', () {
      final (start, end) = juzRange(30);
      expect(end - start + 1, 564);
      expect(pagesBetween(start, end), closeTo(23, 1e-9));
    });

    test('progress di dalam juz', () {
      final (start, end) = juzRange(5);
      expect(juzProgressAfter(5, start - 1), 0);
      expect(juzProgressAfter(5, end), 1);
      expect(juzProgressAfter(5, (start + end) ~/ 2), inExclusiveRange(0, 1));
    });

    test('format', () {
      expect(formatAyah(ayahIndex(2, 142)), 'Al-Baqarah 142');
    });
  });
}
