import 'package:flutter/material.dart';

import '../models/prayer_models.dart';
import '../utils/sky_clock.dart';
import 'sky/birds.dart';
import 'sky/clouds.dart';
import 'sky/kite.dart';
import 'sky/moon.dart';
import 'sky/skyline.dart';
import 'sky/starfield.dart';

class _SkyVisual {
  final Color cloud, shade;
  final double cloudOpacity;
  final List<Color> haze;
  final List<double> hazeStops;
  final bool starfield;

  const _SkyVisual({
    required this.cloud,
    required this.shade,
    required this.cloudOpacity,
    required this.haze,
    required this.hazeStops,
    required this.starfield,
  });
}

/// Rupa langit per fase hari. Padanan `SKY` di SkyAtmosphere.tsx.
const Map<DayPhase, _SkyVisual> _sky = {
  DayPhase.dawn: _SkyVisual(
    cloud: Color(0xFFFFF1E3),
    shade: Color(0xFFEDA877),
    cloudOpacity: 0.85,
    haze: [Color(0x57FFCE9E), Color(0x00FFFFFF), Color(0x42FFAA69)],
    hazeStops: [0, 0.46, 1],
    starfield: false,
  ),
  DayPhase.morning: _SkyVisual(
    cloud: Color(0xFFFFFFFF),
    shade: Color(0xFFB9CFE6),
    cloudOpacity: 0.9,
    haze: [Color(0x66FFFFFF), Color(0x00FFFFFF), Color(0x33FFDDAA)],
    hazeStops: [0, 0.55, 1],
    starfield: false,
  ),
  DayPhase.noon: _SkyVisual(
    cloud: Color(0xFFFFFFFF),
    shade: Color(0xFF9DC2E4),
    cloudOpacity: 0.95,
    haze: [Color(0x6BACD8FF), Color(0x00FFFFFF), Color(0x47D6EEFF)],
    hazeStops: [0, 0.58, 1],
    starfield: false,
  ),
  DayPhase.dusk: _SkyVisual(
    cloud: Color(0xFFFFE0C4),
    shade: Color(0xFFE08A52),
    cloudOpacity: 0.82,
    haze: [Color(0x42FFBC8C), Color(0x00FFFFFF), Color(0x57FF8A58)],
    hazeStops: [0, 0.40, 1],
    starfield: false,
  ),
  DayPhase.night: _SkyVisual(
    cloud: Color(0xFF33456F),
    shade: Color(0xFF131D36),
    cloudOpacity: 0.4,
    haze: [Color(0x7A0A1224), Color(0x000A1224), Color(0x6B0A1224)],
    hazeStops: [0, 0.45, 1],
    starfield: true,
  ),
};

/// Ukuran benda langit untuk variant "card" (dipakai di kartu jadwal sholat).
class SkySizing {
  static const double moon = 38;
  static const Alignment moonAt = Alignment(0.56, -0.14); // ~78%,43%
  static const double bird = 22;
  static const double meteor = 72;
  static const double kite = 26;
  static const Alignment kiteAt = Alignment(-0.72, -0.06); // ~14%,47%
}

/// Lapisan atmosfer yang menyelimuti seluruh kartu jadwal sholat - kabut
/// langit, awan berarak, dan (saat malam) bintang berkelip serta siluet kota
/// dengan masjid. Padanan `SkyAtmosphere` (SkyAtmosphere.tsx).
class SkyAtmosphere extends StatelessWidget {
  const SkyAtmosphere({
    super.key,
    required this.phase,
    this.hour,
    this.kiteAt,
    this.tiles = 3,
    this.clockMs,
    this.creatures = true,
    this.skylineHeightFactor = 0.26,
    this.skylineCover = false,
    this.moonAt,
  });

  /// Posisi bulan (null = [SkySizing.moonAt]).
  final Alignment? moonAt;

  final DayPhase phase;

  /// Bekukan animasi di milidetik ini (lihat [SkyClockProvider.clockMs]).
  final double? clockMs;

  /// Burung, layang-layang, bintang jatuh - gerak cepat yang hanya cocok
  /// untuk animasi sungguhan. Dimatikan pada frame widget layar utama yang
  /// cuma disilangkan pelan antar beberapa pose.
  final bool creatures;

  /// Tinggi siluet kota sebagai pecahan tinggi kartu, dan apakah kotanya
  /// boleh meluber ke samping (lihat [SkylinePainter.cover]).
  final double skylineHeightFactor;
  final bool skylineCover;

  /// Jam setempat (0-23). Lewat pukul 22:00 lampu kota hampir semuanya padam.
  final int? hour;

  final Alignment? kiteAt;

  /// Berapa petak kota diulang mengisi lebar kartu.
  final int tiles;

  @override
  Widget build(BuildContext context) {
    final sky = _sky[phase]!;
    final quiet = hour != null && (hour! >= 22 || hour! < 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = constraints.biggest;

        return ClipRect(
          child: SkyClockProvider(
            clockMs: clockMs,
            builder: (context, clock) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // kabut atmosfer
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: sky.haze,
                          stops: sky.hazeStops,
                        ),
                      ),
                    ),
                  ),

                  // burung pulang, hanya sore hari
                  if (creatures && phase == DayPhase.dusk)
                    Birds(
                      clock: clock,
                      cardSize: cardSize,
                      birdBaseWidth: SkySizing.bird,
                    ),

                  // benda langit jauh
                  if (sky.starfield) ...[
                    Starfield(
                      clock: clock,
                      cardSize: cardSize,
                      starDiameter:
                          2, // dikali r masing-masing (r rata2 ~1.2 -> ~2-3px)
                      meteorWidth: SkySizing.meteor,
                      meteors: creatures,
                    ),
                    Moon(
                      clock: clock,
                      size: SkySizing.moon,
                      cardSize: cardSize,
                      at: moonAt ?? SkySizing.moonAt,
                    ),
                  ],

                  // awan berarak
                  CloudLayer(
                    clock: clock,
                    cardSize: cardSize,
                    cloudColor: sky.cloud,
                    shadeColor: sky.shade,
                    baseOpacity: sky.cloudOpacity,
                    cloudWidthMultiplier: 1,
                  ),

                  // layang-layang: siang & sore
                  if (creatures &&
                      (phase == DayPhase.noon || phase == DayPhase.dusk))
                    Builder(
                      builder: (context) {
                        final at = kiteAt ?? SkySizing.kiteAt;
                        final leftPct = (at.x + 1) / 2;
                        final topPct = (at.y + 1) / 2;
                        return Positioned(
                          left: leftPct * cardSize.width - SkySizing.kite / 2,
                          top: topPct * cardSize.height - SkySizing.kite / 2,
                          child: Kite(
                            clock: clock,
                            size: SkySizing.kite,
                            tone: phase == DayPhase.dusk ? 'dusk' : 'noon',
                          ),
                        );
                      },
                    ),

                  // kota: digambar paling akhir supaya menutupi awan di belakangnya
                  if (sky.starfield) ...[
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cardSize.height * (skylineHeightFactor + 0.08),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xFFFFB75E).withOpacity(quiet ? 0.08 : 0.2),
                              Color(
                                0xFFFFB75E,
                              ).withOpacity(quiet ? 0.02 : 0.06),
                              const Color(0x00FFB75E),
                            ],
                            stops: const [0, 0.42, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cardSize.height * skylineHeightFactor,
                      child: CustomPaint(
                        painter: SkylinePainter(
                          tiles: tiles,
                          quiet: quiet,
                          clockMs: clock.ms,
                          cover: skylineCover,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
