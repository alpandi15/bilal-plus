import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/prayer_models.dart';
import '../../services/hijri_calendar.dart';
import '../../utils/sky_clock.dart';

/// Suasana musiman latar kartu & widget jadwal sholat.
enum SkySeason { normal, ramadan, eid, adha }

/// Pengganti musim untuk pengembangan: `--dart-define=SKY_SEASON=ramadan`
/// (hanya build debug) - supaya ornamen bisa dilihat di luar Ramadan.
const _debugSeason = String.fromEnvironment('SKY_SEASON');

/// Musim pada tanggal hijriah [h] yang SEDANG berlaku (sudah berganti saat
/// Maghrib): Ramadan sebulan penuh - termasuk malam tarawih pertama -,
/// Idulfitri sejak malam takbiran sampai 3 Syawal, dan Iduladha sejak malam
/// takbiran sampai akhir hari tasyrik (13 Dzulhijjah).
SkySeason skySeasonOf(HijriDate h) {
  if (kDebugMode && _debugSeason.isNotEmpty) {
    return SkySeason.values.asNameMap()[_debugSeason] ?? SkySeason.normal;
  }
  if (h.month == 9) return SkySeason.ramadan;
  if (h.month == 10 && h.day <= 3) return SkySeason.eid;
  if (h.month == 12 && h.day >= 10 && h.day <= 13) return SkySeason.adha;
  return SkySeason.normal;
}

/// Kembang api MALAM pada tanggal hijriah [h] yang sedang berlaku: malam
/// takbiran & malam Idulfitri (1-3 Syawal), tapi untuk Iduladha hanya malam
/// takbiran (10 Dzulhijjah) - malam tasyrik lebih tenang.
bool skyFireworksOf(HijriDate h) {
  if (kDebugMode && _debugSeason.isNotEmpty) {
    return _debugSeason == 'eid' || _debugSeason == 'adha';
  }
  return (h.month == 10 && h.day <= 3) || (h.month == 12 && h.day == 10);
}

/// Ornamen musiman di atas langit, satu CustomPaint:
/// - Ramadan: lampion (fanous) & hiasan bulan-bintang tergantung dari tepi
///   atas, bergoyang pelan; malam hari lampionnya menyala & berkelip, dan
///   bulan sabit ditemani bintang.
/// - Idulfitri: ketupat & bintang tergantung; malam takbiran/Idulfitri ada
///   kembang api emas-hijau di atas siluet kota.
///
/// Letaknya di pita tengah-atas & kiri-tengah - celah yang kosong dari teks
/// di kartu maupun widget. Semua gerak berperiode pembagi 8,4 dtk (6 frame x
/// 1,4 dtk atlas widget) supaya putaran frame widget tetap menyambung.
class SeasonalOrnaments extends StatelessWidget {
  const SeasonalOrnaments({
    super.key,
    required this.season,
    required this.phase,
    this.moonAt,
    this.moonSize = 38,
    this.clockMs,
    this.pingPong = false,
    this.layer = OrnamentLayer.all,
    this.fireworks = false,
  });

  /// Kembang api (hanya malam) - lihat [skyFireworksOf].
  final bool fireworks;

  final SkySeason season;
  final DayPhase phase;

  /// Kartu: semua ornamen di posisinya. Widget layar utama: satu lapisan
  /// saja di kanvas kecil ([OrnamentLayer.hangers] / [OrnamentLayer.fireworks])
  /// yang lalu ditempatkan Kotlin di celah teks yang sebenarnya.
  final OrnamentLayer layer;

  /// Posisi & ukuran bulan di lapisan langit (untuk bintang pendampingnya).
  final Alignment? moonAt;
  final double moonSize;

  /// Bekukan animasi (frame atlas widget).
  final double? clockMs;

  /// Frame widget diputar bolak-balik (0..5..1): kembang api digambar sebagai
  /// ledakan yang hanya berkilau (ukuran tetap) supaya tidak tampak
  /// "menguncup" saat diputar mundur.
  final bool pingPong;

  @override
  Widget build(BuildContext context) {
    if (season == SkySeason.normal) return const SizedBox.shrink();
    return IgnorePointer(
      child: SkyClockProvider(
        clockMs: clockMs,
        builder: (context, clock) => CustomPaint(
          size: Size.infinite,
          painter: _OrnamentPainter(
            season: season,
            phase: phase,
            ms: clock.ms,
            moonAt: moonAt ?? const Alignment(0.56, -0.14),
            moonSize: moonSize,
            pingPong: pingPong,
            layer: layer,
            fireworks: fireworks,
          ),
        ),
      ),
    );
  }
}

/// Lapisan ornamen yang digambar (lihat [SeasonalOrnaments.layer]).
enum OrnamentLayer { all, hangers, fireworks }

/// Ukuran kanvas lapisan widget (logis). Gantungan menjuntai paling panjang
/// ±60 satuan; kembang api tiga ledakan berjejer.
const hangersStripSize = Size(120, 72);
const fireworksStripSize = Size(200, 56);

/// Satu gantungan: posisi x (pecahan lebar), panjang tali (u), jenis.
class _Hanger {
  const _Hanger(this.x, this.drop, this.kind, this.phase);
  final double x;
  final double drop;
  final _Kind kind;

  /// Selisih fase ayunan (0..1) supaya tidak bergoyang serempak.
  final double phase;
}

/// Gantungan kecil kedua: bulan sabit (Ramadan), bintang (Idulfitri),
/// kambing (Iduladha - lambang qurban).
enum _Kind { big, star, crescent }

const _hangers = [
  _Hanger(0.462, 22, _Kind.big, 0),
  _Hanger(0.512, 10, _Kind.star, 0.35),
  _Hanger(0.560, 34, _Kind.big, 0.6),
  _Hanger(0.607, 12, _Kind.crescent, 0.15),
  _Hanger(0.652, 18, _Kind.big, 0.8),
];

/// Kembang api: pusat (pecahan), jari-jari (u), warna, selisih waktu (ms).
/// Di celah antara baris tanggal & deretan waktu sholat (kartu & widget).
const _bursts = [
  (Offset(0.12, 0.585), 14.0, Color(0xFFF6D27A), 0.0),
  (Offset(0.29, 0.555), 12.0, Color(0xFF8EE3A8), 2800.0),
  (Offset(0.46, 0.60), 13.0, Color(0xFFFFFFFF), 5600.0),
];

/// Kembang api di kanvas [fireworksStripSize] (pecahan kanvas).
const _stripBursts = [
  (Offset(0.15, 0.55), 13.0, Color(0xFFF6D27A), 0.0),
  (Offset(0.50, 0.42), 12.0, Color(0xFF8EE3A8), 2800.0),
  (Offset(0.85, 0.55), 13.0, Color(0xFFFFFFFF), 5600.0),
];

const _loopMs = 8400.0;

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter({
    required this.season,
    required this.phase,
    required this.ms,
    required this.moonAt,
    required this.moonSize,
    required this.pingPong,
    required this.layer,
    required this.fireworks,
  });

  final SkySeason season;
  final bool fireworks;
  final bool pingPong;
  final OrnamentLayer layer;
  final DayPhase phase;
  final double ms;
  final Alignment moonAt;
  final double moonSize;

  bool get _night => phase == DayPhase.night;

  /// Seberapa menyala lampion: malam penuh, menjelang berbuka redup.
  double get _lit => switch (phase) {
    DayPhase.night => 1,
    DayPhase.dusk => 0.35,
    _ => 0,
  };

  double _wave(double period, [double offset = 0]) =>
      math.sin(2 * math.pi * (ms / period + offset));

  @override
  void paint(Canvas canvas, Size size) {
    switch (layer) {
      case OrnamentLayer.all:
        // satuan: 1u = 1 px pada kartu acuan 360x220
        final u = math.min(size.width / 360, size.height / 220);
        if (fireworks && _night) {
          _fireworks(canvas, u, [
            for (final (at, r, color, delay) in _bursts)
              (
                Offset(at.dx * size.width, at.dy * size.height),
                r,
                color,
                delay,
              ),
          ]);
        }
        if (season == SkySeason.ramadan && _night) _moonStar(canvas, size);
        _drawHangers(canvas, u, (x) => size.width * x);
      case OrnamentLayer.hangers:
        final u = size.height / hangersStripSize.height;
        // rentang x gantungan (0,462..0,652) dipetakan ke tengah kanvas
        _drawHangers(canvas, u, (x) => (20 + (x - 0.462) / 0.19 * 80) * u);
      case OrnamentLayer.fireworks:
        final u = size.height / fireworksStripSize.height;
        _fireworks(canvas, u, [
          for (final (at, r, color, delay) in _stripBursts)
            (Offset(at.dx * size.width, at.dy * size.height), r, color, delay),
        ]);
    }
  }

  void _drawHangers(Canvas canvas, double u, double Function(double) xOf) {
    // siang: gantungan pendek, tetap di atas busur matahari (puncaknya
    // ±18% tinggi kartu); malam tanpa matahari - menjuntai lebih rendah
    final dropScale = _night ? 1.0 : 0.25;
    for (final h in _hangers) {
      final anchor = Offset(xOf(h.x), 0);
      final swing = 0.06 * _wave(4200, h.phase); // ±3,4 derajat
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(swing);
      final drop = (h.drop * dropScale + 1) * u;
      canvas.drawLine(
        Offset.zero,
        Offset(0, drop),
        Paint()
          ..color = (_night ? const Color(0xFFE9C47A) : const Color(0xFFB8893A))
              .withValues(alpha: 0.75)
          ..strokeWidth = math.max(0.8, 0.9 * u),
      );
      canvas.translate(0, drop);
      switch ((season, h.kind)) {
        case (SkySeason.eid, _Kind.big):
          _ketupat(canvas, u);
        case (_, _Kind.big):
          _lantern(canvas, u, h.phase);
        case (_, _Kind.star):
          _star(canvas, Offset(0, 4 * u), 4 * u, _gold);
        case (SkySeason.eid, _Kind.crescent):
          _star(canvas, Offset(0, 3.5 * u), 3.2 * u, _gold);
        case (SkySeason.adha, _Kind.crescent):
          _goat(canvas, u);
        case (_, _Kind.crescent):
          _crescent(canvas, Offset(0, 4.5 * u), 4.2 * u, _gold);
      }
      canvas.restore();
    }
  }

  Color get _gold => _night ? const Color(0xFFF0C766) : const Color(0xFFD4A23A);
  Color get _goldLight =>
      _night ? const Color(0xFFFFE6A6) : const Color(0xFFF6D27A);

  /* ------------------------------ lampion ------------------------------ */

  void _lantern(Canvas canvas, double u, double seed) {
    final lit = _lit;
    // kelip api: gabungan dua gelombang supaya tidak terasa mekanis
    final flicker = 0.85 + 0.1 * _wave(2800, seed) + 0.05 * _wave(1400, seed);
    final bodyCenter = Offset(0, 12 * u);

    if (lit > 0) {
      canvas.drawCircle(
        bodyCenter,
        20 * u,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFC46B).withValues(alpha: 0.42 * lit * flicker),
              const Color(0x00FFC46B),
            ],
          ).createShader(Rect.fromCircle(center: bodyCenter, radius: 20 * u)),
      );
    }

    // gelang & kubah
    final metal = Paint()..color = _gold;
    canvas.drawCircle(
      Offset(0, 0.8 * u),
      1.4 * u,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9 * u,
    );
    final dome = Path()
      ..moveTo(-4.5 * u, 5 * u)
      ..quadraticBezierTo(-4 * u, 2 * u, 0, 1.8 * u)
      ..quadraticBezierTo(4 * u, 2 * u, 4.5 * u, 5 * u)
      ..close();
    canvas.drawPath(dome, metal);

    // badan kaca heksagonal
    final body = Path()
      ..moveTo(-5.5 * u, 5 * u)
      ..lineTo(5.5 * u, 5 * u)
      ..lineTo(7 * u, 11.5 * u)
      ..lineTo(4.8 * u, 19 * u)
      ..lineTo(-4.8 * u, 19 * u)
      ..lineTo(-7 * u, 11.5 * u)
      ..close();
    final glass = lit > 0
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0x66FCE9B8),
                const Color(0xFFFFF1C9),
                lit * flicker,
              )!,
              Color.lerp(
                const Color(0x66F2B25C),
                const Color(0xFFFFA940),
                lit * flicker,
              )!,
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Iduladha: kaca kehijauan, Ramadan: kaca amber
            colors: season == SkySeason.adha
                ? const [Color(0x99E6F6D8), Color(0x8896CF8A)]
                : const [Color(0x99FFF3D1), Color(0x88F4C27A)],
          );
    canvas.drawPath(
      body,
      Paint()
        ..shader = glass.createShader(
          Rect.fromLTRB(-7 * u, 5 * u, 7 * u, 19 * u),
        ),
    );
    // rangka emas
    final frame = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * u
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, frame);
    canvas.drawLine(Offset(0, 5 * u), Offset(0, 19 * u), frame);
    canvas.drawLine(
      Offset(-7 * u, 11.5 * u),
      Offset(7 * u, 11.5 * u),
      frame..strokeWidth = 0.6 * u,
    );

    // alas, rumbai
    final base = Path()
      ..moveTo(-4.8 * u, 19 * u)
      ..lineTo(4.8 * u, 19 * u)
      ..lineTo(3 * u, 21.5 * u)
      ..lineTo(-3 * u, 21.5 * u)
      ..close();
    canvas.drawPath(base, metal);
    canvas.drawLine(
      Offset(0, 21.5 * u),
      Offset(0, 24.5 * u),
      Paint()
        ..color = _gold
        ..strokeWidth = 0.8 * u,
    );
    canvas.drawCircle(
      Offset(0, 25.3 * u),
      1.1 * u,
      Paint()..color = _goldLight,
    );
  }

  /* ------------------------------ ketupat ------------------------------ */

  void _ketupat(Canvas canvas, double u) {
    const top = 2.0, mid = 11.0, bottom = 20.0, half = 8.5;
    final diamond = Path()
      ..moveTo(0, top * u)
      ..lineTo(half * u, mid * u)
      ..lineTo(0, bottom * u)
      ..lineTo(-half * u, mid * u)
      ..close();
    final rect = Rect.fromLTRB(-half * u, top * u, half * u, bottom * u);
    canvas.drawPath(
      diamond,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB7D96B), Color(0xFF4E9A3E), Color(0xFF2F7A34)],
        ).createShader(rect),
    );

    // anyaman: pita kuning-hijau menyilang
    canvas.save();
    canvas.clipPath(diamond);
    final strip = Paint()
      ..color = const Color(0xFFF2D675).withValues(alpha: 0.85)
      ..strokeWidth = 2.1 * u;
    for (final k in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(-half * u, (mid + k * 4.5) * u - half * u),
        Offset(half * u, (mid + k * 4.5) * u + half * u),
        strip,
      );
    }
    final weave = Paint()
      ..color = const Color(0xFF2B6A2F).withValues(alpha: 0.55)
      ..strokeWidth = 0.7 * u;
    for (var k = -2; k <= 2; k++) {
      canvas.drawLine(
        Offset(-half * u, (mid + k * 3.2) * u + half * u),
        Offset(half * u, (mid + k * 3.2) * u - half * u),
        weave,
      );
    }
    canvas.restore();
    canvas.drawPath(
      diamond,
      Paint()
        ..color = const Color(0xFF2B6A2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * u
        ..strokeJoin = StrokeJoin.round,
    );

    // simpul atas & dua ekor daun di bawah
    canvas.drawCircle(Offset(0, top * u), 1.3 * u, Paint()..color = _gold);
    final leaf = Paint()
      ..color = const Color(0xFF6DAE4B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(0, bottom * u)
        ..quadraticBezierTo(
          -1.5 * u,
          (bottom + 3) * u,
          -3.5 * u,
          (bottom + 5.5) * u,
        ),
      leaf,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, bottom * u)
        ..quadraticBezierTo(
          1.8 * u,
          (bottom + 2.5) * u,
          2.5 * u,
          (bottom + 6.5) * u,
        ),
      leaf,
    );
  }

  /* ---------------------------- hiasan kecil ---------------------------- */

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _crescent(Canvas canvas, Offset c, double r, Color color) {
    final shape = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(
        Rect.fromCircle(
          center: c + Offset(r * 0.55, -r * 0.3),
          radius: r * 0.85,
        ),
      ),
    );
    canvas.drawPath(shape, Paint()..color = color);
  }

  /// Siluet kambing emas kecil (Iduladha), tergantung di punggungnya.
  void _goat(Canvas canvas, double u) {
    final fill = Paint()..color = _gold;
    // badan
    canvas.drawRRect(
      RRect.fromLTRBR(
        -4.6 * u,
        2.2 * u,
        3.6 * u,
        7 * u,
        Radius.circular(2.4 * u),
      ),
      fill,
    );
    // leher & kepala menghadap kanan
    final head = Path()
      ..moveTo(2.2 * u, 3.4 * u)
      ..lineTo(4.4 * u, 0.6 * u)
      ..quadraticBezierTo(6.6 * u, 0.2 * u, 7 * u, 2.2 * u)
      ..lineTo(5.6 * u, 3.4 * u)
      ..lineTo(3.6 * u, 4.6 * u)
      ..close();
    canvas.drawPath(head, fill);
    final line = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * u
      ..strokeCap = StrokeCap.round;
    // tanduk melengkung ke belakang, telinga, janggut
    canvas.drawPath(
      Path()
        ..moveTo(4.6 * u, 0.8 * u)
        ..quadraticBezierTo(3.6 * u, -1.4 * u, 2 * u, -0.6 * u),
      line,
    );
    canvas.drawLine(Offset(4.2 * u, 1.6 * u), Offset(2.9 * u, 2.4 * u), line);
    canvas.drawLine(Offset(6.4 * u, 2.4 * u), Offset(6.2 * u, 3.8 * u), line);
    // kaki & ekor
    for (final x in [-3.6, -2.2, 1.4, 2.8]) {
      canvas.drawLine(Offset(x * u, 6.4 * u), Offset(x * u, 9.4 * u), line);
    }
    canvas.drawLine(Offset(-4.4 * u, 3 * u), Offset(-5.6 * u, 1.8 * u), line);
  }

  /// Bintang di celah bulan sabit (Ramadan malam). Posisinya mengikuti
  /// [moonAt] & ukuran bulan di lapisan langit.
  void _moonStar(Canvas canvas, Size size) {
    final center = Offset(
      (moonAt.x + 1) / 2 * size.width,
      (moonAt.y + 1) / 2 * size.height,
    );
    final c = center + Offset(moonSize * 0.3, -moonSize * 0.24);
    final twinkle = 0.8 + 0.2 * _wave(2800);
    final r = moonSize * 0.17;
    canvas.drawCircle(
      c,
      r * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF4D6).withValues(alpha: 0.45 * twinkle),
            const Color(0x00FFF4D6),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.4)),
    );
    _star(canvas, c, r * twinkle, const Color(0xFFFFF7E0));
  }

  /* ---------------------------- kembang api ---------------------------- */

  void _fireworks(
    Canvas canvas,
    double u,
    List<(Offset, double, Color, double)> bursts,
  ) {
    for (final (center, radius, color, delay) in bursts) {
      var p = ((ms - delay) % _loopMs) / _loopMs;
      if (pingPong) {
        // ledakan beku di tahap mekar berbeda-beda, hanya kilaunya berdenyut
        p =
            0.14 +
            0.58 * (0.35 + 0.1 * (delay / 2800)) +
            0.02 * math.sin(2 * math.pi * ms / 2800);
      }
      if (p < 0.14) {
        // roket naik dari balik kota
        final q = p / 0.14;
        // naik pendek saja, tidak melintasi deretan waktu sholat
        final from = center + Offset(0, 22 * u);
        final head = Offset.lerp(from, center, Curves.easeOut.transform(q))!;
        canvas.drawLine(
          Offset.lerp(from, head, 0.6)!,
          head,
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: 0.9),
              ],
            ).createShader(Rect.fromPoints(from, head))
            ..strokeWidth = 1.2 * u
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      if (p > 0.72) continue;
      final q = (p - 0.14) / 0.58;
      final spread = Curves.easeOutCubic.transform(q) * radius * u;
      final fade = (1 - math.pow(q, 1.6)).toDouble();
      final droop = 5 * u * q * q;
      const rays = 14;
      final dot = Paint()..color = color.withValues(alpha: 0.95 * fade);
      final trail = Paint()
        ..color = color.withValues(alpha: 0.35 * fade)
        ..strokeWidth = 0.9 * u
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < rays; i++) {
        final a = i * 2 * math.pi / rays + delay;
        final dir = Offset(math.cos(a), math.sin(a));
        final tip = center + dir * spread + Offset(0, droop);
        final tail = center + dir * spread * 0.55 + Offset(0, droop * 0.5);
        canvas.drawLine(tail, tip, trail);
        canvas.drawCircle(tip, 1.1 * u, dot);
      }
      // kilau di tengah saat baru meledak
      if (q < 0.3) {
        canvas.drawCircle(
          center,
          radius * 0.6 * u,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.5 * (1 - q / 0.3)),
                    color.withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCircle(center: center, radius: radius * 0.6 * u),
                ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) =>
      old.ms != ms ||
      old.season != season ||
      old.phase != phase ||
      old.moonAt != moonAt ||
      old.pingPong != pingPong ||
      old.fireworks != fireworks ||
      old.layer != layer;
}
