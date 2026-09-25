import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'quran_index.dart';

/// Target harian menuju khatam paling lambat [QuranCycle.targetDate].
///
/// Dihitung ulang setiap hari dari posisi AWAL hari ini: sisa halaman dibagi
/// sisa hari. Jadi bila kemarin tertinggal, bebannya otomatis tersebar ke
/// hari-hari yang tersisa - tidak menumpuk di hari terakhir.
class QuranDailyTarget {
  const QuranDailyTarget({
    required this.targetDate,
    required this.daysLeft,
    required this.pagesPerDay,
    required this.pagesToday,
    required this.targetPage,
    required this.targetAyah,
    required this.overdue,
  });

  /// Batas khatam (kunci tanggal).
  final String targetDate;

  /// Sisa hari termasuk hari ini (minimal 1).
  final int daysLeft;

  /// Halaman yang perlu dibaca hari ini.
  final double pagesPerDay;

  /// Halaman yang sudah dibaca hari ini.
  final double pagesToday;

  /// Bacaan hari ini cukup sampai akhir halaman ini ...
  final int targetPage;

  /// ... yaitu sampai ayat global ini.
  final int targetAyah;

  /// Batasnya sudah lewat - seluruh sisa bacaan jadi target hari ini.
  final bool overdue;

  bool get reached => pagesToday + 1e-9 >= pagesPerDay;
  double get fraction =>
      pagesPerDay <= 0 ? 1 : (pagesToday / pagesPerDay).clamp(0, 1);
}

/// Kunci tanggal batas khatam bila mulai [today] dan diberi [days] hari
/// (hari ini termasuk): 30 hari dari 8 Feb = 9 Mar.
String targetDateFor(String today, int days) =>
    dateKey(parseDateKey(today).add(Duration(days: days - 1)));

/// Target hari [today] (kunci tanggal) untuk putaran [cycle]. [logs] = semua
/// sesi baca putaran itu (urutan bebas). Null bila putaran tanpa target.
QuranDailyTarget? dailyTarget({
  required QuranCycle cycle,
  required List<QuranLog> logs,
  required String today,
}) {
  final targetDate = cycle.targetDate;
  if (targetDate == null) return null;

  final sorted = [...logs]
    ..sort((a, b) {
      final c = a.createdAt.compareTo(b.createdAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  // posisi di awal hari ini = sesi terakhir sebelum hari ini
  var startOfToday = 0;
  var current = 0;
  for (final log in sorted) {
    if (log.date.compareTo(today) < 0) startOfToday = log.toAyah;
    current = log.toAyah;
  }

  final remainingDays = daysBetweenKeys(today, targetDate) + 1;
  final overdue = remainingDays < 1;
  final daysLeft = overdue ? 1 : remainingDays;

  final startPages = progressAfter(startOfToday) * totalPages;
  final pagesPerDay = (totalPages - startPages) / daysLeft;
  final pagesToday = (progressAfter(current) * totalPages - startPages)
      .clamp(0, totalPages)
      .toDouble();

  // dibulatkan ke akhir halaman supaya targetnya enak dibaca ("sampai hlm
  // 42"), bukan di tengah halaman
  final targetPage = (startPages + pagesPerDay - 1e-9).ceil().clamp(
    1,
    totalPages,
  );
  final (_, targetAyah) = pageRange(targetPage);

  return QuranDailyTarget(
    targetDate: targetDate,
    daysLeft: daysLeft,
    pagesPerDay: pagesPerDay,
    pagesToday: pagesToday,
    targetPage: targetPage,
    targetAyah: targetAyah,
    overdue: overdue,
  );
}

/// "20" atau "20,3" - jumlah halaman dengan koma desimal Indonesia.
String formatPages(double pages) {
  final rounded = (pages * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
}
