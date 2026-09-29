import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prayer_models.dart';
import '../pages/hijri_calendar_page.dart';
import '../services/hijri_config_scope.dart';
import '../services/home_widget_service.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import 'location_picker.dart';
import 'sky/seasonal_ornaments.dart';
import 'sky_atmosphere.dart';
import 'sun_position_arc.dart';

/// Kartu jadwal sholat lengkap dengan langit hidup (awan, bintang, layangan,
/// siluet kota & masjid) dan busur matahari - padanan `PrayerTimesCard.tsx` +
/// `SkyAtmosphere.tsx` + `SunPositionArc.tsx` di web.
///
/// Lokasi dibaca dari [UserLocationScope] yang harus sudah membungkus widget
/// ini di atas pohon widget (lihat `main.dart`) - padanan `useUserLocation`
/// di web, dipakai bersama oleh kartu ini dan hitung mundur Ramadan.
class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key, this.hero = false, this.greeting});

  /// Beranda: kartu selebar layar, tembus ke balik status bar, hanya sudut
  /// bawah yang membulat.
  final bool hero;

  /// Sapaan di kepala kartu hero (mis. "Assalamu'alaikum, Ahmad").
  final String? greeting;

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  DateTime? _now;
  Timer? _timer;

  // supaya widget layar utama Android disinkron ulang hanya saat jadwal atau
  // lokasinya benar-benar berubah - bukan tiap detik mengikuti jam berjalan.
  String? _lastSyncedKey;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    if (now == null) {
      return AspectRatio(
        aspectRatio: 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xCCFDE9C8)),
          ),
        ),
      );
    }

    final userLocation = UserLocationScope.of(context).location;
    final schedule = calc.calculatePrayerTimes(
      latitude: userLocation.lat,
      longitude: userLocation.long,
    );
    final next = calc.getNextPrayer(
      schedule,
      latitude: userLocation.lat,
      longitude: userLocation.long,
      now: now,
    );
    final active = calc.getCurrentPrayer(schedule, now);
    final phase = calc.getDayPhase(schedule, now);
    final style = phaseStyle[phase]!;
    final night = style.night;

    final hhmm = calc.formatInZone(
      now.toUtc(),
      schedule.timezone,
      withSeconds: true,
    );
    final clockHHMM = hhmm.substring(0, 5);
    final clockSS = hhmm.substring(6);
    final dateLabel = calc.formatDateInZone(now.toUtc(), schedule.timezone);

    // tanggal hijriah yang berlaku SEKARANG: berganti saat Maghrib, bukan
    // tengah malam - konsisten dengan hitung mundur Ramadan
    final anchors = HijriConfigScope.of(context).config.anchors;
    final hijri = anchors.current(
      now: now,
      todayInZone: schedule.date,
      maghribToday: schedule.times[PrayerKey.maghrib]!,
    );
    final hijriLabel = '(${hijri.format()})';
    // Ramadan / Idulfitri: lampion, ketupat, kembang api di atas langit
    final season = skySeasonOf(hijri);

    // sinkron ke widget layar utama Android - hanya saat lokasi, tanggal
    // (jadi jadwalnya), atau jangkar hijriah berubah, dijadwalkan sesudah
    // frame ini supaya tidak memicu efek samping langsung di tengah build().
    final syncKey =
        '${userLocation.id}-${userLocation.lat}-${userLocation.long}-${schedule.date}-${anchors.fingerprint}';
    if (syncKey != _lastSyncedKey) {
      _lastSyncedKey = syncKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        syncPrayerHomeWidget(
          latitude: userLocation.lat,
          longitude: userLocation.long,
          locationName: userLocation.name,
          hijriAnchors: anchors,
        );
      });
    }

    final hero = widget.hero;
    // hero: isi turun karena status bar - bulan di celah di bawah hitung
    // mundur supaya tidak menutupi teks
    final moonAt = hero ? const Alignment(0.7, 0.02) : null;
    final radius = hero
        ? const BorderRadius.vertical(bottom: Radius.circular(30))
        : BorderRadius.circular(24);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33291E0F),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.bg,
            ),
          ),
          // garis tepi dilukis di atas langit/skyline, bukan di bawahnya
          foregroundDecoration: hero
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: night
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
          child: Stack(
            children: [
              // atmosfer: kabut, awan, bintang, layang-layang, kota+masjid -
              // memenuhi kartu sampai tepi, di luar padding konten
              Positioned.fill(
                child: SkyAtmosphere(
                  phase: phase,
                  hour: int.parse(clockHHMM.substring(0, 2)),
                  // kota & masjid lebih besar, boleh meluber ke samping -
                  // sama dengan widget layar utama
                  tiles: 2,
                  skylineHeightFactor: hero ? 0.3 : 0.34,
                  skylineCover: true,
                  moonAt: moonAt,
                ),
              ),

              // scrim tipis biar teks tetap terbaca di atas busur
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: phaseScrim(night),
                    ),
                  ),
                ),
              ),

              // ornamen musiman di atas scrim (tetap terlihat saat malam),
              // di celah yang kosong dari teks
              if (season != SkySeason.normal)
                Positioned.fill(
                  child: SeasonalOrnaments(
                    season: season,
                    phase: phase,
                    moonAt: moonAt,
                  ),
                ),

              Padding(
                padding: hero
                    ? EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.paddingOf(context).top + 12,
                        20,
                        20,
                      )
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------ header ------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hero && widget.greeting != null)
                          Flexible(
                            child: Text(
                              widget.greeting!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: night
                                    ? Colors.white
                                    : const Color(0xFF1C1917),
                              ),
                            ),
                          )
                        else
                          Text(
                            'JADWAL SHOLAT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: style.accent,
                            ),
                          ),
                        GestureDetector(
                          onTap: () => showLocationPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: night
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.7),
                              border: Border.all(
                                color: night
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: night
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFF44403C),
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 130,
                                  ),
                                  child: Text(
                                    userLocation.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: night
                                          ? const Color(0xFFEEF2FF)
                                          : const Color(0xFF44403C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ------------------------- jam & hitung mundur -------------------------
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // mengecil (bukan terpotong) bila hitung
                                // mundur di kanannya sedang panjang atau
                                // layarnya sempit
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        clockHHMM,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: hero ? 36 : 26,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                          color: night
                                              ? Colors.white
                                              : const Color(0xFF1C1917),
                                        ),
                                      ),
                                      Text(
                                        ':$clockSS',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: hero ? 18 : 14,
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                          color: style.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        calc.tzLabel[schedule.timezone]!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6,
                                          color: night
                                              ? const Color(0xCCC7D2FE)
                                              : const Color(0xFF78716C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const HijriCalendarPage(),
                                      ),
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: '$dateLabel '),
                                          TextSpan(
                                            text: hijriLabel,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: night
                                                  ? const Color(0xCCC7D2FE)
                                                  : style.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: night
                                            ? const Color(0x99C7D2FE)
                                            : const Color(0xFF78716C),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Menuju ${prayerLabels[next.key]}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: night
                                      ? const Color(0xB3C7D2FE)
                                      : const Color(0xFF78716C),
                                ),
                              ),
                              Text(
                                calc.formatCountdown(next.at, now),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: night
                                      ? Colors.white
                                      : const Color(0xFF292524),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ------------------------------ busur matahari ------------------------------
                    SizedBox(
                      height: 68,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SunPositionArc(
                          sunrise: schedule.times[PrayerKey.sunrise]!,
                          sunset: schedule.times[PrayerKey.maghrib]!,
                          current: now,
                          hideAtNight: true,
                        ),
                      ),
                    ),

                    // --------------------------- enam waktu sholat ---------------------------
                    Row(
                      children: [
                        for (final key in cardPrayers) ...[
                          if (key != cardPrayers.first)
                            const SizedBox(width: 4),
                          Expanded(
                            child: _PrayerCell(
                              label: prayerLabels[key]!,
                              time: schedule.labels[key]!,
                              isNext: key == next.key && !next.isTomorrow,
                              isActive: key == active,
                              night: night,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ------------------------------ footer ------------------------------
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Metode Kemenag RI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: night
                                    ? const Color(0x99C7D2FE)
                                    : const Color(0xFF78716C),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: night
                                  ? Colors.white.withOpacity(0.9)
                                  : const Color(0xE61C1917),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 12,
                                  color: night
                                      ? const Color(0xFF1C1917)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Imsakiyah',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: night
                                        ? const Color(0xFF1C1917)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!hero) return card;
    // ikon status bar mengikuti langit: terang saat malam, gelap saat siang
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (night ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: card,
    );
  }
}

class _PrayerCell extends StatelessWidget {
  const _PrayerCell({
    required this.label,
    required this.time,
    required this.isNext,
    required this.isActive,
    required this.night,
  });

  final String label, time;
  final bool isNext, isActive, night;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    if (isNext) {
      bg = const Color(0xFFF59E0B);
      border = Colors.transparent;
    } else if (night) {
      bg = isActive
          ? Colors.white.withOpacity(0.15)
          : Colors.white.withOpacity(0.07);
      border = isActive
          ? Colors.white.withOpacity(0.25)
          : Colors.white.withOpacity(0.1);
    } else {
      bg = isActive
          ? Colors.white.withOpacity(0.85)
          : Colors.white.withOpacity(0.5);
      border = isActive
          ? const Color(0xFFFDE68A)
          : Colors.white.withOpacity(0.6);
    }

    final labelColor = isNext
        ? Colors.white.withOpacity(0.85)
        : night
        ? const Color(0xB3C7D2FE)
        : const Color(0xFF78716C);
    final timeColor = isNext || night ? Colors.white : const Color(0xFF292524);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        gradient: isNext
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              )
            : null,
        color: isNext ? null : bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }
}
