import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gambar pembatas (assets/quran/tanda-baca.png, 789x1994).
const mushafBookmarkAsset = 'assets/quran/tanda-baca.png';
const _aspect = 789 / 1994;

/// Pembatas halaman yang tergantung di atas halaman mushaf terakhir dibaca,
/// seperti pembatas pita di mushaf cetak.
///
/// - Ketuk: pembatas naik & tersembunyi, hanya ujung bawahnya yang mengintip
///   di tepi atas halaman. Ketuk ujungnya untuk menurunkannya lagi.
/// - Geser ke atas: pembatas dibuka (dilepas dari halaman) - [onRemoved].
///
/// Hanya gambar pembatas yang menangkap sentuhan; bagian halaman lain tetap
/// bisa diketuk & digeser seperti biasa.
class MushafBookmark extends StatefulWidget {
  const MushafBookmark({super.key, required this.onRemoved});

  final VoidCallback onRemoved;

  @override
  State<MushafBookmark> createState() => _MushafBookmarkState();
}

class _MushafBookmarkState extends State<MushafBookmark>
    with TickerProviderStateMixin {
  /// 0 = tergantung penuh, 1 = tersembunyi (hanya ujung yang mengintip).
  /// Mulai tersembunyi lalu turun - seperti pembatas yang terjulur.
  late final _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );

  /// Dilepas: 0 -> 1 terbang ke atas & memudar.
  late final _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// Kembali ke posisi semula setelah geseran yang tidak cukup jauh.
  late final _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  /// Geseran jari (negatif = ke atas).
  double _drag = 0;
  double _snapFrom = 0;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _snap.addListener(
      () => setState(
        () => _drag = _snapFrom * (1 - Curves.easeOut.transform(_snap.value)),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _show();
    });
  }

  @override
  void dispose() {
    _fold.dispose();
    _out.dispose();
    _snap.dispose();
    super.dispose();
  }

  bool get _folded => _fold.value > 0.5;

  void _show() => _fold.animateTo(0, curve: Curves.easeOutBack);

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_folded) {
      _show();
    } else {
      _fold.animateTo(1, curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _remove() async {
    if (_removed) return;
    _removed = true;
    HapticFeedback.lightImpact();
    await _out.forward();
    if (mounted) widget.onRemoved();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _snap.stop();
    // ke bawah sedikit saja (terasa kenyal), ke atas bebas
    setState(() => _drag = math.min(24, _drag + d.delta.dy));
  }

  void _onDragEnd(DragEndDetails d, double height) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (v < -450 || _drag < -height * 0.18) {
      _remove();
      return;
    }
    _snapFrom = _drag;
    _snap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      var w = math.min(c.maxWidth * 0.46, 210.0);
      var h = w / _aspect;
      if (h > c.maxHeight * 0.92) {
        h = c.maxHeight * 0.92;
        w = h * _aspect;
      }
      // saat tersembunyi hanya ujung lancip bawah yang terlihat
      final peek = h * 0.075;
      final travel = h - peek;
      return ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([_fold, _out]),
          builder: (context, child) {
            final top =
                -travel * _fold.value + _drag - _out.value * (h + 40) - 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: top,
                  left: (c.maxWidth - w) / 2,
                  width: w,
                  height: h,
                  child: Opacity(
                    opacity: (1 - _out.value * 0.7).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: Semantics(
            label: 'Pembatas halaman',
            hint: 'Ketuk untuk menyembunyikan, geser ke atas untuk membuka',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: (d) => _onDragEnd(d, h),
              child: Image.asset(
                mushafBookmarkAsset,
                width: w,
                height: h,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      );
    },
  );
}
