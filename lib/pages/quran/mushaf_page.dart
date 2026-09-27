import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'quran_reader_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// Batas ukuran huruf mushaf: dicari yang terbesar agar satu halaman muat;
/// di bawah [_minFont] halaman boleh digulir.
const _minFont = 17.0;
const _lineHeight = 1.95;

/// Qur'an Indonesia: per halaman seperti mushaf cetak (604 halaman, sama
/// dengan pembagian Mushaf Standar Indonesia pojok). Digeser ke kanan untuk
/// halaman berikutnya.
class MushafPage extends StatefulWidget {
  const MushafPage({super.key, this.page = 1, this.ayah});

  final int page;

  /// Ayat global yang disorot saat dibuka.
  final int? ayah;

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  QuranText? _text;
  late int _page = widget.page.clamp(1, totalPages);
  late final _pages = PageController(initialPage: _page - 1);
  late final int _startPage = _page;
  late int? _selected = widget.ayah;
  Timer? _save;

  @override
  void initState() {
    super.initState();
    QuranText.load().then((t) {
      if (mounted) setState(() => _text = t);
    });
    _remember();
  }

  @override
  void dispose() {
    _save?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _remember() {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 600), () {
      final s = AppSettingsScope.read(context);
      s?.setQuranLastPage(_page);
      final text = _text;
      if (text != null) {
        s?.setQuranLastRead(text.ayahsOnPage(_page).first.index);
      }
    });
  }

  void _jumpTo(int page, {int? ayah}) {
    setState(() => _selected = ayah);
    final p = page.clamp(1, totalPages);
    if ((p - _page).abs() > 3) {
      _pages.jumpToPage(p - 1);
    } else {
      _pages.animateToPage(
        p - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _goto() async {
    final text = _text;
    if (text == null) return;
    final t = await showQuranGoto(
      context,
      surah: text.ayahsOnPage(_page).first.surah,
      page: _page,
      pageFirst: true,
    );
    if (t == null) return;
    final index = targetAyahIndex(text, t);
    _jumpTo(text.pageOfAyah(index), ayah: t is AyahTarget ? index : null);
  }

  void _openSurahMode() {
    final text = _text;
    if (text == null) return;
    AppSettingsScope.read(context)?.setQuranMode(mushaf: false);
    final a = text.ayahsOnPage(_page).first;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderPage(surah: a.surah, ayah: a.number),
      ),
    );
  }

  /// Keluar sesudah membaca maju: tawarkan mencatat tilawah sampai akhir
  /// halaman terakhir - hanya bila melewati posisi tracker.
  Future<void> _maybeLog() async {
    final text = _text;
    if (text == null || _page <= _startPage) return;
    final dao = AppDatabaseScope.of(context).quranDao;
    final last = text.ayahsOnPage(_page).last.index;
    final progress = await dao.progress();
    if (last <= progress.lastAyah || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catat bacaan?'),
        content: Text(
          'Catat tilawah hari ini sampai halaman $_page '
          '(${formatAyah(last)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _amber),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Catat'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final loc = UserLocationScope.of(context).location;
    await dao.logReading(
      date: dateKey(calc.todayInZone(calc.timezoneFromLongitude(loc.long))),
      toAyah: last,
    );
  }

  Future<void> _onAyahTap(QuranAyah a) async {
    setState(() => _selected = a.index);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (sheet) => _AyahSheet(
        ayah: a,
        surah: _text!.surah(a.surah),
        onNote: () {
          Navigator.pop(sheet);
          showQuranNoteSheet(
            context,
            dao: AppDatabaseScope.of(context).quranDao,
            surah: a.surah,
            fromAyah: a.number,
          );
        },
        onLog: () async {
          Navigator.pop(sheet);
          final loc = UserLocationScope.of(context).location;
          final messenger = ScaffoldMessenger.of(context);
          await AppDatabaseScope.of(context).quranDao.logReading(
            date: dateKey(
              calc.todayInZone(calc.timezoneFromLongitude(loc.long)),
            ),
            toAyah: a.index,
          );
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Tercatat di tilawah hari ini: sampai ${formatAyah(a.index)}',
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final settings = AppSettingsScope.maybeOf(context);
    final tajweed = settings?.quranTajweed ?? true;
    final maxFont = (settings?.readerSize ?? 28).clamp(22.0, 40.0);
    final first = text?.ayahsOnPage(_page).first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _maybeLog();
        if (mounted) nav.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EBDA),
        body: Column(
          children: [
            SubHeader(
              title: 'Juz ${first?.juz ?? juzOf(1)} | Hlm. $_page',
              subtitle: first == null
                  ? "Qur'an Indonesia"
                  : '${first.surah}. ${surahName(first.surah)}',
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
                        case 'legend':
                          showTajweedLegend(context);
                        case 'bigger':
                          settings?.setReaderSize(maxFont + 2);
                        case 'smaller':
                          settings?.setReaderSize(maxFont - 2);
                        case 'surah':
                          _openSurahMode();
                      }
                    },
                    itemBuilder: (_) => [
                      CheckedPopupMenuItem(
                        value: 'tajweed',
                        checked: tajweed,
                        child: const Text('Warna tajwid'),
                      ),
                      const PopupMenuItem(
                        value: 'legend',
                        child: Text('Keterangan warna tajwid'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'bigger',
                        child: Text('Huruf lebih besar'),
                      ),
                      const PopupMenuItem(
                        value: 'smaller',
                        child: Text('Huruf lebih kecil'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'surah',
                        child: Text('Buka mode per Surah'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: text == null
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pages,
                      // halaman berikutnya di kiri: geser ke kanan untuk maju
                      reverse: true,
                      itemCount: totalPages,
                      onPageChanged: (i) {
                        setState(() => _page = i + 1);
                        _remember();
                      },
                      itemBuilder: (context, i) => _MushafSheet(
                        key: ValueKey(i + 1),
                        text: text,
                        page: i + 1,
                        tajweed: tajweed,
                        maxFont: maxFont,
                        selected: _selected,
                        onTap: _onAyahTap,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu halaman mushaf di dalam bingkai.
class _MushafSheet extends StatefulWidget {
  const _MushafSheet({
    super.key,
    required this.text,
    required this.page,
    required this.tajweed,
    required this.maxFont,
    required this.selected,
    required this.onTap,
  });

  final QuranText text;
  final int page;
  final bool tajweed;
  final double maxFont;
  final int? selected;
  final ValueChanged<QuranAyah> onTap;

  @override
  State<_MushafSheet> createState() => _MushafSheetState();
}

/// Bagian halaman: spanduk surah, basmalah, atau paragraf ayat.
sealed class _Block {
  const _Block();
}

class _BannerBlock extends _Block {
  const _BannerBlock(this.surah);
  final QuranSurah surah;
}

class _BasmalahBlock extends _Block {
  const _BasmalahBlock();
}

class _TextBlock extends _Block {
  _TextBlock(this.ayahs);
  final List<QuranAyah> ayahs;
}

const _bannerHeight = 50.0;
const _gap = 8.0;

class _MushafSheetState extends State<_MushafSheet> {
  late final List<_Block> _blocks = _makeBlocks();
  final _recognizers = <int, TapGestureRecognizer>{};

  // ukuran huruf hasil pencocokan, per ukuran area
  Size? _fitFor;
  double? _fitMax;
  double _font = 24;
  bool _scroll = false;

  List<_Block> _makeBlocks() {
    final blocks = <_Block>[];
    _TextBlock? current;
    for (final a in widget.text.ayahsOnPage(widget.page)) {
      if (a.number == 1) {
        final s = widget.text.surah(a.surah);
        blocks.add(_BannerBlock(s));
        if (s.hasBasmalah) blocks.add(const _BasmalahBlock());
        current = null;
      }
      if (current == null) {
        current = _TextBlock([]);
        blocks.add(current);
      }
      current.ayahs.add(a);
    }
    return blocks;
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _tapFor(QuranAyah a) => _recognizers.putIfAbsent(
    a.index,
    () => TapGestureRecognizer()..onTap = () => widget.onTap(a),
  );

  double _medallion(double font) => font * 1.15;

  TextStyle _style(double font) => TextStyle(
    fontFamily: arabicFont,
    fontSize: font,
    height: _lineHeight,
    color: mushafInk,
  );

  InlineSpan _paragraph(_TextBlock b, double font, {bool live = true}) {
    const highlight = Color(0x33F59E0B);
    return TextSpan(
      style: _style(font),
      children: [
        for (final a in b.ayahs) ...[
          if (widget.tajweed)
            for (final s in tajweedSegments(a.arabic))
              TextSpan(
                text: s.text,
                recognizer: live ? _tapFor(a) : null,
                style: TextStyle(
                  color: s.rule?.color,
                  backgroundColor: widget.selected == a.index
                      ? highlight
                      : null,
                ),
              )
          else
            TextSpan(
              text: a.arabic,
              recognizer: live ? _tapFor(a) : null,
              style: TextStyle(
                backgroundColor: widget.selected == a.index ? highlight : null,
              ),
            ),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: live
                ? GestureDetector(
                    onTap: () => widget.onTap(a),
                    child: AyahMedallion(
                      number: a.number,
                      size: _medallion(font),
                    ),
                  )
                : SizedBox.square(dimension: _medallion(font)),
          ),
          const TextSpan(text: ' '),
        ],
      ],
    );
  }

  /// Tinggi seluruh isi halaman pada ukuran huruf [font].
  double _measure(double font, double width, TextScaler scaler) {
    var h = 0.0;
    for (final b in _blocks) {
      switch (b) {
        case _BannerBlock():
          h += _bannerHeight + _gap;
        case _BasmalahBlock():
          final tp = TextPainter(
            text: TextSpan(
              text: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: _style(font * 0.92),
            ),
            textDirection: TextDirection.rtl,
            textScaler: scaler,
          )..layout(maxWidth: width);
          h += tp.height;
          tp.dispose();
        case _TextBlock():
          final count = b.ayahs.length;
          final m = _medallion(font);
          final tp = TextPainter(
            text: _paragraph(b, font, live: false),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            textScaler: scaler,
          );
          tp.setPlaceholderDimensions(
            List.filled(
              count,
              PlaceholderDimensions(
                size: Size(m, m),
                alignment: PlaceholderAlignment.middle,
              ),
            ),
          );
          tp.layout(maxWidth: width);
          h += tp.height;
          tp.dispose();
      }
    }
    return h;
  }

  void _fit(Size area, TextScaler scaler) {
    if (_fitFor == area && _fitMax == widget.maxFont) return;
    _fitFor = area;
    _fitMax = widget.maxFont;
    if (_measure(widget.maxFont, area.width, scaler) <= area.height) {
      _font = widget.maxFont;
      _scroll = false;
      return;
    }
    if (_measure(_minFont, area.width, scaler) > area.height) {
      _font = _minFont;
      _scroll = true;
      return;
    }
    var lo = _minFont, hi = widget.maxFont;
    for (var i = 0; i < 7; i++) {
      final mid = (lo + hi) / 2;
      if (_measure(mid, area.width, scaler) <= area.height) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    _font = lo;
    _scroll = false;
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.text.ayahsOnPage(widget.page).first;
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: CustomPaint(
        foregroundPainter: const MushafFramePainter(),
        child: Container(
          decoration: BoxDecoration(
            color: mushafPaper,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22785624),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              _PageHead(
                juz: first.juz,
                page: widget.page,
                surah: '${first.surah}. ${surahName(first.surah)}',
              ),
              const SizedBox(height: 6),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    // cadangan 3%: pengukuran TextPainter & tata letak
                    // sebenarnya bisa berbeda sedikit
                    _fit(Size(c.maxWidth, c.maxHeight * 0.97), scaler);
                    final content = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final b in _blocks)
                          switch (b) {
                            _BannerBlock(:final surah) => Padding(
                              padding: const EdgeInsets.only(bottom: _gap),
                              child: SurahBanner(
                                surah: surah,
                                height: _bannerHeight,
                              ),
                            ),
                            _BasmalahBlock() => BasmalahLine(
                              fontSize: _font * 0.92,
                            ),
                            _TextBlock() => Text.rich(
                              _paragraph(b, _font),
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                            ),
                          },
                      ],
                    );
                    if (_scroll) return SingleChildScrollView(child: content);
                    // pengaman terakhir: tidak pernah meluap
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(width: c.maxWidth, child: content),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                arabicNumber(widget.page),
                style: const TextStyle(
                  fontFamily: arabicFont,
                  fontSize: 15,
                  height: 1.2,
                  color: mushafRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHead extends StatelessWidget {
  const _PageHead({required this.juz, required this.page, required this.surah});
  final int juz, page;
  final String surah;

  @override
  Widget build(BuildContext context) {
    Widget pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: mushafGold),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _stone,
        ),
      ),
    );
    return Row(
      children: [
        pill('Juz $juz'),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: pill(surah)),
        ),
      ],
    );
  }
}

class _AyahSheet extends StatelessWidget {
  const _AyahSheet({
    required this.ayah,
    required this.surah,
    required this.onNote,
    required this.onLog,
  });

  final QuranAyah ayah;
  final QuranSurah surah;
  final VoidCallback onNote, onLog;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AyahMedallion(number: ayah.number, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'QS. ${surah.name}: ${ayah.number}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                ),
                Text(
                  'Juz ${ayah.juz} · Hlm ${ayah.page}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ayah.translation,
              style: const TextStyle(fontSize: 14, height: 1.55, color: _stone),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onNote,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Catatan'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onLog,
                  icon: const Icon(Icons.bookmark_added_rounded),
                  label: const Text('Catat bacaan sampai sini'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${ayah.arabic}\n\n${ayah.translation}\n\n'
                            '(QS. ${surah.name}: ${ayah.number})',
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ayat disalin')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Salin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
