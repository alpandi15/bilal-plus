import 'package:drift/drift.dart' show Value;

import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';
import 'quran_index.dart';
import 'ramadan_calendar.dart';

enum RamadanDayState {
  /// sudah berpuasa
  fasted,

  /// berhalangan (tidak berpuasa, terhitung hutang)
  excused,

  /// sudah lewat tanpa catatan puasa (terhitung hutang)
  missed,

  /// hari ini, belum dicatat
  today,

  /// belum tiba
  upcoming,
}

/// Rekap satu Ramadan, dihitung dari catatan & jangkar yang berlaku SAAT
/// INI. Untuk hutang qadha yang dibekukan, lihat [lockFinishedRamadans].
class RamadanSummary {
  const RamadanSummary({
    required this.ramadan,
    required this.today,
    required this.fasted,
    required this.excused,
    required this.tarawih,
    required this.quranPages,
    required this.khatam,
  });

  final RamadanDate ramadan;
  final String today;
  final Set<String> fasted;
  final Set<String> excused;

  /// Tanggal (malam) tarawih yang tercatat.
  final Set<String> tarawih;
  final double quranPages;

  /// Putaran yang khatam selama Ramadan ini.
  final int khatam;

  /// Tanggal-tanggal puasa Ramadan (kunci tanggal), hari ke-1 dulu.
  List<String> get dates => [
    for (var i = 0; i < ramadan.days; i++)
      dateKey(ramadan.start.add(Duration(days: i))),
  ];

  /// Malam-malam tarawih: malam sebelum hari ke-1 sampai malam sebelum
  /// hari terakhir.
  List<String> get nights => [
    for (var i = -1; i < ramadan.days - 1; i++)
      dateKey(ramadan.start.add(Duration(days: i))),
  ];

  RamadanDayState stateOf(String date) {
    if (fasted.contains(date)) return RamadanDayState.fasted;
    final c = date.compareTo(today);
    if (c > 0) return RamadanDayState.upcoming;
    if (excused.contains(date)) return RamadanDayState.excused;
    return c == 0 ? RamadanDayState.today : RamadanDayState.missed;
  }

  int get fastedCount => dates.where(fasted.contains).length;
  int get tarawihCount => nights.where(tarawih.contains).length;
  int count(RamadanDayState s) => dates.where((d) => stateOf(d) == s).length;

  /// Hari yang sudah lewat tanpa puasa (berhalangan atau terlewat).
  int get owed =>
      count(RamadanDayState.excused) + count(RamadanDayState.missed);

  bool get started => dates.first.compareTo(today) <= 0;
  bool get finished => dates.last.compareTo(today) < 0;

  /// Ada catatan apa pun selama Ramadan ini.
  bool get hasData =>
      dates.any((d) => fasted.contains(d) || excused.contains(d));
}

Future<RamadanSummary> loadRamadanSummary(
  AppDatabase db,
  RamadanDate ramadan,
  String today,
) async {
  final dao = db.ibadahDao;
  final first = dateKey(ramadan.start);
  final last = dateKey(ramadan.end.subtract(const Duration(days: 1)));
  final eve = dateKey(ramadan.start.subtract(const Duration(days: 1)));

  final logs = await dao.quranLogsBetween(first, last);
  final pages = logs.fold<double>(
    0,
    (a, l) =>
        a + (l.toAyah >= l.fromAyah ? pagesBetween(l.fromAyah, l.toAyah) : 0),
  );
  // tanggal bacaan (bukan waktu menyimpan) sesi yang sampai An-Nas - supaya
  // khatam yang dicatat belakangan ("kemarin") tetap masuk Ramadan yang benar
  final khatam = logs.where((l) => l.toAyah == totalAyahs).length;

  return RamadanSummary(
    ramadan: ramadan,
    today: today,
    fasted: await dao.datesOf('puasa', first, last),
    excused: await dao.excusedDates(first, last),
    tarawih: await dao.datesOf('tarawih', eve, last),
    quranPages: pages,
    khatam: khatam,
  );
}

/// Ramadan tahun hijriah [hijriYear] menurut [anchors].
RamadanDate ramadanOfYear(int hijriYear, HijriAnchors anchors) =>
    relevantRamadan(anchors.toGregorian(hijriYear, 9, 1), anchors);

/// Kunci rekap Ramadan yang suasana Idulfitrinya sudah lewat (hari ini >=
/// 1 Syawal + [eidDays]) dan belum punya rekap - hanya bila ada catatan
/// selama Ramadan itu, supaya pengguna yang baru memasang aplikasi sesudah
/// Ramadan tidak mendadak berhutang sebulan. Mengembalikan tahun yang baru
/// dikunci.
Future<List<int>> lockFinishedRamadans(
  AppDatabase db,
  HijriAnchors anchors,
  String today,
) async {
  final t = parseDateKey(today);
  final hy = anchors.fromGregorian(t).year;
  final locked = <int>[];
  for (final year in [hy - 1, hy]) {
    final r = ramadanOfYear(year, anchors);
    if (daysBetweenKeys(dateKey(r.end), today) < eidDays) continue;
    if (await db.ibadahDao.recapOf(year) != null) continue;
    final s = await loadRamadanSummary(db, r, today);
    if (!s.hasData) continue;
    await saveRecapFrom(db, s);
    locked.add(year);
  }
  return locked;
}

/// Simpan (atau timpa) rekap dari [summary] - dipakai penguncian otomatis
/// dan "hitung ulang".
Future<void> saveRecapFrom(AppDatabase db, RamadanSummary summary) =>
    db.ibadahDao.saveRecap(
      RamadanRecapsCompanion.insert(
        hijriYear: Value(summary.ramadan.hijriYear),
        days: summary.ramadan.days,
        fasted: summary.fastedCount,
        excused: summary.count(RamadanDayState.excused),
        lockedAt: DateTime.now(),
      ),
    );

/// Pertanyaan "kapan mulai?" menjelang tanggal 1 Ramadan/Syawal yang belum
/// ditetapkan resmi.
class IsbatPrompt {
  const IsbatPrompt({
    required this.hijriYear,
    required this.month,
    required this.expected,
  });

  final int hijriYear;

  /// 9 (Ramadan) atau 10 (Syawal).
  final int month;

  /// Tanggal 1 yang berlaku sekarang (perkiraan/menunggu isbat).
  final DateTime expected;
}

/// Kartu isbat muncul bila tanggal 1 Ramadan/Syawal berikutnya jatuh besok
/// atau lusa, dan tanggalnya belum resmi (perkiraan atau menunggu isbat)
/// serta belum disesuaikan pengguna sendiri.
IsbatPrompt? isbatPrompt(String today, HijriAnchors anchors) {
  final t = parseDateKey(today);
  final hy = anchors.fromGregorian(t).year;
  for (final year in [hy, hy + 1]) {
    for (final month in [9, 10]) {
      final start = anchors.toGregorian(year, month, 1);
      final daysUntil = daysBetweenKeys(today, dateKey(start));
      if (daysUntil < 1 || daysUntil > 2) continue;
      if (anchors.isOverridden(year, month)) continue;
      final official =
          anchors.has(year, month) && !anchors.isTentative(year, month);
      if (official) continue;
      return IsbatPrompt(hijriYear: year, month: month, expected: start);
    }
  }
  return null;
}
