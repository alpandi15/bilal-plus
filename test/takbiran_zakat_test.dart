import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/data/zakat_fitrah_data.dart';
import 'package:rindu_ramadan/pages/takbiran_page.dart';
import 'package:rindu_ramadan/pages/zakat_fitrah_page.dart';
import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/hijri_config_scope.dart';
import 'package:rindu_ramadan/services/user_location_controller.dart';
import 'package:rindu_ramadan/services/user_location_scope.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(411, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UserLocationScope(
        controller: UserLocationController(),
        child: HijriConfigScope(
          controller: HijriConfigController(remoteUrl: ''),
          child: AppSettingsScope(
            controller: AppSettingsController(),
            child: MaterialApp(home: page),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  test('naskah zakat dari web lengkap', () {
    expect(zakatSyaratWajib, hasLength(3));
    expect(zakatDitanggung, hasLength(3));
    expect(fidyahSiapa, hasLength(4));
    expect(zakatWaktu.map((w) => w.hukum), [
      'Boleh',
      'Wajib',
      'Paling utama',
      'Makruh',
      'Tidak sah',
    ]);
    expect(zakatKadar['utama'], '2,5 kg');
    expect(zakatTataCara.where((s) => s.ucapan != null).map((s) => s.peran), [
      'pemberi',
      'penerima',
    ]);
    expect(zakatDoaPenutup['arabic'], isNotEmpty);
  });

  testWidgets('zakat: kalkulator jiwa, nominal & fidyah', (tester) async {
    await open(tester, const ZakatFitrahPage());
    expect(find.text('2,5 kg beras (≈ 3,5 liter)'), findsOneWidget);

    await tester.tap(find.byTooltip('Tambah').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Tambah').first);
    await tester.pump();
    expect(find.text('7,5 kg beras (≈ 10,5 liter)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '45000');
    await tester.pump();
    expect(find.text('atau Rp135.000 (3 × Rp45.000)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Hari puasa yang ditinggalkan'),
      300,
      // Scrollable halaman (vertikal) - kolom isian nominal punya
      // Scrollable horizontal sendiri
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Tambah').last);
    await tester.pump();
    expect(find.textContaining('2 mud ≈ 1,35 kg'), findsOneWidget);
  });

  testWidgets('takbiran: tanggal hari raya & lafaz', (tester) async {
    await open(tester, const TakbiranPage());
    expect(find.textContaining('Idulfitri'), findsWidgets);
    expect(find.textContaining('Iduladha'), findsWidgets);
    expect(find.textContaining('Malam takbiran:'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('Takbir panjang'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Takbir panjang'), findsOneWidget);
  });
}
