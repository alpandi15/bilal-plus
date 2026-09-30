import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';
import 'sholat_time.dart';

/// Keterangan ibadah sebuah hari kalender Masehi - SELALU diturunkan dari
/// jangkar hijriah saat ditampilkan, tidak pernah disimpan (lihat
/// `app_database.dart`). Bila awal Ramadan bergeser, hasil fungsi ini ikut
/// bergeser tanpa ada data yang perlu diubah.
class IbadahDay {
  const IbadahDay({
    required this.date,
    required this.hijri,
    required this.ramadanDay,
    required this.ramadanNight,
    required this.sunnahFastReasons,
    required this.fastForbidden,
  });

  /// Kunci tanggal Masehi.
  final String date;

  /// Tanggal hijriah SIANG hari itu.
  final HijriDate hijri;

  /// Ramadan hari ke-n (siang hari puasa), null bila bukan Ramadan.
  final int? ramadanDay;

  /// Malam ke-n Ramadan yang jatuh pada MALAM tanggal ini (sesudah
  /// Maghrib) - untuk tarawih. Malam pertama = malam sebelum puasa hari
  /// pertama; malam sesudah puasa terakhir adalah malam takbiran (null).
  final int? ramadanNight;

  /// Alasan puasa sunnah hari ini (mis. "Senin", "Ayyamul Bidh"); kosong =
  /// bukan hari yang disarankan.
  final List<String> sunnahFastReasons;

  /// Hari yang diharamkan berpuasa (Idulfitri, Iduladha, hari tasyrik).
  final bool fastForbidden;

  bool get isRamadan => ramadanDay != null;
  bool get sunnahFastSuggested =>
      sunnahFastReasons.isNotEmpty && !fastForbidden && !isRamadan;
}

/// Puasa awal Dzulhijjah yang diingatkan khusus (kartu, notifikasi, widget).
enum DzulhijjahFast {
  tarwiyah('Hari Tarwiyah'),
  arafah('Hari Arafah');

  const DzulhijjahFast(this.label);
  final String label;
}

/// Tarwiyah (8 Dzulhijjah) / Arafah (9 Dzulhijjah) pada tanggal hijriah
/// SIANG hari [h], null bila bukan keduanya.
DzulhijjahFast? dzulhijjahFastOf(HijriDate h) => h.month != 12
    ? null
    : switch (h.day) {
        8 => DzulhijjahFast.tarwiyah,
        9 => DzulhijjahFast.arafah,
        _ => null,
      };

IbadahDay ibadahDay(String date, HijriAnchors anchors) {
  final d = parseDateKey(date);
  final jdn = gregorianToJdn(d.year, d.month, d.day);
  final hijri = anchors.fromJdn(jdn);
  final night = anchors.fromJdn(jdn + 1);

  final forbidden =
      (hijri.month == 10 && hijri.day == 1) ||
      (hijri.month == 12 && hijri.day >= 10 && hijri.day <= 13);

  final reasons = <String>[
    if (hijri.month == 12 && hijri.day == 8) 'Hari Tarwiyah',
    if (hijri.month == 12 && hijri.day == 9) 'Hari Arafah',
    if (hijri.month == 1 && hijri.day == 9) "Tasu'a",
    if (hijri.month == 1 && hijri.day == 10) 'Asyura',
    if (hijri.month == 10 && hijri.day >= 2) 'Enam hari Syawal',
    if (hijri.day >= 13 && hijri.day <= 15) 'Ayyamul Bidh',
    if (d.weekday == DateTime.monday) 'Senin',
    if (d.weekday == DateTime.thursday) 'Kamis',
  ];

  return IbadahDay(
    date: date,
    hijri: hijri,
    ramadanDay: hijri.month == 9 ? hijri.day : null,
    ramadanNight: night.month == 9 ? night.day : null,
    sunnahFastReasons: reasons,
    fastForbidden: forbidden,
  );
}

/// Item [item] berlaku pada hari [day] menurut cakupannya dan, bila diatur,
/// hari dalam sepekannya ([IbadahItem.weekdays]). Puasa qadha hanya bila
/// masih ada hutang ([qadhaRemaining]).
bool itemApplies(IbadahItem item, IbadahDay day, {int qadhaRemaining = 0}) =>
    appliesOnWeekday(item.weekdays, parseDateKey(day.date).weekday) &&
    switch (item.scope) {
      IbadahScope.daily => true,
      IbadahScope.ramadan => day.isRamadan,
      IbadahScope.ramadanNight => day.ramadanNight != null,
      IbadahScope.sunnah => day.sunnahFastSuggested,
      IbadahScope.qadha =>
        qadhaRemaining > 0 && !day.isRamadan && !day.fastForbidden,
    };

/// Item yang ditampilkan pada [day]: yang berlaku, DAN yang sudah punya
/// catatan walau kini tidak berlaku (mis. awal Ramadan bergeser sesudah
/// tarawih dicatat) - catatan tidak pernah disembunyikan.
List<IbadahItem> visibleItems(
  List<IbadahItem> items,
  IbadahDay day,
  Map<int, int> values, {
  int qadhaRemaining = 0,
}) => [
  for (final i in items)
    if (itemApplies(i, day, qadhaRemaining: qadhaRemaining) ||
        (values[i.id] ?? 0) > 0)
      i,
];

const _excusableKeys = {
  'puasa',
  'puasa_sunnah',
  qadhaKey,
  'tarawih',
  'dhuha',
  'rawatib',
  'tahajud',
  'witir',
};

/// Ibadah yang gugur saat berhalangan (haid/nifas): sholat & puasa.
bool excusable(IbadahItem item) =>
    item.groupKey == sholatWajibGroup ||
    item.groupKey == rawatibGroup ||
    _excusableKeys.contains(item.key);

/// Selesai: check tercentang / counter mencapai target. Tilawah selesai
/// bila ada catatan bacaan Al-Qur'an hari itu.
bool itemDone(IbadahItem item, int value, {bool hasTilawah = false}) {
  if (item.key == tilawahKey && hasTilawah) return true;
  return item.kind == IbadahKind.counter ? value >= item.target : value > 0;
}

/// Hari berturut-turut yang terjaga (lima waktu lengkap atau berhalangan)
/// sampai [today]. Hari ini ikut dihitung bila sudah lengkap; bila belum,
/// hari ini tidak memutus streak (masih berjalan).
int ibadahStreak(Map<String, IbadahDaySummary> days, String today) {
  var cursor = parseDateKey(today);
  if (!(days[today]?.complete ?? false)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (days[dateKey(cursor)]?.complete ?? false) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Kemajuan ibadah satu hari.
class IbadahProgress {
  const IbadahProgress(this.done, this.total, this.score);

  /// Item yang tuntas / yang dihitung.
  final int done, total;

  /// Nilai tertimbang (0..[total]): sholat wajib sendiri bernilai
  /// `soloWeight`, selain itu 1 per item tuntas.
  final double score;

  double get fraction => total == 0 ? 0 : score / total;
  int get percent => (fraction * 100).floor();
  bool get complete => total > 0 && done >= total;
}

/// Kemajuan dari [items] yang tampil - ibadah yang gugur karena berhalangan
/// tidak dihitung. [logs] memberi status jama'ah sholat wajib; sholat
/// sendiri bernilai [soloWeight] (1 = sama dengan berjama'ah).
IbadahProgress ibadahProgress(
  List<IbadahItem> items,
  Map<int, int> values, {
  required bool excused,
  required bool hasTilawah,
  Map<int, IbadahLog> logs = const {},
  double soloWeight = 1,
}) {
  var done = 0, total = 0;
  var score = 0.0;
  for (final i in items) {
    if (excused && excusable(i)) continue;
    total++;
    if (!itemDone(i, values[i.id] ?? 0, hasTilawah: hasTilawah)) continue;
    done++;
    score += i.groupKey == sholatWajibGroup
        ? sholatWeight(logs[i.id]?.jamaah, soloWeight)
        : 1;
  }
  return IbadahProgress(done, total, score);
}
