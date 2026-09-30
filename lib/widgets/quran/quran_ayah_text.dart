import 'package:flutter/widgets.dart';

import '../../services/quran_text.dart';
import '../../services/tajweed.dart';
import '../arabic_font.dart';

/// Teks ayat sesuai font pilihan pengguna ([QuranFont]): LPMQ memakai teks
/// Mushaf Standar Indonesia, Utsmani memakai teks Utsmani - masing-masing
/// dengan pewarnaan tajwidnya.
class QuranAyahText extends StatelessWidget {
  const QuranAyahText(
    this.text, {
    super.key,
    required this.font,
    required this.style,
    this.tajweed = false,
    this.textAlign = TextAlign.right,
  });

  /// Teks yang sesuai [font] - lihat [quranTextFor].
  final String text;
  final QuranFont font;
  final TextStyle style;
  final bool tajweed;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final uthmani = font == QuranFont.uthmani;
    if (!uthmani) {
      return tajweed
          ? ArabicText.rich(
              [
                for (final s in tajweedSegments(text))
                  (text: s.text, color: segmentColor(s)),
              ],
              style: style,
              textAlign: textAlign,
            )
          : ArabicText(text, style: style, textAlign: textAlign);
    }
    return Text.rich(
      TextSpan(
        children: tajweed
            ? [
                for (final s in tajweedSegments(text, uthmani: true))
                  TextSpan(
                    text: s.text,
                    style: segmentColor(s) == null
                        ? null
                        : TextStyle(color: segmentColor(s)),
                  ),
              ]
            : [TextSpan(text: text)],
      ),
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      style: style.copyWith(fontFamily: uthmanicFont),
    );
  }
}

/// Teks ayat [a] untuk [font].
String quranTextFor(QuranAyah a, QuranFont font) =>
    font == QuranFont.uthmani ? a.uthmani : a.arabic;
