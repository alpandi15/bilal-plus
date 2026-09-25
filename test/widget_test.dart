// Uji asap sederhana: pastikan kartu jadwal sholat & hitung mundur Ramadan
// tampil tanpa error, begitu resolusi lokasi (yang async) selesai.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/main.dart';

void main() {
  testWidgets('Kartu jadwal sholat & hitung mundur Ramadan tampil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RinduRamadanApp());
    // resolusi lokasi (shared_preferences + percobaan GPS yang gagal di
    // lingkungan uji) berjalan async - beri waktu sampai semuanya selesai.
    // Bukan `pumpAndSettle`: kartu ini punya timer berjalan terus tiap detik
    // (jam & hitung mundur), jadi tidak akan pernah "diam" sepenuhnya.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('JADWAL SHOLAT'), findsOneWidget);
    expect(find.textContaining('🌙'), findsOneWidget);
  });

  testWidgets('Pengaturan tanggal hijriah terbuka dari kartu hitung mundur', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // lebar ponsel umum: pilihan tanggal tiga kolom tidak boleh overflow
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const RinduRamadanApp());
    // berkas konfigurasi hijriah dibaca dari aset (I/O sungguhan) - beri
    // waktu nyata, bukan waktu palsu, supaya varian metodenya ikut termuat
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.ensureVisible(
      find.textContaining('· ubah', findRichText: true),
    );
    await tester.tap(find.textContaining('· ubah', findRichText: true));
    // animasi lembar naik (timer jam di kartu membuat pumpAndSettle tak
    // pernah selesai)
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Penetapan Tanggal Hijriah'), findsOneWidget);
    expect(find.text('Muhammadiyah'), findsOneWidget);
    expect(find.textContaining('1 Ramadan'), findsOneWidget);
    expect(find.text('sehari lebih lambat'), findsNWidgets(3));

    await tester.tap(find.text('sehari lebih lambat').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Ikuti ketetapan'), findsOneWidget);
  });
}
