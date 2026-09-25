import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/yasin_kitab.dart';

/// Lama satu kali balik lembar. Padanan `FLIP_MS`.
const _flipDuration = Duration(milliseconds: 820);

/// Berapa halaman di sekitar posisi sekarang yang ikut dimuat lebih dulu.
const _preload = 4;

const _paperGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEFE6D6), Color(0xFFE2D6C1)],
);
const _paperBackGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF6EFE3), Color(0xFFE8DCC8)],
);

/// Buku yang dibalik lembar demi lembar - padanan `FlipBook.tsx` di web.
///
/// [page] acuan adalah halaman kanan pada tampilan dua halaman (selalu
/// ganjil, pasangannya `page - 1` di kiri, seperti penomoran buku cetak);
/// pada tampilan satu halaman ia halaman yang terlihat.
class FlipBook extends StatefulWidget {
  const FlipBook({
    super.key,
    required this.total,
    required this.ratio,
    required this.asset,
    required this.title,
    this.chapters = const [],
    this.initialPage = 1,
    this.fullscreen = false,
    this.onPageChanged,
    this.onToggleFullscreen,
  });

  final int total;

  /// Lebar : tinggi satu halaman.
  final double ratio;
  final String Function(int page) asset;
  final String title;
  final List<KitabChapter> chapters;
  final int initialPage;
  final bool fullscreen;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onToggleFullscreen;

  @override
  State<FlipBook> createState() => _FlipBookState();
}

class _Flip {
  final int dir; // 1 maju, -1 mundur
  final int from;
  const _Flip(this.dir, this.from);
}

class _FlipBookState extends State<FlipBook>
    with SingleTickerProviderStateMixin {
  late int _page = widget.initialPage.clamp(1, widget.total);
  _Flip? _flip;
  late final AnimationController _ctrl;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _flipDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _flip = null);
        }
      });
    _t = CurvedAnimation(parent: _ctrl, curve: const Cubic(0.38, 0.02, 0.2, 1));
  }

  Offset? _dragStart;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNearby();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _precacheNearby() {
    for (var p = _page - _preload; p <= _page + _preload; p++) {
      if (p >= 1 && p <= widget.total) {
        precacheImage(AssetImage(widget.asset(p)), context);
      }
    }
  }

  bool _isSpread(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 768 && size.width / size.height >= 4 / 3;
  }

  void _setPage(int p) {
    _page = p;
    widget.onPageChanged?.call(p);
    _precacheNearby();
  }

  void _go(int dir, bool spread) {
    if (_flip != null) return;
    final step = spread ? 2 : 1;
    final target = _page + dir * step;
    if (target < 1 || target > widget.total) return;
    setState(() {
      _flip = _Flip(dir, _page);
      _setPage(target);
    });
    _ctrl.forward(from: 0);
  }

  void _jump(int target, bool spread) {
    final snapped = spread && target.isEven ? math.max(1, target - 1) : target;
    _ctrl.stop();
    setState(() {
      _flip = null;
      _setPage(snapped.clamp(1, widget.total));
    });
  }

  /* ------------------------------------------------------------------ */

  Widget _sheet(int? page) {
    if (page == null || page < 1 || page > widget.total) {
      // sisi kosong, misalnya sebelah kiri sampul
      return const DecoratedBox(
        decoration: BoxDecoration(gradient: _paperGradient),
      );
    }
    return ColoredBox(
      color: Colors.white,
      child: Image.asset(
        widget.asset(page),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  /// Bayangan lipatan di dekat punggung buku, supaya terasa berjilid.
  Widget _gutter({required bool left}) {
    return Positioned.fill(
      child: Align(
        alignment: left ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.08,
          heightFactor: 1,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: left ? Alignment.centerLeft : Alignment.centerRight,
                  end: left ? Alignment.centerRight : Alignment.centerLeft,
                  colors: const [Color(0x00000000), Color(0x2E3C2814)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lembar yang sedang dibalik. Gelap-terang kertasnya diturunkan dari
  /// sudut putar: paling gelap saat tegak lurus pandangan, memudar lagi
  /// ketika mendarat - seperti kertas menangkap cahaya waktu dibalik.
  Widget _leaf({
    required double bookWidth,
    required double bookHeight,
    required double fromDeg,
    required double toDeg,
    required bool originLeft,
    required double leafWidth,
    required bool alignRight,
    required int? front,
    required int? back,
  }) {
    final perspective = math.max(1800.0, bookWidth * 3.2);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final deg = fromDeg + (toDeg - fromDeg) * _t.value;
        final a = deg.abs() % 360;
        final d = a > 180 ? 360 - a : a;
        final edge = math.sin(d / 180 * math.pi);
        final faceShade = edge * 0.5;
        final castShade = edge * 0.28;
        final showBack = d > 90;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, -1 / perspective)
          ..rotateY(deg * math.pi / 180);

        final face = showBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: back != null
                    ? _sheet(back)
                    : const DecoratedBox(
                        decoration: BoxDecoration(gradient: _paperBackGradient),
                      ),
              )
            : _sheet(front);

        return Stack(
          children: [
            // bayangan lembar yang jatuh ke halaman di bawahnya
            Positioned(
              top: 0,
              bottom: 0,
              left: alignRight ? null : 0,
              right: alignRight ? 0 : null,
              width: leafWidth,
              child: IgnorePointer(
                child: Opacity(
                  opacity: castShade.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: originLeft
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        end: originLeft
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        colors: const [Color(0xE61E1408), Color(0x001E1408)],
                        stops: const [0, 0.62],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: alignRight ? null : 0,
              right: alignRight ? 0 : null,
              width: leafWidth,
              child: Transform(
                alignment: originLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                transform: matrix,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      face,
                      IgnorePointer(
                        child: ColoredBox(
                          color: const Color(
                            0xFF1D1408,
                          ).withOpacity(faceShade.clamp(0.0, 1.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /* ------------------------------------------------------------------ */

  void _showChapters(BuildContext context, bool spread) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x801C1917),
      isScrollControlled: true,
      builder: (ctx) => _ChapterSheet(
        title: widget.title,
        chapters: widget.chapters,
        total: widget.total,
        page: _page,
        onPick: (p) {
          Navigator.of(ctx).pop();
          _jump(p, spread);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullscreen = widget.fullscreen;
    final spread = _isSpread(context);
    final screen = MediaQuery.sizeOf(context);
    final step = spread ? 2 : 1;

    // saat berganti ke tampilan dua halaman, acuan disnap ke ganjil
    if (spread && _page.isEven) _page = math.max(1, _page - 1);

    final bookRatio = spread ? widget.ratio * 2 : widget.ratio;

    /// Selama membalik, satu sisi masih memperlihatkan halaman lama sementara
    /// sisi lainnya sudah memperlihatkan halaman tujuan; lembar yang berputar
    /// menutupi peralihannya.
    final flip = _flip;
    final baseLeft = flip?.dir == 1 ? flip!.from - 1 : _page - 1;
    final baseRight = flip?.dir == -1 ? flip!.from : _page;
    final baseSingle = flip?.dir == -1 ? flip!.from : _page;

    final atStart = _page <= 1;
    final atEnd = _page + (spread ? 1 : 0) >= widget.total;

    final stage = LayoutBuilder(
      builder: (context, constraints) {
        // ukuran buku dihitung dari ruang yang tersisa: layar penuh memakai
        // sisa tinggi panggung, halaman biasa dibatasi pecahan tinggi layar
        final availableH = fullscreen
            ? (constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : screen.height * 0.7)
            : screen.height * (spread ? 0.52 : 0.6);
        final bookWidth = math.max(
          0.0,
          math.min(constraints.maxWidth, availableH * bookRatio),
        );
        final bookHeight = bookWidth / bookRatio;

        Widget? leaf;
        if (flip != null) {
          if (spread) {
            leaf = flip.dir == 1
                ? _leaf(
                    bookWidth: bookWidth,
                    bookHeight: bookHeight,
                    fromDeg: 0,
                    toDeg: -180,
                    originLeft: true,
                    leafWidth: bookWidth / 2,
                    alignRight: true,
                    front: flip.from,
                    back: _page - 1,
                  )
                : _leaf(
                    bookWidth: bookWidth,
                    bookHeight: bookHeight,
                    fromDeg: 0,
                    toDeg: 180,
                    originLeft: false,
                    leafWidth: bookWidth / 2,
                    alignRight: false,
                    front: flip.from - 1,
                    back: _page,
                  );
          } else {
            leaf = flip.dir == 1
                ? _leaf(
                    bookWidth: bookWidth,
                    bookHeight: bookHeight,
                    fromDeg: 0,
                    toDeg: -180,
                    originLeft: true,
                    leafWidth: bookWidth,
                    alignRight: false,
                    front: flip.from,
                    back: null,
                  )
                : _leaf(
                    bookWidth: bookWidth,
                    bookHeight: bookHeight,
                    fromDeg: -180,
                    toDeg: 0,
                    originLeft: true,
                    leafWidth: bookWidth,
                    alignRight: false,
                    front: _page,
                    back: null,
                  );
          }
        }

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _dragStart = d.localPosition,
            onHorizontalDragEnd: (d) {
              final start = _dragStart;
              _dragStart = null;
              final v = d.primaryVelocity ?? 0;
              if (start == null && v == 0) return;
              if (v.abs() > 200) {
                _go(v < 0 ? 1 : -1, spread);
              }
            },
            child: SizedBox(
              width: bookWidth,
              height: bookHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: fullscreen
                            ? const [
                                BoxShadow(
                                  color: Color(0xA6000000),
                                  blurRadius: 90,
                                  offset: Offset(0, 30),
                                ),
                              ]
                            : const [
                                BoxShadow(
                                  color: Color(0x52503719),
                                  blurRadius: 60,
                                  offset: Offset(0, 20),
                                ),
                              ],
                        border: fullscreen
                            ? Border.all(color: const Color(0x1AFFFFFF))
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: spread
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _sheet(baseLeft),
                                        _gutter(left: true),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _sheet(baseRight),
                                        _gutter(left: false),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : _sheet(baseSingle),
                      ),
                    ),
                  ),
                  if (leaf != null) Positioned.fill(child: leaf),
                  // area ketuk kiri/kanan
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: bookWidth / 4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: atStart ? null : () => _go(-1, spread),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: bookWidth / 4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: atEnd ? null : () => _go(1, spread),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final pageLabel = spread && _page > 1
        ? 'Halaman ${_page - 1}–${math.min(_page, widget.total)}'
        : 'Halaman $_page';

    final controls = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 768),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _RoundButton(
                icon: Icons.chevron_left_rounded,
                fullscreen: fullscreen,
                onTap: atStart ? null : () => _go(-1, spread),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        activeTrackColor: const Color(0xFFF59E0B),
                        inactiveTrackColor: fullscreen
                            ? const Color(0x33FFFFFF)
                            : const Color(0xCCFDE68A),
                        thumbColor: const Color(0xFFF59E0B),
                        overlayColor: const Color(0x33F59E0B),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        min: 1,
                        max: widget.total.toDouble(),
                        value: _page.toDouble().clamp(
                          1,
                          widget.total.toDouble(),
                        ),
                        onChanged: (v) {
                          final target = ((v - 1) / step).round() * step + 1;
                          _jump(target, spread);
                        },
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: '$pageLabel ',
                        children: [
                          TextSpan(
                            text: 'dari ${widget.total}',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: fullscreen
                                  ? const Color(0x73FFFBEB)
                                  : const Color(0xFFA8A29E),
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: fullscreen
                            ? const Color(0xD9FFFBEB)
                            : const Color(0xFF57534E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RoundButton(
                icon: Icons.chevron_right_rounded,
                fullscreen: fullscreen,
                onTap: atEnd ? null : () => _go(1, spread),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.chapters.isNotEmpty)
                _PillButton(
                  icon: Icons.list_rounded,
                  label: 'Daftar Isi',
                  filled: true,
                  fullscreen: fullscreen,
                  onTap: () => _showChapters(context, spread),
                ),
              if (widget.onToggleFullscreen != null)
                _PillButton(
                  icon: fullscreen
                      ? Icons.close_fullscreen_rounded
                      : Icons.open_in_full_rounded,
                  label: fullscreen ? 'Keluar' : 'Layar Penuh',
                  filled: false,
                  fullscreen: fullscreen,
                  onTap: widget.onToggleFullscreen!,
                ),
            ],
          ),
        ],
      ),
    );

    if (fullscreen) {
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: stage,
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00100C09),
                  Color(0xD1100C09),
                  Color(0xF2100C09),
                ],
                stops: [0, 0.38, 1],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                math.max(16, MediaQuery.paddingOf(context).bottom),
              ),
              child: Center(child: controls),
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F2E8), Color(0xFFEFE4D2)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [stage, const SizedBox(height: 16), controls],
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------------------- */

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.fullscreen,
    this.onTap,
  });
  final IconData icon;
  final bool fullscreen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: fullscreen ? const Color(0x1AFFFFFF) : Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: fullscreen
                ? const Color(0x26FFFFFF)
                : const Color(0xCCFDE68A),
          ),
        ),
        elevation: fullscreen ? 0 : 1,
        shadowColor: const Color(0x33503719),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: fullscreen
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFF44403C),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.fullscreen,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled, fullscreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;
    Color? border;
    if (filled) {
      bg = fullscreen ? const Color(0xFFFFFBEB) : const Color(0xE61C1917);
      fg = fullscreen ? const Color(0xFF1C1917) : Colors.white;
    } else {
      bg = fullscreen ? const Color(0x1AFFFFFF) : Colors.white;
      fg = fullscreen ? const Color(0xFFFFFBEB) : const Color(0xFF44403C);
      border = fullscreen ? const Color(0x26FFFFFF) : const Color(0xCCFDE68A);
    }
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: border != null ? BorderSide(color: border) : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daftar isi - lembar bawah. Padanan panel "Daftar Isi" di FlipBook.tsx.
class _ChapterSheet extends StatelessWidget {
  const _ChapterSheet({
    required this.title,
    required this.chapters,
    required this.total,
    required this.page,
    required this.onPick,
  });
  final String title;
  final List<KitabChapter> chapters;
  final int total, page;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 448, maxHeight: maxH),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFEF3C7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 60,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DAFTAR ISI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.4,
                                    color: Color(0xCCB45309),
                                  ),
                                ),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF292524),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFFA8A29E),
                            ),
                            tooltip: 'Tutup',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF5F5F4)),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: chapters.length,
                        itemBuilder: (context, i) {
                          final chapter = chapters[i];
                          final next = i + 1 < chapters.length
                              ? chapters[i + 1].page
                              : total + 1;
                          final active = page >= chapter.page && page < next;
                          return Material(
                            color: active
                                ? const Color(0xFFFFFBEB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onPick(chapter.page),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chapter.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: active
                                              ? const Color(0xFF92400E)
                                              : const Color(0xFF44403C),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${chapter.page}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFA8A29E),
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }
}
