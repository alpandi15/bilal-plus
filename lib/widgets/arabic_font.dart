import 'package:flutter/widgets.dart';

/// Font teks Arab: LPMQ Isep Misbah (Lajnah Pentashihan Mushaf Al-Qur'an
/// Kemenag RI), rasm mushaf standar Indonesia. Font ini tidak memuat alif
/// washal (ٱ) - teks sumber memakai alif biasa - dan glyph tanda baca Arab
/// (، ؛ ؟) di dalamnya kosong, jadi tanda baca itu digambar dengan font
/// sistem (lihat [ArabicText]).
const arabicFont = 'LPMQ';

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
  });

  final String text;

  /// Gaya dasar; [arabicFont] dipasang otomatis.
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
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
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: overflow,
      style: style.copyWith(fontFamily: arabicFont),
    );
  }
}
