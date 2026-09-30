import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/services/quran_ruku.dart';
import 'package:rindu_ramadan/services/quran_text.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
  );
  final marks = [
    for (var i = 1; i <= totalAyahs; i++)
      if (quran.ayah(i).ruku case final r?) (quran.ayah(i), r),
  ];

  test("556 tanda 'ain, satu di akhir tiap ruku'", () {
    expect(rukuStarts, hasLength(556));
    expect(marks, hasLength(556));
    expect(marks.map((m) => m.$2.number), List.generate(556, (i) => i + 1));
    // ayat terakhir Al-Qur'an menutup ruku' terakhir
    expect(marks.last.$1.index, totalAyahs);
  });

  test("Al-Fatihah & awal Al-Baqarah", () {
    final (fatihah, r1) = marks[0];
    expect((fatihah.surah, fatihah.number), (1, 7));
    expect((r1.inSurah, r1.ayahCount, r1.inJuz), (1, 7, 1));

    // Al-Baqarah: ruku' 1 = ayat 1-7, ruku' 2 = ayat 8-20
    final (b1, m1) = marks[1];
    expect((b1.surah, b1.number), (2, 7));
    expect((m1.inSurah, m1.ayahCount, m1.inJuz), (1, 7, 2));
    final (b2, m2) = marks[2];
    expect((b2.surah, b2.number), (2, 20));
    expect((m2.inSurah, m2.ayahCount), (2, 13));
  });

  test("hitungan ruku' dalam surah & juz mulai lagi dari 1", () {
    for (final (i, (ayah, r)) in marks.indexed) {
      if (i == 0) continue;
      final (prev, pr) = marks[i - 1];
      expect(
        r.inSurah,
        prev.surah == ayah.surah ? pr.inSurah + 1 : 1,
        reason: '${ayah.surah}:${ayah.number}',
      );
      expect(
        r.inJuz,
        prev.juz == ayah.juz ? pr.inJuz + 1 : 1,
        reason: '${ayah.surah}:${ayah.number}',
      );
    }
    // tiap surah berakhir dengan tanda 'ain
    for (final s in quran.surahs) {
      expect(quran.ayahsOf(s.number).last.ruku, isNotNull, reason: s.name);
    }
  });
}
