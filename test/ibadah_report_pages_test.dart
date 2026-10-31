import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/ibadah_daily_report_page.dart';
import 'package:rindu_ramadan/pages/ibadah_monthly_report_page.dart';
import 'package:rindu_ramadan/pages/ibadah_page.dart';
import 'package:rindu_ramadan/pages/ibadah_weekly_report_page.dart';
import 'package:rindu_ramadan/pages/report_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/prayer_calculator.dart' as calc;
import 'package:rindu_ramadan/services/report_export.dart';
import 'package:rindu_ramadan/services/sholat_time.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/utils/date_key.dart';
import 'package:rindu_ramadan/widgets/report/ibadah_heatmap.dart';

void main() {
  late AppDatabase db;
  late String today;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    // lokasi bawaan (Medan, WIB)
    today = dateKey(calc.todayInZone(calc.TimezoneCode.wib));
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Widget app(Widget home) => AppDatabaseScope(
    database: db,
    child: UserLocationScope(
      controller: UserLocationController(),
      child: HijriConfigScope(
        controller: HijriConfigController(remoteUrl: ''),
        child: AppSettingsScope(
          controller: AppSettingsController(),
          child: MaterialApp(home: home),
        ),
      ),
    ),
  );

  Future<void> pray(String key, {int minutesAfter = 0}) async {
    final items = await db.ibadahDao.watchItems().first;
    final id = items.firstWhere((i) => i.key == key).id;
    final w = sholatWindow(
      key,
      parseDateKey(today),
      latitude: 3.59,
      longitude: 98.67,
    )!;
    await db.ibadahDao.setValue(
      today,
      id,
      1,
      prayedAt: w.start.add(Duration(minutes: minutesAfter)),
      place: 'masjid',
      jamaah: true,
    );
  }

  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(411, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('laporan harian: skor, sholat & tiga bagian wawasan', (
    tester,
  ) async {
    size(tester);
    await tester.runAsync(() async {
      await pray('subuh');
      await pray('dzuhur', minutesAfter: 50);
    });
    await tester.pumpWidget(app(IbadahDailyReportPage(date: today)));
    await settle(tester);

    expect(find.text('Laporan Ibadah Harian'), findsOneWidget);
    expect(find.text('SHOLAT LIMA WAKTU'), findsOneWidget);
    expect(find.text('RINCIAN IBADAH'), findsOneWidget);
    expect(find.text('Yang sudah baik'), findsOneWidget);
    expect(find.text('Perlu ditingkatkan'), findsWidgets);
    expect(find.text('Rekomendasi untukmu'), findsOneWidget);
    expect(find.text('Subuh di awal waktu'), findsOneWidget);
    // tombol unduh
    expect(find.text('Gambar'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
  });

  testWidgets('laporan harian: geser hari, hari ini tidak bisa maju', (
    tester,
  ) async {
    size(tester);
    await tester.pumpWidget(app(IbadahDailyReportPage(date: today)));
    await settle(tester);
    final next = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    await settle(tester);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
    final yesterday = dateKey(
      parseDateKey(today).subtract(const Duration(days: 1)),
    );
    expect(find.text('Belum ada catatan'), findsWidgets);
    expect(find.textContaining(yesterday.substring(8)), findsWidgets);
  });

  testWidgets('laporan bulanan: bulan ini, navigasi & pilih bulan', (
    tester,
  ) async {
    size(tester);
    await tester.runAsync(() => pray('subuh'));
    await tester.pumpWidget(app(const IbadahMonthlyReportPage()));
    await settle(tester);

    expect(find.text('Laporan Ibadah Bulanan'), findsOneWidget);
    expect(find.text('KALENDER IBADAH'), findsOneWidget);
    expect(find.text('Rekomendasi bulan depan'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    await settle(tester);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
          )
          .onPressed,
      isNotNull,
    );
    // pemilih bulan
    await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Januari'), findsOneWidget);
    expect(find.text('Desember'), findsOneWidget);
  });

  testWidgets('kalender di Laporan: ketuk kotak membuka laporan harinya', (
    tester,
  ) async {
    size(tester);
    await tester.runAsync(() => pray('subuh'));
    await tester.pumpWidget(app(const ReportPage()));
    await settle(tester);
    expect(find.text('Laporan bulanan'), findsOneWidget);
    expect(find.textContaining('Ketuk sebuah kotak'), findsOneWidget);

    // kotak hari ini = kotak terakhir yang berisi catatan
    final cells = find.descendant(
      of: find.byType(ContributionCalendar),
      matching: find.byType(GestureDetector),
    );
    expect(cells, findsWidgets);
    final tapped = tester
        .widgetList<GestureDetector>(cells)
        .where((g) => g.onTap != null);
    expect(tapped, isNotEmpty);
    tapped.last.onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Laporan Harian'), findsOneWidget);
  });

  testWidgets('tombol laporan di halaman Ibadah', (tester) async {
    size(tester);
    await tester.pumpWidget(app(const IbadahPage()));
    await settle(tester);
    final button = find.text('Lihat laporan hari ini');
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Laporan Harian'), findsOneWidget);
  });

  testWidgets('ekspor: gambar PNG & PDF dari laporan', (tester) async {
    size(tester);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: key,
              child: Container(
                width: 400,
                height: 1200,
                color: const Color(0xFFFFFAF3),
                alignment: Alignment.center,
                child: const Text('isi laporan'),
              ),
            ),
          ),
        ),
      ),
    );
    final result = await tester.runAsync(() async {
      final image = await captureReport(key, pixelRatio: 2);
      final pdf = await reportToPdf(image, title: 'uji');
      return (image, pdf);
    });
    final (image, pdf) = result!;
    // seluruh tinggi isi ikut tertangkap, walau layar hanya 1800/1200
    expect((image.width, image.height), (800, 2400));
    expect(image.png.sublist(1, 4), [0x50, 0x4E, 0x47]); // "PNG"
    expect(Uint8List.fromList(pdf.sublist(0, 5)), [
      0x25,
      0x50,
      0x44,
      0x46,
      0x2D,
    ]);
    expect(pdf.length, greaterThan(image.png.length ~/ 2));
  });

  testWidgets('laporan mingguan: pekan ini, navigasi & ketuk hari', (
    tester,
  ) async {
    size(tester);
    await tester.runAsync(() => pray('subuh'));
    await tester.pumpWidget(app(const IbadahWeeklyReportPage()));
    await settle(tester);

    expect(find.text('Laporan Ibadah Mingguan'), findsOneWidget);
    expect(find.text('TUJUH HARI'), findsOneWidget);
    expect(find.text('KUALITAS SHOLAT WAJIB'), findsOneWidget);
    expect(find.text('Rekomendasi pekan depan'), findsOneWidget);
    expect(find.textContaining('Pekan ini ·'), findsOneWidget);
    final next = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    await settle(tester);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
    expect(find.textContaining('Pekan ini ·'), findsNothing);
  });

  testWidgets('Laporan: dua pintu mingguan & bulanan', (tester) async {
    size(tester);
    await tester.pumpWidget(app(const ReportPage()));
    await settle(tester);
    expect(find.text('Laporan mingguan'), findsOneWidget);
    expect(find.text('Laporan bulanan'), findsOneWidget);
    await tester.tap(find.text('Laporan mingguan'));
    await tester.pumpAndSettle();
    expect(find.text('Laporan Mingguan'), findsOneWidget);
  });
}
