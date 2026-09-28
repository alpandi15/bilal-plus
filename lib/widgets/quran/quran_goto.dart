import 'package:flutter/material.dart';

import '../../data/quran_meta.dart';
import '../../services/app_settings.dart';
import '../../services/quran_index.dart';
import '../../services/quran_text.dart';
import '../../pages/quran/mushaf_page.dart';
import '../../pages/quran/quran_home_page.dart';
import '../../pages/quran/quran_reader_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Tujuan "Pergi ke": ayat global (mode ayat) atau halaman mushaf.
sealed class QuranTarget {
  const QuranTarget();
}

class AyahTarget extends QuranTarget {
  const AyahTarget(this.surah, this.ayah);
  final int surah, ayah;
}

class PageTarget extends QuranTarget {
  const PageTarget(this.page);
  final int page;
}

/// Lembar "Pergi ke": tab Surah (cari surah, lalu pilih ayat), Halaman
/// (1-604, dengan pratinjau isi halaman), dan Juz.
Future<QuranTarget?> showQuranGoto(
  BuildContext context, {
  required int surah,
  required int page,
  bool pageFirst = false,
  QuranText? text,
}) => showModalBottomSheet<QuranTarget>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (_) =>
      _GotoSheet(surah: surah, page: page, pageFirst: pageFirst, text: text),
);

enum _GotoTab { surah, page, juz }

class _GotoSheet extends StatefulWidget {
  const _GotoSheet({
    required this.surah,
    required this.page,
    required this.pageFirst,
    this.text,
  });
  final int surah, page;
  final bool pageFirst;
  final QuranText? text;

  @override
  State<_GotoSheet> createState() => _GotoSheetState();
}

class _GotoSheetState extends State<_GotoSheet> {
  late _GotoTab _tab = widget.pageFirst ? _GotoTab.page : _GotoTab.surah;

  /// Surah yang sedang dipilih ayatnya (null = daftar surah).
  int? _pickAyahOf;
  final _query = TextEditingController();
  late double _page = widget.page.toDouble();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<int> get _surahs {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return [for (var s = 1; s <= 114; s++) s];
    final plain = q.replaceAll(RegExp(r"[-'\s.]"), '');
    return [
      for (var s = 1; s <= 114; s++)
        if ('$s' == q ||
            '$s'.startsWith(q) && RegExp(r'^\d+$').hasMatch(q) ||
            surahNames[s - 1]
                .toLowerCase()
                .replaceAll(RegExp(r"[-'\s]"), '')
                .contains(plain) ||
            (widget.text?.surah(s).meaning.toLowerCase().contains(q) ?? false))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: height * 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pergi ke',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: _muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<_GotoTab>(
              segments: const [
                ButtonSegment(
                  value: _GotoTab.surah,
                  icon: Icon(Icons.format_list_numbered_rounded, size: 18),
                  label: Text('Surah'),
                ),
                ButtonSegment(
                  value: _GotoTab.page,
                  icon: Icon(Icons.auto_stories_outlined, size: 18),
                  label: Text('Halaman'),
                ),
                ButtonSegment(
                  value: _GotoTab.juz,
                  icon: Icon(Icons.grid_view_rounded, size: 18),
                  label: Text('Juz'),
                ),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() {
                _tab = v.first;
                _pickAyahOf = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (_tab) {
              _GotoTab.surah =>
                _pickAyahOf == null ? _surahList() : _ayahGrid(_pickAyahOf!),
              _GotoTab.page => _pagePicker(),
              _GotoTab.juz => _juzGrid(),
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- surah

  Widget _surahList() {
    final list = _surahs;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari surah: nama, arti, atau nomor',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.text.isEmpty
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
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text(
                    'Surah tidak ditemukan',
                    style: TextStyle(color: _muted),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    16 +
                        MediaQuery.viewInsetsOf(context).bottom +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final selected = s == widget.surah;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: selected ? const Color(0xFFFFF1D6) : null,
                      leading: CircleAvatar(
                        radius: 17,
                        backgroundColor: selected
                            ? _amber
                            : const Color(0xFFFFF1D6),
                        child: Text(
                          '$s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : _amber,
                          ),
                        ),
                      ),
                      title: Text(
                        surahNames[s - 1],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                      subtitle: Text(
                        [
                          ?widget.text?.surah(s).meaning,
                          '${ayahCount(s)} ayat',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: _muted,
                      ),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _pickAyahOf = s);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _ayahGrid(int s) {
    final count = ayahCount(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Kembali ke daftar surah',
                onPressed: () => setState(() => _pickAyahOf = null),
                icon: const Icon(Icons.arrow_back_rounded, color: _stone),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$s. ${surahNames[s - 1]}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    Text(
                      'Pilih ayat · $count ayat',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _amber),
                onPressed: () => Navigator.pop(context, AyahTarget(s, 1)),
                child: const Text('Awal surah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 64,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: count,
            itemBuilder: (context, i) => Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(context, AyahTarget(s, i + 1)),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- page

  Widget _pagePicker() {
    final page = _page.round();
    final ayahs = widget.text?.ayahsOnPage(page);
    String? preview;
    if (ayahs != null) {
      final a = ayahs.first, z = ayahs.last;
      preview = a.surah == z.surah
          ? '${surahNames[a.surah - 1]} ${a.number}–${z.number}'
          : '${surahNames[a.surah - 1]} ${a.number} – '
                '${surahNames[z.surah - 1]} ${z.number}';
    }
    Widget step(IconData icon, String tip, int delta) => IconButton.filledTonal(
      tooltip: tip,
      onPressed: () => setState(
        () => _page = (page + delta).clamp(1, totalPages).toDouble(),
      ),
      icon: Icon(icon),
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  step(Icons.remove_rounded, 'Halaman sebelumnya', -1),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$page',
                          style: const TextStyle(
                            fontSize: 44,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Juz ${juzOf(ayahs?.first.index ?? pageRange(page).$1)}'
                          ' · dari $totalPages',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  step(Icons.add_rounded, 'Halaman berikutnya', 1),
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 10),
                Text(
                  preview,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2D38A),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _page,
          min: 1,
          max: totalPages.toDouble(),
          divisions: totalPages - 1,
          activeColor: _amber,
          label: '$page',
          onChanged: (v) => setState(() => _page = v),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _amber,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () => Navigator.pop(context, PageTarget(page)),
          icon: const Icon(Icons.menu_book_rounded),
          label: Text('Buka halaman $page'),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ juz

  Widget _juzGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: totalJuz,
      itemBuilder: (context, i) {
        final (s, a) = juzStarts[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(context, AyahTarget(s, a)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Juz ${i + 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _amber,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surahNames[s - 1]} $a',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Buka Al-Qur'an pada mode terakhir yang dipakai, di posisi terakhir.
Future<void> continueQuran(BuildContext context) async {
  final settings = AppSettingsScope.read(context);
  final nav = Navigator.of(context);
  if (settings?.quranMushaf ?? false) {
    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) => MushafPage(page: settings?.quranLastPage ?? 1),
      ),
    );
    return;
  }
  final last = settings?.quranLastRead;
  if (last == null) {
    await nav.push(
      MaterialPageRoute<void>(builder: (_) => const QuranHomePage()),
    );
    return;
  }
  final (s, a) = surahAyahOf(last);
  await nav.push(
    MaterialPageRoute<void>(
      builder: (_) => QuranReaderPage(surah: s, ayah: a),
    ),
  );
}

/// Pilih cara membaca: per surah (dengan terjemahan) atau Mushaf Indonesia
/// (per halaman).
Future<void> showQuranModeSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (sheet) {
    final settings = AppSettingsScope.read(context);
    final lastRead = settings?.quranLastRead;
    final lastPage = settings?.quranLastPage;
    void open(Widget page) {
      Navigator.pop(sheet);
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Baca Al-Qur'an",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.format_list_bulleted_rounded,
              colors: const [Color(0xFF00503C), Color(0xFF0C3A33)],
              title: "Al-Qur'an per Surah",
              detail: 'Ayat demi ayat dengan terjemahan, tajwid & catatan',
              last: lastRead == null
                  ? null
                  : 'Terakhir: ${formatAyah(lastRead)}',
              onTap: () {
                settings?.setQuranMode(mushaf: false);
                open(const QuranHomePage());
              },
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.menu_book_rounded,
              colors: const [Color(0xFFD9485F), Color(0xFF9F1239)],
              title: "Qur'an Indonesia (Mushaf)",
              detail: 'Per halaman seperti mushaf cetak · 604 halaman',
              last: lastPage == null ? null : 'Terakhir: halaman $lastPage',
              onTap: () {
                settings?.setQuranMode(mushaf: true);
                open(MushafPage(page: lastPage ?? 1));
              },
            ),
          ],
        ),
      ),
    );
  },
);

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.colors,
    required this.title,
    required this.detail,
    required this.onTap,
    this.last,
  });

  final IconData icon;
  final List<Color> colors;
  final String title, detail;
  final String? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                  if (last != null)
                    Text(
                      last!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _amber,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

/// Ayat global pertama untuk tujuan [t].
int targetAyahIndex(QuranText text, QuranTarget t) => switch (t) {
  AyahTarget(:final surah, :final ayah) => ayahIndex(surah, ayah),
  PageTarget(:final page) => text.ayahsOnPage(page).first.index,
};
