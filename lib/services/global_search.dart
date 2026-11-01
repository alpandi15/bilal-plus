import '../data/asmaul_husna_data.dart';
import '../db/hadits_database.dart';
import '../pages/doa_page.dart';
import 'quran_text.dart';

/// Pencarian satu kolom untuk Al-Qur'an, hadits, do'a & Asmaul Husna.
/// Tiap sumber dibatasi jumlahnya ([globalSearchLimit]) dan dicari tanpa
/// memuat seluruh isinya ke memori: Al-Qur'an & do'a sudah ada di memori,
/// hadits dicari lewat kueri basis data (pindai ±40 ribu hadits < 50 ms di
/// desktop, tanpa indeks tambahan).

/// Hasil terbanyak per sumber.
const globalSearchLimit = 30;

/// Panjang kata kunci minimal (angka/rujukan boleh lebih pendek).
const globalSearchMinLength = 2;

/// Satu hasil hadits (hanya yang perlu ditampilkan).
class HaditsHit {
  const HaditsHit(this.book, this.number, this.translation);
  final String book;
  final int number;
  final String translation;

  String get bookName => haditsBookName(book);
}

class DoaHit {
  const DoaHit(this.doa, this.excerpt);
  final Doa doa;

  /// Terjemahan/latin yang memuat kata kunci (atau arti pertama).
  final String excerpt;
}

class GlobalSearchResult {
  const GlobalSearchResult({
    this.surahs = const [],
    this.ayat = const [],
    this.hadits = const [],
    this.haditsTotal = 0,
    this.haditsAvailable = true,
    this.doa = const [],
    this.asmaulHusna = const [],
    this.words = const [],
  });

  static const empty = GlobalSearchResult();

  /// Surah yang namanya cocok.
  final List<QuranSurah> surahs;
  final List<QuranSearchHit> ayat;
  final List<HaditsHit> hadits;

  /// Seluruh hadits yang cocok (bisa lebih dari [hadits]).
  final int haditsTotal;

  /// false bila belum ada kitab hadits yang diunduh.
  final bool haditsAvailable;
  final List<DoaHit> doa;
  final List<AsmaulHusna> asmaulHusna;

  /// Kata yang dicari (untuk sorotan).
  final List<String> words;

  bool get isEmpty =>
      surahs.isEmpty &&
      ayat.isEmpty &&
      hadits.isEmpty &&
      doa.isEmpty &&
      asmaulHusna.isEmpty;
}

/// Kata kunci dari [query]: huruf kecil, dipisah spasi.
List<String> searchTerms(String query) => [
  for (final w in query.trim().toLowerCase().split(RegExp(r'\s+')))
    if (w.isNotEmpty) w,
];

/// Cukup panjang untuk dicari?
bool searchable(String query) {
  final q = query.trim();
  return q.length >= globalSearchMinLength || int.tryParse(q) != null;
}

String _plain(String s) => s.toLowerCase().replaceAll(RegExp(r"[-'`’\s]"), '');

List<AsmaulHusna> searchAsmaulHusna(String query) {
  final q = _plain(query);
  if (q.isEmpty) return const [];
  final n = int.tryParse(query.trim());
  return [
    for (final a in asmaulHusna)
      if (_plain(a.latin).contains(q) ||
          a.arti.toLowerCase().contains(query.trim().toLowerCase()) ||
          (n != null && a.number == n))
        a,
  ];
}

List<DoaHit> searchDoa(List<Doa> all, String query) {
  final words = searchTerms(query);
  if (words.isEmpty) return const [];
  final out = <DoaHit>[];
  for (final d in all) {
    final fields = [
      d.title,
      for (final r in d.readings) ...[r.arti, r.latin],
    ];
    final hay = fields.join(' \n ').toLowerCase();
    if (!words.every(hay.contains)) continue;
    // cuplikan: bagian pertama yang memuat salah satu kata, selain judul
    final hit = fields
        .skip(1)
        .firstWhere(
          (f) => words.any(f.toLowerCase().contains),
          orElse: () => d.readings.isEmpty ? '' : d.readings.first.arti,
        );
    out.add(DoaHit(d, hit));
    if (out.length >= globalSearchLimit) break;
  }
  return out;
}

Future<bool> haditsHasAny(HaditsDatabase db) async =>
    (await db.customSelect('SELECT 1 FROM hadiths LIMIT 1').get()).isNotEmpty;

Future<(List<HaditsHit>, int)> searchHadits(
  HaditsDatabase db,
  String query,
) async {
  final rows = await db.page(null, query, offset: 0, limit: globalSearchLimit);
  final total = await db.countMatching(null, query);
  return (
    [for (final h in rows) HaditsHit(h.book, h.number, h.translation)],
    total,
  );
}

/// Cari [query] di semua sumber. [quran]/[doa] sudah dimuat pemanggil;
/// [hadits] null = lewati hadits.
Future<GlobalSearchResult> globalSearch(
  String query, {
  required QuranText quran,
  required List<Doa> doa,
  HaditsDatabase? hadits,
}) async {
  if (!searchable(query)) return GlobalSearchResult.empty;
  final isRef = RegExp(r'^\d{1,3}\s*[:\s.]\s*\d{1,3}$').hasMatch(query.trim());
  final isNumber = int.tryParse(query.trim()) != null;

  final surahs = isRef
      ? const <QuranSurah>[]
      : quran
            .findSurah(query)
            .where((_) => query.trim().isNotEmpty)
            .take(4)
            .toList();
  final ayat = quran.search(query, limit: globalSearchLimit);

  var haditsHits = const <HaditsHit>[];
  var haditsTotal = 0;
  var available = true;
  if (hadits != null && !isRef) {
    if (await haditsHasAny(hadits)) {
      // nomor saja ("255") bukan kata kunci hadits yang bermakna
      if (!isNumber) {
        final (rows, total) = await searchHadits(hadits, query);
        haditsHits = rows;
        haditsTotal = total;
      }
    } else {
      available = false;
    }
  }

  return GlobalSearchResult(
    surahs: isNumber ? const [] : surahs,
    ayat: ayat,
    hadits: haditsHits,
    haditsTotal: haditsTotal,
    haditsAvailable: available,
    doa: isRef || isNumber ? const [] : searchDoa(doa, query),
    asmaulHusna: isRef ? const [] : searchAsmaulHusna(query),
    words: isRef ? const [] : QuranText.searchWords(query),
  );
}
