import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/hadits_database.dart';
import '../services/global_search.dart';
import '../services/quran_text.dart';
import '../widgets/highlight_text.dart';
import '../widgets/sub_header.dart';
import 'asmaul_husna_page.dart';
import 'doa_page.dart';
import 'hadits_page.dart';
import 'quran/quran_reader_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _teal = Color(0xFF0F766E);

const _recentKey = 'search_recent';
const _recentMax = 8;

/// Cari di Al-Qur'an, hadits, do'a & Asmaul Husna sekaligus; hasil
/// dikelompokkan per sumber dan ketuk membuka tempat aslinya.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({
    super.key,
    this.quran,
    this.doa,
    this.hadits,
    this.initialQuery = '',
  });

  /// Pengganti untuk uji (bawaan: dimuat dari aset / basis data aplikasi).
  final Future<QuranText>? quran;
  final Future<List<Doa>>? doa;
  final HaditsDatabase? hadits;
  final String initialQuery;

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  late final _query = TextEditingController(text: widget.initialQuery);
  late final Future<QuranText> _quran = widget.quran ?? QuranText.load();
  late final Future<List<Doa>> _doa = widget.doa ?? Doa.load();
  Timer? _debounce;
  int _generation = 0;
  GlobalSearchResult? _result;
  bool _loading = false;
  String? _error;
  List<String> _recent = const [];
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _loadRecent();
    if (widget.initialQuery.isNotEmpty) _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _recent = p.getStringList(_recentKey) ?? const []);
      }
    } catch (_) {}
  }

  Future<void> _remember(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    final next = [t, ..._recent.where((r) => r != t)].take(_recentMax).toList();
    setState(() => _recent = next);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_recentKey, next);
    } catch (_) {}
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = const []);
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_recentKey);
    } catch (_) {}
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _run);
    setState(() {});
  }

  Future<void> _run() async {
    final q = _query.text;
    final gen = ++_generation;
    if (!searchable(q)) {
      setState(() {
        _result = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await globalSearch(
        q,
        quran: await _quran,
        doa: await _doa,
        hadits: widget.hadits ?? HaditsDatabase.instance,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _result = r;
        _loading = false;
        _error = null;
        _expanded.clear();
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _loading = false;
        _error = 'Pencarian gagal: $e';
      });
    }
  }

  void _go(Widget page) {
    _remember(_query.text);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(
            title: 'Cari',
            subtitle: "Al-Qur'an, hadits, do'a & Asmaul Husna",
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  controller: _query,
                  autofocus: widget.initialQuery.isEmpty,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    _run();
                    _remember(v);
                  },
                  decoration: InputDecoration(
                    hintText: 'Kata kunci, atau rujukan seperti 2:255',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: q.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _query.clear();
                              _run();
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _line),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final r = _result;
    final pad = EdgeInsets.fromLTRB(
      16,
      8,
      16,
      24 + MediaQuery.paddingOf(context).bottom,
    );
    Widget wrap(List<Widget> children) => ListView(
      padding: pad,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );

    if (_error != null) {
      return wrap([
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xFFB91C1C)),
          ),
        ),
      ]);
    }
    if (r == null) {
      return wrap([
        if (_recent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              "Ketik kata kunci untuk mencari di Al-Qur'an, hadits, do'a, dan "
              'Asmaul Husna. Contoh: sabar, niat, 2:255, rahman.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
          )
        else ...[
          Row(
            children: [
              const Expanded(child: _Heading('PENCARIAN TERAKHIR')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _amber),
                onPressed: _clearRecent,
                child: const Text('Hapus'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final s in _recent)
                ActionChip(
                  label: Text(s),
                  onPressed: () {
                    _query.text = s;
                    _query.selection = TextSelection.collapsed(
                      offset: s.length,
                    );
                    _run();
                  },
                ),
            ],
          ),
        ],
      ]);
    }
    if (r.isEmpty && r.haditsAvailable) {
      return wrap([
        Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _loading
                ? 'Mencari…'
                : 'Tidak ada hasil untuk "${_query.text.trim()}".',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ),
      ]);
    }
    final terms = searchTerms(_query.text);
    return wrap([
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      if (r.surahs.isNotEmpty)
        _Section(
          id: 'surah',
          title: 'Surah',
          icon: Icons.menu_book_rounded,
          count: r.surahs.length,
          expanded: _expanded,
          onToggle: () => setState(() {}),
          children: [
            for (final s in r.surahs)
              _Hit(
                title: 'Surah ${s.name}',
                trailing: s.arabic,
                body: '${s.meaning} · ${s.ayahCount} ayat',
                onTap: () => _go(QuranReaderPage(surah: s.number)),
              ),
          ],
        ),
      if (r.ayat.isNotEmpty)
        _Section(
          id: 'quran',
          title: "Al-Qur'an",
          icon: Icons.auto_stories_rounded,
          count: r.ayat.length,
          expanded: _expanded,
          onToggle: () => setState(() {}),
          children: [
            for (final h in r.ayat)
              _Hit(
                title: 'QS. ${h.surah.name}: ${h.ayah.number}',
                body: h.ayah.translation,
                words: r.words,
                onTap: () => _go(
                  QuranReaderPage(surah: h.surah.number, ayah: h.ayah.number),
                ),
              ),
          ],
        ),
      if (!r.haditsAvailable)
        _NoHadits(onTap: () => _go(const HaditsPage()))
      else if (r.hadits.isNotEmpty)
        _Section(
          id: 'hadits',
          title: 'Hadits',
          icon: Icons.format_quote_rounded,
          count: r.hadits.length,
          total: r.haditsTotal,
          expanded: _expanded,
          onToggle: () => setState(() {}),
          children: [
            for (final h in r.hadits)
              _Hit(
                title: '${h.bookName} · No. ${h.number}',
                body: h.translation,
                words: terms,
                onTap: () =>
                    _go(HadithDetailPage(book: h.book, number: h.number)),
              ),
          ],
        ),
      if (r.doa.isNotEmpty)
        _Section(
          id: 'doa',
          title: "Do'a",
          icon: Icons.volunteer_activism_rounded,
          count: r.doa.length,
          expanded: _expanded,
          onToggle: () => setState(() {}),
          children: [
            for (final d in r.doa)
              _Hit(
                title: d.doa.title,
                body: d.excerpt,
                words: terms,
                onTap: () => _go(DoaPage(initialQuery: _query.text.trim())),
              ),
          ],
        ),
      if (r.asmaulHusna.isNotEmpty)
        _Section(
          id: 'asma',
          title: 'Asmaul Husna',
          icon: Icons.star_rounded,
          count: r.asmaulHusna.length,
          expanded: _expanded,
          onToggle: () => setState(() {}),
          children: [
            for (final a in r.asmaulHusna)
              _Hit(
                title: '${a.number}. ${a.latin}',
                trailing: a.arabic,
                body: a.arti,
                onTap: () => _go(AsmaulHusnaDetailPage(initial: a.number - 1)),
              ),
          ],
        ),
    ]);
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 8, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: _muted,
      ),
    ),
  );
}

/// Satu kelompok hasil: lima teratas, "Lihat semua" memperluas.
class _Section extends StatelessWidget {
  const _Section({
    required this.id,
    required this.title,
    required this.icon,
    required this.count,
    required this.children,
    required this.expanded,
    required this.onToggle,
    this.total,
  });

  static const _preview = 5;

  final String id, title;
  final IconData icon;
  final int count;

  /// Seluruh yang cocok bila lebih banyak dari [count] yang dimuat.
  final int? total;
  final List<Widget> children;
  final Set<String> expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final open = expanded.contains(id);
    final shown = open ? children : children.take(_preview).toList();
    final all = total ?? count;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _teal),
                const SizedBox(width: 6),
                Text(
                  '$title · $all',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                for (final (i, c) in shown.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: _line),
                  c,
                ],
              ],
            ),
          ),
          if (children.length > _preview)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _amber),
              onPressed: () {
                open ? expanded.remove(id) : expanded.add(id);
                onToggle();
              },
              child: Text(
                open
                    ? 'Tampilkan lebih sedikit'
                    : 'Lihat semua (${children.length}'
                          '${all > children.length ? ' dari $all' : ''})',
              ),
            ),
        ],
      ),
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({
    required this.title,
    required this.body,
    required this.onTap,
    this.words = const [],
    this.trailing,
  });

  final String title, body;
  final String? trailing;
  final List<String> words;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: _muted,
                    ),
                    children: highlightSpans(excerptAround(body, words), words),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing!,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 22, color: _teal),
            ),
          ],
        ],
      ),
    ),
  );
}

class _NoHadits extends StatelessWidget {
  const _NoHadits({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.download_rounded, color: _amber),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Kitab hadits belum diunduh, jadi belum ikut dicari. Unduh '
              'kitabnya dari menu Hadits.',
              style: TextStyle(fontSize: 12.5, color: _stone, height: 1.4),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _amber),
            onPressed: onTap,
            child: const Text('Buka'),
          ),
        ],
      ),
    ),
  );
}
