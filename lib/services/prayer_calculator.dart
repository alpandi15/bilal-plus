import 'package:adhan_dart/adhan_dart.dart';

import '../models/prayer_models.dart';

/// Zona waktu Indonesia. Padanan `TimezoneCode`.
enum TimezoneCode { wib, wita, wit }

const Map<TimezoneCode, int> _tzOffset = {
  TimezoneCode.wib: 7,
  TimezoneCode.wita: 8,
  TimezoneCode.wit: 9,
};

const Map<TimezoneCode, String> tzLabel = {
  TimezoneCode.wib: 'WIB',
  TimezoneCode.wita: 'WITA',
  TimezoneCode.wit: 'WIT',
};

/// Perkiraan zona waktu dari bujur - sama seperti `timezoneFromLongitude`,
/// batas 114°BT dan 127°BT sudah tepat untuk hampir semua kabupaten/kota.
TimezoneCode timezoneFromLongitude(double longitude) {
  if (longitude < 114) return TimezoneCode.wib;
  if (longitude < 127) return TimezoneCode.wita;
  return TimezoneCode.wit;
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Format jam pada zona waktu tujuan (bukan zona waktu perangkat). [date]
/// harus berupa waktu UTC absolut (`DateTime.utc` atau `.toUtc()`).
String formatInZone(
  DateTime date,
  TimezoneCode tz, {
  bool withSeconds = false,
}) {
  final shifted = date.toUtc().add(Duration(hours: _tzOffset[tz]!));
  final hhmm = '${_pad2(shifted.hour)}:${_pad2(shifted.minute)}';
  return withSeconds ? '$hhmm:${_pad2(shifted.second)}' : hhmm;
}

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Minggu'];
const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Tanggal pada zona waktu tujuan, misal "Jumat, 4 September".
String formatDateInZone(DateTime date, TimezoneCode tz) {
  final shifted = date.toUtc().add(Duration(hours: _tzOffset[tz]!));
  final namaHari = _hari[shifted.weekday - 1];
  return '$namaHari, ${shifted.day} ${_bulan[shifted.month - 1]}';
}

/// Tanggal kalender (Y/M/D) yang sedang berlaku di zona waktu tujuan.
DateTime todayInZone(TimezoneCode tz, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final shifted = n.toUtc().add(Duration(hours: _tzOffset[tz]!));
  return DateTime.utc(shifted.year, shifted.month, shifted.day);
}

/// Selisih menit imsak sebelum Subuh.
const int imsakOffsetMinutes = 10;

/// Menit pengaman (ihtiyath) Kemenag: +2 untuk seluruh waktu, -2 untuk terbit.
const int kemenagIhtiyathMinutes = 2;

class DailyPrayerTimes {
  final DateTime date;
  final TimezoneCode timezone;
  final Map<PrayerKey, DateTime> times;
  final Map<PrayerKey, String> labels;

  const DailyPrayerTimes({
    required this.date,
    required this.timezone,
    required this.times,
    required this.labels,
  });
}

DateTime _shiftMinutes(DateTime date, int minutes) =>
    date.add(Duration(minutes: minutes));

/// Menghitung jadwal sholat satu hari memakai sudut Kemenag RI (Subuh 20°,
/// Isya 18°, madzhab Syafi'i) lewat paket `adhan_dart` - padanan langsung
/// `calculatePrayerTimes` yang di web memakai paket `adhan` (npm), keduanya
/// port dari algoritma astronomi yang sama (batoulapps/PrayTimes).
DailyPrayerTimes calculatePrayerTimes({
  required double latitude,
  required double longitude,
  DateTime? date,
  bool ihtiyath = true,
}) {
  final tz = timezoneFromLongitude(longitude);
  final target = date ?? todayInZone(tz);

  final params = CalculationMethodParameters.other();
  params.fajrAngle = 20;
  params.ishaAngle = 18;
  params.madhab = Madhab.shafi;

  final coordinates = Coordinates(latitude, longitude);
  final raw = PrayerTimes(
    date: DateTime.utc(target.year, target.month, target.day),
    coordinates: coordinates,
    calculationParameters: params,
  );

  final pad = ihtiyath ? kemenagIhtiyathMinutes : 0;

  final times = <PrayerKey, DateTime>{
    PrayerKey.imsak: _shiftMinutes(raw.fajr, pad - imsakOffsetMinutes),
    PrayerKey.fajr: _shiftMinutes(raw.fajr, pad),
    PrayerKey.sunrise: _shiftMinutes(raw.sunrise, -pad),
    PrayerKey.dhuhr: _shiftMinutes(raw.dhuhr, pad),
    PrayerKey.asr: _shiftMinutes(raw.asr, pad),
    PrayerKey.maghrib: _shiftMinutes(raw.maghrib, pad),
    PrayerKey.isha: _shiftMinutes(raw.isha, pad),
  };

  final labels = times.map(
    (key, value) => MapEntry(key, formatInZone(value, tz)),
  );

  return DailyPrayerTimes(
    date: target,
    timezone: tz,
    times: times,
    labels: labels,
  );
}

class NextPrayer {
  final PrayerKey key;
  final DateTime at;
  final bool isTomorrow;

  const NextPrayer({
    required this.key,
    required this.at,
    required this.isTomorrow,
  });
}

/// Waktu sholat berikutnya. Bila Isya sudah lewat, berikutnya adalah Subuh
/// besok - jadwal hari berikutnya ikut dihitung.
NextPrayer getNextPrayer(
  DailyPrayerTimes schedule, {
  required double latitude,
  required double longitude,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  for (final key in cardPrayers) {
    if (schedule.times[key]!.isAfter(n)) {
      return NextPrayer(key: key, at: schedule.times[key]!, isTomorrow: false);
    }
  }

  final tomorrow = calculatePrayerTimes(
    latitude: latitude,
    longitude: longitude,
    date: schedule.date.add(const Duration(days: 1)),
  );

  return NextPrayer(
    key: PrayerKey.fajr,
    at: tomorrow.times[PrayerKey.fajr]!,
    isTomorrow: true,
  );
}

/// Waktu sholat yang sedang berlangsung sekarang.
PrayerKey getCurrentPrayer(DailyPrayerTimes schedule, [DateTime? now]) {
  final n = now ?? DateTime.now();
  var current = PrayerKey.isha;
  for (final key in cardPrayers) {
    if (!schedule.times[key]!.isAfter(n)) current = key;
  }
  return current;
}

/// Sisa waktu menuju [target] dalam format HH:MM:SS.
String formatCountdown(DateTime target, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final diff = target.difference(n);
  final totalSeconds = diff.isNegative ? 0 : diff.inSeconds;

  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${_pad2(h)}:${_pad2(m)}:${_pad2(s)}';
}

/// Fase hari (untuk gradasi langit), dari jadwal & waktu sekarang.
DayPhase getDayPhase(DailyPrayerTimes schedule, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final fajr = schedule.times[PrayerKey.fajr]!;
  final sunrise = schedule.times[PrayerKey.sunrise]!;
  final dhuhr = schedule.times[PrayerKey.dhuhr]!;
  final asr = schedule.times[PrayerKey.asr]!;
  final maghrib = schedule.times[PrayerKey.maghrib]!;

  if (n.isBefore(fajr)) return DayPhase.night;
  if (n.isBefore(sunrise)) return DayPhase.dawn;
  if (n.isBefore(dhuhr)) return DayPhase.morning;
  if (n.isBefore(asr)) return DayPhase.noon;
  if (n.isBefore(maghrib)) return DayPhase.dusk;
  return DayPhase.night;
}
