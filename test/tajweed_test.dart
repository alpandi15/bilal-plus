import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/tajweed.dart';

/// Potongan berwarna saja: (teks, hukum).
List<(String, TajweedRule)> colored(String ayah) => [
  for (final s in tajweedSegments(ayah))
    if (s.rule != null) (s.text.trim(), s.rule!),
];

Set<TajweedRule> rulesOf(String ayah) => {for (final c in colored(ayah)) c.$2};

/// Ayat asli dari data MSI (surah:ayat).
final _ayah =
    (jsonDecode(File('assets/quran/quran.json').readAsStringSync())
            as Map)['ayah']
        as List;
String msi(int surah, int ayah) {
  const counts = [7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111];
  var index = ayah - 1;
  for (var s = 1; s < surah; s++) {
    index += counts[s - 1];
  }
  return _ayah[index][0] as String;
}

void main() {
  test('teks tidak berubah setelah dipecah', () {
    const a =
        'وَالَّذِيْنَ يُؤْمِنُوْنَ بِمَآ اُنْزِلَ اِلَيْكَ وَمَآ اُنْزِلَ '
        'مِنْ قَبْلِكَ ۚ وَبِالْاٰخِرَةِ هُمْ يُوْقِنُوْنَۗ';
    expect(tajweedSegments(a).map((s) => s.text).join(), a);
  });

  test('tanda waqaf dipisah & diwarnai sesuai hukumnya', () {
    // 2:4 (MSI): ... مِنْ قَبْلِكَ ۚ ... يُوْقِنُوْنَۗ
    final a = msi(2, 4);
    final segs = tajweedSegments(a);
    expect(segs.map((s) => s.text).join(), a);
    final waqf = [
      for (final s in segs)
        if (s.waqf != null) s.waqf!,
    ];
    expect(waqf, [WaqfSign.jaiz, WaqfSign.qala]);
    for (final s in segs.where((s) => s.waqf != null)) {
      expect(s.text, s.waqf!.char);
      expect(segmentColor(s), s.waqf!.color);
    }
    expect(WaqfSign.inText(a), [WaqfSign.jaiz, WaqfSign.qala]);
    // semua jenis tanda di data MSI dikenali
    final all = {for (final x in _ayah) ...WaqfSign.inText(x[0] as String)};
    expect(all, WaqfSign.values.toSet());
  });

  test("nun sukun & tanwin: ikhfa', idgham, iqlab, izhar", () {
    // 2:4 مِنْ قَبْلِكَ = ikhfa (nun + qaf)
    expect(
      colored(msi(2, 4)),
      containsAll([('نْ', TajweedRule.ikhfa), ('قَ', TajweedRule.ikhfa)]),
    );
    // 2:5 هُدًى مِّنْ رَّبِّهِمْ = idgham bighunnah & bilaghunnah
    final r = rulesOf('عَلٰى هُدًى مِّنْ رَّبِّهِمْ');
    expect(
      r,
      containsAll([TajweedRule.idghamGhunnah, TajweedRule.idghamBilaGhunnah]),
    );
    // 2:19 مُحِيْطٌۢ بِالْكٰفِرِيْنَ = iqlab
    expect(
      rulesOf('وَاللّٰهُ مُحِيْطٌۢ بِالْكٰفِرِيْنَ'),
      contains(TajweedRule.iqlab),
    );
    // izhar: مَنْ اٰمَنَ (hamzah) - tidak diwarnai
    expect(colored('مَنْ اٰمَنَ'), isEmpty);
    // izhar mutlak: nun sukun + ya dalam satu kata
    expect(colored('الدُّنْيَا'), isEmpty);
    // tanwin + alif washal: tidak ada hukum nun
    expect(colored('اَحَدٌ اللّٰهُ'), isNot(contains(TajweedRule.ikhfa)));
  });

  test('mim sukun, ghunnah, qalqalah', () {
    expect(
      rulesOf('تَرْمِيْهِمْ بِحِجَارَةٍ'),
      contains(TajweedRule.ikhfaSyafawi),
    );
    expect(
      rulesOf('لَهُمْ مَّا يَشَاۤءُوْنَ'),
      contains(TajweedRule.idghamMimi),
    );
    expect(rulesOf('اِنَّ الَّذِيْنَ'), contains(TajweedRule.ghunnah));
    // qalqalah sughra (jim sukun) & kubra di akhir ayat (112:1 اَحَدٌ)
    expect(rulesOf('يَجْعَلُوْنَ'), contains(TajweedRule.qalqalah));
    expect(colored('قُلْ هُوَ اللّٰهُ اَحَدٌۚ').last, (
      // tanda waqaf ۚ jadi potongan sendiri
      'دٌ',
      TajweedRule.qalqalah,
    ));
    // berakhir fathatan + alif (اَبَدًا) dibaca panjang - bukan qalqalah
    expect(
      rulesOf('خٰلِدِيْنَ فِيْهَآ اَبَدًا'),
      isNot(contains(TajweedRule.qalqalah)),
    );
  });

  test('mad wajib, jaiz, lazim (tanda MSI)', () {
    // 2:19 السَّمَاۤءِ, 2:4 بِمَآ اُنْزِلَ
    expect(rulesOf(msi(2, 19)), contains(TajweedRule.madWajib));
    expect(rulesOf(msi(2, 4)), contains(TajweedRule.madJaiz));
    // 2:1 الۤمّۤ: mad lazim mengalahkan ghunnah pada مّۤ
    final alm = colored(msi(2, 1));
    expect(alm.map((c) => c.$2).toSet(), {TajweedRule.madLazim});
  });

  test('seluruh mushaf: tiap ayat bisa diwarnai tanpa mengubah teks', () {
    final data =
        jsonDecode(File('assets/quran/quran.json').readAsStringSync()) as Map;
    final counts = <TajweedRule, int>{};
    for (final a in data['ayah'] as List) {
      final text = a[0] as String;
      final segs = tajweedSegments(text);
      expect(segs.map((s) => s.text).join(), text);
      for (final s in segs) {
        if (s.rule != null) counts[s.rule!] = (counts[s.rule!] ?? 0) + 1;
      }
    }
    // semua hukum muncul
    expect(counts.keys.toSet(), TajweedRule.values.toSet());
  });

  test('rasm Utsmani (mode Mushaf): semua hukum terdeteksi', () {
    final u =
        (jsonDecode(File('assets/quran/uthmani.json').readAsStringSync())
                as List)
            .cast<String>();
    expect(u, hasLength(6236));
    final counts = <TajweedRule, int>{};
    for (final a in u) {
      final segs = tajweedSegments(a, uthmani: true);
      expect(segs.map((s) => s.text).join(), a);
      for (final s in segs) {
        if (s.rule != null) counts[s.rule!] = (counts[s.rule!] ?? 0) + 1;
      }
    }
    expect(counts.keys.toSet(), TajweedRule.values.toSet());
    // 2:19 مُحِيطُۢ بِٱلۡكَٰفِرِينَ = iqlab (mim kecil); 2:10 مِن قَبۡلِكَ = ikhfa
    String rulesOf(int i) => [
      for (final s in tajweedSegments(u[i], uthmani: true))
        if (s.rule != null) s.rule!.name,
    ].join(',');
    expect(rulesOf(25), contains('iqlab'));
    expect(rulesOf(10), contains('ikhfa'));
    // 2:1 الٓمٓ = mad lazim
    expect(rulesOf(7), 'madLazim');
  });
}
