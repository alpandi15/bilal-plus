import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/widgets/arabic_font.dart';
import 'package:rindu_ramadan/widgets/quran/quran_ayah_text.dart';

void main() {
  test('bawaan LPMQ; kunci tak dikenal kembali ke LPMQ', () {
    expect(QuranFont.parse(null), QuranFont.lpmq);
    expect(QuranFont.parse('x'), QuranFont.lpmq);
    expect(QuranFont.parse('uthmani'), QuranFont.uthmani);
    expect(QuranFont.lpmq.family, arabicFont);
    expect(QuranFont.uthmani.family, uthmanicFont);
  });

  test('tiap font memakai teks rasm-nya sendiri', () {
    const a = QuranAyah(
      surah: 1,
      number: 1,
      index: 1,
      page: 1,
      juz: 1,
      arabic: 'بِسْمِ اللّٰهِ',
      uthmani: 'بِسۡمِ ٱللَّهِ',
      translation: '',
    );
    expect(quranTextFor(a, QuranFont.lpmq), 'بِسْمِ اللّٰهِ');
    expect(quranTextFor(a, QuranFont.uthmani), 'بِسۡمِ ٱللَّهِ');
  });

  testWidgets('Utsmani dirender dengan font Utsmani', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: QuranAyahText(
          'بِسۡمِ ٱللَّهِ',
          font: QuranFont.uthmani,
          tajweed: true,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.style?.fontFamily, uthmanicFont);
  });
}
