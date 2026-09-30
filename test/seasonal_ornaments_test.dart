import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/models/prayer_models.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/widgets/prayer_widget_sky_frame.dart';
import 'package:rindu_ramadan/widgets/sky/seasonal_ornaments.dart';

void main() {
  test('musim: Ramadan sebulan, Idulfitri sampai 3 Syawal', () {
    expect(skySeasonOf(const HijriDate(1448, 8, 29)), SkySeason.normal);
    expect(skySeasonOf(const HijriDate(1448, 9, 1)), SkySeason.ramadan);
    expect(skySeasonOf(const HijriDate(1448, 9, 30)), SkySeason.ramadan);
    // malam takbiran = 1 Syawal (tanggal hijriah berganti saat Maghrib)
    expect(skySeasonOf(const HijriDate(1448, 10, 1)), SkySeason.eid);
    expect(skySeasonOf(const HijriDate(1448, 10, 3)), SkySeason.eid);
    expect(skySeasonOf(const HijriDate(1448, 10, 4)), SkySeason.normal);
    // Iduladha: malam takbiran (10) sampai akhir tasyrik (13)
    expect(skySeasonOf(const HijriDate(1448, 12, 9)), SkySeason.normal);
    expect(skySeasonOf(const HijriDate(1448, 12, 10)), SkySeason.adha);
    expect(skySeasonOf(const HijriDate(1448, 12, 13)), SkySeason.adha);
    expect(skySeasonOf(const HijriDate(1448, 12, 14)), SkySeason.normal);
  });

  test('kembang api: malam Idulfitri & malam takbiran Iduladha saja', () {
    expect(skyFireworksOf(const HijriDate(1448, 10, 1)), isTrue);
    expect(skyFireworksOf(const HijriDate(1448, 10, 3)), isTrue);
    expect(skyFireworksOf(const HijriDate(1448, 12, 10)), isTrue);
    expect(skyFireworksOf(const HijriDate(1448, 12, 11)), isFalse);
    expect(skyFireworksOf(const HijriDate(1448, 9, 27)), isFalse);
  });

  testWidgets('ornamen tergambar di setiap musim, fase & lapisan', (
    tester,
  ) async {
    for (final season in SkySeason.values) {
      for (final phase in DayPhase.values) {
        await tester.pumpWidget(
          SizedBox(
            width: 360,
            height: 220,
            child: SeasonalOrnaments(
              season: season,
              phase: phase,
              clockMs: 21400,
              fireworks: true,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
      for (final layer in [OrnamentLayer.hangers, OrnamentLayer.fireworks]) {
        for (final night in [false, true]) {
          await tester.pumpWidget(
            Center(
              child: PrayerWidgetOrnamentFrame(
                season: season,
                night: night,
                layer: layer,
                clockMs: 20000,
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
    // di luar musim tidak ada yang digambar
    await tester.pumpWidget(
      const SeasonalOrnaments(season: SkySeason.normal, phase: DayPhase.night),
    );
    expect(find.byType(CustomPaint), findsNothing);
  });
}
