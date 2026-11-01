import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/pages/zakat_mal_page.dart';
import 'package:rindu_ramadan/services/zakat_mal.dart';

void main() {
  const harga = 1000000.0; // Rp1.000.000/gram -> nisab Rp85.000.000

  group('zakat mal', () {
    test('nisab 85 gram emas; di bawahnya belum wajib', () {
      final r = hitungZakatMal(hargaEmasPerGram: harga, tunai: 80000000);
      expect(r.nisab, 85000000);
      expect(r.capaiNisab, isFalse);
      expect(r.wajib, isFalse);
      expect(r.zakat, 0);
      expect(r.kurangDariNisab, 5000000);
    });

    test('tepat di nisab wajib 2,5% bila haul', () {
      final r = hitungZakatMal(hargaEmasPerGram: harga, tunai: 85000000);
      expect(r.wajib, isTrue);
      expect(r.zakat, 2125000);
    });

    test('belum satu haul: capai nisab tapi belum wajib', () {
      final r = hitungZakatMal(
        hargaEmasPerGram: harga,
        tunai: 100000000,
        haulTerpenuhi: false,
      );
      expect(r.capaiNisab, isTrue);
      expect(r.wajib, isFalse);
      expect(r.zakat, 0);
    });

    test(
      'emas simpanan dinilai dari harga; hutang & piutang diperhitungkan',
      () {
        final r = hitungZakatMal(
          hargaEmasPerGram: harga,
          tunai: 30000000,
          emasGram: 50, // 50.000.000
          piutang: 10000000,
          investasi: 20000000,
          hutang: 5000000,
        );
        expect(r.harta, 110000000);
        expect(r.bersih, 105000000);
        expect(r.zakat, 105000000 * 0.025);
      },
    );

    test('hutang melebihi harta: bersih 0, bukan negatif', () {
      final r = hitungZakatMal(
        hargaEmasPerGram: harga,
        tunai: 1000000,
        hutang: 9000000,
      );
      expect(r.bersih, 0);
      expect(r.wajib, isFalse);
    });

    test(
      'harga emas belum diisi: tidak wajib (nisab 0 tidak dianggap tercapai)',
      () {
        final r = hitungZakatMal(hargaEmasPerGram: 0, tunai: 999999999);
        expect(r.capaiNisab, isFalse);
        expect(r.zakat, 0);
      },
    );
  });

  group('zakat penghasilan', () {
    test('nisab bulanan = nisab tahunan / 12', () {
      final r = hitungZakatPenghasilan(hargaEmasPerGram: harga, gaji: 8000000);
      expect(r.nisabBulanan, closeTo(85000000 / 12, 1e-6)); // ±7.083.333
      expect(r.wajib, isTrue);
      expect(r.zakatBulanan, 200000);
      expect(r.zakatTahunan, 2400000);
    });

    test('di bawah nisab bulanan: belum wajib', () {
      final r = hitungZakatPenghasilan(hargaEmasPerGram: harga, gaji: 5000000);
      expect(r.wajib, isFalse);
      expect(r.zakatBulanan, 0);
      expect(r.kurangDariNisab, closeTo(85000000 / 12 - 5000000, 1e-6));
    });

    test('kebutuhan pokok dikurangkan (opsional)', () {
      final r = hitungZakatPenghasilan(
        hargaEmasPerGram: harga,
        gaji: 9000000,
        lain: 1000000,
        kebutuhanPokok: 4000000,
      );
      expect(r.dasar, 6000000);
      expect(r.wajib, isFalse); // 6 jt < 7,08 jt
    });
  });

  group('harga emas & format', () {
    test('kedaluwarsa setelah 30 hari / belum pernah diperbarui', () {
      final now = DateTime(2026, 11, 1);
      expect(const GoldPrice(0, null).stale(now), isTrue);
      expect(GoldPrice(1, DateTime(2026, 10, 10)).stale(now), isFalse);
      expect(GoldPrice(1, DateTime(2026, 9, 1)).stale(now), isTrue);
    });

    test('tersimpan di perangkat', () async {
      SharedPreferences.setMockInitialValues({});
      final saved = await GoldPrice.save(1234567, DateTime(2026, 11, 1));
      final loaded = await GoldPrice.load();
      expect(loaded.perGram, saved.perGram);
      expect(loaded.updatedAt, DateTime(2026, 11, 1));
    });

    test('rupiah & penguraian angka', () {
      expect(rupiah(1234567.4), 'Rp1.234.567');
      expect(rupiah(0), 'Rp0');
      expect(rupiah(-1500), '-Rp1.500');
      expect(parseAmount('1.250.000'), 1250000);
      expect(parseAmount('12,5'), 12.5);
      expect(parseAmount(''), 0);
    });
  });

  testWidgets('halaman: isi harga & harta -> hasil zakat', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ZakatMalPage()));
    await tester.pump();
    expect(find.text('Isi harga emas dulu'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Harga emas hari ini'),
      '1000000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Uang tunai & tabungan'),
      '100000000',
    );
    await tester.pump();
    expect(find.text('Rp2.500.000'), findsOneWidget); // 2,5% x 100 jt
    expect(find.text('Rp85.000.000'), findsOneWidget); // nisab

    await tester.tap(find.text('Penghasilan'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Gaji / penghasilan utama'),
      '8000000',
    );
    await tester.pump();
    expect(find.text('Rp200.000 / bulan'), findsOneWidget);
  });
}
