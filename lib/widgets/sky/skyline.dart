import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'starfield.dart' show triangleWave;

class _Building {
  final double x, w, h;
  const _Building(this.x, this.w, this.h);
}

/// Satu petak gedung selebar 750 satuan, garis dasar di y=100. Padanan
/// `BUILDINGS`.
const List<_Building> _buildings = [
  _Building(0, 54, 30),
  _Building(48, 34, 47),
  _Building(78, 40, 25),
  _Building(112, 27, 58),
  _Building(134, 46, 35),
  _Building(176, 32, 50),
  _Building(204, 44, 27),
  _Building(244, 30, 44),
  _Building(270, 48, 31),
  _Building(314, 34, 52),
  _Building(344, 42, 29),
  _Building(382, 30, 46),
  _Building(408, 50, 26),
  _Building(454, 33, 55),
  _Building(482, 45, 33),
  _Building(522, 31, 48),
  _Building(548, 47, 28),
  _Building(590, 36, 42),
  _Building(622, 44, 31),
  _Building(660, 32, 50),
  _Building(688, 40, 27),
  _Building(724, 26, 38),
];

const double _tile = 750;
const double _mosqueW = 96;

class _Placed {
  final double x, w, h;
  final int n;
  const _Placed(this.x, this.w, this.h, this.n);
}

class _Lamp {
  final double x, y, w, h, delayS;
  const _Lamp(this.x, this.y, this.w, this.h, this.delayS);
}

class _CityLayout {
  final List<_Placed> blocks;
  final double mosqueX;
  const _CityLayout(this.blocks, this.mosqueX);
}

/// Posisi absolut tiap gedung untuk sejumlah petak - petak ganjil dicerminkan
/// supaya pengulangannya tidak kentara, gedung yang bertabrakan dengan tapak
/// masjid dibuang. Padanan `layoutCity`.
_CityLayout _layoutCity(int tiles) {
  final width = _tile * tiles;
  final mosqueX = ((width - _mosqueW) / 2).roundToDouble();
  final zoneMin = mosqueX - 10;
  final zoneMax = mosqueX + _mosqueW + 10;
  final blocks = <_Placed>[];

  for (var t = 0; t < tiles; t++) {
    final mirrored = t % 2 == 1;
    for (var i = 0; i < _buildings.length; i++) {
      final b = _buildings[i];
      final x = mirrored ? _tile * (t + 1) - b.x - b.w : _tile * t + b.x;
      if (x + b.w > zoneMin && x < zoneMax) continue;
      blocks.add(_Placed(x, b.w, b.h, t * _buildings.length + i));
    }
  }
  return _CityLayout(blocks, mosqueX);
}

/// Jendela menyala saat kota masih ramai. Padanan `busyWindows`.
List<_Lamp> _busyWindows(List<_Placed> blocks) {
  final lamps = <_Lamp>[];
  const fys = [0.32, 0.56, 0.79];
  const fxs = [0.26, 0.6];
  for (final b in blocks) {
    for (var j = 0; j < fys.length; j++) {
      for (var k = 0; k < fxs.length; k++) {
        final lit = (b.n + j * 2 + k) % 3 != 0;
        if (!lit) continue;
        lamps.add(
          _Lamp(
            b.x + b.w * fxs[k],
            100 - b.h * fys[j],
            4,
            5,
            ((b.n * 5 + j * 3 + k * 7) % 13) * 0.55,
          ),
        );
      }
    }
  }
  return lamps;
}

/// Lewat pukul 22:00, hanya sekitar dua dari sepuluh rumah yang masih
/// menyala. Padanan `quietWindows`.
List<_Lamp> _quietWindows(List<_Placed> blocks) => [
  for (final b in blocks)
    if (b.n % 5 == 1)
      _Lamp(b.x + b.w * 0.4, 100 - b.h * 0.58, 4, 5, (b.n % 5) * 1.6),
];

/// Siluet kota + masjid, digambar via `CustomPainter` sendiri (bukan
/// diregangkan tidak proporsional) - padanan `Skyline`/`Mosque` di
/// SkyAtmosphere.tsx, dengan `BoxFit.contain` anchored ke bawah-tengah yang
/// setara `preserveAspectRatio="xMidYMax meet"`.
class SkylinePainter extends CustomPainter {
  factory SkylinePainter({
    required int tiles,
    required bool quiet,
    required double clockMs,
    bool cover = false,
  }) {
    final layout = _layoutCity(tiles);
    final lamps = quiet
        ? _quietWindows(layout.blocks)
        : _busyWindows(layout.blocks);
    return SkylinePainter._(
      tiles: tiles,
      quiet: quiet,
      clockMs: clockMs,
      cover: cover,
      layout: layout,
      lamps: lamps,
    );
  }

  const SkylinePainter._({
    required this.tiles,
    required this.quiet,
    required this.clockMs,
    required this.cover,
    required this.layout,
    required this.lamps,
  });

  final int tiles;
  final bool quiet;
  final double clockMs;

  /// `true`: skala mengikuti tinggi (ala `BoxFit.cover`, tetap di
  /// bawah-tengah) sehingga kota boleh meluber ke kiri-kanan dan dipotong
  /// oleh pembungkusnya - dipakai widget layar utama supaya kotanya besar.
  /// `false`: `BoxFit.contain` (muat seluruhnya).
  final bool cover;
  final _CityLayout layout;
  final List<_Lamp> lamps;

  @override
  void paint(Canvas canvas, Size size) {
    final vbW = _tile * tiles;
    const vbH = 100.0;
    final byW = size.width / vbW;
    final byH = size.height / vbH;
    final scale = cover ? math.max(byW, byH) : math.min(byW, byH);
    final dx = (size.width - vbW * scale) / 2; // xMid
    final dy = size.height - vbH * scale; // yMax (nempel bawah)

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final buildingPaint = Paint()..color = const Color(0xFF080E1E);
    for (final b in layout.blocks) {
      canvas.drawRect(Rect.fromLTWH(b.x, 100 - b.h, b.w, b.h), buildingPaint);
    }

    for (final l in lamps) {
      final phase = ((clockMs - l.delayS * 1000) % 4200) / 4200;
      final opacity = triangleWave(phase, 0.22, 0.95);
      final paint = Paint()
        ..color = const Color(0xFFFFCF7A).withOpacity(opacity);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(l.x, l.y, l.w, l.h),
        const Radius.circular(0.8),
      );
      canvas.drawRRect(rrect, paint);
    }

    _drawMosque(canvas, layout.mosqueX, quiet);

    canvas.restore();
  }

  void _drawMosque(Canvas canvas, double x, bool dim) {
    canvas.save();
    canvas.translate(x, 0);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Color(dim ? 0x38FFC46E : 0x57FFC46E), const Color(0x00FFC46E)],
      ).createShader(Rect.fromCircle(center: const Offset(48, 62), radius: 62));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(48, 62), width: 124, height: 88),
      glowPaint,
    );

    final dark = Paint()..color = const Color(0xFF080E1E);
    // menara
    canvas.drawRect(const Rect.fromLTWH(4, 38, 8, 62), dark);
    canvas.drawCircle(const Offset(8, 38), 5.5, dark);
    canvas.drawRect(const Rect.fromLTWH(7, 24, 2, 9), dark);
    canvas.drawRect(const Rect.fromLTWH(84, 38, 8, 62), dark);
    canvas.drawCircle(const Offset(88, 38), 5.5, dark);
    canvas.drawRect(const Rect.fromLTWH(87, 24, 2, 9), dark);
    // badan & kubah
    canvas.drawRect(const Rect.fromLTWH(10, 66, 76, 34), dark);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(48, 66), width: 56, height: 50),
      dark,
    );
    canvas.drawRect(const Rect.fromLTWH(46.5, 30, 3, 12), dark);
    canvas.drawCircle(const Offset(48, 28), 3.5, dark);

    final lampPaint = Paint()
      ..color = const Color(0xFFFFD489).withOpacity(dim ? 0.72 : 1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 78, 12, 22),
        const Radius.circular(6),
      ),
      lampPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, 83, 8, 13),
        const Radius.circular(4),
      ),
      lampPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(65, 83, 8, 13),
        const Radius.circular(4),
      ),
      lampPaint,
    );
    canvas.drawCircle(const Offset(8, 38), 2.6, lampPaint);
    canvas.drawCircle(const Offset(88, 38), 2.6, lampPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SkylinePainter oldDelegate) =>
      oldDelegate.cover != cover ||
      oldDelegate.clockMs != clockMs ||
      oldDelegate.quiet != quiet ||
      oldDelegate.tiles != tiles;
}
