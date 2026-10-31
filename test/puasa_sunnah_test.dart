import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/app_settings.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ibadah_day.dart';
import 'package:rindu_ramadan/services/puasa_sunnah.dart';

// 1 Syawal 1447 = Jumat 20 Mar 2026; 1 Dzulhijjah 1447 = Senin 18 Mei 2026
// (Iduladha = Rabu 27 Mei); 1 Muharram 1448 = Selasa 16 Jun 2026.
final _anchors = HijriConfig.parse(
  '{"anchors": {"1447-10": "2026-03-20", "1447-11": "2026-04-18",'
  ' "1447-12": "2026-05-18", "1448-01": "2026-06-16"}}',
  origin: 'test',
).anchors;

List<PuasaSunnah> _on(String date) => puasaSunnahOn(ibadahDay(date, _anchors));

void main() {
  test('Senin & Kamis biasa', () {
    // Senin 13 Apr 2026 = 25 Syawal -> Senin + Syawal
    expect(_on('2026-04-13'), [PuasaSunnah.senin, PuasaSunnah.syawal]);
    // Selasa biasa (14 Apr) hanya Syawal
    expect(_on('2026-04-14'), [PuasaSunnah.syawal]);
  });

  test('Ayyamul Bidh tanggal 13-15 hijriah', () {
    // 13 Dzulhijjah dilarang, jadi pakai Dzulqa'dah (1447-11 mulai 18 Apr)
    final d13 = _on('2026-04-30'); // Kamis, 13 Dzulqa'dah
    expect(d13, containsAll([PuasaSunnah.kamis, PuasaSunnah.ayyamulBidh]));
    expect(_on('2026-05-01'), [PuasaSunnah.ayyamulBidh]); // Jumat 14
    expect(_on('2026-05-02'), [PuasaSunnah.ayyamulBidh]); // Sabtu 15
    expect(_on('2026-05-04'), [PuasaSunnah.senin]); // Senin 17: bukan bidh
  });

  test('Iduladha & hari tasyrik disembunyikan', () {
    expect(_on('2026-05-27'), isEmpty); // 10 Dzulhijjah (Rabu)
    expect(_on('2026-05-28'), isEmpty); // 11, Kamis - Kamis pun disembunyikan
    expect(_on('2026-05-30'), isEmpty); // 13, Sabtu = Ayyamul Bidh tersembunyi
  });

  test('Iedul Fithri disembunyikan, Syawal mulai tanggal 2', () {
    expect(_on('2026-03-20'), isEmpty);
    expect(_on('2026-03-21'), [PuasaSunnah.syawal]);
  });

  test('Tasu\'a & Asyura', () {
    expect(_on('2026-06-24'), [PuasaSunnah.asyura]); // 9 Muharram, Rabu
    expect(_on('2026-06-25'), [PuasaSunnah.kamis, PuasaSunnah.asyura]);
  });

  test('Ramadan tidak menyarankan puasa sunnah', () {
    final a = HijriConfig.parse(
      '{"anchors": {"1448-09": "2027-02-08", "1448-10": "2027-03-09"}}',
      origin: 'test',
    ).anchors;
    expect(puasaSunnahOn(ibadahDay('2027-02-15', a)), isEmpty); // Senin
  });

  test('pesan malam sebelumnya', () {
    expect(puasaSunnahMessage(const []), isNull);
    final m = puasaSunnahMessage([PuasaSunnah.senin, PuasaSunnah.ayyamulBidh]);
    expect(m!.title, 'Besok puasa sunnah: Senin & Ayyamul Bidh');
  });

  test('pengaturan: nama tak dikenal diabaikan, bawaan kosong', () {
    expect(parsePuasaSunnah(null), isEmpty);
    expect(parsePuasaSunnah(['senin', 'ngawur', 'syawal']), {
      PuasaSunnah.senin,
      PuasaSunnah.syawal,
    });
  });
}
