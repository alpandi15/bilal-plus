import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/quran/mushaf_page.dart';
import 'package:rindu_ramadan/pages/quran/quran_reader_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/widgets/quran/quran_goto.dart';
import 'package:rindu_ramadan/widgets/quran/quran_ornaments.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    File('assets/quran/uthmani.json').readAsStringSync(),
  );

  group('halaman mushaf', () {
    test('604 halaman, urut & tanpa celah', () {
      var next = 1;
      for (var p = 1; p <= totalPages; p++) {
        final ayahs = quran.ayahsOnPage(p);
        expect(ayahs, isNotEmpty, reason: 'hlm $p');
        expect(ayahs.first.index, next, reason: 'hlm $p');
        next = ayahs.last.index + 1;
      }
      expect(next, totalAyahs + 1);
    });

    test('hlm 3 = Al-Baqarah 6-16 (seperti mushaf cetak)', () {
      final p3 = quran.ayahsOnPage(3);
      expect((p3.first.surah, p3.first.number), (2, 6));
      expect((p3.last.surah, p3.last.number), (2, 16));
      expect(quran.pageOfAyah(ayahIndex(83, 35)), 589);
      expect(pageOf(ayahIndex(83, 35)), 589); // sama dengan tracker
    });

    test('teks Utsmani terpasang per ayat', () {
      expect(quran.ayah(1).uthmani, startsWith('بِسۡمِ'));
      expect(quran.ayah(ayahIndex(2, 1)).uthmani, 'الٓمٓ');
      expect(quran.ayah(totalAyahs).uthmani, isNot(contains('\u00a0٦')));
    });

    test('tujuan "Pergi ke" -> ayat global', () {
      expect(targetAyahIndex(quran, const PageTarget(3)), ayahIndex(2, 6));
      expect(targetAyahIndex(quran, const AyahTarget(36, 1)), ayahIndex(36, 1));
      expect(arabicNumber(286), '٢٨٦');
    });
  });

  group('tampilan', () {
    late AppDatabase db;
    late AppSettingsController settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settings = AppSettingsController();
      db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    });
    tearDown(() => db.close());

    Future<void> open(WidgetTester tester, Widget page) async {
      // teks mushaf dimuat (di isolate) dengan waktu sungguhan SEBELUM
      // halaman dibangun - Future-nya lalu sudah selesai & di-cache
      await tester.runAsync(QuranText.load);
      tester.view.physicalSize = const Size(411, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AppDatabaseScope(
          database: db,
          child: UserLocationScope(
            controller: UserLocationController(),
            child: AppSettingsScope(
              controller: settings,
              child: MaterialApp(home: page),
            ),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
    }

    testWidgets('mushaf: halaman muat tanpa meluap & ingat halaman', (
      tester,
    ) async {
      await open(tester, const MushafPage(page: 3));
      expect(find.text('Juz 1 | Hlm. 3'), findsOneWidget);
      expect(find.byType(AyahMedallion), findsNWidgets(11)); // ayat 6-16
      expect(tester.takeException(), isNull);

      // geser ke kanan = halaman berikutnya
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Juz 1 | Hlm. 4'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(settings.quranLastPage, 4);
    });

    testWidgets('mushaf: awal surah punya spanduk & basmalah', (tester) async {
      await open(tester, const MushafPage(page: 2));
      expect(find.byType(SurahBanner), findsOneWidget);
      expect(find.byType(BasmalahLine), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('per surah: tab & pergi ke halaman', (tester) async {
      await open(tester, const QuranReaderPage(surah: 1));
      expect(find.text('1. Al-Fatihah'), findsWidgets);
      await tester.tap(find.byTooltip('Pergi ke'));
      // lembar naik: beberapa frame animasi
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.text('Halaman'));
      await tester.pump(const Duration(milliseconds: 400));
      // dari hlm 1: tambah dua halaman
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pump();
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pump();
      expect(find.text('Al-Baqarah 6–16'), findsOneWidget); // pratinjau
      await tester.ensureVisible(find.text('Buka halaman 3'));
      await tester.pump();
      await tester.tap(find.text('Buka halaman 3'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Juz 1 | Hlm. 3'), findsOneWidget);
      expect(find.textContaining('2. Al-Baqarah'), findsWidgets);
    });

    testWidgets('pergi ke: cari surah lalu pilih ayat', (tester) async {
      await open(tester, const QuranReaderPage(surah: 1));
      await tester.tap(find.byTooltip('Pergi ke'));
      // lembar naik: beberapa frame animasi
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.enterText(find.byType(TextField), 'yasin');
      await tester.pump();
      expect(find.text('Yasin'), findsOneWidget);
      expect(find.text('Al-Baqarah'), findsNothing);
      await tester.tap(find.text('Yasin'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('9'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('36. Yasin'), findsWidgets);
    });

    testWidgets('pilih mode: per surah / mushaf', (tester) async {
      await open(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showQuranModeSheet(context),
              child: const Text('buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
      expect(find.text("Al-Qur'an per Surah"), findsOneWidget);
      await tester.tap(find.text("Qur'an Indonesia (Mushaf)"));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(settings.quranMushaf, isTrue);
      expect(find.byType(MushafPage), findsOneWidget);
    });
  });
}
