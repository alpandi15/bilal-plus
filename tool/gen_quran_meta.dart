// Membuat lib/data/quran_meta.dart dari metadata Tanzil (tool/quran-data.js,
// https://tanzil.net/res/text/metadata/quran-data.js, CC BY 3.0).
//
//   dart run tool/gen_quran_meta.dart
//
// Hanya metadata (jumlah ayat, batas juz, awal halaman mushaf Madinah 604
// halaman) - tanpa teks Al-Qur'an.
import 'dart:io';

/// Nama surah dalam ejaan yang lazim di Indonesia (mengikuti transliterasi
/// Kemenag, disederhanakan tanpa diakritik).
const _namaIndonesia = [
  'Al-Fatihah', 'Al-Baqarah', "Ali 'Imran", "An-Nisa'", "Al-Ma'idah", //
  "Al-An'am", "Al-A'raf", 'Al-Anfal', 'At-Taubah', 'Yunus', //
  'Hud', 'Yusuf', "Ar-Ra'd", 'Ibrahim', 'Al-Hijr', //
  'An-Nahl', "Al-Isra'", 'Al-Kahf', 'Maryam', 'Taha', //
  "Al-Anbiya'", 'Al-Hajj', "Al-Mu'minun", 'An-Nur', 'Al-Furqan', //
  "Asy-Syu'ara'", 'An-Naml', 'Al-Qasas', "Al-'Ankabut", 'Ar-Rum', //
  'Luqman', 'As-Sajdah', 'Al-Ahzab', "Saba'", 'Fatir', //
  'Yasin', 'As-Saffat', 'Sad', 'Az-Zumar', 'Gafir', //
  'Fussilat', 'Asy-Syura', 'Az-Zukhruf', 'Ad-Dukhan', 'Al-Jasiyah', //
  'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf', //
  'Az-Zariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman', //
  "Al-Waqi'ah", 'Al-Hadid', 'Al-Mujadilah', 'Al-Hasyr', 'Al-Mumtahanah', //
  'As-Saff', "Al-Jumu'ah", 'Al-Munafiqun', 'At-Tagabun', 'At-Talaq', //
  'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', "Al-Ma'arij", //
  'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddassir', 'Al-Qiyamah', //
  'Al-Insan', 'Al-Mursalat', "An-Naba'", "An-Nazi'at", "'Abasa", //
  'At-Takwir', 'Al-Infitar', 'Al-Mutaffifin', 'Al-Insyiqaq', 'Al-Buruj', //
  'At-Tariq', "Al-A'la", 'Al-Gasyiyah', 'Al-Fajr', 'Al-Balad', //
  'Asy-Syams', 'Al-Lail', 'Ad-Duha', 'Asy-Syarh', 'At-Tin', //
  "Al-'Alaq", 'Al-Qadr', 'Al-Bayyinah', 'Az-Zalzalah', "Al-'Adiyat", //
  "Al-Qari'ah", 'At-Takasur', "Al-'Asr", 'Al-Humazah', 'Al-Fil', //
  'Quraisy', "Al-Ma'un", 'Al-Kausar', 'Al-Kafirun', 'An-Nasr', //
  'Al-Lahab', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas', //
];

String _section(String js, String name) {
  final start = js.indexOf('QuranData.$name = [');
  final end = js.indexOf('];', start);
  return js.substring(start, end);
}

List<(int, int)> _pairs(String section) => [
  for (final m in RegExp(r'\[(\d+),\s*(\d+)\]').allMatches(section))
    (int.parse(m.group(1)!), int.parse(m.group(2)!)),
];

void main() {
  final js = File('tool/quran-data.js').readAsStringSync();

  final suras = [
    for (final m in RegExp(
      r"\[(\d+), (\d+), \d+, \d+, '([^']+)', .*?'(Meccan|Medinan)'\]",
    ).allMatches(_section(js, 'Sura')))
      (
        ayahs: int.parse(m.group(2)!),
        arabic: m.group(3)!,
        makki: m.group(4) == 'Meccan',
      ),
  ];
  final juz = _pairs(_section(js, 'Juz'));
  // Tanzil menutup daftar halaman dengan penanda [115, 1] (sesudah surah
  // terakhir); yang dipakai hanya 604 awal halaman.
  final pages = _pairs(_section(js, 'Page')).where((p) => p.$1 <= 114).toList();

  if (suras.length != 114 || _namaIndonesia.length != 114) {
    throw StateError('jumlah surah ${suras.length}/${_namaIndonesia.length}');
  }
  if (juz.length < 30) throw StateError('jumlah juz ${juz.length}');
  if (pages.length != 604) throw StateError('jumlah halaman ${pages.length}');
  final total = suras.fold<int>(0, (a, s) => a + s.ayahs);
  if (total != 6236) throw StateError('jumlah ayat $total');

  String pairList(List<(int, int)> xs) =>
      xs.map((p) => '(${p.$1}, ${p.$2})').join(', ');
  String quote(String s) => "'${s.replaceAll("'", r"\'")}'";

  final out = StringBuffer()
    ..writeln(
      '// DIBUAT OTOMATIS oleh tool/gen_quran_meta.dart - jangan diedit.',
    )
    ..writeln('//')
    ..writeln('// Metadata Al-Qur\'an dari Tanzil (tanzil.net, CC BY 3.0):')
    ..writeln('// jumlah ayat per surah, awal tiap juz, dan awal tiap halaman')
    ..writeln('// mushaf Madinah standar 604 halaman. Tanpa teks Al-Qur\'an.')
    ..writeln()
    ..writeln('/// Nama surah (ejaan Indonesia), indeks 0 = surah 1.')
    ..writeln('const surahNames = <String>[')
    ..writeln(_namaIndonesia.map(quote).join(',\n'))
    ..writeln('];')
    ..writeln()
    ..writeln('/// Nama surah dalam aksara Arab, indeks 0 = surah 1.')
    ..writeln('const surahArabicNames = <String>[')
    ..writeln(suras.map((s) => quote(s.arabic)).join(',\n'))
    ..writeln('];')
    ..writeln()
    ..writeln('/// Jumlah ayat per surah, indeks 0 = surah 1. Totalnya 6236.')
    ..writeln('const surahAyahCounts = <int>[')
    ..writeln(suras.map((s) => s.ayahs).join(', '))
    ..writeln('];')
    ..writeln()
    ..writeln('/// true = Makkiyah, false = Madaniyah; indeks 0 = surah 1.')
    ..writeln('const surahMakki = <bool>[')
    ..writeln(suras.map((s) => s.makki).join(', '))
    ..writeln('];')
    ..writeln()
    ..writeln('/// Awal tiap juz sebagai (surah, ayat), indeks 0 = juz 1.')
    ..writeln('const juzStarts = <(int, int)>[')
    ..writeln(pairList(juz.take(30).toList()))
    ..writeln('];')
    ..writeln()
    ..writeln('/// Awal tiap halaman mushaf Madinah 604 halaman sebagai')
    ..writeln('/// (surah, ayat), indeks 0 = halaman 1.')
    ..writeln('const pageStarts = <(int, int)>[')
    ..writeln(pairList(pages))
    ..writeln('];');

  File('lib/data/quran_meta.dart').writeAsStringSync(out.toString());
  stdout.writeln('lib/data/quran_meta.dart: 114 surah, 30 juz, 604 halaman');
}
