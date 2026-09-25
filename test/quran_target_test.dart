import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/services/quran_target.dart';

QuranCycle _cycle(String? targetDate) => QuranCycle(
  id: 1,
  startedAt: DateTime(2027, 2, 8),
  completed: false,
  targetDate: targetDate,
);

var _nextId = 1;
QuranLog _log(String date, int from, int to) => QuranLog(
  id: _nextId,
  cycleId: 1,
  date: date,
  fromAyah: from,
  toAyah: to,
  createdAt: DateTime(2027, 1, 1).add(Duration(minutes: _nextId++)),
);

int _endOfPage(int page) => pageRange(page).$2;

void main() {
  test('batas khatam: 30 hari dari 8 Feb = 9 Mar (hari ini termasuk)', () {
    expect(targetDateFor('2027-02-08', 30), '2027-03-09');
    expect(targetDateFor('2027-02-08', 1), '2027-02-08');
  });

  test('tanpa target = null', () {
    expect(
      dailyTarget(cycle: _cycle(null), logs: const [], today: '2027-02-08'),
      isNull,
    );
  });

  test('hari pertama 30 hari: ~20 halaman, sampai akhir Juz 1', () {
    final t = dailyTarget(
      cycle: _cycle('2027-03-09'),
      logs: const [],
      today: '2027-02-08',
    )!;
    expect(t.daysLeft, 30);
    expect(t.pagesPerDay, closeTo(604 / 30, 1e-9));
    expect(t.targetPage, 21);
    expect(t.targetAyah, juzRange(1).$2);
    expect(t.pagesToday, 0);
    expect(t.reached, isFalse);
  });

  test('bacaan hari ini dihitung, bacaan kemarin menggeser titik awal', () {
    final logs = [
      _log('2027-02-08', 1, _endOfPage(20)), // kemarin: 20 halaman
      _log('2027-02-09', _endOfPage(20) + 1, _endOfPage(30)), // hari ini: 10
    ];
    final t = dailyTarget(
      cycle: _cycle('2027-03-09'),
      logs: logs,
      today: '2027-02-09',
    )!;
    expect(t.daysLeft, 29);
    expect(t.pagesToday, closeTo(10, 1e-9));
    expect(t.pagesPerDay, closeTo((604 - 20) / 29, 1e-9));
    expect(t.targetPage, 41); // 20 + 20,1 -> akhir halaman 41
    expect(t.fraction, closeTo(10 / ((604 - 20) / 29), 1e-9));
  });

  test('tertinggal: beban disebar ke sisa hari', () {
    // hari ke-11 tanpa bacaan sama sekali
    final t = dailyTarget(
      cycle: _cycle('2027-03-09'),
      logs: const [],
      today: '2027-02-18',
    )!;
    expect(t.daysLeft, 20);
    expect(t.pagesPerDay, closeTo(604 / 20, 1e-9));
  });

  test('batas terlewat: seluruh sisa jadi target hari ini', () {
    final t = dailyTarget(
      cycle: _cycle('2027-03-09'),
      logs: [_log('2027-03-01', 1, _endOfPage(600))],
      today: '2027-03-12',
    )!;
    expect(t.overdue, isTrue);
    expect(t.daysLeft, 1);
    expect(t.pagesPerDay, closeTo(4, 1e-9));
    expect(t.targetAyah, totalAyahs);
  });

  test('target tercapai', () {
    final t = dailyTarget(
      cycle: _cycle('2027-02-09'), // 2 hari
      logs: [_log('2027-02-08', 1, _endOfPage(302))],
      today: '2027-02-08',
    )!;
    expect(t.reached, isTrue);
    expect(t.fraction, 1);
  });

  test('format halaman', () {
    expect(formatPages(20.13), '20,1');
    expect(formatPages(21), '21');
    expect(formatPages(0.04), '0');
  });
}
