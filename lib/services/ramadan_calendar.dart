import 'hijri_calendar.dart';

/// Ramadan yang relevan untuk ditampilkan: yang sedang berjalan bila hari
/// ini masih di dalamnya, kalau tidak yang berikutnya.
///
/// Tanggalnya berasal dari [HijriAnchors] (berkas `hijri_config.json`,
/// jangkar bulan 9 & 10) - satu sumber yang sama dengan kalender hijriah,
/// jadi keduanya mustahil saling bertentangan. Bulan tanpa jangkar jatuh ke
/// algoritma tabular dan ditandai [estimated].
class RamadanDate {
  final int hijriYear;

  /// 1 Ramadan, tengah malam UTC (hanya Y/M/D yang bermakna).
  final DateTime start;

  /// 1 Syawal (Idulfitri), tengah malam UTC.
  final DateTime end;

  /// Panjang Ramadan, 29 atau 30 hari.
  final int days;

  /// true bila 1 Ramadan-nya belum punya jangkar (masih hasil perhitungan).
  final bool estimated;

  /// true bila 1 Ramadan-nya sudah dijangkar tapi belum resmi (mis.
  /// menunggu sidang isbat).
  final bool tentative;

  /// true bila 1 Ramadan-nya hasil penyesuaian pengguna sendiri.
  final bool overridden;

  const RamadanDate({
    required this.hijriYear,
    required this.start,
    required this.end,
    required this.days,
    required this.estimated,
    this.tentative = false,
    this.overridden = false,
  });

  int get year => start.year;

  /// Keterangan singkat status tanggalnya, kosong bila sudah resmi.
  String get statusLabel => overridden
      ? 'sesuai pilihanmu'
      : estimated
      ? 'perkiraan'
      : tentative
      ? 'menunggu sidang isbat'
      : '';
}

RamadanDate _ramadanOf(int hy, HijriAnchors anchors) {
  final startJdn = anchors.firstDayJdn(hy, 9);
  return RamadanDate(
    hijriYear: hy,
    start: anchors.toGregorian(hy, 9, 1),
    end: anchors.toGregorian(hy, 10, 1),
    days: anchors.firstDayJdn(hy, 10) - startJdn,
    estimated: !anchors.has(hy, 9),
    tentative: anchors.isTentative(hy, 9),
    overridden: anchors.isOverridden(hy, 9),
  );
}

/// Ramadan yang relevan relatif terhadap tanggal kalender [today] (hanya
/// Y/M/D yang dibaca; pemanggil bertanggung jawab memberi tanggal pada zona
/// waktu lokasi, mis. lewat `todayInZone`).
///
/// Dipilih Ramadan pertama yang 1 Syawal-nya masih di depan: selama bulan
/// Ramadan berjalan, itu Ramadan tahun ini; sesudah Idulfitri, tahun depan.
/// Kapan tepatnya "sudah masuk" (Maghrib malam sebelum tanggal 1) diputuskan
/// widget-nya karena butuh jadwal sholat lokasi.
RamadanDate relevantRamadan(DateTime today, HijriAnchors anchors) {
  final todayJdn = gregorianToJdn(today.year, today.month, today.day);
  var hy = anchors.fromJdn(todayJdn).year;

  // maksimal tiga tahun ke depan sudah lebih dari cukup; loop ini hampir
  // selalu berhenti di iterasi pertama atau kedua
  for (var i = 0; i < 3; i++, hy++) {
    if (anchors.firstDayJdn(hy, 10) > todayJdn) return _ramadanOf(hy, anchors);
  }

  // tidak terjangkau
  return _ramadanOf(hy, anchors);
}

/// Berapa hari suasana Idulfitri ditampilkan (1-3 Syawal) sebelum hitung
/// mundur beralih ke Ramadan berikutnya.
const eidDays = 3;

enum RamadanPhase {
  /// menunggu Ramadan: hitung mundur
  before,

  /// sedang Ramadan
  during,

  /// Idulfitri: sejak Maghrib hari terakhir Ramadan sampai Maghrib
  /// [eidDays] Syawal
  eid,
}

class RamadanStatus {
  const RamadanStatus({
    required this.phase,
    required this.ramadan,
    required this.day,
  });

  final RamadanPhase phase;

  /// [RamadanPhase.eid]: Ramadan yang BARU SELESAI; lainnya: yang sedang
  /// berjalan atau berikutnya (sama dengan [relevantRamadan]).
  final RamadanDate ramadan;

  /// Hari Ramadan ke-n (during), tanggal Syawal (eid), atau 0 (before).
  final int day;
}

/// Fase Ramadan pada hari kalender [today] (zona lokasi, hanya Y/M/D yang
/// dibaca). [afterMaghrib]: sudah lewat Maghrib hari itu - hari hijriah
/// berganti saat Maghrib, jadi malam takbiran sudah terhitung 1 Syawal.
///
/// Untuk fase `before` hitung mundur yang tepat (sampai Maghrib malam
/// pertama) tetap diputuskan pemanggil karena butuh jadwal sholat;
/// fungsi ini hanya memakai pergantian hari hijriah.
RamadanStatus ramadanStatus({
  required DateTime today,
  required bool afterMaghrib,
  required HijriAnchors anchors,
}) {
  final todayJdn = gregorianToJdn(today.year, today.month, today.day);
  final hijri = anchors.fromJdn(todayJdn + (afterMaghrib ? 1 : 0));

  if (hijri.month == 10 && hijri.day <= eidDays) {
    return RamadanStatus(
      phase: RamadanPhase.eid,
      ramadan: _ramadanOf(hijri.year, anchors),
      day: hijri.day,
    );
  }

  final ramadan = relevantRamadan(today, anchors);
  if (hijri.month == 9 && hijri.year == ramadan.hijriYear) {
    return RamadanStatus(
      phase: RamadanPhase.during,
      ramadan: ramadan,
      day: hijri.day,
    );
  }
  return RamadanStatus(phase: RamadanPhase.before, ramadan: ramadan, day: 0);
}
