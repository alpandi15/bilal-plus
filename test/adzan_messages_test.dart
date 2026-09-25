import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/adzan_messages.dart';
import 'package:rindu_ramadan/services/app_settings.dart';

void main() {
  final friday = DateTime.utc(2026, 9, 25);
  final saturday = DateTime.utc(2026, 9, 26);

  AdzanMessage msg(String key, DateTime date, Gender? g) => adzanMessage(
    key: key,
    date: date,
    time: '12:19 WIB',
    place: 'Kota Medan',
    gender: g,
  );

  test('laki-laki: Dzuhur hari Jumat menjadi Sholat Jumat', () {
    final m = msg('dzuhur', friday, Gender.male);
    expect(m.title, 'Waktunya Sholat Jumat · 12:19 WIB');
    expect(m.body, contains('masjid'));
    // perempuan & hari lain tetap Dzuhur
    expect(
      msg('dzuhur', friday, Gender.female).title,
      startsWith('Adzan Dzuhur'),
    );
    expect(
      msg('dzuhur', saturday, Gender.male).title,
      startsWith('Adzan Dzuhur'),
    );
  });

  test('laki-laki diajak ke masjid, perempuan diajak di awal waktu', () {
    for (var d = 0; d < 7; d++) {
      final date = saturday.add(Duration(days: d));
      for (final k in ['ashar', 'maghrib', 'isya']) {
        final male = msg(k, date, Gender.male).body;
        expect(male.toLowerCase(), contains('masjid'), reason: '$k $date');
        final female = msg(k, date, Gender.female).body;
        expect(female.toLowerCase(), isNot(contains('masjid')));
      }
    }
  });

  test('Subuh: ash-shalatu khairum minan naum', () {
    expect(
      msg('subuh', saturday, Gender.male).body,
      contains('khairum minan naum'),
    );
    expect(msg('subuh', saturday, null).body, contains('awal waktu'));
  });

  test('nama & lokasi terisi, narasi bergilir per tanggal', () {
    final bodies = {
      for (var d = 0; d < 6; d++)
        msg('ashar', saturday.add(Duration(days: d)), Gender.male).body,
    };
    expect(bodies.length, greaterThan(1));
    expect(bodies.every((b) => !b.contains('{')), isTrue);
  });

  test('pengingat sebelum adzan', () {
    final m = reminderMessage(
      key: 'dzuhur',
      date: friday,
      minutes: 15,
      gender: Gender.male,
    );
    expect(m.title, '15 menit lagi Jumat');
    expect(m.body, contains('berangkat ke masjid'));
    expect(
      reminderMessage(
        key: 'ashar',
        date: friday,
        minutes: 10,
        gender: Gender.female,
      ).body,
      contains('Siapkan wudhu'),
    );
  });
}
