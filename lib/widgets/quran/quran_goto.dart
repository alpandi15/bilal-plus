import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Dialog "Pergi ke": tab Ayat (surah + nomor ayat) atau Halaman (1-604).
Future<QuranTarget?> showQuranGoto(
  BuildContext context, {
  required int surah,
  required int page,
  bool pageFirst = false,
}) => showDialog<QuranTarget>(
  context: context,
  builder: (_) => _GotoDialog(surah: surah, page: page, pageFirst: pageFirst),
);

class _GotoDialog extends StatefulWidget {
  const _GotoDialog({
    required this.surah,
    required this.page,
    required this.pageFirst,
  });
  final int surah, page;
  final bool pageFirst;

  @override
  State<_GotoDialog> createState() => _GotoDialogState();
}

class _GotoDialogState extends State<_GotoDialog> {
  late bool _byPage = widget.pageFirst;
  late int _surah = widget.surah;
  final _ayah = TextEditingController(text: '1');
  late final _page = TextEditingController(text: '${widget.page}');
  String? _error;

  @override
  void dispose() {
    _ayah.dispose();
    _page.dispose();
    super.dispose();
  }

  void _submit() {
    if (_byPage) {
      final p = int.tryParse(_page.text);
      if (p == null || p < 1 || p > totalPages) {
        setState(() => _error = 'Halaman 1–$totalPages');
        return;
      }
      Navigator.pop(context, PageTarget(p));
    } else {
      final count = ayahCount(_surah);
      final a = int.tryParse(_ayah.text);
      if (a == null || a < 1 || a > count) {
        setState(() => _error = '${surahName(_surah)}: ayat 1–$count');
        return;
      }
      Navigator.pop(context, AyahTarget(_surah, a));
    }
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _amber : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _muted,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFAF3),
      title: const Text(
        'Pergi ke',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800, color: _stone),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E4CF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  _tab('Ayat', !_byPage, () {
                    setState(() {
                      _byPage = false;
                      _error = null;
                    });
                  }),
                  _tab('Halaman', _byPage, () {
                    setState(() {
                      _byPage = true;
                      _error = null;
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_byPage)
              TextField(
                controller: _page,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Halaman mushaf',
                  helperText: '1–$totalPages · Juz 1 = hlm 1–21',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: _surah,
                      isExpanded: true,
                      menuMaxHeight: 360,
                      decoration: InputDecoration(
                        labelText: 'Surah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: [
                        for (var s = 1; s <= 114; s++)
                          DropdownMenuItem(
                            value: s,
                            child: Text(
                              '$s. ${surahNames[s - 1]}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _surah = v ?? _surah;
                        _ayah.text = '1';
                        _error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _ayah,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Ayat',
                        helperText: '1–${ayahCount(_surah)}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _stone,
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: _line),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _amber,
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: _submit,
                child: const Text('Buka'),
              ),
            ),
          ],
        ),
      ],
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
