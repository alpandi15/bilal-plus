import 'app_settings.dart';

/// Isi satu notifikasi.
class AdzanMessage {
  const AdzanMessage(this.title, this.body);
  final String title;
  final String body;
}

const _names = {
  'subuh': 'Subuh',
  'dzuhur': 'Dzuhur',
  'ashar': 'Ashar',
  'maghrib': 'Maghrib',
  'isya': 'Isya',
};

/// Narasi ajakan sholat untuk laki-laki: berjamaah di masjid di awal waktu.
/// Dalil yang dirujuk: sholat berjamaah 27 derajat (HR. Bukhari & Muslim),
/// amalan yang paling dicintai Allah adalah sholat pada waktunya (HR.
/// Bukhari & Muslim), langkah ke masjid menghapus dosa & mengangkat derajat
/// (HR. Muslim).
const _male = [
  "Hayya 'alash-shalah! Tinggalkan sejenak aktivitasmu dan sholat {name} "
      'berjamaah di masjid - pahalanya 27 derajat lebih utama.',
  'Adzan {name} berkumandang di {place}. Setiap langkah menuju masjid '
      'menghapus dosa dan mengangkat derajat. Yuk berangkat!',
  'Amalan yang paling dicintai Allah adalah sholat di awal waktunya. '
      'Yuk sholat {name} berjamaah di masjid.',
];

const _neutral = [
  "Hayya 'alash-shalah! Yuk sholat {name} di awal waktu - amalan yang "
      'paling dicintai Allah.',
  'Waktu {name} telah masuk di {place}. Sejenak menghadap Allah, '
      'tenangkan hati.',
  'Sholat di awal waktu, hati pun lapang. Yuk sholat {name} sekarang.',
];

String _fill(String t, String name, String place) =>
    t.replaceAll('{name}', name).replaceAll('{place}', place);

/// Pesan adzan untuk sholat [key] pada [date] (Y/M/D; pesan bergilir per
/// tanggal) jam [time] (mis. "04:59 WIB") di [place].
AdzanMessage adzanMessage({
  required String key,
  required DateTime date,
  required String time,
  required String place,
  required Gender? gender,
}) {
  final male = gender == Gender.male;
  final friday = date.weekday == DateTime.friday;
  if (male && friday && key == 'dzuhur') {
    return AdzanMessage(
      'Waktunya Sholat Jumat · $time',
      'Bersegeralah ke masjid, dengarkan khutbah dari awal. Mandi, '
          'berpakaian terbaik, dan jangan sampai terlewat.',
    );
  }
  final name = _names[key]!;
  if (key == 'subuh') {
    return AdzanMessage(
      'Adzan Subuh · $time',
      male
          ? 'Ash-shalatu khairum minan naum - sholat lebih baik daripada '
                'tidur. Yuk bangun dan sholat Subuh berjamaah di masjid.'
          : 'Ash-shalatu khairum minan naum - sholat lebih baik daripada '
                'tidur. Yuk bangun dan sholat Subuh di awal waktu.',
    );
  }
  final pool = male ? _male : _neutral;
  final pick = pool[(date.day + key.length) % pool.length];
  return AdzanMessage('Adzan $name · $time', _fill(pick, name, place));
}

/// Pengingat [minutes] menit sebelum adzan [key].
AdzanMessage reminderMessage({
  required String key,
  required DateTime date,
  required int minutes,
  required Gender? gender,
}) {
  final male = gender == Gender.male;
  final jumat = male && key == 'dzuhur' && date.weekday == DateTime.friday;
  final name = jumat ? 'Jumat' : _names[key]!;
  return AdzanMessage(
    '$minutes menit lagi $name',
    male
        ? 'Siapkan wudhu dan berangkat ke masjid, supaya dapat takbiratul '
              'ihram bersama imam.'
        : 'Siapkan wudhu, sebentar lagi waktu $name masuk.',
  );
}
