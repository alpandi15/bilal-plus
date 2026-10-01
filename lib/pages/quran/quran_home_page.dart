import 'package:flutter/material.dart';

import '../../data/quran_meta.dart';
import '../../services/app_settings.dart';
import '../../services/quran_index.dart';
import '../../services/quran_text.dart';
import '../../widgets/arabic_font.dart';
import '../../widgets/quran/quran_note_sheet.dart';
import '../../widgets/sub_header.dart';
import '../../widgets/highlight_text.dart';
import 'quran_notes_page.dart';
import 'mushaf_page.dart';
import 'quran_reader_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

/// Al-Qur'an: daftar surah & juz, pencarian (nama surah, kata di
/// terjemahan, atau "2:255"), lanjutkan membaca, dan catatan pribadi.
class QuranHomePage extends StatefulWidget {
  const QuranHomePage({super.key});

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  QuranText? _text;
  final _query = TextEditingController();
  bool _byJuz = false;

  @override
  void initState() {
    super.initState();
    QuranText.load().then((t) {
      if (mounted) setState(() => _text = t);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(int surah, [int? ayah]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderPage(surah: surah, ayah: ayah),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final q = _query.text.trim();
    final lastRead = AppSettingsScope.maybeOf(context)?.quranLastRead;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: "Al-Qur'an",
            subtitle: 'Mushaf Standar Indonesia · terjemahan Kemenag',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Mode Mushaf',
                  onPressed: () {
                    final s = AppSettingsScope.read(context);
                    s?.setQuranMode(mushaf: true);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => MushafPage(
                          page: s?.quranLastPage ?? 1,
                          bookmark: s?.quranLastPage != null,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF92400E),
                  ),
                ),
                IconButton(
                  tooltip: 'Keterangan warna tajwid',
                  onPressed: () => showTajweedLegend(context),
                  icon: const Icon(
                    Icons.palette_outlined,
                    color: Color(0xFF92400E),
                  ),
                ),
                IconButton(
                  tooltip: "Catatan Qur'an",
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QuranNotesPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.sticky_note_2_outlined,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari surah, kata, atau 2:255',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus',
                        onPressed: () => setState(_query.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          Expanded(
            child: text == null
                ? const Center(child: CircularProgressIndicator())
                : q.isNotEmpty
                ? _SearchResults(text: text, query: q, onOpen: _open)
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      6,
                      16,
                      32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      if (lastRead != null)
                        _ContinueCard(
                          index: lastRead,
                          onTap: () {
                            final (s, a) = surahAyahOf(lastRead);
                            _open(s, a);
                          },
                        ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Surah')),
                          ButtonSegment(value: true, label: Text('Juz')),
                        ],
                        selected: {_byJuz},
                        showSelectedIcon: false,
                        onSelectionChanged: (v) =>
                            setState(() => _byJuz = v.first),
                      ),
                      const SizedBox(height: 12),
                      if (_byJuz)
                        for (var j = 1; j <= totalJuz; j++)
                          _JuzTile(juz: j, onOpen: _open)
                      else
                        for (final s in text.surahs)
                          _SurahTile(surah: s, onTap: () => _open(s.number)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.index, required this.onTap});
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFFF2D38A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lanjutkan membaca',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                      Text(
                        '${formatAyah(index)} · Juz ${juzOf(index)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFF2D38A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});
  final QuranSurah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                _NumberBadge(surah.number),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _stone,
                        ),
                      ),
                      Text(
                        '${surah.meaning} · '
                        '${surah.makkiyah ? 'Makkiyah' : 'Madaniyah'} · '
                        '${surah.ayahCount} ayat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _muted),
                      ),
                    ],
                  ),
                ),
                ArabicText(
                  surah.arabic,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.4,
                    color: _emerald,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.number);
  final int number;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.785398,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFF6D9A6)),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: -0.785398,
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _amber,
          ),
        ),
      ),
    ),
  );
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.juz, required this.onOpen});
  final int juz;
  final void Function(int surah, [int? ayah]) onOpen;

  @override
  Widget build(BuildContext context) {
    final (s, a) = juzStarts[juz - 1];
    final parts = surahsInJuz(juz);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpen(s, a),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                _NumberBadge(juz),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juz $juz',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _stone,
                        ),
                      ),
                      Text(
                        'Mulai ${surahName(s)} $a · '
                        '${parts.length} surah',
                        style: const TextStyle(fontSize: 11.5, color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.text,
    required this.query,
    required this.onOpen,
  });

  final QuranText text;
  final String query;
  final void Function(int surah, [int? ayah]) onOpen;

  @override
  Widget build(BuildContext context) {
    final surahs = text.findSurah(query);
    final hits = query.length < 3 && !query.contains(RegExp(r'\d'))
        ? const <QuranSearchHit>[]
        : text.search(query, limit: 100);
    final words = QuranText.searchWords(query);
    if (surahs.isEmpty && hits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Tidak ditemukan. Coba kata lain di terjemahan, nama surah, '
            'atau format surah:ayat seperti 2:255.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        6,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        for (final s in surahs.take(10))
          _SurahTile(surah: s, onTap: () => onOpen(s.number)),
        if (hits.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Text(
              hits.length >= 100
                  ? 'AYAT · 100 TERATAS'
                  : 'AYAT · ${hits.length} HASIL',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xCCB45309),
              ),
            ),
          ),
          for (final h in hits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onOpen(h.surah.number, h.ayah.number),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QS. ${h.surah.name}: ${h.ayah.number}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _emerald,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // potongan di sekitar kata yang dicari, disorot
                        Text.rich(
                          TextSpan(
                            children: highlightSpans(
                              excerptAround(h.ayah.translation, words),
                              words,
                            ),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: _stone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
