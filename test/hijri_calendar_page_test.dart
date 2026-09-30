// Uji halaman kalender: dibuka dari menu Lainnya, menampilkan tanggal
// hijriah hari ini, grid bulan berjalan, dan bisa berpindah bulan.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/main.dart';
import 'package:rindu_ramadan/services/hijri_calendar.dart';

Future<void> _settle(WidgetTester tester, {int ticks = 6}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Kalender hijriah tampil & bisa berpindah bulan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const RinduRamadanApp(homeWidgets: false, onboarding: false),
    );
    await _settle(tester);

    // baris tanggal di kartu jadwal sudah memuat nama bulan hijriah
    final anyHijriMonth = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          hijriMonthNames.any(
            (n) => (w.textSpan?.toPlainText() ?? w.data ?? '').contains(n),
          ),
    );
    expect(anyHijriMonth, findsWidgets);

    // buka halaman kalender dari menu "Lainnya" di Beranda
    // tombol sudah dibangun di area cache (di luar layar) - gulir sampai
    // benar-benar terlihat
    await tester.ensureVisible(find.text('Lainnya'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Lainnya'));
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.text('Kalender Hijriah'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await _settle(tester);
    await tester.tap(find.text('Kalender Hijriah'));
    await _settle(tester);

    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('Min'), findsOneWidget);
    expect(find.text('Sab'), findsOneWidget);

    // mode bawaan: hijriah - judul "<bulan> <tahun> H" dan deretan 12 bulan
    final judulHijri = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          RegExp(r'^[A-Za-z\x27 ]+ \d{4} H$').hasMatch(w.data ?? ''),
    );
    expect(judulHijri, findsOneWidget);
    final judulAwal = (tester.widget(judulHijri) as Text).data!;

    // tidak ada celah kosong antara nama hari & grid (padding MediaQuery)
    final grid = tester.widget<GridView>(find.byType(GridView).first);
    expect(grid.padding, EdgeInsets.zero);

    // bulan berikutnya mengubah judul & memunculkan tombol "Bulan ini"
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect((tester.widget(judulHijri) as Text).data, isNot(judulAwal));
    await tester.tap(find.text('Bulan ini'));
    await tester.pump();
    expect((tester.widget(judulHijri) as Text).data, judulAwal);

    // judul membuka pemilih bulan: lompat ke Ramadan
    await tester.tap(judulHijri);
    await _settle(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Ramadan'),
      ),
    );
    await _settle(tester);
    expect((tester.widget(judulHijri) as Text).data, startsWith('Ramadan '));
    expect(find.text('Awal Ramadan'), findsOneWidget);

    // mode Masehi: judul bulan Masehi berjalan (tombolnya sudah tergulir ke
    // atas setelah langkah-langkah di atas, jadi digulir kembali dulu)
    await tester.ensureVisible(find.text('Masehi'));
    await tester.tap(find.text('Masehi'));
    await tester.pump();
    final now = DateTime.now();
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    expect(find.text('${bulan[now.month - 1]} ${now.year}'), findsOneWidget);
  });
}
