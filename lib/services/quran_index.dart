/// Posisi dalam Al-Qur'an dihitung sebagai nomor ayat GLOBAL 1..[totalAyahs]
/// (Al-Fatihah 1 = 1, An-Nas 6 = 6236). Nomor ini sama di mushaf mana pun,
/// jadi itulah yang disimpan; juz & halaman diturunkan darinya.
///
/// Halaman mengikuti mushaf Madinah standar 604 halaman dan dipakai sebagai
/// BOBOT progress: ayat Al-Baqarah yang panjang tidak dihitung sama dengan
/// ayat Juz 30 yang pendek, jadi "50%" benar-benar setengah mushaf.
library;

import '../data/quran_meta.dart';

const totalAyahs = 6236;
const totalPages = 604;
const totalJuz = 30;

/// Nomor ayat global sebelum surah ke-n (indeks 0 = surah 1).
final List<int> _surahOffsets = () {
  final offsets = <int>[];
  var acc = 0;
  for (final count in surahAyahCounts) {
    offsets.add(acc);
    acc += count;
  }
  return offsets;
}();

/// Nomor ayat global ayat pertama tiap surah.
final List<int> _surahStartIndex = [for (final o in _surahOffsets) o + 1];

final List<int> _juzStartIndex = [
  for (final (s, a) in juzStarts) ayahIndex(s, a),
];

final List<int> _pageStartIndex = [
  for (final (s, a) in pageStarts) ayahIndex(s, a),
];

String surahName(int surah) => surahNames[surah - 1];
int ayahCount(int surah) => surahAyahCounts[surah - 1];

/// (surah, ayat) -> nomor ayat global.
int ayahIndex(int surah, int ayah) {
  assert(surah >= 1 && surah <= 114, 'surah $surah');
  assert(ayah >= 1 && ayah <= ayahCount(surah), 'ayat $surah:$ayah');
  return _surahOffsets[surah - 1] + ayah;
}

/// Indeks terakhir di [starts] yang nilainya <= [index] (pencarian biner).
int _floor(List<int> starts, int index) {
  var lo = 0, hi = starts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (starts[mid] <= index) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo;
}

/// Nomor ayat global -> (surah, ayat).
(int, int) surahAyahOf(int index) {
  assert(index >= 1 && index <= totalAyahs, 'indeks $index');
  final s = _floor(_surahStartIndex, index);
  return (s + 1, index - _surahOffsets[s]);
}

/// Juz (1..30) tempat ayat [index] berada.
int juzOf(int index) => _floor(_juzStartIndex, index) + 1;

/// Halaman mushaf (1..604) tempat ayat [index] berada.
int pageOf(int index) => _floor(_pageStartIndex, index) + 1;

/// Rentang ayat global [awal, akhir] sebuah juz.
(int, int) juzRange(int juz) => (
  _juzStartIndex[juz - 1],
  juz == totalJuz ? totalAyahs : _juzStartIndex[juz] - 1,
);

/// Rentang ayat global [awal, akhir] sebuah halaman.
(int, int) pageRange(int page) => (
  _pageStartIndex[page - 1],
  page == totalPages ? totalAyahs : _pageStartIndex[page] - 1,
);

/// Potongan sebuah surah di dalam satu juz.
class SurahInJuz {
  const SurahInJuz(this.surah, this.firstAyah, this.lastAyah);
  final int surah;
  final int firstAyah;
  final int lastAyah;

  String get name => surahName(surah);

  @override
  bool operator ==(Object other) =>
      other is SurahInJuz &&
      other.surah == surah &&
      other.firstAyah == firstAyah &&
      other.lastAyah == lastAyah;

  @override
  int get hashCode => Object.hash(surah, firstAyah, lastAyah);

  @override
  String toString() => '$name $firstAyah-$lastAyah';
}

/// Surah-surah di dalam [juz] beserta rentang ayatnya - untuk pemilih
/// "Juz -> Surah -> Ayat" (mis. Juz 1: Al-Fatihah 1-7, Al-Baqarah 1-141).
List<SurahInJuz> surahsInJuz(int juz) {
  final (first, last) = juzRange(juz);
  final (s1, a1) = surahAyahOf(first);
  final (s2, a2) = surahAyahOf(last);
  return [
    for (var s = s1; s <= s2; s++)
      SurahInJuz(s, s == s1 ? a1 : 1, s == s2 ? a2 : ayahCount(s)),
  ];
}

/// Bagian mushaf yang sudah terbaca bila bacaan sampai (dan termasuk) ayat
/// [index], 0.0..1.0, berbobot halaman: halaman-halaman penuh sebelumnya
/// ditambah pecahan halaman tempat ayat itu berada (dihitung per ayat di
/// dalam halaman tsb). [index] 0 = belum mulai.
double progressAfter(int index) {
  if (index <= 0) return 0;
  if (index >= totalAyahs) return 1;
  final page = pageOf(index);
  final (start, end) = pageRange(page);
  final withinPage = (index - start + 1) / (end - start + 1);
  return (page - 1 + withinPage) / totalPages;
}

/// Jumlah halaman (boleh pecahan) dari ayat [from] sampai [to], inklusif.
double pagesBetween(int from, int to) =>
    (progressAfter(to) - progressAfter(from - 1)) * totalPages;

/// Progress di dalam satu juz (0.0..1.0) bila bacaan sampai ayat [index].
double juzProgressAfter(int juz, int index) {
  final (start, end) = juzRange(juz);
  if (index < start) return 0;
  if (index >= end) return 1;
  return (progressAfter(index) - progressAfter(start - 1)) /
      (progressAfter(end) - progressAfter(start - 1));
}

/// "Al-Baqarah 142"
String formatAyah(int index) {
  final (s, a) = surahAyahOf(index);
  return '${surahName(s)} $a';
}
