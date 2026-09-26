// Uji pemilih lokasi: buka lembarnya lewat chip lokasi, cari kabupaten
// lewat kotak pencarian, lalu pilih salah satu - pastikan lokasi di kartu
// jadwal sholat ikut berganti.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/main.dart';

Future<void> _settle(WidgetTester tester, {int ticks = 6}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Pemilih lokasi bisa dibuka, dicari, dan dipilih', (
    tester,
  ) async {
    // tanpa ini, SharedPreferences.getInstance() menunggu channel platform
    // yang tak pernah ada di lingkungan uji - macet selamanya, bukan error.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const RinduRamadanApp(homeWidgets: false, onboarding: false),
    );
    await _settle(tester);

    // default sebelum lokasi lain dipilih (GPS gagal di lingkungan uji)
    expect(find.text('Kota Medan'), findsOneWidget);

    // buka lembar pemilih lewat chip lokasi
    await tester.tap(find.text('Kota Medan'));
    await _settle(tester);

    expect(find.text('Pilih Kabupaten / Kota'), findsOneWidget);
    expect(find.text('Gunakan lokasi saat ini'), findsOneWidget);

    // cari "bandung" lalu pilih hasil pertama
    await tester.enterText(find.byType(TextField), 'bandung');
    await _settle(tester);

    expect(find.text('Kota Bandung'), findsWidgets);
    await tester.tap(find.text('Kota Bandung').first);
    await _settle(tester);

    // lembar tertutup, kartu jadwal sholat menampilkan lokasi baru
    expect(find.text('Pilih Kabupaten / Kota'), findsNothing);
    expect(find.text('Kota Bandung'), findsOneWidget);
  });
}
