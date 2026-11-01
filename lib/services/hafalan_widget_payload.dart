import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../utils/date_key.dart';
import '../widgets/arabic_font.dart';
import '../widgets/quran/quran_ayah_text.dart';
import 'hafalan_cue.dart';
import 'quran_text.dart';

/// Jumlah ayat berikutnya yang dititipkan ke widget - cukup untuk beberapa
/// kali "Hafal" dari widget sebelum aplikasi menyusun ulang datanya.
const hafalanWidgetQueue = 8;

/// Data widget Hafalan (`hafalan_json`): surah yang sedang dihafal (surah
/// dari ayat yang terakhir ditandai hafal) dan antrean ayat berikutnya yang
/// belum hafal, mulai dari ayat pertama yang belum hafal di surah itu.
/// Mis. Al-Insyiqaq 1-3 sudah hafal -> antrean dimulai dari ayat 4.
/// [loadText] baru dipanggil bila sudah ada ayat yang dihafal.
Future<Map<String, Object?>> hafalanWidgetPayload(
  AppDatabase db,
  Future<QuranText> Function() loadText, {
  required QuranFont font,
  HafalanWidgetOptions options = const HafalanWidgetOptions(),
  DateTime? now,

  /// Kunci tanggal hari ini untuk menghitung muraja'ah yang jatuh tempo
  /// (bawaan: tanggal di jam perangkat).
  String? today,
}) async {
  final generatedAt = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final last =
      await (db.select(db.hafalanAyahs)
            ..orderBy([(h) => OrderingTerm.desc(h.memorizedAt)])
            ..limit(1))
          .getSingleOrNull();
  if (last == null) {
    return {'generatedAt': generatedAt, 'empty': true};
  }
  final day = today ?? dateKey(now ?? DateTime.now());
  await db.quranDao.syncReviews(day);
  final due = [
    for (final r in await db.quranDao.reviewsAll())
      if (r.dueDate.compareTo(day) <= 0) r,
  ].length;
  final text = await loadText();
  final surah = text.surah(text.ayah(last.ayah).surah);
  final ayahs = text.ayahsOf(surah.number);
  final memorized = {
    for (final h
        in await (db.select(db.hafalanAyahs)..where(
              (h) =>
                  h.ayah.isBetweenValues(ayahs.first.index, ayahs.last.index),
            ))
            .get())
      h.ayah,
  };
  final queue = [
    for (final a in ayahs)
      if (!memorized.contains(a.index)) a,
  ].take(hafalanWidgetQueue);

  return {
    'generatedAt': generatedAt,
    'murajaah': due,
    'surah': surah.number,
    'name': surah.name,
    'arabicName': surah.arabic,
    'ayahCount': surah.ayahCount,
    'memorized': memorized.length,
    'font': font.key,
    'mode': options.mode.name,
    'cueCount': options.count,
    'cueWords': options.words,
    'queue': [
      for (final a in queue)
        {
          'i': a.index,
          'n': a.number,
          'ar': quranTextFor(a, font),
          'tr': a.translation,
        },
    ],
  };
}
