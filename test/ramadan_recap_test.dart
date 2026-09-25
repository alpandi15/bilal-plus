import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/services/ramadan_notices.dart';
import 'package:rindu_ramadan/services/ramadan_recap.dart';

// 1 Ramadan 1448 = 8 Feb 2027, 1 Syawal = 9 Mar 2027 (29 hari)
final _anchors = HijriConfig.parse(
  '{"anchors": {"1448-09": "2027-02-08", "1448-10": "2027-03-09"}}',
  origin: 'test',
).anchors;

void main() {
  late AppDatabase db;
  late IbadahDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.ibadahDao;
  });
  tearDown(() => db.close());

  Future<int> idOf(String key) async =>
      (await dao.watchItems(includeInactive: true).first)
          .firstWhere((i) => i.key == key)
          .id;

  Future<void> fast(String date) async =>
      dao.setValue(date, await idOf('puasa'), 1);

  group('ringkasan Ramadan', () {
    test('puasa, berhalangan, terlewat, tarawih, tilawah, khatam', () async {
      final r = ramadanOfYear(1448, _anchors);
      expect(r.days, 29);
      await fast('2027-02-08');
      await fast('2027-02-09');
      await dao.setExcused('2027-02-10', true);
      // 11 Feb terlewat, 12 Feb = hari ini
      await dao.setValue('2027-02-07', await idOf('tarawih'), 1); // malam 1
      await dao.setValue('2027-02-08', await idOf('tarawih'), 1);
      await dao.setValue('2027-03-08', await idOf('tarawih'), 1); // takbiran
      await db.quranDao.logReading(date: '2027-02-08', toAyah: juzRange(1).$2);
      await db.quranDao.logReading(date: '2027-02-01', toAyah: juzRange(2).$2);

      final s = await loadRamadanSummary(db, r, '2027-02-12');
      expect(s.fastedCount, 2);
      expect(s.stateOf('2027-02-10'), RamadanDayState.excused);
      expect(s.stateOf('2027-02-11'), RamadanDayState.missed);
      expect(s.stateOf('2027-02-12'), RamadanDayState.today);
      expect(s.stateOf('2027-02-13'), RamadanDayState.upcoming);
      expect(s.owed, 2);
      expect(s.tarawihCount, 2); // malam takbiran bukan tarawih
      expect(s.quranPages, closeTo(21, 1e-9)); // 1 Feb di luar Ramadan
      expect(s.khatam, 0);

      // khatam yang dicatat belakangan tetap terhitung di tanggal bacaannya
      await db.quranDao.logReading(date: '2027-02-11', toAyah: totalAyahs);
      final after = await loadRamadanSummary(db, r, '2027-02-12');
      expect(after.khatam, 1);
      expect(s.started, isTrue);
      expect(s.finished, isFalse);
    });
  });

  group('kunci rekap & qadha', () {
    test('dikunci hanya sesudah suasana Idulfitri dan bila ada data', () async {
      // tanpa data: tidak dikunci
      expect(await lockFinishedRamadans(db, _anchors, '2027-03-20'), isEmpty);

      for (var d = 8; d <= 28; d++) {
        await fast('2027-02-${d.toString().padLeft(2, '0')}');
      }
      // 3 Syawal (masih suasana Idulfitri): belum
      expect(await lockFinishedRamadans(db, _anchors, '2027-03-11'), isEmpty);
      // 4 Syawal: dikunci
      expect(await lockFinishedRamadans(db, _anchors, '2027-03-12'), [1448]);
      final recap = (await dao.recapOf(1448))!;
      expect(recap.days, 29);
      expect(recap.fasted, 21);
      // tidak dikunci dua kali
      expect(await lockFinishedRamadans(db, _anchors, '2027-03-13'), isEmpty);

      var q = await dao.qadhaStatus();
      expect(q.owed, 8);
      expect(q.remaining, 8);

      await dao.setValue('2027-03-15', await idOf(qadhaKey), 1);
      await dao.setValue('2027-03-16', await idOf(qadhaKey), 1);
      q = await dao.qadhaStatus();
      expect(q.paid, 2);
      expect(q.remaining, 6);
    });

    test('rekap terkunci tidak berubah walau jangkar bergeser', () async {
      await fast('2027-02-08');
      await lockFinishedRamadans(db, _anchors, '2027-04-01');
      final before = (await dao.recapOf(1448))!;
      final shifted = resolveAnchors(_anchors, {
        (1448, 9): gregorianToJdn(2027, 2, 9),
      });
      await lockFinishedRamadans(db, shifted, '2027-04-01');
      expect((await dao.recapOf(1448))!.fasted, before.fasted);
    });

    test('hutang manual tahun lalu ikut dihitung', () async {
      await dao.saveRecap(
        RamadanRecapsCompanion.insert(
          hijriYear: const Value(1446),
          days: 5,
          fasted: 0,
          excused: 0,
          manual: const Value(true),
          lockedAt: DateTime(2027),
        ),
      );
      expect((await dao.qadhaStatus()).remaining, 5);
      final data = await dao.loadDay(
        '2027-04-05',
        summariesFrom: '2027-01-01',
        summariesTo: '2027-04-05',
      );
      expect(data.qadhaRemaining, 5);
    });

    test(
      'item puasa qadha tampil hanya saat berhutang & boleh puasa',
      () async {
        final items = await dao.watchItems().first;
        bool shows(String date, int remaining) => visibleItems(
          items,
          ibadahDay(date, _anchors),
          const {},
          qadhaRemaining: remaining,
        ).any((i) => i.key == qadhaKey);

        expect(shows('2027-04-05', 0), isFalse);
        expect(shows('2027-04-05', 3), isTrue);
        expect(shows('2027-02-10', 3), isFalse); // Ramadan
        expect(shows('2027-03-09', 3), isFalse); // Idulfitri
      },
    );
  });

  group('kartu isbat', () {
    final tentative = HijriConfig.parse(
      '{"anchors": {"1448-09": {"date": "2027-02-08", "status": "tentative"},'
      ' "1448-10": "2027-03-09"}}',
      origin: 'test',
    ).anchors;

    test('muncul H-2 dan H-1 selama belum resmi', () {
      expect(isbatPrompt('2027-02-05', tentative), isNull);
      final p = isbatPrompt('2027-02-06', tentative)!;
      expect((p.hijriYear, p.month), (1448, 9));
      expect(p.expected, DateTime.utc(2027, 2, 8));
      expect(isbatPrompt('2027-02-07', tentative), isNotNull);
      expect(isbatPrompt('2027-02-08', tentative), isNull);
    });

    test('tidak muncul bila sudah resmi atau sudah dipilih sendiri', () {
      expect(isbatPrompt('2027-02-07', _anchors), isNull);
      final chosen = resolveAnchors(tentative, {
        (1448, 9): gregorianToJdn(2027, 2, 8),
      });
      expect(isbatPrompt('2027-02-07', chosen), isNull);
    });

    test('Syawal tanpa jangkar (perkiraan) juga ditanyakan', () {
      final onlyRamadan = HijriConfig.parse(
        '{"anchors": {"1448-09": "2027-02-08"}}',
        origin: 'test',
      ).anchors;
      final syawal = onlyRamadan.toGregorian(1448, 10, 1);
      final eve = syawal.subtract(const Duration(days: 1));
      final p = isbatPrompt(
        '${eve.year}-${eve.month.toString().padLeft(2, '0')}-'
        '${eve.day.toString().padLeft(2, '0')}',
        onlyRamadan,
      )!;
      expect(p.month, 10);
    });
  });

  group('pemberitahuan pergeseran', () {
    test(
      'kali pertama dicatat, berikutnya diberi tahu bila bergeser',
      () async {
        SharedPreferences.setMockInitialValues({});
        final notices = await RamadanNotices.load();
        final r = ramadanOfYear(1448, _anchors);
        expect(notices.shiftOf(r), isNull);
        expect(notices.shiftOf(r), isNull);

        final shifted = ramadanOfYear(
          1448,
          resolveAnchors(_anchors, {(1448, 9): gregorianToJdn(2027, 2, 9)}),
        );
        final shift = notices.shiftOf(shifted)!;
        expect((shift.from, shift.to), ('2027-02-08', '2027-02-09'));
        await notices.acknowledgeShift(shift);
        expect(notices.shiftOf(shifted), isNull);
      },
    );
  });
}
