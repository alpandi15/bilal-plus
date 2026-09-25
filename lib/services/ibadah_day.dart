import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';

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

IbadahDay ibadahDay(String date, HijriAnchors anchors) {
  final d = parseDateKey(date);
  final jdn = gregorianToJdn(d.year, d.month, d.day);
  final hijri = anchors.fromJdn(jdn);
  final night = anchors.fromJdn(jdn + 1);

  final forbidden =
      (hijri.month == 10 && hijri.day == 1) ||
      (hijri.month == 12 && hijri.day >= 10 && hijri.day <= 13);

  final reasons = <String>[
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

/// Item [item] berlaku pada hari [day] menurut cakupannya. Puasa qadha
/// hanya bila masih ada hutang ([qadhaRemaining]).
bool itemApplies(IbadahItem item, IbadahDay day, {int qadhaRemaining = 0}) =>
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
    item.groupKey == sholatWajibGroup || _excusableKeys.contains(item.key);

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
