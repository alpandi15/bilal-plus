import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/asmaul_husna_data.dart';
import 'package:rindu_ramadan/data/silsilah_data.dart';
import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/pages/asmaul_husna_page.dart';
import 'package:rindu_ramadan/pages/silsilah_page.dart';
import 'package:rindu_ramadan/services/dzikir.dart';
import 'package:rindu_ramadan/widgets/ibadah/sholat_nudge_card.dart';

void main() {
  group('amalan Jumat', () {
    test('Al-Kahfi, sholawat & mandi Jumat hanya hari Jumat', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final items = await db.ibadahDao.watchItems(includeInactive: true).first;
      for (final key in [kahfiKey, 'sholawat', 'mandi_jumat']) {
        final item = items.firstWhere((i) => i.key == key);
        expect(appliesOnWeekday(item.weekdays, DateTime.friday), isTrue);
        expect(appliesOnWeekday(item.weekdays, DateTime.thursday), isFalse);
      }
      await db.close();
    });

    // 2026-10-02 = Jumat, 2026-10-01 = Kamis
    final maghribFri = DateTime(2026, 10, 2, 18);
    final maghribThu = DateTime(2026, 10, 1, 18);

    test('Jumat sebelum Maghrib bila Al-Kahfi belum', () {
      final n = fridayNudge(
        today: '2026-10-02',
        now: DateTime(2026, 10, 2, 9),
        maghribToday: maghribFri,
        kahfiDone: false,
      );
      expect(n?.openSurah, 18);
      expect(
        fridayNudge(
          today: '2026-10-02',
          now: DateTime(2026, 10, 2, 9),
          maghribToday: maghribFri,
          kahfiDone: true,
        ),
        isNull,
      );
      expect(
        fridayNudge(
          today: '2026-10-02',
          now: DateTime(2026, 10, 2, 19),
          maghribToday: maghribFri,
          kahfiDone: false,
        ),
        isNull,
      );
    });

    test('malam Jumat = Kamis setelah Maghrib', () {
      expect(
        fridayNudge(
          today: '2026-10-01',
          now: DateTime(2026, 10, 1, 19),
          maghribToday: maghribThu,
          kahfiDone: false,
        )?.title,
        contains('Malam Jumat'),
      );
      expect(
        fridayNudge(
          today: '2026-10-01',
          now: DateTime(2026, 10, 1, 12),
          maghribToday: maghribThu,
          kahfiDone: false,
        ),
        isNull,
      );
    });
  });

  group('dzikir setelah sholat', () {
    test('tahlil 10x hanya Subuh & Maghrib, ilman nafi\'a hanya Subuh', () {
      final subuh = dzikirFor(DzikirSession.sholat, prayer: 'subuh');
      final maghrib = dzikirFor(DzikirSession.sholat, prayer: 'maghrib');
      final dzuhur = dzikirFor(DzikirSession.sholat, prayer: 'dzuhur');
      expect(subuh.length, 12);
      expect(maghrib.length, 11);
      expect(dzuhur.length, 10);
      expect(subuh.map((d) => d.title), contains(contains('Kursi')));
    });

    test('pagi/petang tidak memuat dzikir sholat', () {
      final pagi = dzikirFor(DzikirSession.pagi);
      expect(pagi.any((d) => d.time == DzikirTime.sholat), isFalse);
    });

    test('sholat terakhir mengikuti waktu (Jakarta)', () {
      String at(int h, int m) => lastSholat(
        DateTime(2026, 10, 1, h, m),
        latitude: -6.2,
        longitude: 106.8,
      );
      expect(at(3, 0), 'isya');
      expect(at(6, 0), 'subuh');
      expect(at(13, 0), 'dzuhur');
      expect(at(16, 0), 'ashar');
      expect(at(18, 30), 'maghrib');
      expect(at(20, 0), 'isya');
    });
  });

  group('Asmaul Husna', () {
    test('99 nama berurutan & lengkap', () {
      expect(asmaulHusna.length, 99);
      for (var i = 0; i < 99; i++) {
        final a = asmaulHusna[i];
        expect(a.number, i + 1);
        expect(a.arabic, isNotEmpty);
        expect(a.latin, isNotEmpty);
        expect(a.arti, isNotEmpty);
      }
      expect(asmaulHusna.map((a) => a.latin).toSet().length, 99);
    });

    testWidgets('cari & buka detail', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AsmaulHusnaPage()));
      await tester.pump();
      expect(find.text('Ar-Rahman'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'sabar');
      await tester.pump();
      expect(find.text('Ash-Shabur'), findsOneWidget);
      expect(find.text('Ar-Rahman'), findsNothing);
      await tester.tap(find.text('Ash-Shabur'));
      await tester.pumpAndSettle();
      expect(find.text('99 / 99'), findsOneWidget);
    });
  });

  group('Silsilah Nabi', () {
    test("21 leluhur sampai 'Adnan, bertemu nasab ibu di Kilab", () {
      expect(silsilahNabi.length, 22);
      expect(silsilahNabi.first.latin, 'Muhammad ﷺ');
      expect(silsilahNabi.last.latin, "'Adnan");
      expect(silsilahNabi[6].latin, 'Kilab');
      expect(nasabIbu.last.latin, 'Kilab');
      // setiap leluhur punya nama Arab
      for (final p in silsilahNabi.skip(1)) {
        expect(p.arabic, isNotEmpty);
      }
    });

    testWidgets('tampil & bisa dibalik urutannya', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SilsilahPage()));
      await tester.pump();
      expect(find.text('Muhammad ﷺ'), findsOneWidget);
      await tester.tap(find.text("'Adnan").first);
      await tester.pump();
      // dari 'Adnan: kartu pertama di daftar adalah 'Adnan
      expect(find.text('Batas yang disepakati'), findsOneWidget);
    });
  });
}
