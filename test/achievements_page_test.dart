import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/achievements_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/prayer_calculator.dart' as calc;
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

void main() {
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
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Widget app() => AppDatabaseScope(
    database: db,
    child: UserLocationScope(
      controller: UserLocationController(),
      child: AppSettingsScope(
        controller: AppSettingsController(),
        child: const MaterialApp(home: AchievementsPage()),
      ),
    ),
  );

  testWidgets('kosong: lencana terkunci, tanpa perayaan', (tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.textContaining('lencana'), findsWidgets);
    expect(find.text('Pekan Terjaga'), findsOneWidget);
    expect(find.text('Alhamdulillah!'), findsNothing);
  });

  testWidgets('lencana baru dirayakan sekali, lalu tidak lagi', (tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final today = calc.todayInZone(calc.TimezoneCode.wib);
    await tester.runAsync(() async {
      final items = await db.select(db.ibadahItems).get();
      int id(String k) => items.firstWhere((i) => i.key == k).id;
      for (var i = 0; i < 7; i++) {
        final d = dateKey(today.subtract(Duration(days: i)));
        for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
          await db.ibadahDao.setValue(d, id(k), 1);
        }
      }
    });
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('Alhamdulillah!'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await settle(tester);
    expect(find.text('Alhamdulillah!'), findsNothing);

    // buka lagi: sudah dilihat, tidak dirayakan ulang
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('Alhamdulillah!'), findsNothing);
    expect(find.textContaining('Diraih'), findsWidgets);
  });
}
