import '../db/app_database.dart';
import '../models/prayer_models.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';
import 'ibadah_day.dart';
import 'prayer_calculator.dart' as calc;
import 'quran_index.dart';
import 'quran_target.dart';

/// Data untuk widget layar utama Ibadah & Al-Qur'an (dibaca
/// `IbadahWidgetProvider.kt` / `QuranWidgetProvider.kt`). Widget tidak
/// menjalankan Flutter, jadi semua yang perlu ditampilkan sudah jadi di sini;
/// Kotlin cukup memilih hari yang cocok dan menggambar.
///
/// Dua hari (hari ini & besok) sekaligus supaya sesudah tengah malam widget
/// langsung menampilkan checklist hari baru walau aplikasi belum dibuka.

const _prayerOfItem = {
  'subuh': PrayerKey.fajr,
  'dzuhur': PrayerKey.dhuhr,
  'ashar': PrayerKey.asr,
  'maghrib': PrayerKey.maghrib,
  'isya': PrayerKey.isha,
};

const _hari = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
const _bulan = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MEI',
  'JUN',
  'JUL',
  'AGU',
  'SEP',
  'OKT',
  'NOV',
  'DES',
];

const tzIds = {
  calc.TimezoneCode.wib: 'Asia/Jakarta',
  calc.TimezoneCode.wita: 'Asia/Makassar',
  calc.TimezoneCode.wit: 'Asia/Jayapura',
};

String _tomorrow(String date) =>
    dateKey(parseDateKey(date).add(const Duration(days: 1)));

/* -------------------------------------------------------------------------- */
/*  Ibadah                                                                     */
/* -------------------------------------------------------------------------- */

Future<Map<String, Object?>> ibadahWidgetPayload(
  AppDatabase db, {
  required HijriAnchors anchors,
  required String today,
  required double latitude,
  required double longitude,
}) async {
  final tz = calc.timezoneFromLongitude(longitude);
  return {
    'generatedAt': DateTime.now().millisecondsSinceEpoch,
    'tzId': tzIds[tz],
    'days': [
      for (final date in [today, _tomorrow(today)])
        await ibadahWidgetDay(
          db,
          anchors: anchors,
          date: date,
          latitude: latitude,
          longitude: longitude,
        ),
    ],
  };
}

Future<Map<String, Object?>> ibadahWidgetDay(
  AppDatabase db, {
  required HijriAnchors anchors,
  required String date,
  required double latitude,
  required double longitude,
}) async {
  final data = await db.ibadahDao.loadDay(
    date,
    summariesFrom: dateKey(
      parseDateKey(date).subtract(const Duration(days: 400)),
    ),
    summariesTo: date,
  );
  final day = ibadahDay(date, anchors);
  final items = visibleItems(
    data.items,
    day,
    data.values,
    qadhaRemaining: data.qadhaRemaining,
  );
  final schedule = calc.calculatePrayerTimes(
    latitude: latitude,
    longitude: longitude,
    date: parseDateKey(date),
  );
  final d = parseDateKey(date);

  Map<String, Object?> entry(IbadahItem i) {
    final value = data.values[i.id] ?? 0;
    final prayer = _prayerOfItem[i.key];
    return {
      'id': i.id,
      'name': i.name,
      'kind': i.key == tilawahKey ? 'tilawah' : i.kind.name,
      'value': value,
      'target': i.target,
      'done': itemDone(i, value, hasTilawah: data.hasTilawah),
      'excused': data.excused && excusable(i),
      if (prayer != null) ...{
        'at': schedule.times[prayer]!.millisecondsSinceEpoch,
        'time': schedule.labels[prayer],
      },
    };
  }

  final (done, total) = ibadahProgress(
    items,
    data.values,
    excused: data.excused,
    hasTilawah: data.hasTilawah,
  );

  return {
    'date': date,
    'kicker': day.isRamadan
        ? 'RAMADAN · HARI ${day.ramadanDay}'
        : '${_hari[d.weekday - 1]} · ${d.day} ${_bulan[d.month - 1]}',
    'hijri': day.hijri.format(),
    'excused': data.excused,
    'streak': ibadahStreak(data.summaries, date),
    'done': done,
    'total': total,
    'sholat': [
      for (final i in items)
        if (i.groupKey == sholatWajibGroup) entry(i),
    ],
    'items': [
      for (final i in items)
        if (i.groupKey != sholatWajibGroup) entry(i),
    ],
  };
}

/// Perbarui satu hari di payload widget yang sudah ada sesudah sebuah
/// catatan diubah dari widget (isolate latar, tanpa jangkar & lokasi):
/// nilai, selesai/tidak, jumlah, dan streak dihitung ulang dari basis data;
/// daftar item & jam sholat dipertahankan.
Future<Map<String, Object?>> patchIbadahPayload(
  AppDatabase db,
  Map<String, Object?> payload,
  String date,
) async {
  final days = (payload['days'] as List).cast<Map<String, Object?>>();
  final day = days.where((d) => d['date'] == date).firstOrNull;
  if (day == null) return payload;

  final data = await db.ibadahDao.loadDay(
    date,
    summariesFrom: dateKey(
      parseDateKey(date).subtract(const Duration(days: 400)),
    ),
    summariesTo: date,
  );
  final byId = {for (final i in data.items) i.id: i};
  var done = 0;
  var total = 0;
  for (final key in ['sholat', 'items']) {
    for (final e in (day[key] as List).cast<Map<String, Object?>>()) {
      final item = byId[e['id']];
      if (item == null) continue;
      final value = data.values[item.id] ?? 0;
      final isDone = itemDone(item, value, hasTilawah: data.hasTilawah);
      e['value'] = value;
      e['done'] = isDone;
      e['excused'] = data.excused && excusable(item);
      if (e['excused'] != true) {
        total++;
        if (isDone) done++;
      }
    }
  }
  day['done'] = done;
  day['total'] = total;
  day['excused'] = data.excused;
  day['streak'] = ibadahStreak(data.summaries, date);
  payload['generatedAt'] = DateTime.now().millisecondsSinceEpoch;
  return payload;
}

/* -------------------------------------------------------------------------- */
/*  Al-Qur'an                                                                  */
/* -------------------------------------------------------------------------- */

const _hariPendek = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

Future<Map<String, Object?>> quranWidgetPayload(
  AppDatabase db, {
  required String today,
  required String tzId,
}) async {
  final dao = db.quranDao;
  final p = await dao.progress();
  final logs = await dao.logsOf(p.cycle.id);
  final cycles = await dao.cycles();

  // khatam baru saja: putaran aktif masih kosong & putaran sebelumnya khatam
  var justKhatam = false;
  if (logs.isEmpty) {
    for (final c in cycles) {
      if (c.id == p.cycle.id) continue;
      justKhatam = c.completed;
      break;
    }
  }

  // halaman per hari, 7 hari terakhir (semua putaran)
  final from = dateKey(parseDateKey(today).subtract(const Duration(days: 6)));
  final recent = await db.ibadahDao.quranLogsBetween(from, today);
  final week = <double>[];
  final weekLabels = <String>[];
  for (var i = 6; i >= 0; i--) {
    final d = parseDateKey(today).subtract(Duration(days: i));
    final key = dateKey(d);
    week.add(
      recent
          .where((l) => l.date == key && l.toAyah >= l.fromAyah)
          .fold<double>(0, (a, l) => a + pagesBetween(l.fromAyah, l.toAyah)),
    );
    weekLabels.add(_hariPendek[d.weekday - 1]);
  }

  final last = p.lastAyah;
  return {
    'generatedAt': DateTime.now().millisecondsSinceEpoch,
    'tzId': tzId,
    'round': justKhatam ? p.completedCycles : p.round,
    'justKhatam': justKhatam,
    'progress': p.progress,
    'percent': (p.progress * 100).floor(),
    'lastAyah': last,
    'juz': last == 0 ? 0 : juzOf(last),
    'position': last == 0 ? '' : formatAyah(last),
    'page': last == 0 ? 0 : pageOf(last),
    'week': week,
    'weekLabels': weekLabels,
    'days': [
      for (final date in [today, _tomorrow(today)])
        if (dailyTarget(cycle: p.cycle, logs: logs, today: date) case final t?)
          {
            'date': date,
            'hasTarget': true,
            'target': 's/d ${formatAyah(t.targetAyah)}',
            'pagesToday': t.pagesToday,
            'pagesPerDay': t.pagesPerDay,
            'pagesLabel':
                '${formatPages(t.pagesToday)}/${formatPages(t.pagesPerDay)} hlm',
            'reached': t.reached,
          }
        else
          {'date': date, 'hasTarget': false},
    ],
  };
}
