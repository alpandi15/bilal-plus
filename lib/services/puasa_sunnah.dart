import '../data/sholat_dalil.dart';
import 'ibadah_day.dart';

/// Puasa sunnah yang bisa diingatkan malam sebelumnya. Tarwiyah & Arafah
/// punya saklar tersendiri (`fastReminder`, lihat [DzulhijjahFast]).
///
/// Kuncinya (`name`) disimpan di pengaturan - jangan diganti.
enum PuasaSunnah {
  senin('Senin', 'Puasa hari Senin', dalilPuasaSenin),
  kamis('Kamis', 'Puasa hari Kamis', dalilPuasaSenin),
  ayyamulBidh(
    'Ayyamul Bidh',
    'Puasa Ayyamul Bidh (tanggal 13, 14, 15 hijriah)',
    dalilPuasaAyyamulBidh,
  ),
  asyura(
    "Tasu'a & Asyura",
    "Puasa Tasu'a & Asyura (9-10 Muharram)",
    dalilPuasaAsyura,
  ),
  syawal('Enam hari Syawal', 'Puasa enam hari Syawal', dalilPuasaSyawal);

  const PuasaSunnah(this.label, this.title, this.dalil);

  /// Nama singkat (sama dengan keterangan di [IbadahDay.sunnahFastReasons]
  /// untuk Senin/Kamis).
  final String label;

  /// Judul untuk saklar & lembar dalil.
  final String title;
  final List<Dalil> dalil;
}

/// Puasa sunnah yang disarankan pada [day] (kosong pada hari yang
/// diharamkan berpuasa - Iedul Fithri, Iedul Adha, tasyrik - dan pada
/// Ramadan). Diturunkan dari [IbadahDay.sunnahFastReasons], jadi selalu
/// sejalan dengan checklist.
List<PuasaSunnah> puasaSunnahOn(IbadahDay day) {
  if (!day.sunnahFastSuggested) return const [];
  final r = day.sunnahFastReasons;
  return [
    if (r.contains('Senin')) PuasaSunnah.senin,
    if (r.contains('Kamis')) PuasaSunnah.kamis,
    if (r.contains('Ayyamul Bidh')) PuasaSunnah.ayyamulBidh,
    if (r.contains("Tasu'a") || r.contains('Asyura')) PuasaSunnah.asyura,
    if (r.contains('Enam hari Syawal')) PuasaSunnah.syawal,
  ];
}

/// Pengingat malam sebelumnya untuk [fasts] (sudah disaring sesuai saklar
/// pengguna). Null bila kosong.
({String title, String body})? puasaSunnahMessage(List<PuasaSunnah> fasts) {
  if (fasts.isEmpty) return null;
  final names = fasts.map((f) => f.label).join(' & ');
  final tail = fasts.contains(PuasaSunnah.syawal)
      ? ' Satu langkah menuju enam hari Syawal.'
      : '';
  return (
    title: 'Besok puasa sunnah: $names',
    body:
        'Niatkan malam ini dan siapkan sahur - bila berkenan.$tail '
        'Tidak ada paksaan; catat di checklist bila jadi berpuasa.',
  );
}
