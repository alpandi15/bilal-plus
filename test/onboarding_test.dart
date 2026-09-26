import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/main.dart';
import 'package:rindu_ramadan/services/app_settings.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> flip(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RinduRamadanApp(database: db, homeWidgets: false));
    // splash -> setup/beranda (pengaturan dibaca dari penyimpanan tiruan)
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('pertama kali: splash, setup, lalu beranda dengan sapaan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(RinduRamadanApp(database: db, homeWidgets: false));
    expect(find.text('Teman ibadah harian'), findsOneWidget); // splash
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text("Assalamu'alaikum"), findsOneWidget);
    await tester.tap(find.text('Siapkan'));
    await flip(tester);

    await tester.enterText(find.byType(TextField), 'Ahmad');
    await tester.tap(find.text('Laki-laki'));
    await tester.pump();
    await tester.tap(find.text('Lanjut'));
    await flip(tester);

    expect(find.text('Izin aplikasi'), findsOneWidget);
    expect(find.text('Izinkan lokasi'), findsOneWidget);
    expect(find.text('Aktifkan'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await flip(tester);

    expect(find.text('Data Anda, milik Anda'), findsOneWidget);
    expect(find.text('Data Anda tetap di HP ini'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppSettings.onboardedKey), isTrue);
    expect(prefs.getString(AppSettings.userNameKey), 'Ahmad');
    expect(prefs.getString(AppSettings.genderKey), 'male');
    expect(find.text("Assalamu'alaikum, Ahmad"), findsOneWidget);
  });

  testWidgets('lewati langsung ke info privasi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await start(tester);
    await tester.tap(find.text('Lewati'));
    await flip(tester);
    expect(find.text('Data Anda, milik Anda'), findsOneWidget);
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets('sudah pernah setup: langsung beranda', (tester) async {
    SharedPreferences.setMockInitialValues({AppSettings.onboardedKey: true});
    await start(tester);
    expect(find.text('Selamat datang di Bilal+'), findsNothing);
    expect(find.text('Beranda'), findsOneWidget);
  });
}
