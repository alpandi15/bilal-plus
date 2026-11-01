import '../utils/date_key.dart';
import 'quran_index.dart';

/// Muraja'ah: hafalan diulang berjarak. Satu UNIT = rentang ayat berurutan
/// (satu surah) berukuran paling banyak [murajaahMaxUnit] ayat; tiap unit
/// punya jadwalnya sendiri.

/// Jarak ulang (hari) per tahap: 1, 3, 7, 14, 30. Sesudah tahap terakhir
/// jaraknya tetap 30 hari.
const murajaahIntervals = [1, 3, 7, 14, 30];

/// Ayat terbanyak dalam satu unit.
const murajaahMaxUnit = 10;

/// Unit baru yang menumpuk (mis. menandai satu surah sekaligus) diberi
/// jadwal bertahap: paling banyak segini unit jatuh tempo per hari.
const murajaahNewPerDay = 3;

/// Penilaian sesudah mengulang satu unit.
enum MurajaahGrade {
  /// lancar: naik satu tahap
  lancar('Lancar'),

  /// ragu: turun satu tahap
  ragu('Ragu'),

  /// lupa: kembali ke tahap awal (besok diulang)
  lupa('Lupa');

  const MurajaahGrade(this.label);
  final String label;
}

/// Keadaan jadwal satu unit.
class MurajaahState {
  const MurajaahState({
    required this.stage,
    required this.due,
    this.lapses = 0,
  });

  /// Indeks di [murajaahIntervals].
  final int stage;

  /// Tanggal jatuh tempo (kunci tanggal).
  final String due;
  final int lapses;

  bool isDue(String today) => due.compareTo(today) <= 0;

  /// Hari terlambat (0 bila belum/baru jatuh tempo).
  int overdueDays(String today) {
    final d = parseDateKey(today).difference(parseDateKey(due)).inDays;
    return d < 0 ? 0 : d;
  }
}

String _plusDays(String today, int days) =>
    dateKey(parseDateKey(today).add(Duration(days: days)));

/// Keadaan sesudah [grade] pada hari [today].
MurajaahState murajaahGraded(
  MurajaahState s,
  MurajaahGrade grade,
  String today,
) {
  final last = murajaahIntervals.length - 1;
  switch (grade) {
    case MurajaahGrade.lancar:
      final stage = s.stage >= last ? last : s.stage + 1;
      return MurajaahState(
        stage: stage,
        due: _plusDays(today, murajaahIntervals[stage]),
        lapses: s.lapses,
      );
    case MurajaahGrade.ragu:
      final stage = s.stage <= 0 ? 0 : s.stage - 1;
      return MurajaahState(
        stage: stage,
        due: _plusDays(today, murajaahIntervals[stage]),
        lapses: s.lapses,
      );
    case MurajaahGrade.lupa:
      return MurajaahState(
        stage: 0,
        due: _plusDays(today, murajaahIntervals[0]),
        lapses: s.lapses + 1,
      );
  }
}

/// Jatuh tempo unit baru ke-[i] (0-based) yang dibuat pada [today].
String murajaahFirstDue(String today, int i) =>
    _plusDays(today, 1 + i ~/ murajaahNewPerDay);

/// Rentang ayat global [start]..[end] satu unit.
typedef MurajaahRange = (int, int);

/// Bagi ayat-ayat [ayahs] (urut naik) menjadi unit: ayat berurutan dalam
/// satu surah dikelompokkan, lalu dipecah rata bila lebih dari
/// [murajaahMaxUnit].
List<MurajaahRange> murajaahChunks(List<int> ayahs) {
  final out = <MurajaahRange>[];
  var i = 0;
  while (i < ayahs.length) {
    var j = i;
    while (j + 1 < ayahs.length &&
        ayahs[j + 1] == ayahs[j] + 1 &&
        surahAyahOf(ayahs[j + 1]).$1 == surahAyahOf(ayahs[i]).$1) {
      j++;
    }
    final n = j - i + 1;
    final parts = (n + murajaahMaxUnit - 1) ~/ murajaahMaxUnit;
    var at = i;
    for (var p = 0; p < parts; p++) {
      // pembagian rata: sisa dibagikan ke bagian-bagian awal
      final size = n ~/ parts + (p < n % parts ? 1 : 0);
      out.add((ayahs[at], ayahs[at + size - 1]));
      at += size;
    }
    i = j + 1;
  }
  return out;
}

/// Hasil penyesuaian unit terhadap hafalan sekarang.
class MurajaahPlan {
  const MurajaahPlan({required this.remove, required this.create});

  /// Unit yang ayatnya tidak lagi seluruhnya hafal (dihapus bersama
  /// jadwalnya).
  final List<int> remove;

  /// Unit baru untuk ayat hafal yang belum tercakup unit mana pun.
  final List<MurajaahRange> create;
}

/// Sesuaikan unit [existing] (id -> rentang) dengan ayat [memorized]. Unit
/// yang masih utuh dibiarkan (jadwalnya tetap); hanya ayat yang belum
/// tercakup yang dijadikan unit baru - jadi menambah hafalan tidak
/// mengacak jadwal yang sudah berjalan.
MurajaahPlan planMurajaah(
  Set<int> memorized,
  Map<int, MurajaahRange> existing,
) {
  final remove = <int>[];
  final covered = <int>{};
  for (final e in existing.entries) {
    final (s, t) = e.value;
    var whole = true;
    for (var a = s; a <= t; a++) {
      if (!memorized.contains(a)) {
        whole = false;
        break;
      }
    }
    if (whole) {
      for (var a = s; a <= t; a++) {
        covered.add(a);
      }
    } else {
      remove.add(e.key);
    }
  }
  final fresh = [
    for (final a in memorized)
      if (!covered.contains(a)) a,
  ]..sort();
  return MurajaahPlan(remove: remove, create: murajaahChunks(fresh));
}

/// "Al-Baqarah 1-5" / "Al-Ikhlas 1-4" / "Al-Kautsar 2".
String murajaahLabel(int start, int end) {
  final (s, a) = surahAyahOf(start);
  final (_, b) = surahAyahOf(end);
  return a == b ? '${surahName(s)} $a' : '${surahName(s)} $a-$b';
}
