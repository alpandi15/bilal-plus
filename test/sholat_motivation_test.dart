import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/ibadah_report.dart';
import 'package:rindu_ramadan/services/sholat_motivation.dart';
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/widgets/ibadah/sholat_nudge_card.dart';

IbadahItem _sholat(int id, String key, String name) => IbadahItem(
  id: id,
  key: key,
  name: name,
  kind: IbadahKind.check,
  target: 1,
  scope: IbadahScope.daily,
  active: true,
  sort: id,
  builtIn: true,
  groupKey: sholatWajibGroup,
);

const _empty = IbadahReport(
  days: [],
  items: [],
  weekday: [],
  sholat: [],
  currentStreak: 0,
  longestStreak: 0,
);

// Jakarta, Senin 28 Sep 2026: Dzuhur ±11:45, Ashar ±15:00 WIB
final _items = [
  _sholat(1, 'subuh', 'Subuh'),
  _sholat(2, 'dzuhur', 'Dzuhur'),
  _sholat(3, 'ashar', 'Ashar'),
];

List<SholatNudge> _nudges(DateTime dzuhurAt) => sholatNudges(
  sholatItems: _items,
  todayValues: const {1: 1, 2: 1},
  todayPrayedAt: {
    1: DateTime.utc(2026, 9, 27, 22, 0), // 05:00 WIB
    2: dzuhurAt,
  },
  excusedToday: false,
  week: _empty,
  now: DateTime.utc(2026, 9, 28, 7, 30), // 14:30 WIB, belum Ashar
  today: '2026-09-28',
  latitude: -6.2,
  longitude: 106.8,
  onTimeMinutes: defaultOnTimeMinutes,
  tracking: true,
);

void main() {
  test('Dzuhur terlambat hari ini -> disemangati untuk Ashar', () {
    final n = _nudges(DateTime.utc(2026, 9, 28, 7, 15)); // 14:15 WIB
    expect(n, hasLength(1));
    expect(n.single.tone, SholatStatus.late);
    expect(n.single.title, startsWith('Dzuhur terlambat'));
    expect(n.single.message, contains('Ashar'));
  });

  test('Dzuhur di awal waktu -> tidak ada pesan', () {
    final n = _nudges(DateTime.utc(2026, 9, 28, 4, 50)); // 11:50 WIB
    expect(n, isEmpty);
  });

  test('pesan bervariasi antar hari, tetap sepanjang hari', () {
    final a = pickMessage(
      lateToday('Dzuhur', 'Ashar'),
      dailySeed('2026-09-28', 2),
    );
    final b = pickMessage(
      lateToday('Dzuhur', 'Ashar'),
      dailySeed('2026-09-28', 2),
    );
    final c = pickMessage(
      lateToday('Dzuhur', 'Ashar'),
      dailySeed('2026-09-29', 2),
    );
    expect(a, b);
    expect(a, isNot(c));
  });
}
