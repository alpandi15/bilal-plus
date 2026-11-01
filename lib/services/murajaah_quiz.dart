import 'dart:math';

import '../widgets/arabic_font.dart';
import '../widgets/quran/quran_ayah_text.dart';
import 'quran_text.dart';

/// Satu soal sambung ayat: tampil awal ayat, pilih lanjutannya.
class QuizQuestion {
  const QuizQuestion({
    required this.ayah,
    required this.prompt,
    required this.options,
    required this.correct,
    required this.full,
  });

  /// Ayat global asal soal.
  final int ayah;

  /// Kata-kata awal yang ditampilkan.
  final String prompt;

  /// Pilihan lanjutan (satu benar, sisanya pengecoh dari ayat lain).
  final List<String> options;

  /// Indeks jawaban benar di [options].
  final int correct;

  /// Ayat utuh (untuk ditampilkan sesudah menjawab).
  final String full;
}

/// Ayat yang bisa dijadikan soal: cukup panjang untuk dibagi dua.
const quizMinWords = 6;

/// Susun [count] soal dari ayat [memorized] yang cukup panjang; pengecoh
/// berupa lanjutan ayat lain dengan panjang yang sama. Kosong bila tidak
/// ada ayat hafal yang cocok.
List<QuizQuestion> buildQuiz(
  QuranText text,
  Set<int> memorized,
  Random rnd, {
  QuranFont font = QuranFont.lpmq,
  int count = 10,
  int choices = 4,
}) {
  List<String> words(int i) => quranTextFor(text.ayah(i), font).split(' ');
  final pool = [
    for (final i in memorized)
      if (i >= 1 && i <= 6236 && words(i).length >= quizMinWords) i,
  ]..shuffle(rnd);

  final out = <QuizQuestion>[];
  for (final i in pool.take(count)) {
    final w = words(i);
    final cut = (w.length ~/ 2).clamp(2, 5);
    final len = (w.length - cut).clamp(2, 5);
    final correct = w.sublist(cut, cut + len).join(' ');
    final options = {correct};
    var guard = 0;
    while (options.length < choices && guard++ < 400) {
      final j = rnd.nextInt(6236) + 1;
      if (j == i) continue;
      final o = words(j);
      if (o.length < cut + len) continue;
      options.add(o.sublist(cut, cut + len).join(' '));
    }
    if (options.length < 2) continue;
    final shuffled = options.toList()..shuffle(rnd);
    out.add(
      QuizQuestion(
        ayah: i,
        prompt: w.take(cut).join(' '),
        options: shuffled,
        correct: shuffled.indexOf(correct),
        full: w.join(' '),
      ),
    );
  }
  return out;
}
