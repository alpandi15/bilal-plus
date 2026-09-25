import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';
import 'ibadah_day.dart';
import 'prayer_calculator.dart' as calc;
import 'sholat_time.dart';

/// Skor ibadah satu hari: berapa dari ibadah aktif yang berlaku hari itu
/// yang tuntas. Ibadah yang gugur karena berhalangan tidak dihitung.
class DayScore {
  const DayScore({
    required this.date,
    required this.done,
    required this.total,
    required this.excused,
    required this.hasData,
    required this.sholat,
  });

  final String date;
  final int done;
  final int total;
  final bool excused;

  /// false untuk hari sebelum catatan pertama - ditampilkan kosong, bukan 0%.
  final bool hasData;

  /// Sholat wajib yang tercentang (0..5).
  final int sholat;

  double get fraction => total == 0 ? 0 : done / total;

  /// Lima waktu lengkap atau berhalangan (dasar streak).
  bool get kept => excused || sholat >= 5;
}

/// Konsistensi satu ibadah: tuntas di berapa dari hari yang berlaku.
class ItemStat {
  const ItemStat(this.item, this.done, this.days);
  final IbadahItem item;
  final int done;
  final int days;
  double get rate => days == 0 ? 0 : done / days;
}

/// Kualitas satu waktu sholat wajib dalam rentang laporan.
class SholatStat {
  SholatStat(this.item);
  final IbadahItem item;
  int onTime = 0, late = 0, qadha = 0;

  /// Tercentang tapi jamnya tidak dicatat (mis. sebelum fitur diaktifkan).
  int untimed = 0;

  /// Tidak tercentang sama sekali (dan tidak berhalangan).
  int missed = 0;
  int delayMinutes = 0;
  final places = <String, int>{};

  int get timed => onTime + late + qadha;
  int get total => timed + untimed + missed;
  double get avgDelay => timed == 0 ? 0 : delayMinutes / timed;
}

class IbadahReport {
  const IbadahReport({
    required this.days,
    required this.items,
    required this.weekday,
    required this.sholat,
    required this.currentStreak,
    required this.longestStreak,
  });

  /// Satu per tanggal di rentang, urut.
  final List<DayScore> days;

  /// Diurutkan dari yang paling konsisten.
  final List<ItemStat> items;

  /// Rata-rata tuntas per hari dalam pekan, indeks 0 = Senin.
  final List<double?> weekday;
  final List<SholatStat> sholat;
  final int currentStreak;
  final int longestStreak;

  Iterable<DayScore> get counted =>
      days.where((d) => d.hasData && !d.excused && d.total > 0);

  double get average {
    final c = counted.toList();
    return c.isEmpty
        ? 0
        : c.fold<double>(0, (a, d) => a + d.fraction) / c.length;
  }

  int get fullDays => counted.where((d) => d.done >= d.total).length;

  /// Rekap semua waktu sholat.
  (int, int, int) get sholatTotals => sholat.fold((
    0,
    0,
    0,
  ), (a, s) => (a.$1 + s.onTime, a.$2 + s.late, a.$3 + s.qadha));
}

/// Susun laporan [data] (hasil `IbadahDao.loadRange`). [today] membatasi
/// hari yang dihitung (hari mendatang diabaikan); [latitude]/[longitude]
/// untuk jadwal sholat bila [sholatTime] aktif.
IbadahReport buildIbadahReport(
  IbadahRangeData data, {
  required HijriAnchors anchors,
  required String today,
  double? latitude,
  double? longitude,
  int onTimeMinutes = defaultOnTimeMinutes,
}) {
  final last = data.to.compareTo(today) < 0 ? data.to : today;
  final first = data.firstDate;
  final days = <DayScore>[];
  final doneCount = <int, int>{};
  final dayCount = <int, int>{};
  final weekdaySum = List<double>.filled(7, 0);
  final weekdayCount = List<int>.filled(7, 0);
  final sholatItems = [
    for (final i in data.items)
      if (i.groupKey == sholatWajibGroup) i,
  ];
  final sholat = {for (final i in sholatItems) i.id: SholatStat(i)};
  final timed = latitude != null && longitude != null;

  for (
    var d = parseDateKey(data.from);
    dateKey(d).compareTo(last) <= 0;
    d = d.add(const Duration(days: 1))
  ) {
    final date = dateKey(d);
    final logs = data.logs[date] ?? const {};
    final values = {for (final e in logs.entries) e.key: e.value.value};
    final excused = data.excused.contains(date);
    final hasData = first != null && date.compareTo(first) >= 0;
    final day = ibadahDay(date, anchors);
    final hasTilawah = data.tilawah.contains(date);
    final visible = visibleItems(data.items, day, values);
    final (done, total) = ibadahProgress(
      visible,
      values,
      excused: excused,
      hasTilawah: hasTilawah,
    );
    final sholatDone = sholatItems.where((i) => (values[i.id] ?? 0) > 0).length;
    days.add(
      DayScore(
        date: date,
        done: done,
        total: total,
        excused: excused,
        hasData: hasData,
        sholat: sholatDone,
      ),
    );
    if (!hasData) continue;

    if (!excused && total > 0) {
      weekdaySum[d.weekday - 1] += done / total;
      weekdayCount[d.weekday - 1]++;
    }
    for (final i in visible) {
      if (excused && excusable(i)) continue;
      dayCount[i.id] = (dayCount[i.id] ?? 0) + 1;
      if (itemDone(i, values[i.id] ?? 0, hasTilawah: hasTilawah)) {
        doneCount[i.id] = (doneCount[i.id] ?? 0) + 1;
      }
    }

    // kualitas sholat wajib
    if (excused) continue;
    calc.DailyPrayerTimes? todayTimes, nextTimes;
    for (final i in sholatItems) {
      final stat = sholat[i.id]!;
      final log = logs[i.id];
      if (log == null || log.value <= 0) {
        // hari ini: sholat yang waktunya belum tiba bukan "terlewat"
        if (date != today) stat.missed++;
        continue;
      }
      final place = log.place;
      if (place != null) stat.places[place] = (stat.places[place] ?? 0) + 1;
      final at = log.prayedAt;
      if (!timed || at == null) {
        stat.untimed++;
        continue;
      }
      todayTimes ??= calc.calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: d,
      );
      final window = sholatWindowFrom(
        i.key,
        todayTimes,
        () => nextTimes ??= calc.calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: d.add(const Duration(days: 1)),
        ),
      )!;
      switch (sholatStatus(at, window, onTimeMinutes: onTimeMinutes)) {
        case SholatStatus.onTime:
          stat.onTime++;
        case SholatStatus.late:
          stat.late++;
        case SholatStatus.qadha:
          stat.qadha++;
      }
      stat.delayMinutes += minutesAfterAdzan(at, window);
    }
  }

  // streak (dasar: lima waktu lengkap atau berhalangan)
  var longest = 0, run = 0;
  for (final d in days) {
    if (!d.hasData) continue;
    run = d.kept ? run + 1 : 0;
    if (run > longest) longest = run;
  }
  var current = 0;
  for (var i = days.length - 1; i >= 0; i--) {
    final d = days[i];
    // hari ini yang belum lengkap tidak memutus streak
    if (d.date == today && !d.kept) continue;
    if (!d.hasData || !d.kept) break;
    current++;
  }

  final stats = [
    for (final i in data.items)
      if ((dayCount[i.id] ?? 0) > 0)
        ItemStat(i, doneCount[i.id] ?? 0, dayCount[i.id]!),
  ]..sort((a, b) => b.rate.compareTo(a.rate));

  return IbadahReport(
    days: days,
    items: stats,
    weekday: [
      for (var w = 0; w < 7; w++)
        weekdayCount[w] == 0 ? null : weekdaySum[w] / weekdayCount[w],
    ],
    sholat: [for (final i in sholatItems) sholat[i.id]!],
    currentStreak: current,
    longestStreak: longest,
  );
}
