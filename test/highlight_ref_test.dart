import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/widgets/hadith_ref_text.dart';
import 'package:rindu_ramadan/widgets/highlight_text.dart';

void main() {
  test(
    'sorotan kata: tanpa beda huruf besar-kecil, tumpang tindih digabung',
    () {
      final spans = highlightSpans('Sabar dan sholat, sabar selalu', [
        'sabar',
        'bar dan',
      ]);
      final marked = [
        for (final s in spans)
          if (s.style == searchHighlight) s.text,
      ];
      expect(marked, ['Sabar dan', 'sabar']);
      expect(spans.map((s) => s.text).join(), 'Sabar dan sholat, sabar selalu');
      expect(highlightSpans('tanpa cocok', ['xyz']), hasLength(1));
    },
  );

  test('potongan di sekitar kata yang dicari', () {
    final long = '${'kata ' * 40}sabar di akhir';
    final ex = excerptAround(long, ['sabar']);
    expect(ex.startsWith('…'), isTrue);
    expect(ex.contains('sabar'), isTrue);
    expect(excerptAround('sabar di awal', ['sabar']), 'sabar di awal');
  });

  test('kata cari Al-Qur\'an memakai ejaan Kemenag', () {
    expect(QuranText.searchWords('Sholat sabar'), ['salat', 'sabar']);
    expect(QuranText.searchWords('2:255'), isEmpty);
  });

  test('rujukan HTML dari web dibersihkan', () {
    expect(
      plainReference(
        "<p>HR. Abu Daud no. <a href='https://bilal-tarawih.vercel.app/"
        "bacaan/hadits/abu-daud?number=2010' target='__blank'>2010</a></p>",
      ),
      'HR. Abu Daud no. 2010',
    );
  });

  testWidgets('rujukan hadits jadi tautan di aplikasi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HadithRefText(
            '<p>HR. Tirmidzi no. 3513 dan Ibnu Majah no. 3850, dari Aisyah.</p>',
          ),
        ),
      ),
    );
    final rich = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    final links = [
      for (final s in rich.children!.cast<TextSpan>())
        if (s.recognizer != null) s.text,
    ];
    expect(links, ['Tirmidzi no. 3513', 'Ibnu Majah no. 3850']);
    expect(
      rich.toPlainText(),
      'HR. Tirmidzi no. 3513 dan Ibnu Majah no. 3850, dari Aisyah.',
    );
  });
}
