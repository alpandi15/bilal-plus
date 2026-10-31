import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/data/ayat_harian_data.dart';
import 'package:rindu_ramadan/services/ayat_harian.dart';
import 'package:rindu_ramadan/services/muhasabah.dart';
import 'package:rindu_ramadan/services/reminder_ids.dart';
import 'package:rindu_ramadan/services/waktu_penting.dart';

DaySummary _s({
  int done = 3,
  int total = 10,
  double? score,
  bool excused = false,
  int sholatDone = 5,
  int sholatTotal = 5,
}) => DaySummary(
  date: '2026-10-31',
  done: done,
  total: total,
  score: score ?? done.toDouble(),
  excused: excused,
  sholatDone: sholatDone,
  sholatTotal: sholatTotal,
);

void main() {
  group('muhasabah', () {
    test('tanpa data: teks generik', () {
      expect(muhasabahMessage(null).body, contains('Luangkan'));
    });

    test('tetap berbunyi saat semua tuntas, dengan ucapan syukur', () {
      final s = _s(done: 10, total: 10);
      expect(s.complete, isTrue);
      final m = muhasabahMessage(s);
      expect(m.title, 'Muhasabah malam');
      expect(m.body, contains('10 dari 10'));
    });

    test('>=70% menyebut sisa, sholat kurang menyebut jumlahnya', () {
      expect(muhasabahMessage(_s(done: 8, total: 10)).body, contains('80%'));
      final m = muhasabahMessage(_s(sholatDone: 3));
      expect(m.body, contains('2 sholat wajib'));
    });

    test('berhalangan: nada ringan, tanpa persen', () {
      expect(muhasabahMessage(_s(excused: true)).body, isNot(contains('%')));
    });
  });

  group('waktu penting', () {
    test('sepertiga malam terakhir berakhir tepat Subuh', () {
      final t = lastThirdOfNight(
        DateTime(2026, 10, 30, 18),
        DateTime(2026, 10, 31, 6),
      );
      expect(t.end, DateTime(2026, 10, 31, 6));
      expect(t.start, DateTime(2026, 10, 31, 2));
    });

    test('waktu terlarang: tiga rentang, Dhuha sebelum Dzuhur', () {
      final w = waktuPenting(
        now: DateTime(2026, 10, 31, 9),
        latitude: -6.2,
        longitude: 106.8,
        date: DateTime(2026, 10, 31),
      );
      expect(w.forbidden, hasLength(3));
      expect(w.dhuha.start.isBefore(w.dhuha.end), isTrue);
      expect(w.thirdNight.length.inMinutes, greaterThan(200));
    });
  });

  group('id notifikasi', () {
    test('id harian berbeda per tanggal & per jenis, tanpa bentrok', () {
      final a = DateTime(2026, 10, 31), b = DateTime(2026, 11);
      expect(NotifId.muhasabah(a), isNot(NotifId.muhasabah(b)));
      expect(NotifId.muhasabah(a), isNot(NotifId.ayat(a)));
      expect(NotifId.adzan(13, 4), lessThan(NotifId.fast(0)));
    });

    test('payload ayat & tanggal terurai', () {
      expect(NotifPayload.parseAyat('ayat|2:255'), (2, 255));
      expect(NotifPayload.parseAyat('laporan|2026-10-31'), isNull);
    });
  });

  group('ayat harian', () {
    test('pilihan deterministik per tanggal dan berganti tiap hari', () {
      final d = DateTime(2026, 10, 31);
      expect(ayatOfDate(d).ref, ayatOfDate(DateTime(2026, 10, 31, 23)).ref);
      expect(
        ayatOfDate(d).ref,
        isNot(ayatOfDate(d.add(const Duration(days: 1))).ref),
      );
    });

    test('daftar valid: nomor ayat ada & tidak ganda', () {
      final json = jsonDecode(
        File('assets/quran/quran.json').readAsStringSync(),
      );
      expect(json, isNotNull);
      expect(ayatHarianRefs.toSet().length, ayatHarianRefs.length);
      for (final (s, a) in ayatHarianRefs) {
        expect(s, inInclusiveRange(1, 114));
        expect(a, greaterThanOrEqualTo(1));
      }
    });
  });
}
