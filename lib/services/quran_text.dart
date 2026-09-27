import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'quran_index.dart';

/// Keterangan satu surah.
class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.name,
    required this.arabic,
    required this.meaning,
    required this.makkiyah,
    required this.ayahCount,
    required this.description,
  });

  final int number, ayahCount;
  final String name, arabic, meaning, description;
  final bool makkiyah;

  /// Nomor ayat global ayat pertama surah ini.
  int get firstIndex => ayahIndex(number, 1);

  /// Basmalah dibaca di awal surah - kecuali Al-Fatihah (sudah jadi ayat 1)
  /// dan At-Taubah.
  bool get hasBasmalah => number != 1 && number != 9;
}

/// Satu ayat: teks Mushaf Standar Indonesia & terjemahan Kemenag.
class QuranAyah {
  const QuranAyah({
    required this.index,
    required this.surah,
    required this.number,
    required this.arabic,
    required this.translation,
    required this.juz,
    required this.page,
  });

  /// Nomor ayat global 1..6236.
  final int index;
  final int surah, number, juz, page;
  final String arabic, translation;
}

const _spelling = {
  'sholat': 'salat',
  'shalat': 'salat',
  'solat': 'salat',
  'shalih': 'saleh',
  'sholeh': 'saleh',
  'shaleh': 'saleh',
  'shodaqoh': 'sedekah',
  'sodaqoh': 'sedekah',
  'shodaqah': 'sedekah',
  'zakah': 'zakat',
  'quran': "qur'an",
  'alquran': "qur'an",
  'sabr': 'sabar',
  'taqwa': 'takwa',
  'syurga': 'surga',
};

/// Hasil pencarian: ayat & potongan terjemahan yang cocok.
class QuranSearchHit {
  const QuranSearchHit(this.ayah, this.surah);
  final QuranAyah ayah;
  final QuranSurah surah;
}

/// Teks Al-Qur'an lengkap (assets/quran/quran.json, dibuat
/// tool/gen_quran_text.py dari data web Bilal Tarawih). Dimuat sekali di
/// isolate terpisah lalu disimpan di memori.
class QuranText {
  QuranText._(this.surahs, this._ayahs) : _pageStart = _pageStarts(_ayahs);

  /// Indeks (0-based) ayat pertama tiap halaman mushaf 1..604 (+ ujung).
  static List<int> _pageStarts(List<QuranAyah> ayahs) {
    final starts = List<int>.filled(totalPages + 2, ayahs.length);
    for (var i = ayahs.length - 1; i >= 0; i--) {
      starts[ayahs[i].page] = i;
    }
    return starts;
  }

  final List<QuranSurah> surahs;
  final List<QuranAyah> _ayahs;
  final List<int> _pageStart;

  /// Ayat-ayat di halaman mushaf [page] (1..604), urut.
  List<QuranAyah> ayahsOnPage(int page) =>
      _ayahs.sublist(_pageStart[page], _pageStart[page + 1]);

  /// Halaman mushaf tempat ayat global [index] berada.
  int pageOfAyah(int index) => _ayahs[index - 1].page;

  static Future<QuranText>? _loading;

  static Future<QuranText> load() =>
      _loading ??= _load().catchError((Object e) {
        _loading = null;
        throw e;
      });

  static Future<QuranText> _load() async {
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    return compute(_parse, raw);
  }

  /// Untuk uji: parse langsung dari teks JSON.
  @visibleForTesting
  static QuranText parse(String raw) => _parse(raw);

  static QuranText _parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final surahs = [
      for (final (i, s) in (data['surah'] as List).indexed)
        QuranSurah(
          number: i + 1,
          name: s[0] as String,
          arabic: s[1] as String,
          meaning: s[2] as String,
          makkiyah: s[3] == 'mekah' || s[3] == 'makkiyah',
          ayahCount: s[4] as int,
          description: s[5] as String,
        ),
    ];
    final ayahs = <QuranAyah>[];
    final list = data['ayah'] as List;
    var i = 0;
    for (final s in surahs) {
      for (var n = 1; n <= s.ayahCount; n++, i++) {
        final a = list[i] as List;
        ayahs.add(
          QuranAyah(
            index: i + 1,
            surah: s.number,
            number: n,
            arabic: a[0] as String,
            translation: a[1] as String,
            juz: a[2] as int,
            page: a[3] as int,
          ),
        );
      }
    }
    return QuranText._(surahs, ayahs);
  }

  QuranSurah surah(int number) => surahs[number - 1];

  /// Ayat global [index] (1..6236).
  QuranAyah ayah(int index) => _ayahs[index - 1];

  List<QuranAyah> ayahsOf(int surah) {
    final s = this.surah(surah);
    return _ayahs.sublist(s.firstIndex - 1, s.firstIndex - 1 + s.ayahCount);
  }

  /// Cari di terjemahan (semua kata harus ada) - atau "2:255" / "2 255"
  /// untuk langsung ke ayat.
  List<QuranSearchHit> search(String query, {int limit = 200}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final ref = RegExp(r'^(\d{1,3})\s*[:\s.]\s*(\d{1,3})$').firstMatch(q);
    if (ref != null) {
      final s = int.parse(ref[1]!), a = int.parse(ref[2]!);
      if (s >= 1 && s <= 114 && a >= 1 && a <= surah(s).ayahCount) {
        final ayah = this.ayah(ayahIndex(s, a));
        return [QuranSearchHit(ayah, surah(s))];
      }
      return const [];
    }
    // ejaan yang lazim dipakai -> ejaan terjemahan Kemenag
    final words = [for (final w in q.split(RegExp(r'\s+'))) _spelling[w] ?? w];
    final hits = <QuranSearchHit>[];
    for (final a in _ayahs) {
      final t = a.translation.toLowerCase();
      if (words.every(t.contains)) {
        hits.add(QuranSearchHit(a, surah(a.surah)));
        if (hits.length >= limit) break;
      }
    }
    return hits;
  }

  /// Surah yang namanya/artinya/nomornya cocok.
  List<QuranSurah> findSurah(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    final plain = q.replaceAll(RegExp(r"[-'\s]"), '');
    return [
      for (final s in surahs)
        if ('${s.number}' == q ||
            s.name
                .toLowerCase()
                .replaceAll(RegExp(r"[-'\s]"), '')
                .contains(plain) ||
            s.meaning.toLowerCase().contains(q))
          s,
    ];
  }
}
