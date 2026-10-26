import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/ibadah_report.dart';
import 'package:rindu_ramadan/widgets/report/ibadah_heatmap.dart';

DayScore day(
  String date, {
  int qadha = 0,
  int uzur = 0,
  bool excused = false,
}) => DayScore(
  date: date,
  done: 5,
  total: 10,
  excused: excused,
  hasData: true,
  sholat: 5,
  qadha: qadha,
  uzur: uzur,
);

void main() {
  testWidgets('pita qadha: tinggi mengikuti jumlah, warna sesuai alasan', (
    tester,
  ) async {
    final days = [
      day('2026-09-21'),
      day('2026-09-22', qadha: 1),
      day('2026-09-23', qadha: 3),
      day('2026-09-24', uzur: 2),
      day('2026-09-25', qadha: 1, uzur: 1),
      day('2026-09-26', qadha: 2, excused: true),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ContributionCalendar(days: days, cell: 40)),
      ),
    );

    double? fill(int i) {
      final cell = find
          .byType(FractionallySizedBox)
          .evaluate()
          .map((e) => e.widget as FractionallySizedBox)
          .where((w) => w.heightFactor != null && w.widthFactor == null)
          .toList();
      return i < cell.length ? cell[i].heightFactor : null;
    }

    // hari tanpa qadha & hari berhalangan tidak punya pita: 4 pita
    expect(find.byType(FractionallySizedBox), findsNWidgets(4));
    final one = fill(0)!, three = fill(1)!, two = fill(2)!;
    expect(one, closeTo(0.2, 1e-9));
    expect(three, greaterThan(one));
    expect(two, greaterThan(one));
    expect(two, lessThan(three));

    // hari 25 memuat kedua warna berdampingan
    final colors = find
        .byType(ColoredBox)
        .evaluate()
        .map((e) => (e.widget as ColoredBox).color)
        .toList();
    expect(colors, contains(qadhaColor));
    expect(colors, contains(uzurColor));
  });

  test('keterangan hari memuat jumlah qadha', () {
    expect(day('2026-09-22', qadha: 2, uzur: 1).qadha, 2);
    expect(day('2026-09-22').withQadha(1, 2).uzur, 2);
  });
}
