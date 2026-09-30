import '../db/app_database.dart';
import '../models/prayer_models.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';
import 'ibadah_day.dart';
import 'prayer_calculator.dart' as calc;
import 'quran_index.dart';
import 'quran_target.dart';
import 'sholat_time.dart';

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
  bool sholatTime = false,
  int onTimeMinutes = defaultOnTimeMinutes,
  double soloWeight = 1,
  bool lastJamaah = false,
}) async {
  final tz = calc.timezoneFromLongitude(longitude);
  return {
    'generatedAt': DateTime.now().millisecondsSinceEpoch,
    'tzId': tzIds[tz],
    'sholatTime': sholatTime,
    'onTimeMinutes': onTimeMinutes,
    'soloWeight': soloWeight,
    'lastJamaah': lastJamaah,
    'days': [
      for (final date in [today, _tomorrow(today)])
        await ibadahWidgetDay(
          db,
          anchors: anchors,
          date: date,
          latitude: latitude,
          longitude: longitude,
          sholatTime: sholatTime,
          onTimeMinutes: onTimeMinutes,
          soloWeight: soloWeight,
          lastJamaah: lastJamaah,
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
  bool sholatTime = false,
  int onTimeMinutes = defaultOnTimeMinutes,
  double soloWeight = 1,
  bool lastJamaah = false,
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

  final tz = calc.timezoneFromLongitude(longitude);
  Map<String, Object?> entry(IbadahItem i) {
    final value = data.values[i.id] ?? 0;
    final prayer = _prayerOfItem[i.key];
    final window = prayer == null
        ? null
        : sholatWindow(
            i.key,
            parseDateKey(date),
            latitude: latitude,
            longitude: longitude,
          );
    final prayedAt = data.logs[i.id]?.prayedAt;
    return {
      'id': i.id,
      'name': i.name,
      'kind': i.key == tilawahKey ? 'tilawah' : i.kind.name,
      'value': value,
      'target': i.target,
      'done': itemDone(i, value, hasTilawah: data.hasTilawah),
      'excused': data.excused && excusable(i),
      if (i.groupKey == sholatWajibGroup)
        'w': _weight(data.logs[i.id], value, soloWeight, lastJamaah),
      if (prayer != null) ...{
        'at': schedule.times[prayer]!.millisecondsSinceEpoch,
        'end': window!.end.millisecondsSinceEpoch,
        'time': schedule.labels[prayer],
      },
      if (sholatTime && window != null && prayedAt != null && value > 0) ...{
        'status': sholatStatus(
          prayedAt,
          window,
          onTimeMinutes: onTimeMinutes,
        ).name,
        'prayed': calc.formatInZone(prayedAt.toUtc(), tz),
      },
    };
  }

  final progress = ibadahProgress(
    items,
    data.values,
    excused: data.excused,
    hasTilawah: data.hasTilawah,
    logs: data.logs,
    soloWeight: soloWeight,
  );

  return {
    'date': date,
    'kicker': day.isRamadan
        ? 'RAMADAN · HARI ${day.ramadanDay}'
        : '${_hari[d.weekday - 1]} · ${d.day} ${_bulan[d.month - 1]}',
    'hijri': day.hijri.format(),
    // Hari Tarwiyah/Arafah + item puasa sunnah (widget Semangat Sholat)
    if (dzulhijjahFastOf(day.hijri) case final fast?) 'fast': fast.name,
    if (items.where((i) => i.key == 'puasa_sunnah').firstOrNull case final i?)
      'fastItem': i.id,
    'excused': data.excused,
    'streak': ibadahStreak(data.summaries, date),
    'done': progress.done,
    'total': progress.total,
    'score': progress.score,
    'sholat': [
      for (final i in items)
        if (i.groupKey == sholatWajibGroup) entry(i),
    ],
    'items': [
      ?_rawatibEntry(items, data.values, data.excused),
      for (final i in items)
        if (i.groupKey != sholatWajibGroup && i.groupKey != rawatibGroup)
          entry(i),
    ],
  };
}

/// Id entri ringkasan rawatib di payload widget (bukan id item sungguhan).
const rawatibSummaryId = -1;

/// Rawatib diringkas jadi satu baris hitungan ("Sunnah rawatib 2/5") -
/// ketuk membuka aplikasi. Null bila tidak ada rawatib yang aktif.
Map<String, Object?>? _rawatibEntry(
  List<IbadahItem> items,
  Map<int, int> values,
  bool excused,
) {
  final rawatib = [
    for (final i in items)
      if (i.groupKey == rawatibGroup) i,
  ];
  if (rawatib.isEmpty) return null;
  final done = rawatib.where((i) => (values[i.id] ?? 0) > 0).length;
  return {
    'id': rawatibSummaryId,
    'name': 'Sunnah rawatib',
    'kind': 'counter',
    'value': done,
    'target': rawatib.length,
    'done': done >= rawatib.length,
    'excused': excused,
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
  final rawatib = [
    for (final i in data.items)
      if (i.groupKey == rawatibGroup) i,
  ];
  final soloWeight = (payload['soloWeight'] as num?)?.toDouble() ?? 1;
  final lastJamaah = payload['lastJamaah'] == true;
  var done = 0;
  var total = 0;
  var score = 0.0;
  for (final key in ['sholat', 'items']) {
    for (final e in (day[key] as List).cast<Map<String, Object?>>()) {
      if (e['id'] == rawatibSummaryId) {
        final n = rawatib.where((i) => (data.values[i.id] ?? 0) > 0).length;
        e['value'] = n;
        e['done'] = n >= rawatib.length;
        e['excused'] = data.excused;
        // tiap rawatib dihitung sendiri-sendiri di jumlah hari itu
        if (!data.excused) {
          total += rawatib.length;
          done += n;
          score += n;
        }
        continue;
      }
      final item = byId[e['id']];
      if (item == null) continue;
      final value = data.values[item.id] ?? 0;
      final isDone = itemDone(item, value, hasTilawah: data.hasTilawah);
      e['value'] = value;
      e['done'] = isDone;
      e['excused'] = data.excused && excusable(item);
      final w = item.groupKey == sholatWajibGroup
          ? _weight(data.logs[item.id], value, soloWeight, lastJamaah)
          : 1.0;
      if (item.groupKey == sholatWajibGroup) e['w'] = w;
      final prayedAt = data.logs[item.id]?.prayedAt;
      final at = e['at'], end = e['end'];
      if (payload['sholatTime'] == true &&
          prayedAt != null &&
          value > 0 &&
          at is int &&
          end is int) {
        e['status'] = sholatStatus(
          prayedAt,
          SholatWindow(
            DateTime.fromMillisecondsSinceEpoch(at),
            DateTime.fromMillisecondsSinceEpoch(end),
          ),
          onTimeMinutes:
              payload['onTimeMinutes'] as int? ?? defaultOnTimeMinutes,
        ).name;
      } else {
        e.remove('status');
      }
      if (e['excused'] != true) {
        total++;
        if (isDone) {
          done++;
          score += w;
        }
      }
    }
  }
  day['done'] = done;
  day['total'] = total;
  day['score'] = score;
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

/// Bobot sholat wajib di widget: yang sudah dicentang sesuai catatannya;
/// yang belum, sesuai pilihan jama'ah terakhir (dipakai bila dicentang dari
/// widget).
double _weight(IbadahLog? log, int value, double soloWeight, bool lastJamaah) =>
    sholatWeight(value > 0 ? log?.jamaah : lastJamaah, soloWeight);
