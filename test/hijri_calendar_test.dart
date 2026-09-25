import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';

void main() {
  group('algoritma tabular', () {
    test(
      '1 Muharram 1 H = 16 Juli 622 Julian = 19 Juli 622 Gregorian proleptik',
      () {
        // epoch kalender "civil" biasa disebut 16 Juli 622 - itu tanggal
        // Julian; jdnToGregorian menghasilkan Gregorian proleptik (+3 hari)
        final (y, m, d) = jdnToGregorian(hijriToJdnTabular(1, 1, 1));
        expect((y, m, d), (622, 7, 19));
      },
    );

    test('bolak-balik konsisten untuk 3000 hari', () {
      final start = gregorianToJdn(2020, 1, 1);
      for (var jd = start; jd < start + 3000; jd++) {
        final h = jdnToHijriTabular(jd);
        expect(hijriToJdnTabular(h.year, h.month, h.day), jd);
        expect(h.day, inInclusiveRange(1, 30));
        expect(h.month, inInclusiveRange(1, 12));
      }
    });
  });

  group('jangkar', () {
    test('tanpa jangkar, 1 Ramadan 1447 jatuh 18 Feb 2026 (tabular)', () {
      final none = HijriAnchors.none;
      expect(none.toGregorian(1447, 9, 1), DateTime.utc(2026, 2, 18));
      expect(none.fromGregorian(DateTime(2026, 2, 19)).day, 2);
    });

    test('jangkar 19 Feb 2026 menggeser seluruh Ramadan satu hari', () {
      final cfg = HijriConfig.parse(
        '{"anchors": {"1447-09": "2026-02-19", "1447-10": "2026-03-21"}}',
        origin: 'test',
      );
      final a = cfg.anchors;
      expect(cfg.warnings, isEmpty);

      // 18 Feb masih 30 Sya'ban, 19 Feb baru 1 Ramadan
      expect(
        a.fromGregorian(DateTime(2026, 2, 18)),
        const HijriDate(1447, 8, 30),
      );
      expect(
        a.fromGregorian(DateTime(2026, 2, 19)),
        const HijriDate(1447, 9, 1),
      );
      expect(a.fromGregorian(DateTime(2026, 2, 19)).estimated, isFalse);

      // Ramadan 30 hari, Idulfitri 21 Mar
      expect(a.daysInMonth(1447, 9), 30);
      expect(
        a.fromGregorian(DateTime(2026, 3, 20)),
        const HijriDate(1447, 9, 30),
      );
      expect(
        a.fromGregorian(DateTime(2026, 3, 21)),
        const HijriDate(1447, 10, 1),
      );

      // bulan tanpa jangkar tetap ditandai perkiraan
      expect(a.fromGregorian(DateTime(2026, 9, 14)).estimated, isTrue);
    });

    test(
      "Sya'ban ikut memanjang saat 1 Ramadan mundur, tanpa jangkar sendiri",
      () {
        final cfg = HijriConfig.parse(
          '{"anchors": {"1447-09": "2026-02-19"}}',
          origin: 'test',
        );
        // tabular: 1 Sya'ban 1447 = 20 Jan 2026 -> Sya'ban jadi 30 hari
        expect(cfg.anchors.daysInMonth(1447, 8), 30);
        expect(
          cfg.anchors.fromGregorian(DateTime(2026, 2, 18)),
          const HijriDate(1447, 8, 30),
        );
      },
    );
  });

  group('validasi konfigurasi', () {
    test(
      'jangkar yang membuat bulan 31 hari dibuang, yang lebih awal dipertahankan',
      () {
        final cfg = HijriConfig.parse(
          '{"anchors": {"1445-09": "2024-03-12", "1445-10": "2024-04-12"}}',
          origin: 'test',
        );
        expect(cfg.anchors.has(1445, 9), isTrue);
        expect(cfg.anchors.has(1445, 10), isFalse);
        expect(cfg.warnings, hasLength(1));
        expect(cfg.warnings.first, contains('31 hari'));
      },
    );

    test('kunci/tanggal rusak dilewati tanpa mematikan yang lain', () {
      final cfg = HijriConfig.parse(
        '{"anchors": {"abc": "2026-01-01", "1447-13": "2026-01-01", '
        '"1447-09": "bukan-tanggal", "1448-09": "2027-02-08"}}',
        origin: 'test',
      );
      expect(cfg.anchors.length, 1);
      expect(cfg.anchors.has(1448, 9), isTrue);
      expect(cfg.warnings, hasLength(3));
    });

    test(
      'jangkar yang melenceng jauh dari perhitungan ditolak (salah tahun)',
      () {
        final cfg = HijriConfig.parse(
          '{"anchors": {"1449-09": "2027-02-08"}}', // seharusnya 1448
          origin: 'test',
        );
        expect(cfg.anchors.isEmpty, isTrue);
        expect(cfg.warnings.first, contains('melenceng'));
      },
    );

    test('berkas bundel ikut tervalidasi', () {
      final text = File('assets/hijri_config.json').readAsStringSync();
      final cfg = HijriConfig.parse(text, origin: 'bundle');
      expect(cfg.anchors.has(1447, 9), isTrue);
      expect(cfg.anchors.has(1448, 9), isTrue);
      expect(cfg.anchors.toGregorian(1448, 9, 1), DateTime.utc(2027, 2, 8));
      // dua pasangan tahun lama di data web tidak konsisten (31 hari)
      expect(cfg.warnings, hasLength(2));
    });
  });

  test('hari penting: 1 Ramadan & Idulfitri terdeteksi', () {
    expect(eventsOn(const HijriDate(1448, 9, 1)).single.name, 'Awal Ramadan');
    expect(eventsOn(const HijriDate(1448, 10, 1)).single.name, 'Idulfitri');
    expect(eventsOn(const HijriDate(1448, 4, 3)), isEmpty);
  });
}
