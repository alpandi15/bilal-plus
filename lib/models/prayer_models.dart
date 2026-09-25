import 'package:flutter/material.dart';

/// Lima fase hari yang menentukan rupa langit & warna kartu. Padanan
/// `DayPhase` di `src/utils/prayerTimes.ts`.
enum DayPhase { dawn, morning, noon, dusk, night }

/// Tujuh waktu yang dihitung. Padanan `PrayerKey`.
enum PrayerKey { imsak, fajr, sunrise, dhuhr, asr, maghrib, isha }

const Map<PrayerKey, String> prayerLabels = {
  PrayerKey.imsak: 'Imsak',
  PrayerKey.fajr: 'Subuh',
  PrayerKey.sunrise: 'Terbit',
  PrayerKey.dhuhr: 'Dzuhur',
  PrayerKey.asr: 'Ashar',
  PrayerKey.maghrib: 'Maghrib',
  PrayerKey.isha: 'Isya',
};

/// Enam yang tampil di kartu (tanpa Imsak). Padanan `CARD_PRAYERS`.
const List<PrayerKey> cardPrayers = [
  PrayerKey.fajr,
  PrayerKey.sunrise,
  PrayerKey.dhuhr,
  PrayerKey.asr,
  PrayerKey.maghrib,
  PrayerKey.isha,
];

/// Gaya kartu per fase hari. Padanan `PHASE_STYLE` di phaseStyle.ts.
class PhaseStyle {
  final List<Color> bg;
  final Color accent;
  final bool night;

  const PhaseStyle({
    required this.bg,
    required this.accent,
    required this.night,
  });
}

const Map<DayPhase, PhaseStyle> phaseStyle = {
  DayPhase.dawn: PhaseStyle(
    bg: [Color(0xFFFFF5EB), Color(0xFFFFE8CF), Color(0xFFFFDCBB)],
    accent: Color(0xFFB45309),
    night: false,
  ),
  DayPhase.morning: PhaseStyle(
    bg: [Color(0xFFFFFDF7), Color(0xFFFFF4E0), Color(0xFFFFEACB)],
    accent: Color(0xFFB45309),
    night: false,
  ),
  DayPhase.noon: PhaseStyle(
    bg: [Color(0xFFF6FCFF), Color(0xFFE9F5FF), Color(0xFFDCECFB)],
    accent: Color(0xFF0369A1),
    night: false,
  ),
  DayPhase.dusk: PhaseStyle(
    bg: [Color(0xFFFFF1E6), Color(0xFFFFDEC6), Color(0xFFFFCAA8)],
    accent: Color(0xFFC2410C),
    night: false,
  ),
  DayPhase.night: PhaseStyle(
    bg: [Color(0xFF16233D), Color(0xFF1D2B4A), Color(0xFF25325A)],
    accent: Color(0xFFC7D2FE),
    night: true,
  ),
};

/// Scrim tipis supaya teks tetap terbaca di atas busur matahari.
List<Color> phaseScrim(bool night) => night
    ? [
        const Color(0xFF16233D).withOpacity(0.78),
        const Color(0xFF16233D).withOpacity(0.10),
        const Color(0xFF16233D).withOpacity(0.22),
      ]
    : [
        Colors.white.withOpacity(0.70),
        Colors.white.withOpacity(0.04),
        Colors.white.withOpacity(0.22),
      ];
