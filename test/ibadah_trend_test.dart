import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/ibadah_report.dart';
import 'package:rindu_ramadan/utils/date_key.dart';
import 'package:rindu_ramadan/widgets/report/ibadah_trend_chart.dart';

DayScore _day(
  DateTime d, {
  int done = 5,
  int total = 10,
  bool excused = false,
  bool hasData = true,
}) => DayScore(
  date: dateKey(d),
  done: done,
  total: total,
  excused: excused,
  hasData: hasData,
  sholat: 0,
);

List<DayScore> _days(int n, DateTime last) => [
  for (var i = n - 1; i >= 0; i--) _day(last.subtract(Duration(days: i))),
];

void main() {
  final last = DateTime.utc(2026, 11, 5);
  const today = '2026-11-05';

  test('hanya mengambil rentang terakhir, urut naik', () {
    final p = trendPoints(_days(36, last), span: 30, today: today);
    expect(p.length, 30);
    expect(p.first.to, '2026-10-07');
    expect(p.last.to, today);
    expect(p.last.partial, isTrue);
    expect(p.first.partial, isFalse);
    expect(p.first.value, 0.5);
  });

  test('hari tak dihitung memutus garis, bukan 0%', () {
    final days = _days(4, last);
    days[0] = _day(last.subtract(const Duration(days: 3)), hasData: false);
    days[1] = _day(last.subtract(const Duration(days: 2)), excused: true);
    days[3] = _day(last, done: 0); // hari ini belum dicentang
    final p = trendPoints(days, span: 30, today: today);
    expect(p.map((e) => e.value), [null, null, 0.5, null]);
  });

  test('rentang panjang dirata-rata per pekan dari hari ini', () {
    final p = trendPoints(_days(364, last), span: 364, today: today);
    expect(p.length, 52);
    expect(p.last.to, today);
    expect(p.last.from, '2026-10-30');
    expect(p.last.value, 0.5);
  });

  testWidgets('sentuh grafik membaca satu titik', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: IbadahTrendChart(
              points: trendPoints(_days(30, last), span: 30, today: today),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Sentuh grafik'), findsOneWidget);
    await tester.tapAt(
      tester.getBottomRight(find.byType(CustomPaint).last) -
          const Offset(12, 60),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kam, 5 Nov: 50% (masih berjalan)'), findsOneWidget);
  });
}
