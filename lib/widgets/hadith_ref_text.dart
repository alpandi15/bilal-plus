import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../pages/hadits_page.dart';

/// Nama kitab di teks rujukan -> kunci kitab hadits di app.
const _books = {
  'bukhari': 'bukhari',
  'muslim': 'muslim',
  'abu daud': 'abu-daud',
  'abu dawud': 'abu-daud',
  'tirmidzi': 'tirmidzi',
  "nasa'i": 'nasai',
  'nasai': 'nasai',
  'ibnu majah': 'ibnu-majah',
  'ahmad': 'ahmad',
  'malik': 'malik',
  'darimi': 'darimi',
  'ad-darimi': 'darimi',
};

final _ref = RegExp(
  "(Bukhari|Muslim|Abu Daud|Abu Dawud|Tirmidzi|Nasa'?i|Ibnu Majah|Ahmad|"
  r'Malik|Ad-Darimi|Darimi)\s+no\.\s*(\d+)',
  caseSensitive: false,
);

/// Teks rujukan tanpa tag HTML ("<p>HR. Abu Daud no. <a …>2010</a></p>").
String plainReference(String html) => html
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Keterangan perawi do'a/dzikir. Setiap "Kitab no. N" (Bukhari, Muslim,
/// Abu Daud, ...) menjadi tautan yang membuka hadits itu DI APLIKASI (bukan
/// di web) - kitab yang belum diunduh ditawarkan untuk diunduh.
class HadithRefText extends StatefulWidget {
  const HadithRefText(this.source, {super.key, this.style});

  /// Teks rujukan, boleh berisi HTML dari data web.
  final String source;
  final TextStyle? style;

  @override
  State<HadithRefText> createState() => _HadithRefTextState();
}

class _HadithRefTextState extends State<HadithRefText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _open(String book, int number) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HadithDetailPage(book: book, number: number),
    ),
  );

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final text = plainReference(widget.source);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _ref.allMatches(text)) {
      final book = _books[m[1]!.toLowerCase()];
      if (book == null) continue;
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      final number = int.parse(m[2]!);
      final tap = TapGestureRecognizer()..onTap = () => _open(book, number);
      _recognizers.add(tap);
      spans.add(
        TextSpan(
          text: m[0],
          recognizer: tap,
          style: const TextStyle(
            color: Color(0xFF047857),
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: Color(0x80047857),
          ),
        ),
      );
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
