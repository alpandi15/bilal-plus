import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/models/prayer_models.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/ibadah_report.dart';
import 'package:rindu_ramadan/services/prayer_calculator.dart' as calc;
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

// Kota Medan
const _lat = 3.5952;
const _long = 98.6722;

SholatWindow _window(String key, String date) =>
    sholatWindow(key, parseDateKey(date), latitude: _lat, longitude: _long)!;

void main() {
  group('waktu & status sholat', () {
    test('Subuh sampai terbit, Isya sampai Subuh esok', () {
      final d = parseDateKey('2026-09-25');
      final t = calc.calculatePrayerTimes(
        latitude: _lat,
        longitude: _long,
        date: d,
      );
      final subuh = _window('subuh', '2026-09-25');
      expect(subuh.start, t.times[PrayerKey.fajr]);
      expect(subuh.end, t.times[PrayerKey.sunrise]);

      final isya = _window('isya', '2026-09-25');
      final next = calc.calculatePrayerTimes(
        latitude: _lat,
        longitude: _long,
        date: d.add(const Duration(days: 1)),
      );
      expect(isya.end, next.times[PrayerKey.fajr]);
    });

    test('awal waktu <= 15 menit, terlambat, qadha', () {
      final w = _window('subuh', '2026-09-25');
      final at = w.start;
      expect(sholatStatus(at, w), SholatStatus.onTime);
      expect(
        sholatStatus(at.add(const Duration(minutes: 15)), w),
        SholatStatus.onTime,
      );
      // contoh pengguna: adzan 05.00, sholat 05.30 -> terlambat
      expect(
        sholatStatus(at.add(const Duration(minutes: 30)), w),
        SholatStatus.late,
      );
      expect(
        sholatStatus(w.end.add(const Duration(minutes: 1)), w),
        SholatStatus.qadha,
      );
      // batas bisa diubah
      expect(
        sholatStatus(at.add(const Duration(minutes: 30)), w, onTimeMinutes: 30),
        SholatStatus.onTime,
      );
      expect(minutesAfterAdzan(at.add(const Duration(minutes: 30)), w), 30);
    });

    test('Isya lewat tengah malam masih terlambat, bukan qadha', () {
      final w = _window('isya', '2026-09-25');
      final lateNight = calc.atTimeInZone(
        calc.TimezoneCode.wib,
        parseDateKey('2026-09-26'),
        0,
        30,
      );
      expect(sholatStatus(lateNight, w), SholatStatus.late);
    });

    test('jam di zona lokasi bolak-balik', () {
      final at = calc.atTimeInZone(
        calc.TimezoneCode.wita,
        parseDateKey('2026-09-25'),
        5,
        30,
      );
      expect(at, DateTime.utc(2026, 9, 24, 21, 30));
      expect(calc.hourMinuteInZone(at, calc.TimezoneCode.wita), (5, 30));
    });
  });

  group('laporan', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> idOf(String key) async =>
        (await db.ibadahDao.watchItems(includeInactive: true).first)
            .firstWhere((i) => i.key == key)
            .id;

    Future<void> allSholat(String date, {int lateMinutes = 0}) async {
      for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
        await db.ibadahDao.setValue(
          date,
          await idOf(k),
          1,
          prayedAt: _window(k, date).start.add(Duration(minutes: lateMinutes)),
          place: k == 'subuh' ? 'rumah' : 'masjid',
        );
      }
    }

    Future<IbadahReport> report(String from, String to, String today) async =>
        buildIbadahReport(
          await db.ibadahDao.loadRange(from, to),
          anchors: HijriAnchors.none,
          today: today,
          latitude: _lat,
          longitude: _long,
        );

    test(
      'skor harian, per ibadah, per hari, kualitas sholat, streak',
      () async {
        // Senin 21 - Jumat 25 Sep 2026
        await allSholat('2026-09-21');
        await db.ibadahDao.setValue('2026-09-21', await idOf('sedekah'), 1);
        await allSholat('2026-09-22', lateMinutes: 30);
        await db.ibadahDao.setExcused('2026-09-23', true);
        await db.ibadahDao.setValue('2026-09-24', await idOf('subuh'), 1);
        await allSholat('2026-09-25');

        final r = await report('2026-09-14', '2026-09-30', '2026-09-25');

        // sebelum catatan pertama = kosong, sesudah hari ini tidak dihitung
        expect(r.days.first.hasData, isFalse);
        expect(r.days.last.date, '2026-09-25');
        final mon = r.days.firstWhere((d) => d.date == '2026-09-21');
        expect(mon.done, 6);
        expect(mon.total, greaterThan(6));
        expect(
          r.days.firstWhere((d) => d.date == '2026-09-23').excused,
          isTrue,
        );

        // Sedekah 1 dari 4 hari (hari berhalangan tidak gugurkan sedekah)
        final sedekah = r.items.firstWhere((s) => s.item.key == 'sedekah');
        expect((sedekah.done, sedekah.days), (1, 5));
        final subuh = r.items.firstWhere((s) => s.item.key == 'subuh');
        expect((subuh.done, subuh.days), (4, 4));
        expect(r.items.first.rate, greaterThanOrEqualTo(r.items.last.rate));

        // Senin lebih rajin dari Kamis; Sabtu/Minggu tanpa data
        expect(r.weekday[0]!, greaterThan(r.weekday[3]!));
        expect(r.weekday[5], isNull);

        final s = r.sholat.firstWhere((x) => x.item.key == 'subuh');
        expect((s.onTime, s.late, s.untimed, s.missed), (2, 1, 1, 0));
        expect(s.places, {'rumah': 3});
        final isya = r.sholat.firstWhere((x) => x.item.key == 'isya');
        expect(isya.missed, 1); // Kamis
        expect(r.sholatTotals, (10, 5, 0));

        // streak: Kamis bolong -> hanya Jumat
        expect(r.currentStreak, 1);
        expect(r.longestStreak, 3); // Sen, Sel, Rab (berhalangan)
      },
    );

    test('hari ini yang belum lengkap tidak memutus streak', () async {
      await allSholat('2026-09-23');
      await allSholat('2026-09-24');
      await db.ibadahDao.setValue('2026-09-25', await idOf('subuh'), 1);
      final r = await report('2026-09-20', '2026-09-25', '2026-09-25');
      expect(r.currentStreak, 2);
      // sholat hari ini yang belum dikerjakan bukan "terlewat"
      expect(r.sholat.firstWhere((x) => x.item.key == 'isya').missed, 0);
    });
  });
}
