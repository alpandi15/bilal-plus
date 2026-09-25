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

  const RamadanDate({
    required this.hijriYear,
    required this.start,
    required this.end,
    required this.days,
    required this.estimated,
  });

  int get year => start.year;
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
    final eidJdn = anchors.firstDayJdn(hy, 10);
    if (eidJdn > todayJdn) {
      final startJdn = anchors.firstDayJdn(hy, 9);
      return RamadanDate(
        hijriYear: hy,
        start: anchors.toGregorian(hy, 9, 1),
        end: anchors.toGregorian(hy, 10, 1),
        days: eidJdn - startJdn,
        estimated: !anchors.has(hy, 9),
      );
    }
  }

  // tidak terjangkau
  return RamadanDate(
    hijriYear: hy,
    start: anchors.toGregorian(hy, 9, 1),
    end: anchors.toGregorian(hy, 10, 1),
    days: anchors.daysInMonth(hy, 9),
    estimated: !anchors.has(hy, 9),
  );
}
