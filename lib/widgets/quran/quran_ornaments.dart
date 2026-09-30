import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/quran_text.dart';
import '../arabic_font.dart';

/// Warna ornamen mushaf (merah marun & emas di atas kertas krem).
const mushafPaper = Color(0xFFFFFDF2);
const mushafGold = Color(0xFFC9A24A);
const mushafRed = Color(0xFFB4233A);
const mushafInk = Color(0xFF1C1917);

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// 12 -> "١٢".
String arabicNumber(int n) =>
    n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();

/// Medali nomor ayat: lingkaran emas dengan delapan kelopak merah.
class AyahMedallion extends StatelessWidget {
  const AyahMedallion({
    super.key,
    required this.number,
    required this.size,
    this.arabicDigits = true,
  });

  final int number;
  final double size;

  /// Angka Arab-Indik (mushaf) atau angka biasa (mode per surah).
  final bool arabicDigits;

  @override
  Widget build(BuildContext context) {
    final label = arabicDigits ? arabicNumber(number) : '$number';
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedallionPainter(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: FittedBox(
              child: Text(
                label,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: arabicDigits ? arabicFont : null,
                  fontSize: size * 0.42,
                  height: 1,
                  fontWeight: arabicDigits ? null : FontWeight.w800,
                  color: const Color(0xFF7F1D1D),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // kelopak merah di delapan arah
    final petal = Paint()..color = mushafRed;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * r * 0.86;
      canvas.drawCircle(p, r * (i.isEven ? 0.16 : 0.11), petal);
    }
    // cincin emas & isi krem
    canvas.drawCircle(c, r * 0.74, Paint()..color = mushafGold);
    canvas.drawCircle(c, r * 0.64, Paint()..color = mushafPaper);
    canvas.drawCircle(
      c,
      r * 0.56,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.05)
        ..color = mushafRed.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_MedallionPainter oldDelegate) => false;
}

/// Spanduk awal surah: nama surah di tengah, Makkiyah/Madaniyah di kanan,
/// jumlah ayat di kiri - diapit roset.
class SurahBanner extends StatelessWidget {
  const SurahBanner({super.key, required this.surah, this.height = 58});
  final QuranSurah surah;
  final double height;

  @override
  Widget build(BuildContext context) {
    final side = TextStyle(
      fontFamily: arabicFont,
      fontSize: height * 0.26,
      height: 1.2,
      color: mushafInk,
    );
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BannerPainter(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              SizedBox(
                width: height * 1.4,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      surah.makkiyah ? 'مَكِّيَّةٌ' : 'مَدَنِيَّةٌ',
                      style: side,
                    ),
                  ),
                ),
              ),
              // ruang roset
              SizedBox(width: height * 0.6),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: height * 0.3),
                      child: Text(
                        'سُوْرَةُ ${surah.arabic}',
                        style: TextStyle(
                          fontFamily: arabicFont,
                          fontSize: height * 0.4,
                          height: 1.3,
                          color: mushafInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: height * 0.6),
              SizedBox(
                width: height * 1.4,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'اٰيَاتُهَا ${arabicNumber(surah.ayahCount)}',
                      style: side,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final rect = Offset.zero & size;

    // dasar krem-emas dengan bingkai ganda
    final bg = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.18));
    canvas.drawRRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF7E9C4), Color(0xFFFFF8E4), Color(0xFFF7E9C4)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      bg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = mushafGold,
    );
    canvas.drawRRect(
      bg.deflate(h * 0.09),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = mushafRed.withValues(alpha: 0.6),
    );

    // kapsul tengah untuk nama surah
    final capsule = RRect.fromLTRBR(
      h * 2.0,
      h * 0.2,
      size.width - h * 2.0,
      h * 0.8,
      Radius.circular(h * 0.3),
    );
    canvas.drawRRect(capsule, Paint()..color = const Color(0xFFFFFDF2));
    canvas.drawRRect(
      capsule,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = mushafGold,
    );

    // roset di kedua sisi kapsul
    for (final x in [h * 1.7, size.width - h * 1.7]) {
      _rosette(canvas, Offset(x, h / 2), h * 0.26);
    }
  }

  void _rosette(Canvas canvas, Offset c, double r) {
    final petal = Paint()..color = mushafRed;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.62,
        r * 0.34,
        petal,
      );
    }
    canvas.drawCircle(c, r * 0.5, Paint()..color = mushafGold);
    canvas.drawCircle(c, r * 0.24, Paint()..color = const Color(0xFFFFF8E4));
  }

  @override
  bool shouldRepaint(_BannerPainter oldDelegate) => false;
}

/// Basmalah di awal surah (kecuali Al-Fatihah - sudah ayat 1 - & At-Taubah).
class BasmalahLine extends StatelessWidget {
  const BasmalahLine({super.key, required this.fontSize, this.uthmani = false});
  final double fontSize;

  /// Rasm Utsmani & font Hafs (mode Mushaf).
  final bool uthmani;

  static const msi = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ';
  static const uthmaniText = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

  @override
  Widget build(BuildContext context) => uthmani
      ? Text(
          uthmaniText,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: uthmanicFont,
            fontSize: fontSize,
            height: 1.9,
            color: mushafInk,
          ),
        )
      : ArabicText(
          msi,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize, height: 1.9, color: mushafInk),
        );
}

/// Geometri bingkai halaman mushaf (dp) - dipakai painter & tata letak isi.
/// Seperti mushaf cetak: pita ornamen di atas, bawah & SISI LUAR halaman
/// (halaman ganjil: kanan, genap: kiri), sisi punggung hanya garis lurus.
abstract final class MushafFrame {
  /// Jarak pita dari tepi kertas.
  static const inset = 3.0;

  /// Tebal pita sisi luar & bawah.
  static const band = 14.0;

  /// Tebal pita atas - memuat label juz, halaman & surah.
  static const topBand = 26.0;

  /// Garis punggung dari tepi kertas.
  static const spine = 6.0;

  /// Pusat pita sisi luar dari tepi kertas (tempat kotak tanda 'ain).
  static const bandCenter = inset + band / 2;

  /// Jarak isi halaman dari tepi kertas.
  static EdgeInsets contentPadding({required bool outerRight}) {
    const outer = inset + band + 8, inner = spine + 9;
    return EdgeInsets.fromLTRB(
      outerRight ? inner : outer,
      inset + topBand + 6,
      outerRight ? outer : inner,
      inset + band + 6,
    );
  }
}

/// Bingkai halaman mushaf: pita bermotif bunga merah-emas di atas, bawah &
/// sisi luar ([outerRight]), roset di sudut, dan garis lurus di punggung.
class MushafFramePainter extends CustomPainter {
  const MushafFramePainter({required this.outerRight});

  /// Halaman ganjil: pita ornamen di kanan; genap: di kiri.
  final bool outerRight;

  static const _bandFill = Color(0xFFFBEFD2);

  @override
  void paint(Canvas canvas, Size size) {
    const i = MushafFrame.inset;
    final w = size.width, h = size.height;
    final top = Rect.fromLTRB(i, i, w - i, i + MushafFrame.topBand);
    final bottom = Rect.fromLTRB(i, h - i - MushafFrame.band, w - i, h - i);
    final side = outerRight
        ? Rect.fromLTRB(w - i - MushafFrame.band, top.bottom, w - i, bottom.top)
        : Rect.fromLTRB(i, top.bottom, i + MushafFrame.band, bottom.top);

    // punggung: garis lurus merah & emas di antara pita atas dan bawah
    final sx = outerRight ? MushafFrame.spine : w - MushafFrame.spine;
    final dir = outerRight ? 1 : -1;
    canvas.drawLine(
      Offset(sx - dir * 2.5, top.bottom),
      Offset(sx - dir * 2.5, bottom.top),
      Paint()
        ..color = mushafRed.withValues(alpha: 0.85)
        ..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(sx + dir * 1.5, top.bottom),
      Offset(sx + dir * 1.5, bottom.top),
      Paint()
        ..color = mushafGold
        ..strokeWidth = 1,
    );

    _band(canvas, top, horizontal: true);
    _band(canvas, bottom, horizontal: true);
    _band(canvas, side, horizontal: false);

    // roset di sudut pertemuan pita sisi luar
    final ox = outerRight
        ? w - i - MushafFrame.band / 2
        : i + MushafFrame.band / 2;
    _rosette(canvas, Offset(ox, top.bottom), MushafFrame.band * 0.5);
    _rosette(canvas, Offset(ox, bottom.top), MushafFrame.band * 0.5);
  }

  /// Pita: dasar krem, tepi emas, garis luar merah, motif bunga berulang.
  void _band(Canvas canvas, Rect r, {required bool horizontal}) {
    canvas.drawRect(r, Paint()..color = _bandFill);
    canvas.drawRect(
      r.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = mushafGold,
    );
    canvas.drawRect(
      r.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = mushafRed.withValues(alpha: 0.45),
    );
    final thick = horizontal ? r.height : r.width;
    final len = horizontal ? r.width : r.height;
    final r0 = (thick < 20 ? thick : 14.0) * 0.16;
    final step = r0 * 6.2;
    final count = (len / step).floor();
    final start = (len - (count - 1) * step) / 2;
    final petal = Paint()..color = mushafRed.withValues(alpha: 0.85);
    final gold = Paint()..color = mushafGold;
    for (var k = 0; k < count; k++) {
      final t = start + k * step;
      final c = horizontal
          ? Offset(r.left + t, r.center.dy)
          : Offset(r.center.dx, r.top + t);
      // bunga empat kelopak + titik emas di antaranya
      for (var q = 0; q < 4; q++) {
        final a = q * math.pi / 2 + math.pi / 4;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r0 * 1.05,
          r0 * 0.62,
          petal,
        );
      }
      canvas.drawCircle(c, r0 * 0.55, gold);
      if (k < count - 1) {
        final m = horizontal
            ? c + Offset(step / 2, 0)
            : c + Offset(0, step / 2);
        canvas.drawCircle(m, r0 * 0.32, gold);
      }
    }
  }

  void _rosette(Canvas canvas, Offset c, double r) {
    final petal = Paint()..color = mushafRed;
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.62,
        r * 0.3,
        petal,
      );
    }
    canvas.drawCircle(c, r * 0.46, Paint()..color = mushafGold);
    canvas.drawCircle(c, r * 0.22, Paint()..color = _bandFill);
  }

  @override
  bool shouldRepaint(MushafFramePainter oldDelegate) =>
      oldDelegate.outerRight != outerRight;
}

/// "Akhir ruku' ke-3 Al-Baqarah · 7 ayat · ruku' ke-5 juz 1".
String rukuLabel(RukuMark r, String surahName, int juz) =>
    "Akhir ruku' ke-${r.inSurah} $surahName · ${r.ayahCount} ayat · "
    "ruku' ke-${r.inJuz} juz $juz";

/// Tanda 'ain (ع) akhir ruku' seperti di mushaf cetak: huruf 'ain merah marun
/// dengan tiga angka kecil - atas: ruku' ke-n dalam surah, kanan: jumlah
/// ayatnya, bawah: ruku' ke-n dalam juz. [size] = tinggi keseluruhan.
/// Memakai font Arab sistem - metrik vertikal LPMQ terlalu tinggi untuk
/// disusun rapat seperti ini.
class RukuSign extends StatelessWidget {
  const RukuSign({super.key, required this.mark, required this.size});
  final RukuMark mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    Text digits(int n) => Text(
      arabicNumber(n),
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontSize: size * 0.26,
        height: 1,
        fontWeight: FontWeight.w700,
        color: mushafInk,
      ),
    );
    return SizedBox(
      width: size * 1.1,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          digits(mark.inSurah),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'ع',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: size * 0.46,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: mushafRed,
                ),
              ),
              SizedBox(width: size * 0.06),
              digits(mark.ayahCount),
            ],
          ),
          digits(mark.inJuz),
        ],
      ),
    );
  }
}
