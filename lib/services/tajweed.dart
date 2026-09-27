import 'package:flutter/painting.dart';

/// Hukum tajwid yang diwarnai. Dideteksi otomatis dari harakat & tanda
/// Mushaf Standar Indonesia (lihat [tajweedSegments]).
enum TajweedRule {
  ghunnah(
    'Ghunnah',
    'Nun/mim bertasydid - dengung 2 harakat',
    Color(0xFF16A34A),
  ),
  ikhfa(
    "Ikhfa'",
    'Nun sukun/tanwin bertemu huruf ikhfa - samar berdengung',
    Color(0xFF0E7490),
  ),
  ikhfaSyafawi(
    "Ikhfa' syafawi",
    'Mim sukun bertemu ba - samar di bibir',
    Color(0xFF0891B2),
  ),
  idghamGhunnah(
    'Idgham bighunnah',
    'Nun sukun/tanwin bertemu ya, nun, mim, wau - lebur berdengung',
    Color(0xFF7C3AED),
  ),
  idghamMimi(
    'Idgham mimi',
    'Mim sukun bertemu mim - lebur berdengung',
    Color(0xFF9333EA),
  ),
  idghamBilaGhunnah(
    'Idgham bilaghunnah',
    'Nun sukun/tanwin bertemu lam, ra - lebur tanpa dengung',
    Color(0xFF64748B),
  ),
  iqlab(
    'Iqlab',
    'Nun sukun/tanwin bertemu ba - berubah bunyi mim',
    Color(0xFF2563EB),
  ),
  qalqalah(
    'Qalqalah',
    'Qaf, tha, ba, jim, dal sukun atau di akhir bacaan - memantul',
    Color(0xFFDB2777),
  ),
  madWajib(
    'Mad wajib muttashil',
    'Mad bertemu hamzah dalam satu kata - 4/5 harakat',
    Color(0xFFDC2626),
  ),
  madJaiz(
    'Mad jaiz munfashil',
    'Mad bertemu hamzah di kata berikutnya - 2/4/5 harakat',
    Color(0xFFEA580C),
  ),
  madLazim(
    'Mad lazim',
    'Mad bertemu sukun/tasydid (termasuk huruf muqatta\'ah) - 6 harakat',
    Color(0xFF991B1B),
  );

  const TajweedRule(this.label, this.description, this.color);
  final String label, description;
  final Color color;
}

/// Potongan teks ayat dengan hukum tajwidnya (null = biasa).
typedef TajweedSegment = ({String text, TajweedRule? rule});

// harakat & tanda yang menempel pada huruf sebelumnya
bool _isMark(int c) =>
    (c >= 0x0610 && c <= 0x061A) ||
    (c >= 0x064B && c <= 0x065F) ||
    c == 0x0670 ||
    (c >= 0x06D6 && c <= 0x06DC) ||
    (c >= 0x06DF && c <= 0x06E4) ||
    (c >= 0x06E7 && c <= 0x06E8) ||
    (c >= 0x06EA && c <= 0x06ED) ||
    (c >= 0x08D3 && c <= 0x08FF);

const _sukun = 0x0652, _shadda = 0x0651, _maddah = 0x0653;
const _smallHighMadda = 0x06E4, _hamzaAbove = 0x0654, _hamzaBelow = 0x0655;
const _tanwin = {0x064B, 0x064C, 0x064D};
const _vowels = {0x064E, 0x064F, 0x0650, 0x0656, 0x0657, 0x0670};

const _izharLetters = 'هعحغخ';
const _ghunnahLetters = 'ينمو';
const _ikhfaLetters = 'تثجدذزسشصضطظفقك';
const _qalqalahLetters = 'قطبجد';
const _hamzaLetters = 'ءأإؤئآ';

class _Cluster {
  _Cluster(this.base, this.word);
  final String? base; // null = tanda tanpa huruf (mis. tanda waqaf lepas)
  final int word;
  final marks = <int>[];
  final buffer = StringBuffer();

  bool get isLetter => base != null && base != ' ';
  bool has(int m) => marks.contains(m);
  bool get hasTanwin => marks.any(_tanwin.contains);
  bool get hasVowel =>
      marks.any((m) => _vowels.contains(m) || _tanwin.contains(m));

  /// Hamzah: huruf hamzah, alif berharakat (cara MSI menulis hamzah
  /// qatha'), atau kursi (ya/tatwil) dengan tanda hamzah.
  bool get isHamza =>
      _hamzaLetters.contains(base!) ||
      (base == 'ا' && hasVowel) ||
      has(_hamzaAbove) ||
      has(_hamzaBelow);

  /// Alif/alif maqshurah tanpa harakat - tidak dibaca (alif washal di awal
  /// kata, atau alif sesudah fathatan/mad).
  bool get isSilentAlif =>
      (base == 'ا' || base == 'ى') && !isHamza && !hasVowel;
}

List<_Cluster> _clusters(String text) {
  final out = <_Cluster>[];
  var word = 0;
  for (final c in text.runes) {
    final ch = String.fromCharCode(c);
    if (ch == ' ') {
      word++;
      out.add(_Cluster(' ', word)..buffer.write(ch));
      continue;
    }
    if (_isMark(c) && out.isNotEmpty && out.last.base != ' ') {
      out.last
        ..marks.add(c)
        ..buffer.write(ch);
      continue;
    }
    final cl = _Cluster(_isMark(c) ? null : ch, word)..buffer.write(ch);
    if (_isMark(c)) cl.marks.add(c);
    out.add(cl);
  }
  return out;
}

/// Huruf terbaca berikutnya sesudah [i]: melewati spasi, tanda lepas, dan
/// alif tak terbaca di kata yang sama. null bila ayat habis (berhenti) atau
/// kata berikutnya diawali alif washal (tidak ada hukum nun/mim).
int? _nextSpoken(List<_Cluster> cs, int i) {
  for (var k = i + 1; k < cs.length; k++) {
    final c = cs[k];
    if (!c.isLetter) continue;
    if (c.isSilentAlif) {
      if (c.word == cs[i].word) continue;
      return null;
    }
    // tatwil tanpa hamzah hanya penyambung tulisan
    if (c.base == 'ـ' && !c.isHamza) continue;
    return k;
  }
  return null;
}

/// Pecah [text] (satu ayat) menjadi potongan berwarna sesuai hukum tajwid.
/// Aturan dibaca dari harakat & tanda MSI; hukum yang melewati batas ayat
/// tidak diterapkan (bacaan berhenti di akhir ayat).
List<TajweedSegment> tajweedSegments(String text) {
  final cs = _clusters(text);
  final rules = List<TajweedRule?>.filled(cs.length, null);
  void mark(int i, TajweedRule r) => rules[i] ??= r;

  // mad lebih dulu: pada huruf muqatta'ah (mis. مّۤ) mad lazim mengalahkan
  // ghunnah
  for (var i = 0; i < cs.length; i++) {
    final c = cs[i];
    if (!c.isLetter) continue;
    // mad far'i: ۤ (mad wajib / lazim) & ٓ (mad jaiz / lazim) di MSI
    if (c.has(_smallHighMadda) || c.has(_maddah)) {
      final k = _nextSpoken(cs, i);
      final n = k == null ? null : cs[k];
      final same = n != null && n.word == c.word;
      TajweedRule r;
      if (n != null && same && (n.has(_shadda) || n.has(_sukun))) {
        r = TajweedRule.madLazim;
      } else if (n != null && same && n.isHamza) {
        r = TajweedRule.madWajib;
      } else if (c.has(_smallHighMadda)) {
        // ۤ tanpa hamzah sesudahnya: huruf muqatta'ah (mis. الۤمّۤ)
        r = TajweedRule.madLazim;
      } else {
        r = TajweedRule.madJaiz;
      }
      mark(i, r);
    }
  }

  for (var i = 0; i < cs.length; i++) {
    final c = cs[i];
    if (!c.isLetter) continue;
    final base = c.base!;

    // nun sukun / tanwin
    if ((base == 'ن' && c.has(_sukun)) || c.hasTanwin) {
      final k = _nextSpoken(cs, i);
      if (k != null) {
        final n = cs[k];
        final same = n.word == c.word;
        final nb = n.base!;
        TajweedRule? r;
        if (n.isHamza || _izharLetters.contains(nb)) {
          r = null; // izhar
        } else if (_ghunnahLetters.contains(nb)) {
          // dalam satu kata (mis. دُنْيَا) = izhar mutlak
          r = same ? null : TajweedRule.idghamGhunnah;
        } else if (nb == 'ل' || nb == 'ر') {
          r = TajweedRule.idghamBilaGhunnah;
        } else if (nb == 'ب') {
          r = TajweedRule.iqlab;
        } else if (_ikhfaLetters.contains(nb)) {
          r = TajweedRule.ikhfa;
        }
        if (r != null) {
          mark(i, r);
          mark(k, r);
        }
      }
    }

    // mim sukun
    if (base == 'م' && c.has(_sukun)) {
      final k = _nextSpoken(cs, i);
      if (k != null && cs[k].base == 'ب') {
        mark(i, TajweedRule.ikhfaSyafawi);
        mark(k, TajweedRule.ikhfaSyafawi);
      } else if (k != null && cs[k].base == 'م') {
        mark(i, TajweedRule.idghamMimi);
        mark(k, TajweedRule.idghamMimi);
      }
    }

    // ghunnah: nun/mim bertasydid
    if ((base == 'ن' || base == 'م') && c.has(_shadda)) {
      mark(i, TajweedRule.ghunnah);
    }

    // qalqalah sughra
    if (_qalqalahLetters.contains(base) && c.has(_sukun)) {
      mark(i, TajweedRule.qalqalah);
    }
  }

  // qalqalah kubra: huruf qalqalah terakhir yang dibaca saat berhenti.
  // Berakhir alif/ya tak berharakat (fathatan + alif, mad) = dibaca panjang,
  // bukan dimatikan - tidak ada qalqalah.
  for (var i = cs.length - 1; i >= 0; i--) {
    final c = cs[i];
    if (!c.isLetter) continue;
    if (!c.isSilentAlif && _qalqalahLetters.contains(c.base!)) {
      mark(i, TajweedRule.qalqalah);
    }
    break;
  }

  // gabungkan potongan berurutan dengan hukum yang sama
  final out = <TajweedSegment>[];
  final buf = StringBuffer();
  TajweedRule? current;
  for (var i = 0; i < cs.length; i++) {
    final r = rules[i];
    if (r != current && buf.isNotEmpty) {
      out.add((text: buf.toString(), rule: current));
      buf.clear();
    }
    current = r;
    buf.write(cs[i].buffer);
  }
  if (buf.isNotEmpty) out.add((text: buf.toString(), rule: current));
  return out;
}
