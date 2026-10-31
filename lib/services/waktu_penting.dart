import '../models/prayer_models.dart';
import 'prayer_calculator.dart' as calc;

/// Waktu ibadah yang sering ditanyakan, diturunkan dari jadwal sholat yang
/// sudah ada: sepertiga malam terakhir, waktu Dhuha, dan waktu terlarang
/// untuk sholat sunnah mutlak.

/// Dhuha dimulai ±15 menit setelah matahari terbit (setinggi satu tombak).
const dhuhaAfterSunriseMinutes = 15;

/// Waktu istiwa' (matahari tepat di tengah) ±10 menit sebelum Dzuhur.
const istiwaMinutes = 10;

/// Satu rentang waktu.
class TimeSpan {
  const TimeSpan(this.key, this.label, this.start, this.end);

  /// Pengenal tetap: 'third', 'dhuha', 'forbid_fajr', 'forbid_istiwa',
  /// 'forbid_asr'.
  final String key;
  final String label;
  final DateTime start, end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
  Duration get length => end.difference(start);
}

/// Sepertiga malam terakhir untuk malam yang dimulai [maghrib] dan berakhir
/// [nextFajr] (adzan Subuh berikutnya): malam dibagi tiga, sepertiga
/// terakhirnya berakhir tepat saat Subuh.
TimeSpan lastThirdOfNight(DateTime maghrib, DateTime nextFajr) {
  final third = Duration(
    microseconds: nextFajr.difference(maghrib).inMicroseconds ~/ 3,
  );
  return TimeSpan(
    'third',
    'Sepertiga malam terakhir',
    nextFajr.subtract(third),
    nextFajr,
  );
}

class WaktuPenting {
  const WaktuPenting({
    required this.thirdNight,
    required this.dhuha,
    required this.forbidden,
    required this.zone,
  });

  /// Sepertiga malam terakhir untuk malam yang berakhir pada Subuh terdekat
  /// berikutnya (sebelum Subuh = malam tadi; sesudahnya = malam ini).
  final TimeSpan thirdNight;
  final TimeSpan dhuha;

  /// Tiga waktu terlarang hari ini, urut.
  final List<TimeSpan> forbidden;
  final calc.TimezoneCode zone;

  String hm(DateTime d) => calc.formatInZone(d.toUtc(), zone);

  /// Waktu yang sedang berlangsung pada [now] (null bila tidak ada).
  TimeSpan? current(DateTime now) {
    for (final s in [thirdNight, dhuha, ...forbidden]) {
      if (s.contains(now)) return s;
    }
    return null;
  }
}

/// Hitung waktu penting di lokasi ([latitude], [longitude]) pada [now].
/// [date] (bawaan: hari ini di zona lokasi) menentukan hari yang dihitung.
WaktuPenting waktuPenting({
  required DateTime now,
  required double latitude,
  required double longitude,
  DateTime? date,
}) {
  final zone = calc.timezoneFromLongitude(longitude);
  final today = date ?? calc.todayInZone(zone);
  calc.DailyPrayerTimes times(DateTime d) => calc.calculatePrayerTimes(
    latitude: latitude,
    longitude: longitude,
    date: d,
  );

  final t0 = times(today);
  final fajr = t0.times[PrayerKey.fajr]!;
  final TimeSpan third;
  if (now.isBefore(fajr)) {
    // dini hari: malam yang sedang berjalan dimulai Maghrib kemarin
    final yesterday = times(today.subtract(const Duration(days: 1)));
    third = lastThirdOfNight(yesterday.times[PrayerKey.maghrib]!, fajr);
  } else {
    final tomorrow = times(today.add(const Duration(days: 1)));
    third = lastThirdOfNight(
      t0.times[PrayerKey.maghrib]!,
      tomorrow.times[PrayerKey.fajr]!,
    );
  }

  final sunrise = t0.times[PrayerKey.sunrise]!;
  final dhuhr = t0.times[PrayerKey.dhuhr]!;
  final asr = t0.times[PrayerKey.asr]!;
  final maghrib = t0.times[PrayerKey.maghrib]!;
  const after = Duration(minutes: dhuhaAfterSunriseMinutes);
  const istiwa = Duration(minutes: istiwaMinutes);

  return WaktuPenting(
    thirdNight: third,
    dhuha: TimeSpan(
      'dhuha',
      'Waktu Dhuha',
      sunrise.add(after),
      dhuhr.subtract(istiwa),
    ),
    forbidden: [
      TimeSpan(
        'forbid_fajr',
        'Setelah Subuh sampai matahari naik',
        fajr,
        sunrise.add(after),
      ),
      TimeSpan(
        'forbid_istiwa',
        "Saat matahari tepat di tengah (istiwa')",
        dhuhr.subtract(istiwa),
        dhuhr,
      ),
      TimeSpan('forbid_asr', 'Setelah Ashar sampai Maghrib', asr, maghrib),
    ],
    zone: zone,
  );
}
