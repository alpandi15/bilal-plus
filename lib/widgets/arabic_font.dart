import 'package:flutter/widgets.dart';

/// Font teks Arab: LPMQ Isep Misbah (Lajnah Pentashihan Mushaf Al-Qur'an
/// Kemenag RI), rasm mushaf standar Indonesia. Font ini tidak memuat alif
/// washal (ٱ) - teks sumber memakai alif biasa - dan glyph tanda baca Arab
/// (، ؛ ؟) di dalamnya kosong, jadi tanda baca itu digambar dengan font
/// sistem (lihat [ArabicText]).
const arabicFont = 'LPMQ';

/// Font mode Mushaf: KFGQPC Uthmanic Script HAFS v18 (Kompleks Percetakan
/// Al-Qur'an Raja Fahd), pasangan teks Utsmani di assets/quran/uthmani.json.
const uthmanicFont = 'UthmanicHafs';

/// Pilihan font teks Al-Qur'an (Pengaturan). Tiap font berpasangan dengan
/// teksnya sendiri: LPMQ dengan rasm Mushaf Standar Indonesia
/// ([QuranAyah.arabic]), Utsmani dengan teks Utsmani ([QuranAyah.uthmani]).
enum QuranFont {
  lpmq('lpmq', 'LPMQ Isep Misbah', 'Mushaf Standar Indonesia (Kemenag)'),
  uthmani('uthmani', 'Utsmani Hafs', "Mushaf Madinah (Kompleks Raja Fahd)");

  const QuranFont(this.key, this.label, this.description);
  final String key, label, description;

  String get family => this == lpmq ? arabicFont : uthmanicFont;

  static QuranFont parse(String? key) =>
      values.firstWhere((f) => f.key == key, orElse: () => lpmq);
}

final _punctuation = RegExp('[،؛؟]');

/// Teks Arab kanan-ke-kiri dengan font LPMQ.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.right,
    this.maxLines,
    this.overflow,
  }) : parts = null;

  /// Teks berwarna per potongan (mis. hukum tajwid); warna null = biasa.
  const ArabicText.rich(
    List<({String text, Color? color})> this.parts, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.right,
    this.maxLines,
    this.overflow,
  }) : text = '';

  final String text;
  final List<({String text, Color? color})>? parts;

  /// Gaya dasar; [arabicFont] dipasang otomatis.
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spans = parts == null
        ? _spans(text)
        : [
            for (final p in parts!)
              TextSpan(
                style: p.color == null ? null : TextStyle(color: p.color),
                children: _spans(p.text),
              ),
          ];
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: overflow,
      style: style.copyWith(fontFamily: arabicFont),
    );
  }

  static List<InlineSpan> _spans(String text) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _punctuation.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m[0],
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }
}
