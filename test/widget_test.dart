// Uji asap sederhana: pastikan kartu jadwal sholat & hitung mundur Ramadan
// tampil tanpa error, begitu resolusi lokasi (yang async) selesai.

import 'package:flutter_test/flutter_test.dart';

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
}
