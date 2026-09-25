import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/db/app_database_scope.dart';
import 'package:rindu_ramadan/pages/backup_page.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';

void main() {
  testWidgets('halaman cadangan menampilkan status & jumlah catatan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await tester.runAsync(
      () => db.quranDao.logReading(date: '2027-02-08', toAyah: 7),
    );

    await tester.pumpWidget(
      AppDatabaseScope(
        database: db,
        child: HijriConfigScope(
          controller: HijriConfigController(remoteUrl: ''),
          child: const MaterialApp(home: BackupPage()),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Belum pernah dicadangkan'), findsOneWidget);
    expect(
      find.textContaining('0 catatan ibadah & 1 sesi baca'),
      findsOneWidget,
    );
    expect(find.text('Buat & bagikan cadangan'), findsOneWidget);
    expect(find.text('Pulihkan dari berkas'), findsOneWidget);

    await tester.runAsync(db.close);
  });
}
