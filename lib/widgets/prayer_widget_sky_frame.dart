import 'package:flutter/material.dart';

import '../models/prayer_models.dart';
import 'sky/seasonal_ornaments.dart';
import 'sky_atmosphere.dart';

/// Satu frame beku lapisan latar kartu jadwal sholat - gradasi fase hari +
/// atmosfer langit + scrim - persis tiga lapisan terbawah [PrayerTimesCard],
/// tanpa teks. Dirender offscreen jadi PNG untuk widget layar utama Android
/// (lihat `home_widget_service_io.dart`); teks, jam, busur matahari, dan sel
/// sholatnya digambar native oleh `PrayerWidgetProvider.kt` di atas gambar
/// ini.
class PrayerWidgetSkyFrame extends StatelessWidget {
  const PrayerWidgetSkyFrame({
    super.key,
    required this.phase,
    required this.quiet,
    required this.clockMs,
    required this.size,
  });

  final DayPhase phase;

  /// Malam larut (>= 22:00 atau < 04:00): lampu kota hampir semua padam.
  final bool quiet;
  final double clockMs;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final style = phaseStyle[phase]!;
    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style.bg,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SkyAtmosphere(
                phase: phase,
                hour: quiet ? 23 : 20,
                clockMs: clockMs,
                creatures: false,
                // kota dibuat besar: satu petak, skala mengikuti tinggi,
                // meluber ke kiri-kanan lalu dipotong tepi kartu
                tiles: 1,
                skylineHeightFactor: 0.38,
                skylineCover: true,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: phaseScrim(style.night),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu lapisan ornamen musiman SAJA (latar transparan) untuk widget layar
/// utama - lampion/ketupat ([OrnamentLayer.hangers]) atau kembang api
/// ([OrnamentLayer.fireworks]) di kanvas kecil. `PrayerWidgetProvider.kt`
/// menempatkannya di celah teks yang sebenarnya (lebar judul & pil lokasi
/// berbeda-beda), jadi atlas langit biasa tidak perlu dirender ulang saat
/// Ramadan/Idulfitri tiba.
class PrayerWidgetOrnamentFrame extends StatelessWidget {
  const PrayerWidgetOrnamentFrame({
    super.key,
    required this.season,
    required this.night,
    required this.layer,
    required this.clockMs,
  });

  final SkySeason season;
  final bool night;
  final OrnamentLayer layer;
  final double clockMs;

  Size get size =>
      layer == OrnamentLayer.fireworks ? fireworksStripSize : hangersStripSize;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: SeasonalOrnaments(
      season: season,
      phase: night ? DayPhase.night : DayPhase.noon,
      clockMs: clockMs,
      pingPong: true,
      layer: layer,
      fireworks: true,
    ),
  );
}
