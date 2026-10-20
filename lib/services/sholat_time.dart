import '../models/prayer_models.dart';
import 'prayer_calculator.dart' as calc;

/// Ketepatan waktu sholat wajib - dihitung dari jadwal sholat saat
/// ditampilkan, tidak disimpan (yang disimpan hanya jam dikerjakan).
enum SholatStatus {
  /// paling lambat [onTimeMinutes] menit sesudah adzan
  onTime,

  /// sesudah itu, tapi masih di dalam waktunya
  late,

  /// sesudah waktunya habis, tanpa uzur (atau alasannya belum dipilih)
  qadha,

  /// dijamak dengan pasangannya saat safar - dikerjakan di waktu sholat
  /// pasangannya, sah & bukan qadha
  jamak,

  /// qadha karena uzur syar'i (tertidur, lupa, ...) - tidak berdosa,
  /// kaffaratnya menunaikan saat ingat (HR. Muslim no. 1103)
  uzur,
}

const sholatStatusLabel = {
  SholatStatus.onTime: 'Awal waktu',
  SholatStatus.late: 'Terlambat',
  SholatStatus.qadha: 'Qadha',
  SholatStatus.jamak: 'Jamak',
  SholatStatus.uzur: 'Qadha (uzur)',
};

/// Alasan qadha yang bisa dipilih. Semua selain 'tanpa' adalah uzur yang
/// dibenarkan syariat: tertidur & lupa (HR. Muslim no. 1103 & 1099), hilang
/// kesadaran, keadaan darurat, dan perjalanan yang benar-benar tidak
/// memungkinkan sholat (bila masih bisa dijamak, pilih Jamak).
const qadhaReasons = {
  'tertidur': 'Tertidur',
  'lupa': 'Lupa',
  'pingsan': 'Pingsan / tak sadar',
  'perjalanan': 'Perjalanan',
  'darurat': 'Darurat',
  'tanpa': 'Tanpa uzur',
};

/// Nilai sholat qadha tanpa uzur dibanding yang tepat waktu - tetap wajib
/// diqadha & tetap dihitung, tapi tidak penuh sebagai pengingat.
const qadhaNoUzurWeight = 0.5;

/// Sholat yang bisa diqashar (empat rakaat menjadi dua).
const qasharPrayers = {'dzuhur', 'ashar', 'isya'};

/// Pasangan jamak: Dzuhur-Ashar & Maghrib-Isya.
const jamakPair = {
  'dzuhur': 'ashar',
  'ashar': 'dzuhur',
  'maghrib': 'isya',
  'isya': 'maghrib',
};

/// Tempat sholat yang bisa dipilih.
const sholatPlaces = ['masjid', 'rumah', 'lainnya'];
const sholatPlaceLabel = {
  'masjid': 'Masjid',
  'rumah': 'Rumah',
  'lainnya': 'Lainnya',
};

/// Nilai sholat wajib sendiri dibanding berjama'ah (= 1): "Sholat
/// berjama'ah lebih utama dari sholat sendirian dengan dua puluh tujuh
/// derajat" (HR. Al-Bukhari & Muslim) - jadi bawaannya 1/27.
const hadithSoloWeight = 1 / 27;

/// Pilihan nilai sholat sendiri di Pengaturan.
const soloWeightChoices = [hadithSoloWeight, 0.25, 0.5, 0.75, 1.0];

/// "1/27 (≈4%)", "50%", ...
String soloWeightLabel(double w) => w == hadithSoloWeight
    ? '1/27 (≈${(w * 100).round()}%)'
    : '${(w * 100).round()}%';

/// Bobot satu sholat wajib yang sudah dikerjakan: berjama'ah atau belum
/// tercatat = 1, sendiri = [soloWeight].
double sholatWeight(bool? jamaah, double soloWeight, {String? qadhaReason}) =>
    (jamaah == false ? soloWeight : 1) *
    (qadhaReason == 'tanpa' ? qadhaNoUzurWeight : 1);

/// Batas bawaan "awal waktu", menit sesudah adzan.
const defaultOnTimeMinutes = 15;

/// Waktu satu sholat wajib: dari adzan ([start]) sampai waktunya habis
/// ([end]) - Subuh sampai terbit, Dzuhur sampai Ashar, Ashar sampai
/// Maghrib, Maghrib sampai Isya, Isya sampai Subuh esok hari.
class SholatWindow {
  const SholatWindow(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

/// Kunci item sholat wajib -> waktu adzannya di jadwal.
const sholatPrayerKey = {
  'subuh': PrayerKey.fajr,
  'dzuhur': PrayerKey.dhuhr,
  'ashar': PrayerKey.asr,
  'maghrib': PrayerKey.maghrib,
  'isya': PrayerKey.isha,
};

const _endKey = {
  'subuh': PrayerKey.sunrise,
  'dzuhur': PrayerKey.asr,
  'ashar': PrayerKey.maghrib,
  'maghrib': PrayerKey.isha,
};

/// Waktu sholat [key] dari jadwal hari itu ([today]) - Isya memerlukan
/// jadwal esok hari ([tomorrow]) untuk akhir waktunya. Null bila [key]
/// bukan sholat wajib.
SholatWindow? sholatWindowFrom(
  String key,
  calc.DailyPrayerTimes today,
  calc.DailyPrayerTimes Function() tomorrow,
) {
  final start = sholatPrayerKey[key];
  if (start == null) return null;
  final end = key == 'isya'
      ? tomorrow().times[PrayerKey.fajr]!
      : today.times[_endKey[key]]!;
  return SholatWindow(today.times[start]!, end);
}

/// Waktu sholat [key] ('subuh'..'isya') pada tanggal [date] (Y/M/D, UTC
/// tengah malam seperti `todayInZone`). Null bila bukan sholat wajib.
SholatWindow? sholatWindow(
  String key,
  DateTime date, {
  required double latitude,
  required double longitude,
}) => sholatWindowFrom(
  key,
  calc.calculatePrayerTimes(
    latitude: latitude,
    longitude: longitude,
    date: date,
  ),
  () => calc.calculatePrayerTimes(
    latitude: latitude,
    longitude: longitude,
    date: date.add(const Duration(days: 1)),
  ),
);

/// Status sholat dari jam dikerjakan. [jamak]: dikerjakan di waktu
/// pasangannya (taqdim sebelum waktunya, ta'khir sesudahnya) = Jamak.
/// [qadhaReason] selain 'tanpa' menjadikan qadha sebagai qadha karena uzur.
SholatStatus sholatStatus(
  DateTime prayedAt,
  SholatWindow window, {
  int onTimeMinutes = defaultOnTimeMinutes,
  bool jamak = false,
  String? qadhaReason,
}) {
  final outside =
      prayedAt.isBefore(window.start) || !prayedAt.isBefore(window.end);
  if (jamak && outside) return SholatStatus.jamak;
  if (!prayedAt.isAfter(window.start.add(Duration(minutes: onTimeMinutes)))) {
    return SholatStatus.onTime;
  }
  if (prayedAt.isBefore(window.end)) return SholatStatus.late;
  return qadhaReason != null && qadhaReason != 'tanpa'
      ? SholatStatus.uzur
      : SholatStatus.qadha;
}

/// Menit keterlambatan dari adzan (0 bila sebelum/tepat adzan).
int minutesAfterAdzan(DateTime prayedAt, SholatWindow window) =>
    prayedAt.difference(window.start).inMinutes.clamp(0, 24 * 60);
