import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/quran/hafalan_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/hafalan_cue.dart';
import 'package:rindu_ramadan/services/hafalan_widget_payload.dart';
import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/widgets/arabic_font.dart';
import 'package:rindu_ramadan/widgets/hafalan_display_sheet.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    File('assets/quran/uthmani.json').readAsStringSync(),
  );

  group('kata awal', () {
    const ayah = 'اِنَّ مَعَ الْعُسْرِ يُسْرًا';
    test('jumlah kata dibatasi 1..3', () {
      expect(cueOf(ayah, 1), 'اِنَّ');
      expect(cueOf(ayah, 2), 'اِنَّ مَعَ');
      expect(cueOf(ayah, 3), 'اِنَّ مَعَ الْعُسْرِ');
      expect(cueOf(ayah, 9), 'اِنَّ مَعَ الْعُسْرِ'); // dibatasi 3
      expect(cueOf(ayah, 0), 'اِنَّ'); // minimal 1
    });

    test('ayat pendek tidak ada yang disembunyikan', () {
      expect(cueHides('قُلْ هُوَ', 3), isFalse);
      expect(cueHides(ayah, 1), isTrue);
    });

    test('pilihan widget dibaca dari pengaturan & dibatasi', () async {
      SharedPreferences.setMockInitialValues({
        'hafalan_widget_mode': 'cue',
        'hafalan_widget_count': 99,
        'hafalan_cue_words': 0,
      });
      final o = HafalanWidgetOptions.fromPrefs(
        await SharedPreferences.getInstance(),
      );
      expect((o.mode, o.count, o.words), (HafalanWidgetMode.cue, 8, 1));
      SharedPreferences.setMockInitialValues({});
      final d = HafalanWidgetOptions.fromPrefs(
        await SharedPreferences.getInstance(),
      );
      expect((d.mode, d.count, d.words), (HafalanWidgetMode.full, 5, 1));
    });
  });

  group('pengaturan', () {
    test('tersimpan & dimuat lagi', () async {
      SharedPreferences.setMockInitialValues({});
      final a = AppSettingsController();
      await a.init();
      expect((a.hafalanCue, a.cueWords, a.hafalanWidgetCount), (false, 1, 5));
      await a.setHafalanCue(true);
      await a.setCueWords(2);
      await a.setHafalanWidgetMode(HafalanWidgetMode.cue);
      await a.setHafalanWidgetCount(7);
      final b = AppSettingsController();
      await b.init();
      expect(b.hafalanCue, isTrue);
      expect(b.cueWords, 2);
      expect(b.hafalanWidgetMode, HafalanWidgetMode.cue);
      expect(b.hafalanWidgetCount, 7);
    });
  });

  test('data widget memuat mode, jumlah ayat & kata awal', () async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    await db.quranDao.setHafal(6232, 6232, true); // mulai dihafal
    final p = await hafalanWidgetPayload(
      db,
      () async => quran,
      font: QuranFont.lpmq,
      options: const HafalanWidgetOptions(
        mode: HafalanWidgetMode.cue,
        count: 6,
        words: 2,
      ),
    );
    expect((p['mode'], p['cueCount'], p['cueWords']), ('cue', 6, 2));
    // antrean cukup untuk jumlah ayat maksimum
    expect((p['queue'] as List).length, greaterThanOrEqualTo(5));
    // json-nya sah (dibaca Kotlin)
    expect(() => jsonDecode(jsonEncode(p)), returnsNormally);
  });

  group('halaman hafalan', () {
    late AppDatabase db;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    });
    tearDown(() => db.close());

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Widget app(AppSettingsController c) => AppDatabaseScope(
      database: db,
      child: AppSettingsScope(
        controller: c,
        child: MaterialApp(
          home: HafalanSurahPage(text: quran, surah: quran.surah(112)),
        ),
      ),
    );

    testWidgets('mode kata awal: hanya kata pertama, ketuk untuk mengintip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = AppSettingsController();
      await tester.runAsync(c.init);
      await tester.pumpWidget(app(c));
      await settle(tester);
      final first = quran
          .ayahsOf(112)
          .first
          .arabic; // قُلْ هُوَ اللّٰهُ اَحَدٌۚ
      expect(find.text(first), findsOneWidget); // ayat penuh

      await tester.tap(find.text('Kata awal'));
      await settle(tester);
      expect(c.hafalanCue, isTrue);
      expect(find.text(first), findsNothing);
      expect(find.text('${cueOf(first, 1)} …'), findsOneWidget);

      // ketuk baris = intip ayat utuh
      await tester.tap(find.text('${cueOf(first, 1)} …'));
      await settle(tester);
      expect(find.text(first), findsOneWidget);
    });

    testWidgets('lembar tampilan: ganti mode halaman & widget', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = AppSettingsController();
      await tester.runAsync(c.init);
      await tester.pumpWidget(app(c));
      await settle(tester);
      await tester.tap(find.byTooltip('Tampilan hafalan'));
      await settle(tester);
      expect(find.text('Tampilan hafalan'), findsWidgets);

      await tester.tap(find.text('Beberapa ayat'));
      await settle(tester);
      expect(c.hafalanWidgetMode, HafalanWidgetMode.cue);
      expect(find.text('JUMLAH AYAT DI WIDGET'), findsOneWidget);
      await tester.tap(find.text('7 ayat'));
      await settle(tester);
      expect(c.hafalanWidgetCount, 7);
      await tester.tap(find.text('2 kata'));
      await settle(tester);
      expect(c.cueWords, 2);
    });
  });

  test('lembar tampilan bisa dibuka dari mana saja', () {
    expect(showHafalanDisplaySheet, isA<Function>());
  });
}
