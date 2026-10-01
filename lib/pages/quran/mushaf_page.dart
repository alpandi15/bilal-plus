import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/quran/mushaf_bookmark.dart';
import '../../widgets/quran/quran_ayah_text.dart';
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
  const MushafPage({
    super.key,
    this.page = 1,
    this.ayah,
    this.bookmark = false,
  });

  final int page;

  /// Dibuka melanjutkan bacaan: pembatas tergantung di [page].
  final bool bookmark;

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

  /// Halaman tempat pembatas tergantung; null = sudah dibuka/dilepas.
  late int? _bookmarkPage = widget.bookmark ? _page : null;

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
      text: text,
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
    final font = settings?.quranFont ?? QuranFont.lpmq;
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
        // keyboard (mis. dialog Pergi ke) menimpa halaman - ukuran halaman &
        // huruf tidak dihitung ulang
        resizeToAvoidBottomInset: false,
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
                        case 'bookmark':
                          final on = !(settings?.mushafBookmark ?? true);
                          settings?.setMushafBookmark(on);
                          // dinyalakan: langsung tergantung di halaman ini
                          setState(() => _bookmarkPage = on ? _page : null);
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
                      CheckedPopupMenuItem(
                        value: 'bookmark',
                        checked: settings?.mushafBookmark ?? true,
                        child: const Text('Pembatas halaman'),
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
                      itemBuilder: (context, i) {
                        final sheet = _MushafSheet(
                          key: ValueKey(i + 1),
                          text: text,
                          page: i + 1,
                          tajweed: tajweed,
                          font: font,
                          maxFont: maxFont,
                          selected: _selected,
                          onTap: _onAyahTap,
                        );
                        if (i + 1 != _bookmarkPage ||
                            !(settings?.mushafBookmark ?? true)) {
                          return sheet;
                        }
                        // pembatas ikut halamannya saat digeser
                        return Stack(
                          children: [
                            Positioned.fill(child: sheet),
                            Positioned.fill(
                              child: MushafBookmark(
                                onRemoved: () =>
                                    setState(() => _bookmarkPage = null),
                              ),
                            ),
                          ],
                        );
                      },
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
    required this.font,
    required this.maxFont,
    required this.selected,
    required this.onTap,
  });

  final QuranText text;
  final int page;
  final bool tajweed;
  final QuranFont font;
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

/// Ukuran huruf acuan untuk mengukur lebar kata (lebar sebanding dengan
/// ukuran huruf, jadi cukup diukur sekali).
const _refFont = 100.0;

/// Jarak minimum antarkata, relatif terhadap ukuran huruf.
const _minSpace = 0.28;

/// Satu unit baris: sebuah kata (dengan warna tajwid per potongan) atau
/// medali nomor ayat.
class _Token {
  _Token.word(this.ayah, this.runs, this.width) : medallion = false;
  _Token.medallion(this.ayah, this.width) : medallion = true, runs = const [];

  final QuranAyah ayah;
  final List<({String text, Color? color})> runs;
  final bool medallion;

  /// Lebar pada [_refFont].
  final double width;
}

class _MushafSheetState extends State<_MushafSheet> {
  late final List<_Block> _blocks = _makeBlocks();

  /// Kata-kata tiap blok teks, diukur sekali (per mode tajwid & font).
  final _tokens = <_TextBlock, List<_Token>>{};
  (bool, QuranFont)? _tokensFor;

  // hasil pencocokan: ukuran huruf & baris-baris tiap blok teks
  Size? _fitFor;
  double? _fitMax;
  double _font = 24;
  bool _scroll = false;
  Map<_TextBlock, List<List<_Token>>> _lines = {};

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

  TextStyle _style(double font) => TextStyle(
    fontFamily: widget.font.family,
    fontSize: font,
    height: _lineHeight,
    color: mushafInk,
  );

  static double _medallion(double font) => font * 1.15;

  /// Pecah ayat-ayat [b] menjadi kata (warna tajwid dipertahankan per
  /// potongan) + medali, lalu ukur lebarnya pada [_refFont].
  List<_Token> _tokenize(_TextBlock b) {
    final painter = TextPainter(textDirection: TextDirection.rtl);
    double measure(List<({String text, Color? color})> runs) {
      painter
        ..text = TextSpan(
          style: _style(_refFont),
          children: [for (final r in runs) TextSpan(text: r.text)],
        )
        ..layout();
      return painter.width;
    }

    final out = <_Token>[];
    for (final a in b.ayahs) {
      final uthmani = widget.font == QuranFont.uthmani;
      final text = quranTextFor(a, widget.font);
      final segments = widget.tajweed
          ? [
              for (final s in tajweedSegments(text, uthmani: uthmani))
                (text: s.text, color: segmentColor(s)),
            ]
          : [(text: text, color: null)];
      var word = <({String text, Color? color})>[];
      void flush() {
        if (word.isEmpty) return;
        out.add(_Token.word(a, word, measure(word)));
        word = [];
      }

      for (final seg in segments) {
        final parts = seg.text.split(' ');
        for (var i = 0; i < parts.length; i++) {
          if (i > 0) flush();
          if (parts[i].isNotEmpty) {
            word.add((text: parts[i], color: seg.color));
          }
        }
      }
      flush();
      out.add(_Token.medallion(a, _medallion(_refFont)));
    }
    painter.dispose();
    return out;
  }

  /// Susun [tokens] ke baris selebar [width] (satuan [_refFont]): cari
  /// jumlah baris minimum (greedy), lalu lebar target terkecil yang tetap
  /// menghasilkan jumlah baris itu - baris jadi seimbang, baris terakhir
  /// tidak menggantung pendek.
  static List<List<_Token>> _breakLines(List<_Token> tokens, double width) {
    List<List<_Token>> greedy(double w) {
      final lines = <List<_Token>>[];
      var line = <_Token>[];
      var used = 0.0;
      for (final t in tokens) {
        final add = line.isEmpty ? t.width : t.width + _minSpace * _refFont;
        if (line.isNotEmpty && used + add > w) {
          lines.add(line);
          line = [t];
          used = t.width;
        } else {
          line.add(t);
          used += add;
        }
      }
      if (line.isNotEmpty) lines.add(line);
      return lines;
    }

    final best = greedy(width);
    if (best.length <= 1) return best;
    var lo = width * 0.5, hi = width;
    var result = best;
    for (var i = 0; i < 14; i++) {
      final mid = (lo + hi) / 2;
      final lines = greedy(mid);
      if (lines.length <= best.length) {
        result = lines;
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return result;
  }

  /// Tinggi isi halaman & baris-baris pada ukuran huruf [font].
  (double, Map<_TextBlock, List<List<_Token>>>) _layout(
    double font,
    double width,
  ) {
    final lines = <_TextBlock, List<List<_Token>>>{};
    var h = 0.0;
    for (final b in _blocks) {
      switch (b) {
        case _BannerBlock():
          h += _bannerHeight + _gap;
        case _BasmalahBlock():
          h += font * 0.92 * 1.9;
        case _TextBlock():
          final l = _breakLines(_tokens[b]!, width * _refFont / font);
          lines[b] = l;
          h += l.length * font * _lineHeight;
      }
    }
    return (h, lines);
  }

  void _set(
    double font,
    Map<_TextBlock, List<List<_Token>>> lines, {
    required bool scroll,
  }) {
    _font = font;
    _lines = lines;
    _scroll = scroll;
  }

  void _fit(Size area) {
    if (_tokensFor != (widget.tajweed, widget.font)) {
      _tokensFor = (widget.tajweed, widget.font);
      _tokens.clear();
      _fitFor = null;
      for (final b in _blocks) {
        if (b is _TextBlock) _tokens[b] = _tokenize(b);
      }
    }
    if (_fitFor == area && _fitMax == widget.maxFont) return;
    _fitFor = area;
    _fitMax = widget.maxFont;

    var (h, lines) = _layout(widget.maxFont, area.width);
    if (h <= area.height) {
      _set(widget.maxFont, lines, scroll: false);
      return;
    }
    (h, lines) = _layout(_minFont, area.width);
    if (h > area.height) {
      _set(_minFont, lines, scroll: true);
      return;
    }
    var lo = _minFont, hi = widget.maxFont;
    var fit = lines;
    for (var i = 0; i < 8; i++) {
      final mid = (lo + hi) / 2;
      final (mh, ml) = _layout(mid, area.width);
      if (mh <= area.height) {
        lo = mid;
        fit = ml;
      } else {
        hi = mid;
      }
    }
    _set(lo, fit, scroll: false);
  }

  Widget _tokenView(_Token t, double font) {
    final selected = widget.selected == t.ayah.index;
    final Widget child = t.medallion
        ? _medallionView(t.ayah, font)
        : Text.rich(
            TextSpan(
              style: _style(font),
              children: [
                for (final r in t.runs)
                  TextSpan(
                    text: r.text,
                    style: r.color == null ? null : TextStyle(color: r.color),
                  ),
              ],
            ),
            textDirection: TextDirection.rtl,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            softWrap: false,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(t.ayah),
      child: selected
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x33F59E0B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: child,
            )
          : child,
    );
  }

  /// Medali nomor ayat; ayat terakhir ruku' diberi tanda 'ain (ع) kecil di
  /// atasnya - di celah antar-baris, jadi lebar baris (rata kanan-kiri)
  /// tidak berubah. Rincian ruku'-nya ada di lembar ayat saat diketuk.
  /// Halaman ganjil: pita ornamen & kotak 'ain di kanan; genap: di kiri.
  bool get _outerRight => widget.page.isOdd;

  Widget _medallionView(QuranAyah ayah, double font) {
    final size = _medallion(font);
    final medallion = AyahMedallion(number: ayah.number, size: size);
    if (ayah.ruku == null) return medallion;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        medallion,
        // di akhir kalimat: kecil & terangkat di atas ujung kata sebelum
        // medali (sebelah kanannya, karena teks mengalir dari kanan)
        Positioned(
          right: -font * 0.3,
          bottom: size * 0.9,
          child: Text(
            'ع',
            textDirection: TextDirection.rtl,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: arabicFont,
              fontSize: font * 0.46,
              height: 1,
              fontWeight: FontWeight.w700,
              color: mushafRed,
            ),
          ),
        ),
      ],
    );
  }

  /// Satu baris: rata kanan-kiri penuh, garis tipis di bawahnya.
  Widget _lineView(List<_Token> line, double font) {
    return Container(
      height: font * _lineHeight,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x55C9A24A), width: 0.8),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: line.length == 1
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [for (final t in line) _tokenView(t, font)],
            ),
          ),
          // baris berisi akhir ruku': kotak ع di pita bingkai sisi luar
          if (line.any((t) => t.medallion && t.ayah.ruku != null))
            _rukuMarginMark(font),
        ],
      ),
    );
  }

  /// Kotak 'ain di tengah pita sisi luar, sejajar baris ini.
  Widget _rukuMarginMark(double font) {
    const w = 13.0;
    final pad = MushafFrame.contentPadding(outerRight: _outerRight);
    final gap =
        (_outerRight ? pad.right : pad.left) - MushafFrame.bandCenter + w / 2;
    final box = Container(
      width: w,
      height: (font * _lineHeight * 0.62).clamp(16.0, 26.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: mushafGold, width: 0.8),
      ),
      child: const Text(
        'ع',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
          color: mushafRed,
        ),
      ),
    );
    return Positioned(
      top: 0,
      bottom: 0,
      right: _outerRight ? -gap : null,
      left: _outerRight ? null : -gap,
      child: Center(child: box),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.text.ayahsOnPage(widget.page).first;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            // bingkai digambar DI BAWAH isi (di atas warna kertas), supaya
            // kotak 'ain di pita sisi luar tidak tertutup
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
              child: CustomPaint(
                painter: MushafFramePainter(outerRight: _outerRight),
                child: Padding(
                  padding: MushafFrame.contentPadding(outerRight: _outerRight),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            // cadangan 2% untuk pembulatan tata letak
                            _fit(Size(c.maxWidth, c.maxHeight * 0.98));
                            final content = Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final b in _blocks)
                                  switch (b) {
                                    _BannerBlock(:final surah) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: _gap,
                                      ),
                                      child: SurahBanner(
                                        surah: surah,
                                        height: _bannerHeight,
                                      ),
                                    ),
                                    _BasmalahBlock() => SizedBox(
                                      height: _font * 0.92 * 1.9,
                                      child: Center(
                                        child: BasmalahLine(
                                          fontSize: _font * 0.92,
                                          uthmani:
                                              widget.font == QuranFont.uthmani,
                                        ),
                                      ),
                                    ),
                                    _TextBlock() => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (final line
                                            in _lines[b] ?? const [])
                                          _lineView(line, _font),
                                      ],
                                    ),
                                  },
                              ],
                            );
                            if (_scroll) {
                              return SingleChildScrollView(child: content);
                            }
                            // pengaman terakhir: tidak pernah meluap
                            // halaman pendek (mis. Al-Fatihah) di tengah seperti
                            // mushaf cetak
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: c.maxWidth,
                                child: content,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // label juz, halaman & surah di atas pita bingkai atas
          Positioned(
            left: MushafFrame.inset + 8,
            right: MushafFrame.inset + 8,
            top: MushafFrame.inset,
            height: MushafFrame.topBand,
            child: _PageHead(
              juz: first.juz,
              page: widget.page,
              surah: '${first.surah}. ${surahName(first.surah)}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Label di pita atas bingkai: juz (kiri), nomor halaman (tengah), surah
/// (kanan) - seperti mushaf cetak.
class _PageHead extends StatelessWidget {
  const _PageHead({required this.juz, required this.page, required this.surah});
  final int juz, page;
  final String surah;

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, {bool center = false}) => Container(
      padding: EdgeInsets.symmetric(horizontal: center ? 8 : 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(center ? 6 : 99),
        border: Border.all(color: mushafGold),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: center ? 12.5 : 11.5,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: center ? mushafRed : _stone,
        ),
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: pill('Juz $juz'),
          ),
        ),
        pill('$page', center: true),
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
            if (ayah.ruku case final r?) ...[
              const SizedBox(height: 10),
              _RukuInfo(mark: r, label: rukuLabel(r, surah.name, ayah.juz)),
            ],
            // tanda waqaf di ayat ini beserta hukumnya
            if (WaqfSign.inText(ayah.uthmani) case final signs
                when signs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'TANDA WAQAF DI AYAT INI',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 8),
              for (final w in signs) WaqfSignRow(sign: w),
            ],
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

/// Keterangan tanda 'ain di lembar ayat.
class _RukuInfo extends StatelessWidget {
  const _RukuInfo({required this.mark, required this.label});
  final RukuMark mark;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x55C9A24A)),
    ),
    child: Row(
      children: [
        RukuSign(mark: mark, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, height: 1.4, color: _stone),
          ),
        ),
      ],
    ),
  );
}
