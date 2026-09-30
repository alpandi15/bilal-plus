import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/widgets/ibadah/sholat_nudge_card.dart';

// 1 Dzulhijjah 1448 = Jumat 7 Mei 2027: Tarwiyah 14 Mei, Arafah 15 Mei,
// Iduladha 16 Mei
final _anchors = HijriConfig.parse(
  '{"anchors": {"1448-12": "2027-05-07", "1449-01": "2027-06-06"}}',
  origin: 'test',
).anchors;

final _puasa = IbadahItem(
  id: 20,
  key: 'puasa_sunnah',
  name: 'Puasa sunnah',
  kind: IbadahKind.check,
  target: 1,
  scope: IbadahScope.sunnah,
  active: true,
  sort: 20,
  builtIn: true,
);

SholatNudge? _nudge(
  String today,
  DateTime now, {
  bool done = false,
  bool excused = false,
}) => fastNudge(
  today: today,
  anchors: _anchors,
  now: now,
  maghribToday: DateTime(
    2027,
    5,
    1,
    18,
    5,
  ).copyWith(year: now.year, month: now.month, day: now.day),
  fastItem: _puasa,
  fastDone: done,
  excusedToday: excused,
);

void main() {
  test('Tarwiyah & Arafah dikenali sebagai puasa sunnah', () {
    expect(ibadahDay('2027-05-14', _anchors).sunnahFastReasons, [
      'Hari Tarwiyah',
    ]);
    expect(
      ibadahDay('2027-05-15', _anchors).sunnahFastReasons,
      contains('Hari Arafah'),
    );
    expect(
      dzulhijjahFastOf(const HijriDate(1448, 12, 8)),
      DzulhijjahFast.tarwiyah,
    );
    expect(
      dzulhijjahFastOf(const HijriDate(1448, 12, 9)),
      DzulhijjahFast.arafah,
    );
    expect(dzulhijjahFastOf(const HijriDate(1448, 12, 10)), isNull);
  });

  test('kartu pengingat: harinya (sebelum Maghrib) & sore sebelumnya', () {
    // Arafah siang, belum puasa -> kartu dengan tombol Catat
    final day = _nudge('2027-05-15', DateTime(2027, 5, 15, 10));
    expect(day?.title, 'Hari ini Hari Arafah 🌙');
    expect(day?.item, _puasa);

    // sudah dicatat / berhalangan -> tak ada kartu hari ini
    expect(_nudge('2027-05-15', DateTime(2027, 5, 15, 10), done: true), isNull);
    expect(
      _nudge('2027-05-15', DateTime(2027, 5, 15, 10), excused: true),
      isNull,
    );

    // Tarwiyah pagi: kartu Tarwiyah; Tarwiyah sesudah Maghrib: "Besok Arafah"
    expect(
      _nudge('2027-05-14', DateTime(2027, 5, 14, 9))?.title,
      'Hari ini Hari Tarwiyah 🌙',
    );
    final eve = _nudge('2027-05-14', DateTime(2027, 5, 14, 19));
    expect(eve?.title, 'Besok Hari Arafah 🌙');
    expect(eve?.item, isNull);

    // sehari sebelum Tarwiyah: baru muncul mulai sore
    expect(_nudge('2027-05-13', DateTime(2027, 5, 13, 10)), isNull);
    expect(
      _nudge('2027-05-13', DateTime(2027, 5, 13, 16))?.title,
      'Besok Hari Tarwiyah 🌙',
    );

    // hari biasa
    expect(_nudge('2027-05-20', DateTime(2027, 5, 20, 16)), isNull);
  });
}
