import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/ibadah_insight.dart';
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

const _lat = 3.59, _long = 98.67;
// Senin 2026-09-21
const _date = '2026-09-21';

void main() {
  late AppDatabase db;
  setUp(
    () => db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
  tearDown(() => db.close());

  Future<int> idOf(String key) async =>
      (await db.ibadahDao.watchItems(includeInactive: true).first)
          .firstWhere((i) => i.key == key)
          .id;

  SholatWindow window(String key, String date) =>
      sholatWindow(key, parseDateKey(date), latitude: _lat, longitude: _long)!;

  Future<void> pray(
    String key, {
    String date = _date,
    int minutesAfter = 0,
    bool jamaah = true,
    bool afterEnd = false,
    String? reason,
  }) async {
    final w = window(key, date);
    await db.ibadahDao.setValue(
      date,
      await idOf(key),
      1,
      prayedAt: afterEnd
          ? w.end.add(Duration(minutes: minutesAfter))
          : w.start.add(Duration(minutes: minutesAfter)),
      place: 'masjid',
      jamaah: jamaah,
      qadhaReason: reason == null ? const Value.absent() : Value(reason),
    );
  }

  Future<DailyReport> daily(
    String date, {
    String? today,
    DateTime? now,
    bool male = true,
  }) async {
    final from = dateKey(parseDateKey(date).subtract(const Duration(days: 7)));
    return buildDailyReport(
      await db.ibadahDao.loadRange(from, date),
      date: date,
      today: today ?? '2026-09-30',
      anchors: HijriAnchors.none,
      latitude: _lat,
      longitude: _long,
      onTimeMinutes: 15,
      soloWeight: 1,
      male: male,
      now: now,
    );
  }

  bool has(List<Insight> l, String text) =>
      l.any((i) => i.title.contains(text) || i.detail.contains(text));

  group('laporan harian', () {
    test('lima waktu tepat waktu & berjama\'ah: banyak yang baik', () async {
      for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
        await pray(k);
      }
      final r = await daily(_date);
      expect(r.prayers.map((p) => p.state), everyElement(PrayerState.onTime));
      expect(has(r.good, 'Lima waktu tertunaikan'), isTrue);
      expect(has(r.good, 'Subuh di awal waktu'), isTrue);
      expect(has(r.good, '5 sholat tepat waktu'), isTrue);
      expect(has(r.good, 'Berjama\'ah 5 dari 5'), isTrue);
      expect(has(r.improve, 'terlewat'), isFalse);
      expect(r.tips, isNotEmpty);
      expect(r.categories.first.done, 5);
    });

    test('rujukan hadits memakai nomor kitab', () async {
      await pray('subuh');
      final r = await daily(_date);
      final refs = [...r.good, ...r.improve, ...r.tips].map((i) => i.ref);
      for (final ref in refs.whereType<String>()) {
        expect(ref, matches(RegExp(r'^HR\. [\w ]+ no\. \d+$')));
      }
      expect(refs, contains('HR. Muslim no. 1050'));
    });

    test('qadha tanpa uzur diperingatkan; terlewat dicatat', () async {
      await pray('subuh', afterEnd: true, minutesAfter: 20, reason: 'tanpa');
      await pray('dzuhur');
      final r = await daily(_date);
      expect(
        r.prayers.firstWhere((p) => p.key == 'subuh').state,
        PrayerState.qadha,
      );
      final warn = r.improve.firstWhere((i) => i.title.contains('tanpa uzur'));
      expect(warn.ref, 'HR. Muslim no. 116');
      // Ashar, Maghrib, Isya tidak dikerjakan pada hari yang sudah lewat
      final missed = r.improve.firstWhere((i) => i.title.contains('terlewat'));
      expect(missed.title, contains('Ashar'));
      expect(missed.ref, 'HR. Muslim no. 1103');
      // alarm sebelum adzan + tidur lebih awal (Subuh bermasalah)
      expect(has(r.tips, 'alarm'), isTrue);
      expect(has(r.tips, 'Tidur lebih awal'), isTrue);
    });

    test('qadha karena uzur tidak diancam, justru diapresiasi', () async {
      await pray('subuh', afterEnd: true, minutesAfter: 20, reason: 'tertidur');
      final r = await daily(_date);
      expect(
        r.prayers.firstWhere((p) => p.key == 'subuh').state,
        PrayerState.uzur,
      );
      expect(has(r.improve, 'tanpa uzur'), isFalse);
      expect(has(r.good, 'segera ditunaikan'), isTrue);
    });

    test('terlambat disebut dengan menitnya', () async {
      await pray('ashar', minutesAfter: 40);
      final r = await daily(_date);
      final late = r.improve.firstWhere((i) => i.title.contains('terlambat'));
      expect(late.title, contains('Ashar'));
      expect(late.detail, contains('40 menit'));
    });

    test(
      'laki-laki sholat sendiri disarankan ke masjid; perempuan tidak',
      () async {
        await pray('isya', jamaah: false);
        expect(has((await daily(_date)).improve, 'sendiri'), isTrue);
        expect(
          has((await daily(_date, male: false)).improve, 'sendiri'),
          isFalse,
        );
      },
    );

    test(
      'hari ini: sholat berjalan & yang belum masuk tidak dianggap terlewat',
      () async {
        final w = window('dzuhur', _date);
        final now = w.start.add(const Duration(minutes: 30));
        await pray('subuh');
        final r = await daily(_date, today: _date, now: now);
        expect(
          r.prayers.firstWhere((p) => p.key == 'dzuhur').state,
          PrayerState.ongoing,
        );
        expect(
          r.prayers.firstWhere((p) => p.key == 'isya').state,
          PrayerState.upcoming,
        );
        expect(has(r.improve, 'Dzuhur belum dikerjakan'), isTrue);
        expect(has(r.improve, 'Isya'), isFalse);
        // amalan lain yang belum: rekomendasi, bukan teguran
        expect(has(r.tips, 'Masih bisa hari ini'), isTrue);
      },
    );

    test('hari berhalangan', () async {
      await db.ibadahDao.setExcused(_date, true);
      final r = await daily(_date);
      expect(r.grade, Grade.berhalangan);
      expect(r.prayers.map((p) => p.state), everyElement(PrayerState.excused));
      expect(r.improve, isEmpty);
    });

    test('tanpa catatan: ajakan mulai', () async {
      final r = await daily('2026-09-10');
      expect(r.grade, Grade.kosong);
      expect(has(r.tips, 'Mulai dengan mencatat'), isTrue);
    });

    test('naik dari rata-rata sepekan', () async {
      // sepekan sebelumnya hampir kosong, hari ini penuh
      await pray('subuh', date: '2026-09-18');
      for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
        await pray(k);
      }
      final r = await daily(_date);
      expect(r.delta, greaterThan(0));
      expect(has(r.good, 'Naik'), isTrue);
    });
  });

  group('predikat', () {
    test('ambang skor', () {
      expect(gradeOf(0.97), Grade.luarBiasa);
      expect(gradeOf(0.85), Grade.sangatBaik);
      expect(gradeOf(0.65), Grade.baik);
      expect(gradeOf(0.4), Grade.cukup);
      expect(gradeOf(0.1), Grade.perluDitingkatkan);
      expect(gradeOf(0.9, excused: true), Grade.berhalangan);
      expect(gradeOf(0.9, hasData: false), Grade.kosong);
    });
  });

  group('laporan bulanan', () {
    Future<MonthlyReport> monthly(DateTime month) async {
      final (from, to) = monthRange(month);
      final prev = monthRange(DateTime.utc(month.year, month.month - 1, 1));
      return buildMonthlyReport(
        await db.ibadahDao.loadRange(from, to),
        month: month,
        today: '2026-10-31',
        anchors: HijriAnchors.none,
        latitude: _lat,
        longitude: _long,
        onTimeMinutes: 15,
        soloWeight: 1,
        male: true,
        previous: await db.ibadahDao.loadRange(prev.$1, prev.$2),
      );
    }

    test('rentang bulan', () {
      expect(monthRange(DateTime.utc(2026, 2, 1)), (
        '2026-02-01',
        '2026-02-28',
      ));
      expect(monthRange(DateTime.utc(2026, 12, 1)), (
        '2026-12-01',
        '2026-12-31',
      ));
    });

    test('ringkasan, kualitas sholat & rekomendasi', () async {
      for (final d in [
        '2026-09-21',
        '2026-09-22',
        '2026-09-23',
        '2026-09-24',
      ]) {
        for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
          await pray(k, date: d);
        }
      }
      // satu qadha tanpa uzur & Ashar terlewat di hari lain
      await pray(
        'subuh',
        date: '2026-09-25',
        afterEnd: true,
        minutesAfter: 5,
        reason: 'tanpa',
      );
      final r = await monthly(DateTime.utc(2026, 9, 1));
      expect(r.title, 'September 2026');
      expect(r.daysWithData, greaterThan(4));
      expect(r.onTime, 20);
      expect(r.qadha, 1);
      expect(r.missed, greaterThan(0));
      expect(r.jamaahPercent, 100);
      expect(
        has(r.good, '100% sholat di awal waktu') ||
            has(r.good, '% sholat di awal waktu'),
        isTrue,
      );
      expect(has(r.good, 'berjama'), isTrue);
      expect(has(r.improve, '1 sholat diqadha tanpa uzur'), isTrue);
      expect(has(r.improve, 'tidak tercatat'), isTrue);
      expect(r.tips, isNotEmpty);
      expect(r.tips.length, lessThanOrEqualTo(4));
    });

    test('bulan kosong', () async {
      final r = await monthly(DateTime.utc(2026, 3, 1));
      expect(r.grade, Grade.kosong);
      expect(r.good, isEmpty);
      expect(has(r.tips, 'Belum ada catatan'), isTrue);
    });
  });

  group('laporan mingguan', () {
    Future<WeeklyReport> weekly(
      DateTime monday, {
      String today = '2026-10-31',
    }) async {
      final (from, to) = weekRange(monday);
      final (pFrom, pTo) = weekRange(monday.subtract(const Duration(days: 7)));
      return buildWeeklyReport(
        await db.ibadahDao.loadRange(from, to),
        monday: monday,
        today: today,
        anchors: HijriAnchors.none,
        latitude: _lat,
        longitude: _long,
        onTimeMinutes: 15,
        soloWeight: 1,
        male: true,
        previous: await db.ibadahDao.loadRange(pFrom, pTo),
      );
    }

    test('Senin & rentang pekan', () {
      // 2026-09-23 = Rabu -> Senin 2026-09-21
      expect(mondayOf(DateTime.utc(2026, 9, 23)), DateTime.utc(2026, 9, 21));
      expect(mondayOf(DateTime.utc(2026, 9, 27)), DateTime.utc(2026, 9, 21));
      expect(mondayOf(DateTime.utc(2026, 9, 21)), DateTime.utc(2026, 9, 21));
      expect(weekRange(DateTime.utc(2026, 9, 21)), (
        '2026-09-21',
        '2026-09-27',
      ));
      expect(weekTitle(DateTime.utc(2026, 10, 26)), '26 Okt - 1 Nov 2026');
      expect(weekTitle(DateTime.utc(2026, 12, 28)), '28 Des 2026 - 3 Jan 2027');
    });

    test('ringkasan, hari terbaik/terendah & rekomendasi', () async {
      // Sen-Rab penuh tepat waktu, Kamis hanya Subuh qadha tanpa uzur
      for (final d in ['2026-09-21', '2026-09-22', '2026-09-23']) {
        for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
          await pray(k, date: d);
        }
      }
      await pray(
        'subuh',
        date: '2026-09-24',
        afterEnd: true,
        minutesAfter: 5,
        reason: 'tanpa',
      );
      final r = await weekly(DateTime.utc(2026, 9, 21));
      expect(r.title, '21 Sep - 27 Sep 2026');
      expect(r.onTime, 15);
      expect(r.qadha, 1);
      expect(r.jamaahPercent, 100);
      expect(r.bestDay, isNotNull);
      expect(r.worstDay, isNotNull);
      expect(has(r.good, 'berturut-turut'), isTrue);
      expect(has(r.good, '% sholat di awal waktu'), isTrue);
      expect(has(r.improve, '1 sholat diqadha tanpa uzur'), isTrue);
      expect(has(r.improve, 'tidak tercatat'), isTrue);
      expect(r.tips, isNotEmpty);
      expect(r.tips.length, lessThanOrEqualTo(4));
      for (final i in [...r.good, ...r.improve, ...r.tips]) {
        if (i.ref != null) {
          expect(i.ref, matches(RegExp(r'^HR\. [\w ]+ no\. \d+$')));
        }
      }
    });

    test('naik dari pekan lalu', () async {
      await pray('subuh', date: '2026-09-15');
      for (final d in ['2026-09-21', '2026-09-22', '2026-09-23']) {
        for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
          await pray(k, date: d);
        }
      }
      final r = await weekly(DateTime.utc(2026, 9, 21));
      expect(r.delta, greaterThanOrEqualTo(5));
      expect(has(r.good, 'Naik'), isTrue);
    });

    test('pekan kosong', () async {
      final r = await weekly(DateTime.utc(2026, 3, 2));
      expect(r.grade, Grade.kosong);
      expect(r.good, isEmpty);
      expect(has(r.tips, 'Belum ada catatan'), isTrue);
    });
  });

  test(
    'hutang sholat: saran mencicil hanya hari ini & bila ada hutang',
    () async {
      Future<DailyReport> report(String date, int debt) async =>
          buildDailyReport(
            await db.ibadahDao.loadRange('2026-09-20', date),
            date: date,
            today: '2026-09-21',
            anchors: HijriAnchors.none,
            latitude: _lat,
            longitude: _long,
            onTimeMinutes: 15,
            soloWeight: 1,
            male: true,
            sholatDebtLeft: debt,
          );
      expect(
        has((await report('2026-09-21', 12)).tips, 'Cicil hutang'),
        isTrue,
      );
      expect(
        has((await report('2026-09-21', 0)).tips, 'Cicil hutang'),
        isFalse,
      );
      expect(
        has((await report('2026-09-20', 12)).tips, 'Cicil hutang'),
        isFalse,
      );
    },
  );
}
