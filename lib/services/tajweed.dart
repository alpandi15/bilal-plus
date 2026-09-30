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

/// Tanda waqaf (berhenti/lanjut) di Mushaf Standar Indonesia & rasm
/// Utsmani, dengan hukumnya. Warnanya mengikuti "lampu lalu lintas": merah =
/// berhenti, kuning = bebas, hijau/biru = lanjut.
enum WaqfSign {
  lazim(
    '\u06D8',
    'م',
    'Mim (waqaf lazim)',
    'Wajib berhenti - bila disambung bisa mengubah makna',
    Color(0xFF7F1D1D),
  ),
  qala(
    '\u06D7',
    'قلى',
    'Qala (قلى)',
    'Boleh berhenti, dan berhenti lebih utama',
    Color(0xFFDC2626),
  ),
  jaiz(
    '\u06DA',
    'ج',
    'Jim (waqaf jaiz)',
    'Boleh berhenti atau melanjutkan - sama baiknya',
    Color(0xFFD97706),
  ),
  shala(
    '\u06D6',
    'صلى',
    'Shala (صلى)',
    'Boleh berhenti, tapi melanjutkan lebih utama',
    Color(0xFF16A34A),
  ),
  la(
    '\u06D9',
    'لا',
    'Lam alif (لا)',
    'Jangan berhenti di sini (kecuali di akhir ayat); bila terpaksa '
        'berhenti, ulangi dari kata sebelumnya',
    Color(0xFF2563EB),
  ),
  muanaqah(
    '\u06DB',
    '∴',
    "Mu'anaqah (∴ ∴)",
    'Berpasangan: berhenti di salah satu tanda saja, jangan di keduanya',
    Color(0xFF7C3AED),
  ),
  saktah(
    '\u06DC',
    'س',
    'Saktah (س)',
    'Berhenti sejenak tanpa mengambil napas, lalu lanjut',
    Color(0xFF0891B2),
  );

  const WaqfSign(
    this.char,
    this.glyph,
    this.label,
    this.description,
    this.color,
  );

  /// Karakter tanda di teks (tanda kecil di atas huruf).
  final String char;

  /// Bentuk tandanya sebagai huruf biasa - untuk ditampilkan tersendiri di
  /// legenda (tanda kecil tak bisa berdiri tanpa huruf dasar).
  final String glyph;
  final String label, description;
  final Color color;

  static final _byChar = {for (final w in values) w.char.codeUnitAt(0): w};

  /// Tanda waqaf untuk kode karakter [c], null bila bukan.
  static WaqfSign? of(int c) => _byChar[c];

  /// Tanda-tanda waqaf dalam [text] (urut, tanpa duplikat).
  static List<WaqfSign> inText(String text) => {
    for (final c in text.codeUnits)
      if (_byChar[c] case final w?) w,
  }.toList();
}

/// Potongan teks ayat dengan hukum tajwidnya (null = biasa), atau satu
/// tanda waqaf ([waqf]) yang diwarnai tersendiri.
typedef TajweedSegment = ({String text, TajweedRule? rule, WaqfSign? waqf});

/// Warna potongan: tanda waqaf, lalu hukum tajwid (null = warna teks biasa).
Color? segmentColor(TajweedSegment s) => s.waqf?.color ?? s.rule?.color;

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

// Rasm Utsmani KFGQPC (mode Mushaf): sukun = ۡ (U+06E1), ْ (U+0652) =
// huruf tidak dibaca, tanwin bertingkat ٞ ٗ ٖ = idgham/ikhfa, mim kecil
// ۢ ۭ = iqlab, nun/mim mati sebelum idgham/ikhfa ditulis tanpa tanda.
const _uSukun = 0x06E1, _uSilent = 0x0652;
const _uTanwin = {0x064B, 0x064C, 0x064D, 0x065E, 0x0657, 0x0656};
const _uVowels = {0x064E, 0x064F, 0x0650, 0x0670};
const _uIqlab = {0x06E2, 0x06ED};

const _izharLetters = 'هعحغخ';
const _ghunnahLetters = 'ينمو';
const _ikhfaLetters = 'تثجدذزسشصضطظفقك';
const _qalqalahLetters = 'قطبجد';
const _hamzaLetters = 'ءأإؤئآ';

class _Cluster {
  _Cluster(this.base, this.word, this.uthmani);
  final String? base; // null = tanda tanpa huruf (mis. tanda waqaf lepas)
  final int word;
  final bool uthmani;
  final marks = <int>[];
  final buffer = StringBuffer();

  bool get isLetter => base != null && base != ' ';
  bool has(int m) => marks.contains(m);
  bool get hasTanwin => marks.any((uthmani ? _uTanwin : _tanwin).contains);
  bool get hasVowel => marks.any(
    (m) =>
        (uthmani ? _uVowels : _vowels).contains(m) ||
        (uthmani ? _uTanwin : _tanwin).contains(m),
  );
  bool get hasSukun => has(uthmani ? _uSukun : _sukun);

  /// Huruf mati: bersukun - atau, di rasm Utsmani, nun/mim tanpa tanda
  /// apa pun (mati yang dilebur/disamarkan).
  bool get isSakin =>
      hasSukun ||
      (uthmani &&
          (base == 'ن' || base == 'م') &&
          !hasVowel &&
          !has(_shadda) &&
          !has(_uSilent));

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
      base == 'ٱ' ||
      ((base == 'ا' || base == 'ى') && !isHamza && !hasVowel) ||
      (uthmani && has(_uSilent));
}

List<_Cluster> _clusters(String text, bool uthmani) {
  final out = <_Cluster>[];
  var word = 0;
  for (final c in text.runes) {
    final ch = String.fromCharCode(c);
    if (ch == ' ') {
      word++;
      out.add(_Cluster(' ', word, uthmani)..buffer.write(ch));
      continue;
    }
    if (_isMark(c) && out.isNotEmpty && out.last.base != ' ') {
      out.last
        ..marks.add(c)
        ..buffer.write(ch);
      continue;
    }
    final cl = _Cluster(_isMark(c) ? null : ch, word, uthmani)
      ..buffer.write(ch);
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
/// Aturan dibaca dari harakat & tanda MSI - atau rasm Utsmani KFGQPC bila
/// [uthmani]; hukum yang melewati batas ayat tidak diterapkan (bacaan
/// berhenti di akhir ayat).
List<TajweedSegment> tajweedSegments(String text, {bool uthmani = false}) {
  final cs = _clusters(text, uthmani);
  final rules = List<TajweedRule?>.filled(cs.length, null);
  void mark(int i, TajweedRule r) => rules[i] ??= r;

  // mad lebih dulu: pada huruf muqatta'ah (mis. مّۤ) mad lazim mengalahkan
  // ghunnah
  for (var i = 0; i < cs.length; i++) {
    final c = cs[i];
    if (!c.isLetter) continue;
    // mad far'i: ۤ (mad wajib / lazim) & ٓ (mad jaiz / lazim) di MSI
    if (c.has(_smallHighMadda) || c.has(_maddah)) {
      // Utsmani: ٓ di atas hamzah (mis. ٱلۡأٓخِرَةِ) = mad badal, bukan far'i
      if (uthmani && c.isHamza) continue;
      final k = _nextSpoken(cs, i);
      final n = k == null ? null : cs[k];
      final same = n != null && n.word == c.word;
      TajweedRule r;
      if (n != null && same && (n.has(_shadda) || n.hasSukun)) {
        r = TajweedRule.madLazim;
      } else if (n != null && same && n.isHamza) {
        r = TajweedRule.madWajib;
      } else if (c.has(_smallHighMadda) ||
          (uthmani && (n == null || !n.isHamza))) {
        // tanda mad tanpa hamzah sesudahnya: huruf muqatta'ah (mis. الۤمّۤ)
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

    // iqlab bertanda (Utsmani: mim kecil ۢ ۭ di atas/bawah nun/tanwin)
    if (uthmani && c.marks.any(_uIqlab.contains)) {
      mark(i, TajweedRule.iqlab);
      final k = _nextSpoken(cs, i);
      if (k != null) mark(k, TajweedRule.iqlab);
    }

    // nun sukun / tanwin
    if ((base == 'ن' && c.isSakin) || c.hasTanwin) {
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
    if (base == 'م' && c.isSakin) {
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
    if (_qalqalahLetters.contains(base) && c.hasSukun) {
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

  // gabungkan potongan berurutan dengan hukum yang sama; tanda waqaf
  // dipisah jadi potongan sendiri (hanya warnanya yang beda, jadi bentuk
  // huruf tetap tersambung)
  final out = <TajweedSegment>[];
  final buf = StringBuffer();
  TajweedRule? current;
  void flush() {
    if (buf.isEmpty) return;
    out.add((text: buf.toString(), rule: current, waqf: null));
    buf.clear();
  }

  for (var i = 0; i < cs.length; i++) {
    final r = rules[i];
    if (r != current) flush();
    current = r;
    for (final ch in cs[i].buffer.toString().runes) {
      final w = WaqfSign.of(ch);
      if (w == null) {
        buf.writeCharCode(ch);
      } else {
        flush();
        out.add((text: w.char, rule: null, waqf: w));
      }
    }
  }
  flush();
  return out;
}
