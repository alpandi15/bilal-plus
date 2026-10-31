import '../data/ayat_harian_data.dart';
import '../utils/date_key.dart';
import '../widgets/arabic_font.dart';
import '../widgets/quran/quran_ayah_text.dart';
import 'quran_text.dart';
import 'reminder_ids.dart';

/// Ayat hari ini: dipilih deterministik dari tanggal (sama di semua
/// perangkat & tidak berubah selama sehari), berputar melalui
/// [ayatHarianRefs].
class AyatHarian {
  const AyatHarian(this.surah, this.ayah);
  final int surah, ayah;

  /// "18:10" - juga dipakai di payload & pengenal.
  String get ref => '$surah:$ayah';
}

/// Ayat untuk [date] (Y/M/D, zona apa pun - hanya tanggalnya yang dipakai).
AyatHarian ayatOfDate(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final n = day.difference(DateTime.utc(2024)).inDays;
  final (s, a) = ayatHarianRefs[n % ayatHarianRefs.length];
  return AyatHarian(s, a);
}

/// Ayat lengkap dengan teksnya dari Al-Qur'an aplikasi.
class AyatContent {
  const AyatContent({
    required this.surah,
    required this.surahName,
    required this.ayah,
    required this.arabic,
    required this.translation,
  });

  final int surah, ayah;
  final String surahName, arabic, translation;

  /// "QS. Al-Baqarah: 152".
  String get label => 'QS. $surahName: $ayah';
}

AyatContent ayatContent(QuranText text, AyatHarian a, {QuranFont? font}) {
  final s = text.surah(a.surah);
  final q = text.ayahsOf(a.surah)[a.ayah - 1];
  return AyatContent(
    surah: a.surah,
    surahName: s.name,
    ayah: a.ayah,
    arabic: quranTextFor(q, font ?? QuranFont.lpmq),
    translation: q.translation,
  );
}

/// Notifikasi ayat harian untuk [days] hari mulai [today] (UTC tengah
/// malam). Isinya tetap per tanggal - tidak pernah basi.
List<DayNotice> ayatNotices(
  QuranText text,
  DateTime today, {
  int days = 14,
  QuranFont font = QuranFont.lpmq,
}) => [
  for (var i = 0; i < days; i++)
    (() {
      final date = today.add(Duration(days: i));
      final a = ayatContent(text, ayatOfDate(date), font: font);
      return DayNotice(
        date: date,
        title: 'Ayat hari ini · ${a.label}',
        body: '${a.arabic}\n\n${a.translation}',
        payload: '${NotifPayload.ayat}${a.surah}:${a.ayah}',
      );
    })(),
];

/// Data widget Ayat Harian (`ayat_json`): [days] hari ke depan sekaligus,
/// supaya widget tetap berganti ayat tiap tengah malam walau aplikasi tidak
/// dibuka berhari-hari.
Map<String, Object?> ayatWidgetPayload(
  QuranText text, {
  required DateTime today,
  required String tzId,
  required QuranFont font,
  int days = 7,
}) => {
  'generatedAt': DateTime.now().millisecondsSinceEpoch,
  'tzId': tzId,
  'font': font.key,
  'days': [
    for (var i = 0; i < days; i++)
      (() {
        final date = today.add(Duration(days: i));
        final a = ayatContent(text, ayatOfDate(date), font: font);
        return {
          'date': dateKey(date),
          'surah': a.surah,
          'name': a.surahName,
          'n': a.ayah,
          'ar': a.arabic,
          'tr': a.translation,
        };
      })(),
  ],
};
