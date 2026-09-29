import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

// 1 Ramadan 1448 = Senin 8 Feb 2027, 1 Syawal = Selasa 9 Mar 2027 (29 hari)
final _anchors = HijriConfig.parse(
  '{"anchors": {"1448-09": "2027-02-08", "1448-10": "2027-03-09"}}',
  origin: 'test',
).anchors;

IbadahItem _item(int id, String key, IbadahScope scope) => IbadahItem(
  id: id,
  key: key,
  name: key,
  kind: IbadahKind.check,
  target: 1,
  scope: scope,
  active: true,
  sort: id,
  builtIn: true,
);

void main() {
  group('Ramadan', () {
    test('malam sebelum puasa pertama = malam tarawih ke-1', () {
      final d = ibadahDay('2027-02-07', _anchors);
      expect(d.isRamadan, isFalse);
      expect(d.ramadanNight, 1);
    });

    test('hari pertama puasa', () {
      final d = ibadahDay('2027-02-08', _anchors);
      expect(d.ramadanDay, 1);
      expect(d.ramadanNight, 2);
      // Senin di bulan Ramadan bukan saran puasa sunnah
      expect(d.sunnahFastReasons, contains('Senin'));
      expect(d.sunnahFastSuggested, isFalse);
    });

    test('hari terakhir: malamnya takbiran, bukan tarawih', () {
      final d = ibadahDay('2027-03-08', _anchors);
      expect(d.ramadanDay, 29);
      expect(d.ramadanNight, isNull);
    });

    test('Idulfitri diharamkan puasa, 2 Syawal disarankan', () {
      final eid = ibadahDay('2027-03-09', _anchors);
      expect(eid.fastForbidden, isTrue);
      expect(eid.sunnahFastSuggested, isFalse);
      final syawal2 = ibadahDay('2027-03-10', _anchors);
      expect(syawal2.sunnahFastReasons, contains('Enam hari Syawal'));
      expect(syawal2.sunnahFastSuggested, isTrue);
    });
  });

  group('hari tertentu', () {
    // Jumat 12 Feb 2027 (Ramadan hari ke-5), Sabtu 13 Feb 2027
    final jumat = ibadahDay('2027-02-12', _anchors);
    final sabtu = ibadahDay('2027-02-13', _anchors);
    IbadahItem limited(IbadahScope scope, int? mask) =>
        _item(99, 'kahfi', scope).copyWith(weekdays: Value(mask));

    test('item harian hanya muncul di hari terpilih', () {
      final kahfi = limited(IbadahScope.daily, 1 << 4);
      expect(itemApplies(kahfi, jumat), isTrue);
      expect(itemApplies(kahfi, sabtu), isFalse);
      expect(itemApplies(limited(IbadahScope.daily, null), sabtu), isTrue);
    });

    test('bersama cakupan: Ramadan DAN Jumat', () {
      final item = limited(IbadahScope.ramadan, 1 << 4);
      expect(itemApplies(item, jumat), isTrue);
      expect(itemApplies(item, ibadahDay('2027-04-16', _anchors)), isFalse);
    });

    test('catatan lama tetap tampil walau bukan harinya', () {
      final kahfi = limited(IbadahScope.daily, 1 << 4);
      expect(visibleItems([kahfi], sabtu, const {}), isEmpty);
      expect(visibleItems([kahfi], sabtu, const {99: 1}), [kahfi]);
    });

    test('label hari', () {
      expect(weekdaysLabel(null), isNull);
      expect(weekdaysLabel(1 << 4), 'Jumat');
      expect(weekdaysLabel(1 | 1 << 3), 'Senin & Kamis');
      expect(weekdaysLabel(1 | 1 << 2 | 1 << 4), 'Sen, Rab, Jum');
      expect(weekdaysLabel(allWeekdays), isNull);
    });
  });

  group('puasa sunnah', () {
    test('Senin & Kamis', () {
      // 28 Sep 2026 kebetulan juga Ayyamul Bidh - alasannya digabung
      expect(
        ibadahDay('2026-09-28', _anchors).sunnahFastReasons,
        containsAll(['Ayyamul Bidh', 'Senin']),
      );
      expect(ibadahDay('2026-10-01', _anchors).sunnahFastReasons, ['Kamis']);
      expect(ibadahDay('2026-10-03', _anchors).sunnahFastSuggested, isFalse);
    });

    test('Ayyamul Bidh 13-15', () {
      for (final day in [13, 14, 15]) {
        final date = dateKey(_anchors.toGregorian(1448, 4, day));
        expect(
          ibadahDay(date, _anchors).sunnahFastReasons,
          contains('Ayyamul Bidh'),
        );
      }
    });

    test('Arafah disarankan, hari tasyrik diharamkan', () {
      final arafah = dateKey(_anchors.toGregorian(1448, 12, 9));
      expect(
        ibadahDay(arafah, _anchors).sunnahFastReasons,
        contains('Hari Arafah'),
      );
      final tasyrik = dateKey(_anchors.toGregorian(1448, 12, 13));
      // 13 Dzulhijjah juga Ayyamul Bidh - tetap haram
      final t = ibadahDay(tasyrik, _anchors);
      expect(t.fastForbidden, isTrue);
      expect(t.sunnahFastSuggested, isFalse);
    });

    test("Tasu'a & Asyura", () {
      final d9 = dateKey(_anchors.toGregorian(1449, 1, 9));
      final d10 = dateKey(_anchors.toGregorian(1449, 1, 10));
      expect(ibadahDay(d9, _anchors).sunnahFastReasons, contains("Tasu'a"));
      expect(ibadahDay(d10, _anchors).sunnahFastReasons, contains('Asyura'));
    });
  });

  group('item yang tampil', () {
    final items = [
      _item(1, 'subuh', IbadahScope.daily),
      _item(2, 'puasa', IbadahScope.ramadan),
      _item(3, 'tarawih', IbadahScope.ramadanNight),
      _item(4, 'puasa_sunnah', IbadahScope.sunnah),
    ];
    List<String> keys(String date, [Map<int, int> values = const {}]) => [
      for (final i in visibleItems(items, ibadahDay(date, _anchors), values))
        i.key,
    ];

    test('mengikuti hari', () {
      expect(keys('2027-02-07'), ['subuh', 'tarawih']);
      expect(keys('2027-02-08'), ['subuh', 'puasa', 'tarawih']);
      expect(keys('2027-03-08'), ['subuh', 'puasa']);
      expect(keys('2026-09-28'), ['subuh', 'puasa_sunnah']);
    });

    test('awal Ramadan bergeser: catatan yang sudah ada tetap tampil', () {
      // pengguna tarawih 7 Feb, lalu 1 Ramadan diundur ke 9 Feb
      final shifted = resolveAnchors(_anchors, {
        (1448, 9): gregorianToJdn(2027, 2, 9),
      });
      final day = ibadahDay('2027-02-07', shifted);
      expect(day.ramadanNight, isNull);
      expect(visibleItems(items, day, const {}).map((i) => i.key), ['subuh']);
      expect(visibleItems(items, day, const {3: 1}).map((i) => i.key), [
        'subuh',
        'tarawih',
      ]);
    });
  });

  group('selesai & streak', () {
    test('counter selesai saat mencapai target, tilawah otomatis', () {
      final istighfar = IbadahItem(
        id: 9,
        key: 'istighfar',
        name: 'Istighfar',
        kind: IbadahKind.counter,
        target: 100,
        scope: IbadahScope.daily,
        active: true,
        sort: 0,
        builtIn: true,
      );
      expect(itemDone(istighfar, 99), isFalse);
      expect(itemDone(istighfar, 100), isTrue);
      final tilawah = _item(10, tilawahKey, IbadahScope.daily);
      expect(itemDone(tilawah, 0), isFalse);
      expect(itemDone(tilawah, 0, hasTilawah: true), isTrue);
    });

    test('hari ini yang belum lengkap tidak memutus streak', () {
      const full = IbadahDaySummary(sholat: 5);
      final days = {
        '2027-02-05': full,
        '2027-02-06': const IbadahDaySummary(excused: true),
        '2027-02-07': full,
        '2027-02-08': const IbadahDaySummary(sholat: 2),
      };
      expect(ibadahStreak(days, '2027-02-08'), 3);
      expect(ibadahStreak({...days, '2027-02-08': full}, '2027-02-08'), 4);
      // bolong sehari memutus
      expect(ibadahStreak(days, '2027-02-10'), 0);
    });
  });
}
