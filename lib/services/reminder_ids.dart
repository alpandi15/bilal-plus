/// Registri id notifikasi: satu tempat yang membagi rentang id per jenis
/// pengingat supaya tidak saling menimpa.
///
/// - Adzan, pengingat sebelum adzan, puasa & Jumat memakai id lama
///   (relatif terhadap hari penjadwalan) - semuanya dihapus & dibuat ulang
///   bersamaan di `reschedule()`.
/// - Jenis baru memakai id **berbasis tanggal**: tanggal yang sama selalu
///   mendapat id yang sama. Dengan begitu notifikasi hari ini bisa
///   diperbarui sendiri (mis. dari isolate latar saat ibadah dicentang lewat
///   widget) tanpa menggandakan yang sudah dijadwalkan pada hari lain.
abstract final class NotifId {
  /// Adzan (`day*16 + i`, i 0-4) & pengingat sebelum adzan (`day*16 + 8 + i`)
  /// untuk `day` 0..13 - maksimum 239.
  static int adzan(int day, int i) => day * 16 + i;
  static int adzanReminder(int day, int i) => day * 16 + 8 + i;

  /// Puasa Tarwiyah/Arafah & amalan Jumat: `base + day` (day 0..13).
  static int fast(int day) => 900 + day;
  static int friday(int day) => 950 + day;

  /// Tunda adzan layar penuh & contoh notifikasi.
  static const snooze = 990;
  static const test = 999;

  /// Jenis berbasis tanggal: 100 id per jenis (`base + hari-ke % 100`).
  static const _muhasabah = 1000;
  static const _weekly = 1100;
  static const _tahajud = 1200;
  static const _ayat = 1300;
  static const _sunnah = 1400;
  static const _murajaah = 1500;

  static int muhasabah(DateTime date) => _muhasabah + _slot(date);
  static int weekly(DateTime date) => _weekly + _slot(date);
  static int tahajud(DateTime date) => _tahajud + _slot(date);
  static int ayat(DateTime date) => _ayat + _slot(date);
  static int sunnah(DateTime date) => _sunnah + _slot(date);
  static int murajaah(DateTime date) => _murajaah + _slot(date);

  /// Nomor hari sejak 2020-01-01 (UTC) modulo 100.
  static int _slot(DateTime date) =>
      DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime.utc(2020)).inDays %
      100;
}

/// Awalan payload notifikasi yang membuka halaman tertentu.
abstract final class NotifPayload {
  static const reportDay = 'laporan|'; // laporan|YYYY-MM-DD
  static const reportWeek = 'laporan-minggu|'; // laporan-minggu|YYYY-MM-DD
  static const ayat = 'ayat|'; // ayat|SURAH:AYAT
  static const prayerTimes = 'waktu-penting'; // sepertiga malam dll.
  static const ibadah = 'ibadah'; // membuka tab Ibadah

  /// "ayat|18:10" -> (18, 10); null bila bukan payload ayat yang sah.
  static (int, int)? parseAyat(String? payload) {
    if (payload == null || !payload.startsWith(ayat)) return null;
    final parts = payload.substring(ayat.length).split(':');
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]), a = int.tryParse(parts[1]);
    return s == null || a == null ? null : (s, a);
  }

  /// Tanggal `YYYY-MM-DD` di balik [prefix], atau null.
  static String? parseDate(String? payload, String prefix) {
    if (payload == null || !payload.startsWith(prefix)) return null;
    final d = payload.substring(prefix.length);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d) ? d : null;
  }
}

/// Satu notifikasi untuk satu tanggal yang isinya sudah disusun pemanggil
/// (mis. ayat harian: teksnya tetap per tanggal).
class DayNotice {
  const DayNotice({
    required this.date,
    required this.title,
    required this.body,
    required this.payload,
  });

  /// Tanggal (UTC tengah malam, seperti `todayInZone`).
  final DateTime date;
  final String title, body, payload;
}
