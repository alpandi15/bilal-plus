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
import '../../widgets/quran/quran_goto.dart';
import '../../widgets/quran/quran_note_sheet.dart';
import '../../widgets/quran/quran_ornaments.dart';
import '../../widgets/sub_header.dart';
import 'mushaf_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Pembaca Al-Qur'an per surah: tab nama surah yang bisa digeser (kanan ke
/// kiri seperti mushaf), teks Mushaf Standar Indonesia (warna tajwid bisa
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

/// Permintaan lompat ke ayat; [token] berubah tiap permintaan baru.
typedef _Jump = ({int surah, int ayah, int token});

class _QuranReaderPageState extends State<QuranReaderPage>
    with SingleTickerProviderStateMixin {
  QuranText? _text;
  late final _tabs = TabController(
    length: 114,
    vsync: this,
    initialIndex: widget.surah - 1,
  );
  late int _surah = widget.surah;
  late _Jump? _jump = widget.ayah == null
      ? null
      : (surah: widget.surah, ayah: widget.ayah!, token: 0);

  /// Ayat global teratas yang terlihat di surah yang sedang dibuka.
  late int _visible = ayahIndex(widget.surah, widget.ayah ?? 1);
  Timer? _saveLast;

  @override
  void initState() {
    super.initState();
    QuranText.load().then((t) {
      if (mounted) setState(() => _text = t);
    });
    _tabs.addListener(() {
      final s = _tabs.index + 1;
      if (s == _surah) return;
      setState(() {
        _surah = s;
        _visible = ayahIndex(s, _jump?.surah == s ? _jump!.ayah : 1);
      });
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _saveLast?.cancel();
    super.dispose();
  }

  void _onVisible(int surah, int index) {
    if (surah != _surah) return;
    if (index != _visible) setState(() => _visible = index);
    _saveLast?.cancel();
    _saveLast = Timer(const Duration(milliseconds: 800), () {
      AppSettingsScope.read(context)?.setQuranLastRead(index);
    });
  }

  void _go(int surah, int ayah) {
    setState(() {
      _jump = (surah: surah, ayah: ayah, token: (_jump?.token ?? 0) + 1);
      if (surah == _surah) _visible = ayahIndex(surah, ayah);
    });
    if (surah != _surah) _tabs.animateTo(surah - 1);
  }

  Future<void> _goto() async {
    final text = _text;
    if (text == null) return;
    final t = await showQuranGoto(
      context,
      surah: _surah,
      page: text.pageOfAyah(_visible),
      text: text,
    );
    if (t == null) return;
    final (s, a) = surahAyahOf(targetAyahIndex(text, t));
    _go(s, a);
  }

  void _openMushaf() {
    final text = _text;
    if (text == null) return;
    AppSettingsScope.read(context)?.setQuranMode(mushaf: true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MushafPage(page: text.pageOfAyah(_visible)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final settings = AppSettingsScope.maybeOf(context);
    final tajweed = settings?.quranTajweed ?? true;
    final showArti = settings?.showArti ?? true;
    final size = settings?.readerSize ?? 28;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: text == null
                ? '$_surah. ${surahName(_surah)}'
                : 'Juz ${juzOf(_visible)} | Hlm. ${text.pageOfAyah(_visible)}',
            subtitle:
                '$_surah. ${surahName(_surah)} · ${ayahCount(_surah)} ayat',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Pergi ke',
                  onPressed: _goto,
                  icon: const Icon(
                    Icons.move_down_rounded,
                    color: Color(0xFF92400E),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tampilan',
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF92400E),
                  ),
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
                      case 'mushaf':
                        _openMushaf();
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
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'mushaf',
                      child: Text('Buka mode Mushaf'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // tab & halaman kanan-ke-kiri: surah berikutnya ada di kiri
          Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              color: const Color(0xFFFFFBF3),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _amber,
                unselectedLabelColor: _muted,
                indicatorColor: _amber,
                indicatorWeight: 3,
                dividerColor: _line,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  for (var s = 1; s <= 114; s++)
                    Tab(
                      // label Latin tetap kiri-ke-kanan walau baris tab RTL
                      child: Text(
                        '$s. ${surahName(s)}',
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: text == null
                ? const Center(child: CircularProgressIndicator())
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        for (var s = 1; s <= 114; s++)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: _SurahView(
                              key: ValueKey(s),
                              text: text,
                              surah: s,
                              jump: _jump?.surah == s ? _jump : null,
                              tajweed: tajweed,
                              showArti: showArti,
                              size: size,
                              onVisible: (i) => _onVisible(s, i),
                              onOpenSurah: (n) => _tabs.animateTo(n - 1),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Isi satu surah: spanduk, basmalah, lalu ayat-ayatnya.
class _SurahView extends StatefulWidget {
  const _SurahView({
    super.key,
    required this.text,
    required this.surah,
    required this.jump,
    required this.tajweed,
    required this.showArti,
    required this.size,
    required this.onVisible,
    required this.onOpenSurah,
  });

  final QuranText text;
  final int surah;
  final _Jump? jump;
  final bool tajweed, showArti;
  final double size;
  final ValueChanged<int> onVisible;
  final ValueChanged<int> onOpenSurah;

  @override
  State<_SurahView> createState() => _SurahViewState();
}

class _SurahViewState extends State<_SurahView> {
  final _items = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  late int? _focus = widget.jump?.ayah;
  Stream<List<QuranNote>>? _notes;

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_SurahView old) {
    super.didUpdateWidget(old);
    final j = widget.jump;
    if (j != null && j.token != old.jump?.token) {
      setState(() => _focus = j.ayah);
      if (_items.isAttached) {
        _items.scrollTo(
          index: j.ayah,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  // ayat teratas yang terlihat -> kepala halaman & posisi terakhir dibaca
  void _onScroll() {
    final visible = _positions.itemPositions.value.where(
      (p) => p.itemTrailingEdge > 0.05,
    );
    if (visible.isEmpty) return;
    // ayat yang tepi atasnya paling dekat ke atas layar (bukan yang hanya
    // tersisa ujungnya)
    final top = visible.reduce(
      (a, b) => a.itemLeadingEdge.abs() <= b.itemLeadingEdge.abs() ? a : b,
    );
    final ayah = top.index.clamp(1, ayahCount(widget.surah));
    widget.onVisible(ayahIndex(widget.surah, ayah));
  }

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
    final dao = AppDatabaseScope.of(context).quranDao;
    final surah = widget.text.surah(widget.surah);
    final ayahs = widget.text.ayahsOf(widget.surah);
    _notes ??= dao.watchNotesBetween(
      ayahIndex(widget.surah, 1),
      ayahIndex(widget.surah, surah.ayahCount),
    );
    return StreamBuilder<List<QuranNote>>(
      stream: _notes,
      builder: (context, snap) {
        final notes = snap.data ?? const <QuranNote>[];
        return ScrollablePositionedList.builder(
          itemScrollController: _items,
          itemPositionsListener: _positions,
          initialScrollIndex: (widget.jump?.ayah ?? 0).clamp(
            0,
            surah.ayahCount,
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
              return _SurahNav(surah: widget.surah, onOpen: widget.onOpenSurah);
            }
            final a = ayahs[i - 1];
            return _AyahTile(
              ayah: a,
              tajweed: widget.tajweed,
              showArti: widget.showArti,
              size: widget.size,
              focused: _focus == a.number,
              notes: [
                for (final n in notes)
                  if (n.toAyah == a.index ||
                      (a.number == surah.ayahCount && n.toAyah > a.index))
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurahBanner(surah: surah),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '${surah.meaning} · '
                  '${surah.makkiyah ? 'Makkiyah' : 'Madaniyah'} · '
                  '${surah.ayahCount} ayat',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
              if (surah.description.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _amber,
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
                  child: const Text('Tentang surah'),
                ),
            ],
          ),
          if (surah.hasBasmalah)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: BasmalahLine(fontSize: 26),
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
              AyahMedallion(number: ayah.number, size: 38, arabicDigits: false),
              const SizedBox(width: 8),
              Text(
                'Juz ${ayah.juz} · Hal ${ayah.page}',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              // tanda 'ain: ayat terakhir ruku' (ketuk untuk keterangan)
              if (ayah.ruku case final r?) ...[
                const SizedBox(width: 8),
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 4),
                  message: rukuLabel(r, surahName(ayah.surah), ayah.juz),
                  child: RukuSign(mark: r, size: 38),
                ),
              ],
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

/// Pindah surah di akhir bacaan - seperti mushaf: berikutnya di kiri.
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
          if (surah < 114)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _amber,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => onOpen(surah + 1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(
                  surahName(surah + 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (surah > 1 && surah < 114) const SizedBox(width: 10),
          if (surah > 1)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _amber,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => onOpen(surah - 1),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(
                  surahName(surah - 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
