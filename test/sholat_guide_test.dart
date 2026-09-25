import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/data/sholat_data.dart';
import 'package:rindu_ramadan/pages/settings_page.dart';
import 'package:rindu_ramadan/pages/sholat_guide_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/sholat_guide.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';

void main() {
  group('data bacaan sholat', () {
    test('lengkap & bersih', () {
      for (final s in sholatSteps) {
        expect(s.variants, isNotEmpty, reason: s.id);
        for (final v in s.variants) {
          expect(v.arabic, isNotEmpty);
          expect(v.latin, isNotEmpty);
          expect(v.arti, isNotEmpty);
          // glyph yang tidak ada di font LPMQ & sisa penanda sumber
          expect(v.arabic, isNot(contains('ٱ')), reason: v.label);
          expect(v.arabic, isNot(contains('﻿')), reason: v.label);
          expect(v.arabic, isNot(contains('((')), reason: v.label);
          expect(v.arabic, isNot(contains('ثلاث')), reason: v.label);
        }
      }
    });

    test('setiap madzhab punya versi bawaan, kecuali yang memang tidak', () {
      for (final m in Madzhab.values) {
        for (final s in sholatSteps) {
          final skip =
              (s.id == 'iftitah' && m == Madzhab.maliki) ||
              (s.id == 'qunut' &&
                  (m == Madzhab.hanafi || m == Madzhab.hanbali));
          expect(s.defaultFor(m) == null, skip, reason: '${s.id} ${m.name}');
        }
      }
    });

    test('urutan langkah per sholat', () {
      final subuh = sholatStepsFor(Fardhu.subuh, SholatRole.sendiri);
      final ids = subuh.map((s) => s.id).toList();
      expect(ids.first, 'niat');
      expect(ids.indexOf('qunut'), ids.indexOf('itidal') + 1);
      expect(ids, isNot(contains('tasyahud_awal')));
      expect(ids.last, 'salam');

      final maghrib = sholatStepsFor(Fardhu.maghrib, SholatRole.makmum);
      expect(maghrib.map((s) => s.id), contains('tasyahud_awal'));
      expect(maghrib.map((s) => s.id), isNot(contains('qunut')));
      final niat = maghrib.first.variants.single;
      expect(niat.arabic, contains('الْمَغْرِبِ'));
      expect(niat.arabic, contains('مَأْمُومًا'));
      expect(niat.arti, contains('tiga rakaat'));
    });
  });

  group('halaman', () {
    late AppSettingsController settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settings = AppSettingsController();
    });

    Future<void> open(WidgetTester tester, Widget page) async {
      tester.view.physicalSize = const Size(411, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UserLocationScope(
          controller: UserLocationController(),
          child: HijriConfigScope(
            controller: HijriConfigController(remoteUrl: ''),
            child: AppSettingsScope(
              controller: settings,
              child: MaterialApp(home: page),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('ganti madzhab & versi', (tester) async {
      await open(tester, const SholatGuidePage());
      expect(find.text('Bacaan Sholat'), findsOneWidget);
      // Syafi'i: iftitah versi Indonesia tampil
      expect(find.textContaining('Allaahu akbar kabiiraa'), findsOneWidget);

      await tester.tap(find.text('Maliki'));
      await tester.pump();
      expect(settings.madzhab, Madzhab.maliki);
      expect(
        find.textContaining('Tidak dibaca menurut madzhab Maliki'),
        findsWidgets,
      );
      expect(find.textContaining('Allaahu akbar kabiiraa'), findsNothing);

      // bandingkan: pilih versi lain secara manual
      await tester.ensureVisible(find.text('Pendek (Subhanaka)'));
      await tester.pump();
      await tester.tap(find.text('Pendek (Subhanaka)'));
      await tester.pump();
      expect(
        find.textContaining('Subhaanakallaahumma wa bihamdika'),
        findsOneWidget,
      );
    });

    testWidgets('pilih sholat mengubah niat', (tester) async {
      await open(tester, const SholatGuidePage());
      expect(find.textContaining('fardhash shubhi'), findsOneWidget);
      await tester.tap(find.text('Isya'));
      await tester.pump();
      expect(find.textContaining("fardhal 'isyaa-i"), findsOneWidget);
      await tester.tap(find.text('Imam'));
      await tester.pump();
      expect(find.textContaining('imaaman'), findsOneWidget);
    });

    testWidgets('pengaturan menampilkan info privasi', (tester) async {
      await open(tester, const SettingsPage());
      await tester.scrollUntilVisible(
        find.text('Data Anda tetap di HP ini'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('PRIVASI & DATA'), findsOneWidget);
    });
  });
}
