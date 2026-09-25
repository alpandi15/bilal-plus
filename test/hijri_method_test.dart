import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/services/hijri_calendar.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ramadan_calendar.dart';

const _json = '''
{
  "updatedAt": "2027-02-07",
  "source": "Isbat",
  "anchors": {
    "1448-09": "2027-02-08",
    "1448-10": { "date": "2027-03-09", "status": "tentative" }
  },
  "variants": {
    "muhammadiyah": {
      "label": "Muhammadiyah",
      "source": "Maklumat",
      "anchors": { "1448-09": "2027-02-07" }
    },
    "pemerintah": { "anchors": {} },
    "rusak": "bukan objek"
  }
}
''';

int _jdn(int y, int m, int d) => gregorianToJdn(y, m, d);

void main() {
  group('format berkas', () {
    test('status tentative terbaca, string biasa dianggap resmi', () {
      final cfg = HijriConfig.parse(_json, origin: 'test');
      expect(cfg.anchors.isTentative(1448, 9), isFalse);
      expect(cfg.anchors.isTentative(1448, 10), isTrue);
      expect(cfg.anchors.has(1448, 10), isTrue);
      expect(
        relevantRamadan(DateTime.utc(2027, 1, 1), cfg.anchors).statusLabel,
        '',
      );
    });

    test('varian terbaca, kunci bawaan & bentuk rusak ditolak', () {
      final cfg = HijriConfig.parse(_json, origin: 'test');
      expect(cfg.methods.keys, ['pemerintah', 'muhammadiyah']);
      expect(cfg.methods['muhammadiyah']!.label, 'Muhammadiyah');
      expect(cfg.warnings, hasLength(2));
    });

    test('varian berdiri sendiri, tidak mewarisi jangkar Pemerintah', () {
      final cfg = HijriConfig.parse(
        _json,
        origin: 'test',
      ).resolve(method: 'muhammadiyah');
      expect(cfg.method, 'muhammadiyah');
      expect(cfg.anchors.toGregorian(1448, 9, 1), DateTime.utc(2027, 2, 7));
      // 1 Syawal tidak ada di varian: jatuh ke tabular, bukan jangkar isbat
      expect(cfg.anchors.has(1448, 10), isFalse);
      expect(
        cfg.anchors.toGregorian(1448, 10, 1),
        HijriAnchors.none.toGregorian(1448, 10, 1),
      );
    });

    test('metode yang tidak dikenal jatuh ke Pemerintah', () {
      final cfg = HijriConfig.parse(
        _json,
        origin: 'test',
      ).resolve(method: 'entah');
      expect(cfg.method, 'pemerintah');
    });
  });

  group('penyesuaian pengguna', () {
    final file = HijriConfig.parse(_json, origin: 'test');

    test('1 Ramadan mundur sehari: Syawal ikut mundur (Ramadan 29 hari)', () {
      final cfg = file.resolve(
        method: 'pemerintah',
        overrides: {(1448, 9): _jdn(2027, 2, 9)},
      );
      final a = cfg.anchors;
      expect(a.toGregorian(1448, 9, 1), DateTime.utc(2027, 2, 9));
      expect(a.isOverridden(1448, 9), isTrue);
      // tanpa geser berantai Ramadan jadi 28 hari
      expect(a.daysInMonth(1448, 9), 29);
      expect(a.toGregorian(1448, 10, 1), DateTime.utc(2027, 3, 10));
      // bulan yang ikut tergeser bukan ketetapan
      expect(a.has(1448, 10), isFalse);
      expect(a.isTentative(1448, 10), isFalse);
      expect(a.daysInMonth(1448, 8), inInclusiveRange(29, 30));

      final r = relevantRamadan(DateTime.utc(2027, 1, 1), a);
      expect(r.overridden, isTrue);
      expect(r.statusLabel, 'sesuai pilihanmu');
    });

    test('1 Ramadan maju sehari: Ramadan jadi 30 hari tanpa geser', () {
      final a = file
          .resolve(
            method: 'pemerintah',
            overrides: {(1448, 9): _jdn(2027, 2, 7)},
          )
          .anchors;
      expect(a.daysInMonth(1448, 9), 30);
      expect(a.toGregorian(1448, 10, 1), DateTime.utc(2027, 3, 9));
      expect(a.has(1448, 10), isTrue);
    });

    test('penyesuaian yang melenceng >1 hari dari ketetapan dibuang', () {
      final cfg = file.resolve(
        method: 'pemerintah',
        overrides: {(1448, 9): _jdn(2027, 2, 11)},
      );
      expect(cfg.anchors.isOverridden(1448, 9), isFalse);
      expect(cfg.anchors.toGregorian(1448, 9, 1), DateTime.utc(2027, 2, 8));
      expect(cfg.warnings.last, contains('1448-09'));
    });

    test('sidik jari berubah saat penyesuaian berubah', () {
      final a = file.resolve(method: 'pemerintah').anchors;
      final b = file
          .resolve(
            method: 'pemerintah',
            overrides: {(1448, 9): _jdn(2027, 2, 7)},
          )
          .anchors;
      expect(a.fingerprint, isNot(b.fingerprint));
      expect(a.length, b.length);
    });
  });

  group('fase Ramadan', () {
    // 1 Ramadan 1448 = 8 Feb 2027, 1 Syawal = 9 Mar 2027 (29 hari)
    final a = HijriConfig.parse(_json, origin: 'test').anchors;

    RamadanStatus at(int m, int d, {bool afterMaghrib = false}) =>
        ramadanStatus(
          today: DateTime.utc(2027, m, d),
          afterMaghrib: afterMaghrib,
          anchors: a,
        );

    test('sebelum Ramadan: hitung mundur', () {
      final s = at(2, 7);
      expect(s.phase, RamadanPhase.before);
      expect(s.ramadan.hijriYear, 1448);
    });

    test('malam pertama sudah terhitung 1 Ramadan', () {
      final s = at(2, 7, afterMaghrib: true);
      expect(s.phase, RamadanPhase.during);
      expect(s.day, 1);
    });

    test('hari terakhir Ramadan siang hari masih Ramadan ke-29', () {
      final s = at(3, 8);
      expect(s.phase, RamadanPhase.during);
      expect(s.day, 29);
    });

    test('malam takbiran = Idulfitri hari ke-1', () {
      final s = at(3, 8, afterMaghrib: true);
      expect(s.phase, RamadanPhase.eid);
      expect(s.day, 1);
      expect(s.ramadan.hijriYear, 1448);
    });

    test('Idulfitri bertahan sampai Maghrib 3 Syawal', () {
      expect(at(3, 9).day, 1);
      expect(at(3, 11).phase, RamadanPhase.eid);
      expect(at(3, 11).day, 3);
    });

    test('lewat Maghrib 3 Syawal: hitung mundur Ramadan berikutnya', () {
      final s = at(3, 11, afterMaghrib: true);
      expect(s.phase, RamadanPhase.before);
      expect(s.ramadan.hijriYear, 1449);
      expect(s.ramadan.estimated, isTrue);
      expect(s.ramadan.statusLabel, 'perkiraan');
    });
  });

  group('HijriConfigController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    TestWidgetsFlutterBinding.ensureInitialized();

    test('metode & penyesuaian tersimpan dan dimuat ulang', () async {
      final c = HijriConfigController(remoteUrl: '');
      await c.init();
      expect(c.method, 'pemerintah');
      expect(c.methods.map((m) => m.key), contains('muhammadiyah'));

      final base = c.baseFirstDay(1448, 9);
      expect(base, DateTime.utc(2027, 2, 8));
      await c.setOverride(1448, 9, DateTime.utc(2027, 2, 9));
      await c.setMethod('muhammadiyah');
      expect(c.config.method, 'muhammadiyah');

      final again = HijriConfigController(remoteUrl: '');
      await again.init();
      expect(again.method, 'muhammadiyah');
      expect(again.overrideFor(1448, 9), DateTime.utc(2027, 2, 9));
    });

    test('memilih tanggal ketetapan = hapus penyesuaian', () async {
      final c = HijriConfigController(remoteUrl: '');
      await c.init();
      await c.setOverride(1448, 9, DateTime.utc(2027, 2, 9));
      expect(c.config.anchors.isOverridden(1448, 9), isTrue);
      await c.setOverride(1448, 9, DateTime.utc(2027, 2, 8));
      expect(c.overrideFor(1448, 9), isNull);
      expect(c.config.anchors.isOverridden(1448, 9), isFalse);
    });

    test(
      'penyesuaian yang sama dengan ketetapan resmi dibuang otomatis',
      () async {
        SharedPreferences.setMockInitialValues({
          'hijri_overrides': '{"1448-09": "2027-02-08"}',
        });
        final c = HijriConfigController(remoteUrl: '');
        await c.init();
        expect(c.overrideFor(1448, 9), isNull);
      },
    );
  });
}
