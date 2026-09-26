import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/dzikir_page.dart';
import 'package:rindu_ramadan/pages/ibadah_page.dart';
import 'package:rindu_ramadan/pages/tasbih_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/dzikir.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';

void main() {
  late AppDatabase db;
  late AppSettingsController settings;
  late List<String> haptics;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    settings = AppSettingsController();
    haptics = [];
    // getar lewat kanal native (lib/services/haptics.dart): catat polanya
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('bilalplus/haptics'), (
          call,
        ) async {
          haptics.add('${call.arguments}');
          return true;
        });
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> open(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(411, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: UserLocationScope(
          controller: UserLocationController(),
          child: HijriConfigScope(
            controller: HijriConfigController(remoteUrl: ''),
            child: AppSettingsScope(
              controller: settings,
              child: MaterialApp(home: page),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('rawatib: pil di bawah sholat, sekali ketuk tercentang', (
    tester,
  ) async {
    await open(tester, const IbadahPage());
    expect(find.text('SUNNAH RAWATIB'), findsOneWidget);
    expect(find.text('0/5'), findsWidgets);
    // Subuh: Qabl; Dzuhur: Qabl & Ba'd; Maghrib & Isya: Ba'd
    expect(find.text('Qabl'), findsNWidgets(2));
    expect(find.text("Ba'd"), findsNWidgets(3));

    await tester.tap(find.bySemanticsLabel(RegExp('^Qabliyah Subuh')));
    await settle(tester);
    final items = await tester.runAsync(() => db.ibadahDao.watchItems().first);
    final id = items!.firstWhere((i) => i.key == 'qabliyah_subuh').id;
    final log = await tester.runAsync(
      () => (db.select(
        db.ibadahLogs,
      )..where((l) => l.itemId.equals(id))).getSingleOrNull(),
    );
    expect(log?.value, 1);
    // "Sholat rawatib" lama tidak lagi tampil sebagai baris
    expect(find.text('Sholat rawatib'), findsNothing);
  });

  testWidgets('dzikir: hitung sampai selesai mencentang checklist', (
    tester,
  ) async {
    await open(tester, const DzikirPage(session: DzikirSession.petang));
    expect(find.text('Dzikir Petang'), findsOneWidget);
    expect(find.text('Ayat Kursi'), findsOneWidget);

    // tandai selesai semua lewat tombol di akhir daftar
    await tester.scrollUntilVisible(
      find.text('Tandai selesai'),
      600,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Tandai selesai'));
    await settle(tester);
    final items = await tester.runAsync(() => db.ibadahDao.watchItems().first);
    final id = items!.firstWhere((i) => i.key == 'dzikir_petang').id;
    final log = await tester.runAsync(
      () => (db.select(
        db.ibadahLogs,
      )..where((l) => l.itemId.equals(id))).getSingleOrNull(),
    );
    expect(log?.value, 1);
    // selesai semua: pola getar "complete", beda dari hitungan biasa
    expect(haptics, ['complete']);
  });

  testWidgets('dzikir: tombol hitung maju & bergetar', (tester) async {
    await open(tester, const DzikirPage(session: DzikirSession.pagi));
    // Al-Ikhlas dkk: 3x
    // kartu 3x pertama = Al-Ikhlas, Al-Falaq & An-Nas
    await tester.scrollUntilVisible(
      find.text('0/3'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    await tester.tap(find.text('0/3').first);
    await settle(tester);
    expect(find.text('1/3'), findsOneWidget);
    expect(haptics, ['tap']);
  });

  testWidgets('tasbih: ketuk layar menambah, getar bisa dimatikan', (
    tester,
  ) async {
    var saved = 0;
    await open(
      tester,
      TasbihPage(title: 'Istighfar', target: 3, onChanged: (v) => saved = v),
    );
    await tester.tapAt(const Offset(200, 900));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1'), findsOneWidget);
    expect(saved, 1);
    expect(haptics, ['tap']);

    await tester.tap(find.byTooltip('Matikan getar'));
    await tester.pump();
    expect(settings.haptic, isFalse);
    haptics.clear();

    await tester.tapAt(const Offset(200, 900));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(200, 900));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Masyaa Allah, selesai'), findsOneWidget);
    expect(haptics, isEmpty);
    expect(saved, 3);
  });

  testWidgets('tasbih: getar berbeda saat target tercapai', (tester) async {
    await open(tester, const TasbihPage(title: 'Istighfar', target: 3));
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(const Offset(200, 900));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(haptics, ['tap', 'tap', 'target']);
  });

  testWidgets('tasbih bebas: pilih bacaan', (tester) async {
    await open(
      tester,
      const TasbihPage(
        title: 'Subhanallah',
        target: 33,
        presets: tasbihPresets,
      ),
    );
    // daftar pilihan bergulir mendatar
    await tester.scrollUntilVisible(
      find.text('Istighfar 100×'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Istighfar 100×'));
    await tester.pump();
    await tester.tap(find.text('Istighfar 100×'));
    await tester.pump();
    expect(find.text('dari 100'), findsOneWidget);
    expect(find.text('أَسْتَغْفِرُ اللَّهَ'), findsOneWidget);
  });
}
