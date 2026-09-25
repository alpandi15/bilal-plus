/// Kalender hijriah = algoritma dasar + lapisan koreksi manual (jangkar).
///
/// Algoritma dasarnya kalender tabular "islamic-civil" (epoch Jumat 16 Juli
/// 622 M, siklus 30 tahun dengan 11 tahun kabisat) - deterministik, tanpa
/// dependensi, sama persis dengan kalender `islamic-civil` milik ICU. Hasilnya
/// bisa meleset 1-2 hari dari rukyat, karena itu hanya menjadi cadangan.
///
/// Yang menentukan hasil akhir adalah [HijriAnchors]: tanggal Masehi untuk
/// tanggal 1 bulan-bulan hijriah yang sudah ditetapkan (mis. hasil sidang
/// isbat). Tiap bulan ditetapkan sendiri-sendiri - koreksi Ramadan tidak
/// otomatis berlaku untuk Syawal - jadi modelnya jangkar per bulan, bukan
/// satu offset global.
library;

/// Nama bulan hijriah dalam ejaan yang lazim di Indonesia.
const List<String> hijriMonthNames = [
  'Muharram',
  'Safar',
  'Rabiul Awwal',
  'Rabiul Akhir',
  'Jumadil Awwal',
  'Jumadil Akhir',
  'Rajab',
  "Sya'ban",
  'Ramadan',
  'Syawal',
  "Dzulqa'dah",
  'Dzulhijjah',
];

class HijriDate {
  final int year;
  final int month; // 1..12
  final int day; // 1..30

  /// true bila bulan ini TIDAK punya jangkar, jadi tanggalnya hasil
  /// algoritma - bisa meleset 1-2 hari dari ketetapan resmi.
  final bool estimated;

  const HijriDate(this.year, this.month, this.day, {this.estimated = false});

  String get monthName => hijriMonthNames[month - 1];

  /// "1 Rabiul Akhir 1448 H"
  String format({bool withSuffix = true}) =>
      '$day $monthName $year${withSuffix ? ' H' : ''}';

  @override
  String toString() => format();

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/* -------------------------------------------------------------------------- */
/*  Algoritma tabular (Julian Day Number)                                      */
/* -------------------------------------------------------------------------- */

/// Kalender Masehi -> Julian Day Number (tengah hari).
int gregorianToJdn(int y, int m, int d) {
  final a = (m - 14) ~/ 12;
  return (1461 * (y + 4800 + a)) ~/ 4 +
      (367 * (m - 2 - 12 * a)) ~/ 12 -
      (3 * ((y + 4900 + a) ~/ 100)) ~/ 4 +
      d -
      32075;
}

/// Julian Day Number -> kalender Masehi (year, month, day).
(int, int, int) jdnToGregorian(int jd) {
  var l = jd + 68569;
  final n = (4 * l) ~/ 146097;
  l = l - (146097 * n + 3) ~/ 4;
  final i = (4000 * (l + 1)) ~/ 1461001;
  l = l - (1461 * i) ~/ 4 + 31;
  final j = (80 * l) ~/ 2447;
  final d = l - (2447 * j) ~/ 80;
  l = j ~/ 11;
  final m = j + 2 - 12 * l;
  final y = 100 * (n - 49) + i + l;
  return (y, m, d);
}

const int _hijriEpochJdn = 1948440; // 1 Muharram 1 H, kalender "civil"

/// Julian Day Number -> hijriah tabular (tanpa jangkar).
HijriDate jdnToHijriTabular(int jd) {
  var l = jd - _hijriEpochJdn + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j =
      ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
      (l ~/ 5670) * ((43 * l) ~/ 15238);
  l =
      l -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final m = (24 * l) ~/ 709;
  final d = l - (709 * m) ~/ 24;
  final y = 30 * n + j - 30;
  return HijriDate(y, m, d, estimated: true);
}

/// Hijriah tabular -> Julian Day Number.
int hijriToJdnTabular(int y, int m, int d) =>
    (11 * y + 3) ~/ 30 +
    354 * y +
    30 * m -
    (m - 1) ~/ 2 +
    d +
    _hijriEpochJdn -
    385;

/* -------------------------------------------------------------------------- */
/*  Jangkar                                                                    */
/* -------------------------------------------------------------------------- */

/// Kumpulan tanggal 1 bulan hijriah yang sudah ditetapkan, dipetakan sebagai
/// `(tahun, bulan) -> JDN`. Dibangun dari berkas konfigurasi
/// (lihat `hijri_config.dart`); kelas ini sendiri tidak peduli asalnya.
class HijriAnchors {
  HijriAnchors(Map<(int, int), int> anchorsByMonth)
    : _byMonth = Map.unmodifiable(anchorsByMonth);

  static final HijriAnchors none = HijriAnchors(const {});

  final Map<(int, int), int> _byMonth;

  bool get isEmpty => _byMonth.isEmpty;
  int get length => _byMonth.length;

  bool has(int year, int month) => _byMonth.containsKey((year, month));

  /// JDN tanggal 1 untuk bulan hijriah [year]-[month]: jangkar bila ada,
  /// kalau tidak hasil algoritma tabular.
  int firstDayJdn(int year, int month) =>
      _byMonth[(year, month)] ?? hijriToJdnTabular(year, month, 1);

  static (int, int) _nextMonth(int y, int m) =>
      m == 12 ? (y + 1, 1) : (y, m + 1);
  static (int, int) _prevMonth(int y, int m) =>
      m == 1 ? (y - 1, 12) : (y, m - 1);

  /// Jumlah hari bulan [year]-[month] = tanggal 1 bulan berikutnya dikurangi
  /// tanggal 1 bulan ini (masing-masing jangkar bila ada).
  int daysInMonth(int year, int month) {
    final (ny, nm) = _nextMonth(year, month);
    return firstDayJdn(ny, nm) - firstDayJdn(year, month);
  }

  /// Konversi JDN -> tanggal hijriah dengan memperhitungkan jangkar.
  ///
  /// Kandidatnya bulan hasil algoritma beserta satu bulan sebelum dan
  /// sesudahnya - jangkar hanya menggeser batas bulan 1-2 hari, jadi tiga
  /// kandidat itu pasti mencakup jawabannya. Untuk tiap kandidat, [start,end)
  /// = tanggal 1 bulan itu sampai tanggal 1 bulan berikutnya.
  HijriDate fromJdn(int jd) {
    final base = jdnToHijriTabular(jd);
    final (py, pm) = _prevMonth(base.year, base.month);
    final (ny, nm) = _nextMonth(base.year, base.month);

    for (final (y, m) in [(py, pm), (base.year, base.month), (ny, nm)]) {
      final start = firstDayJdn(y, m);
      final (ey, em) = _nextMonth(y, m);
      final end = firstDayJdn(ey, em);
      if (jd >= start && jd < end) {
        return HijriDate(y, m, jd - start + 1, estimated: !has(y, m));
      }
    }

    // mustahil terjadi bila jangkarnya lolos validasi (lihat hijri_config)
    return base;
  }

  /// Tanggal Masehi (tengah malam, UTC) dari tanggal hijriah.
  DateTime toGregorian(int year, int month, int day) {
    final (y, m, d) = jdnToGregorian(firstDayJdn(year, month) + day - 1);
    return DateTime.utc(y, m, d);
  }

  /// Tanggal hijriah untuk satu hari kalender Masehi (hanya Y/M/D yang
  /// dibaca - zona waktu [date] diabaikan).
  HijriDate fromGregorian(DateTime date) =>
      fromJdn(gregorianToJdn(date.year, date.month, date.day));

  /// Tanggal hijriah yang SEDANG BERLAKU pada saat [now]: hari hijriah
  /// berganti saat Maghrib, jadi lewat [maghribToday] tanggalnya sudah milik
  /// hari Masehi berikutnya. [todayInZone] = tanggal kalender Masehi hari ini
  /// di zona lokasi (mis. dari `todayInZone`), [maghribToday] = waktu Maghrib
  /// hari itu dari jadwal sholat.
  HijriDate current({
    required DateTime now,
    required DateTime todayInZone,
    required DateTime maghribToday,
  }) {
    final jdn = gregorianToJdn(
      todayInZone.year,
      todayInZone.month,
      todayInZone.day,
    );
    return fromJdn(now.isBefore(maghribToday) ? jdn : jdn + 1);
  }
}

/* -------------------------------------------------------------------------- */
/*  Hari-hari penting                                                          */
/* -------------------------------------------------------------------------- */

class HijriEvent {
  final int month;
  final int day;
  final String name;
  const HijriEvent(this.month, this.day, this.name);
}

/// Hari besar/penting yang ditandai di kalender. Sengaja dibatasi pada yang
/// jatuh di tanggal hijriah tetap; yang berbasis pekan (mis. Jumat terakhir)
/// tidak termasuk.
const List<HijriEvent> hijriEvents = [
  HijriEvent(1, 1, 'Tahun Baru Hijriah'),
  HijriEvent(1, 10, 'Asyura'),
  HijriEvent(3, 12, 'Maulid Nabi'),
  HijriEvent(7, 27, "Isra' Mi'raj"),
  HijriEvent(8, 15, "Nisfu Sya'ban"),
  HijriEvent(9, 1, 'Awal Ramadan'),
  HijriEvent(9, 17, 'Nuzulul Quran'),
  HijriEvent(10, 1, 'Idulfitri'),
  HijriEvent(12, 9, 'Hari Arafah'),
  HijriEvent(12, 10, 'Iduladha'),
];

List<HijriEvent> eventsOn(HijriDate date) => [
  for (final e in hijriEvents)
    if (e.month == date.month && e.day == date.day) e,
];
