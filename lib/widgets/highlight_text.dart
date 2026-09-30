import 'package:flutter/material.dart';

/// Gaya sorotan kata yang dicari (hasil pencarian Al-Qur'an & hadits).
const searchHighlight = TextStyle(
  backgroundColor: Color(0xFFFDE68A),
  fontWeight: FontWeight.w700,
  color: Color(0xFF78350F),
);

/// Potongan [text] dengan setiap kemunculan [words] (tanpa beda huruf
/// besar-kecil) disorot [highlight].
List<TextSpan> highlightSpans(
  String text,
  Iterable<String> words, {
  TextStyle highlight = searchHighlight,
}) {
  final lower = text.toLowerCase();
  final ranges = <(int, int)>[];
  for (final w in words) {
    final q = w.trim().toLowerCase();
    if (q.isEmpty) continue;
    for (var i = lower.indexOf(q); i >= 0; i = lower.indexOf(q, i + q.length)) {
      ranges.add((i, i + q.length));
    }
  }
  if (ranges.isEmpty) return [TextSpan(text: text)];
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  // gabungkan yang bertumpuk
  final merged = <(int, int)>[];
  for (final r in ranges) {
    if (merged.isNotEmpty && r.$1 <= merged.last.$2) {
      final last = merged.removeLast();
      merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
    } else {
      merged.add(r);
    }
  }
  final spans = <TextSpan>[];
  var at = 0;
  for (final (s, e) in merged) {
    if (s > at) spans.add(TextSpan(text: text.substring(at, s)));
    spans.add(TextSpan(text: text.substring(s, e), style: highlight));
    at = e;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return spans;
}

/// Potongan [text] di sekitar kemunculan pertama salah satu [words], supaya
/// kata yang dicari tetap terlihat walau teksnya dipotong beberapa baris.
String excerptAround(String text, Iterable<String> words, {int before = 70}) {
  final lower = text.toLowerCase();
  var first = -1;
  for (final w in words) {
    final i = lower.indexOf(w.trim().toLowerCase());
    if (i >= 0 && (first < 0 || i < first)) first = i;
  }
  if (first <= before) return text;
  var start = text.lastIndexOf(' ', first - before);
  start = start < 0 ? 0 : start + 1;
  return '…${text.substring(start)}';
}
