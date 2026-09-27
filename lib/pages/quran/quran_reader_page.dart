import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../db/app_database.dart';
import '../../db/app_database_scope.dart';
import '../../services/app_settings.dart';
import '../../services/prayer_calculator.dart' as calc;
import '../../services/quran_index.dart';
import '../../services/quran_text.dart';
import '../../services/tajweed.dart';
import '../../services/user_location_scope.dart';
import '../../utils/date_key.dart';
import '../../widgets/arabic_font.dart';
import '../../widgets/quran/quran_note_sheet.dart';
import '../../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

/// Pembaca satu surah: teks Mushaf Standar Indonesia (warna tajwid bisa
/// dinyalakan), terjemahan Kemenag, catatan pribadi per rentang ayat, dan
/// "catat bacaan sampai ayat ini" ke tracker tilawah.
class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key, required this.surah, this.ayah});

  final int surah;

  /// Ayat yang langsung dituju & disorot (null = awal surah).
  final int? ayah;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  QuranText? _text;
  final _items = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  Timer? _saveLast;
  late int? _focus = widget.ayah;

  @override
  void initState() {
    super.initState();
    QuranText.load().then((t) {
      if (mounted) setState(() => _text = t);
    });
    _positions.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onScroll);
    _saveLast?.cancel();
    super.dispose();
  }

  // posisi terakhir dibaca = ayat teratas yang terlihat (disimpan sesudah
  // gulir berhenti sebentar)
  void _onScroll() {
    final visible = _positions.itemPositions.value.where(
      (p) => p.itemTrailingEdge > 0.15,
    );
    if (visible.isEmpty) return;
    final first = visible.map((p) => p.index).reduce((a, b) => a < b ? a : b);
    final ayah = first.clamp(1, ayahCount(widget.surah));
    _saveLast?.cancel();
    _saveLast = Timer(const Duration(milliseconds: 800), () {
      AppSettingsScope.read(
        context,
      )?.setQuranLastRead(ayahIndex(widget.surah, ayah));
    });
  }

  void _openSurah(int surah) => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => QuranReaderPage(surah: surah)),
  );

  Future<void> _logReading(QuranAyah a) async {
    final loc = UserLocationScope.of(context).location;
    final today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(loc.long)),
    );
    final dao = AppDatabaseScope.of(context).quranDao;
    final messenger = ScaffoldMessenger.of(context);
    await dao.logReading(date: today, toAyah: a.index);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Tercatat di tilawah hari ini: sampai ${formatAyah(a.index)}',
        ),
      ),
    );
  }

  void _copy(QuranAyah a, QuranSurah s) {
    Clipboard.setData(
      ClipboardData(
        text:
            '${a.arabic}\n\n${a.translation}\n\n'
            '(QS. ${s.name}: ${a.number})',
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ayat disalin')));
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final settings = AppSettingsScope.maybeOf(context);
    final tajweed = settings?.quranTajweed ?? true;
    final showArti = settings?.showArti ?? true;
    final size = settings?.readerSize ?? 28;
    final meta = (
      name: surahName(widget.surah),
      count: ayahCount(widget.surah),
    );
    final dao = AppDatabaseScope.of(context).quranDao;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: '${widget.surah}. ${meta.name}',
            subtitle: text == null
                ? '${meta.count} ayat'
                : '${text.surah(widget.surah).makkiyah ? 'Makkiyah' : 'Madaniyah'}'
                      ' · ${meta.count} ayat',
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF92400E)),
              onSelected: (v) {
                switch (v) {
                  case 'tajweed':
                    settings?.setQuranTajweed(!tajweed);
                  case 'arti':
                    settings?.setShowArti(!showArti);
                  case 'bigger':
                    settings?.setReaderSize(size + 2);
                  case 'smaller':
                    settings?.setReaderSize(size - 2);
                  case 'legend':
                    showTajweedLegend(context);
                  case 'jump':
                    _jump();
                }
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'tajweed',
                  checked: tajweed,
                  child: const Text('Warna tajwid'),
                ),
                CheckedPopupMenuItem(
                  value: 'arti',
                  checked: showArti,
                  child: const Text('Tampilkan terjemahan'),
                ),
                const PopupMenuItem(
                  value: 'legend',
                  child: Text('Keterangan warna tajwid'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'bigger',
                  child: Text('Perbesar teks'),
                ),
                const PopupMenuItem(
                  value: 'smaller',
                  child: Text('Perkecil teks'),
                ),
                const PopupMenuItem(value: 'jump', child: Text('Ke ayat…')),
              ],
            ),
          ),
          Expanded(
            child: text == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<QuranNote>>(
                    stream: dao.watchNotesBetween(
                      ayahIndex(widget.surah, 1),
                      ayahIndex(widget.surah, meta.count),
                    ),
                    builder: (context, snap) {
                      final notes = snap.data ?? const <QuranNote>[];
                      final surah = text.surah(widget.surah);
                      final ayahs = text.ayahsOf(widget.surah);
                      return ScrollablePositionedList.builder(
                        itemScrollController: _items,
                        itemPositionsListener: _positions,
                        initialScrollIndex: (widget.ayah ?? 0).clamp(
                          0,
                          meta.count,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: ayahs.length + 2,
                        itemBuilder: (context, i) {
                          if (i == 0) return _SurahHead(surah: surah);
                          if (i == ayahs.length + 1) {
                            return _SurahNav(
                              surah: widget.surah,
                              onOpen: _openSurah,
                            );
                          }
                          final a = ayahs[i - 1];
                          return _AyahTile(
                            ayah: a,
                            tajweed: tajweed,
                            showArti: showArti,
                            size: size,
                            focused: _focus == a.number,
                            notes: [
                              for (final n in notes)
                                if (n.toAyah == a.index ||
                                    (a.number == meta.count &&
                                        n.toAyah > a.index))
                                  n,
                            ],
                            onNote: () => showQuranNoteSheet(
                              context,
                              dao: dao,
                              surah: widget.surah,
                              fromAyah: a.number,
                            ),
                            onOpenNote: (n) => showQuranNoteSheet(
                              context,
                              dao: dao,
                              surah: widget.surah,
                              fromAyah: a.number,
                              note: n,
                            ),
                            onLog: () => _logReading(a),
                            onCopy: () => _copy(a, surah),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _jump() async {
    final count = ayahCount(widget.surah);
    final controller = TextEditingController();
    final ayah = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ke ayat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1–$count'),
          onSubmitted: (v) => Navigator.pop(context, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Buka'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (ayah == null || ayah < 1 || ayah > count) return;
    setState(() => _focus = ayah);
    _items.scrollTo(
      index: ayah,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }
}

class _SurahHead extends StatelessWidget {
  const _SurahHead({required this.surah});
  final QuranSurah surah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33064E3B),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                ArabicText(
                  surah.arabic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.6,
                    color: Color(0xFFF2D38A),
                  ),
                ),
                Text(
                  surah.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${surah.meaning} · '
                  '${surah.makkiyah ? 'Makkiyah' : 'Madaniyah'} · '
                  '${surah.ayahCount} ayat',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                if (surah.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF2D38A),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      backgroundColor: const Color(0xFFFFFAF3),
                      builder: (_) => SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Text(
                            surah.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: _stone,
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Tentang surah ini'),
                  ),
                ],
              ],
            ),
          ),
          if (surah.hasBasmalah)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: ArabicText(
                'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 2,
                  color: Color(0xFF1C1917),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayah,
    required this.tajweed,
    required this.showArti,
    required this.size,
    required this.focused,
    required this.notes,
    required this.onNote,
    required this.onOpenNote,
    required this.onLog,
    required this.onCopy,
  });

  final QuranAyah ayah;
  final bool tajweed, showArti, focused;
  final double size;
  final List<QuranNote> notes;
  final VoidCallback onNote, onLog, onCopy;
  final ValueChanged<QuranNote> onOpenNote;

  @override
  Widget build(BuildContext context) {
    const arabicStyle = TextStyle(height: 2.1, color: Color(0xFF1C1917));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: focused ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: focused ? const Color(0xFFF59E0B) : _line,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 34),
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '${ayah.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _emerald,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Juz ${ayah.juz} · Hal ${ayah.page}',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Catatan ayat ${ayah.number}',
                visualDensity: VisualDensity.compact,
                onPressed: onNote,
                icon: const Icon(
                  Icons.edit_note_rounded,
                  size: 22,
                  color: _amber,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Lainnya',
                icon: const Icon(Icons.more_horiz_rounded, color: _muted),
                onSelected: (v) => switch (v) {
                  'log' => onLog(),
                  'copy' => onCopy(),
                  _ => onNote(),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'log',
                    child: Text('Catat bacaan sampai ayat ini'),
                  ),
                  PopupMenuItem(value: 'note', child: Text('Tambah catatan')),
                  PopupMenuItem(value: 'copy', child: Text('Salin ayat')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (tajweed)
            ArabicText.rich([
              for (final s in tajweedSegments(ayah.arabic))
                (text: s.text, color: s.rule?.color),
            ], style: arabicStyle.copyWith(fontSize: size))
          else
            ArabicText(
              ayah.arabic,
              style: arabicStyle.copyWith(fontSize: size),
            ),
          if (showArti) ...[
            const SizedBox(height: 10),
            Text(
              ayah.translation,
              style: const TextStyle(fontSize: 14, height: 1.55, color: _stone),
            ),
          ],
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Material(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onOpenNote(n),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.sticky_note_2_rounded,
                          size: 18,
                          color: _amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan · ${formatAyahRange(n.fromAyah, n.toAyah)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _amber,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                maxLines: 4,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SurahNav extends StatelessWidget {
  const _SurahNav({required this.surah, required this.onOpen});
  final int surah;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (surah > 1)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _amber,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => onOpen(surah - 1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(
                  surahName(surah - 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (surah > 1 && surah < 114) const SizedBox(width: 10),
          if (surah < 114)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _amber,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => onOpen(surah + 1),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(
                  surahName(surah + 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
