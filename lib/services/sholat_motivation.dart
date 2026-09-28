/// Variasi pesan penyemangat sholat di awal waktu - dipakai kartu pengingat
/// di aplikasi ([sholatNudges]). Widget layar utama punya versi pendeknya
/// sendiri (IbadahWidgetProvider.kt).
///
/// Pesan dipilih dengan [pickMessage] dari benih yang tetap sepanjang hari
/// (tanggal + sholat), jadi tidak berganti-ganti setiap kali layar dibangun
/// ulang, tapi bervariasi dari hari ke hari.
library;

/// Pesan ke-([seed] mod panjang) dari [variants].
String pickMessage(List<String> variants, int seed) =>
    variants[seed.abs() % variants.length];

/// Benih harian untuk [pickMessage]: tanggal (YYYY-MM-DD) + pembeda.
int dailySeed(String dateKey, [int salt = 0]) {
  final d = DateTime.parse(dateKey);
  final dayOfYear = d.difference(DateTime.utc(d.year)).inDays;
  return dayOfYear * 7 + salt;
}

/// Sholat [name] sudah masuk & masih di awal waktu (sampai [until]).
List<String> onTimeReminders(String name, String until) => [
  'Masih awal waktu sampai $until. Yuk, segera sholat lalu catat.',
  'Amalan yang paling dicintai Allah: sholat di awal waktunya. '
      'Masih ada waktu sampai $until.',
  'Tinggalkan sejenak urusanmu - $name sudah memanggil. Awal waktu '
      'sampai $until.',
  "Hayya 'alash-shalah! Sholat $name sekarang, hati pun lapang. "
      'Awal waktu sampai $until.',
  'Sebelum sibuk lagi, sholat $name dulu yuk. Awal waktu sampai $until.',
];

/// Sholat [name] sudah lewat awal waktu, tapi waktunya masih ada ([end]).
List<String> lateReminders(String name, String end) => [
  'Awal waktu sudah lewat, tapi waktu $name masih ada sampai $end. '
      'Jangan sampai qadha.',
  'Belum terlambat untuk menunaikan $name - waktunya sampai $end. '
      'Yuk sekarang.',
  'Masih ada kesempatan sampai $end. Sholat $name dulu, urusan lain '
      'menyusul.',
  'Jangan tunda lagi, waktu $name tinggal sampai $end.',
];

/// Sholat [name] hari ini tercatat terlambat; [next] = sholat berikutnya
/// yang belum dikerjakan (null bila tidak ada lagi hari ini).
List<String> lateToday(String name, String? next) => next != null
    ? [
        'Tak apa, $name sudah tertunai. Yuk $next nanti di awal waktu.',
        'Terlambat bukan akhir - $next jadi kesempatan baru untuk lebih '
            'awal.',
        'Pasang niat & alarm sebelum adzan $next, insyaa Allah lebih '
            'tepat.',
        'Satu langkah lagi: begitu adzan $next, langsung ambil wudhu.',
      ]
    : [
        'Tak apa, $name sudah tertunai. Besok insyaa Allah lebih awal.',
        'Pasang niat sebelum tidur: esok semua sholat di awal waktu.',
        'Terlambat bukan akhir - esok kesempatan baru untuk lebih awal.',
      ];

/// Sholat [name] hari ini tercatat qadha (dikerjakan sesudah waktunya).
List<String> qadhaToday(String name, String? next) => next != null
    ? [
        'Alhamdulillah $name sudah diqadha. Jaga $next di awal waktu ya.',
        'Perbanyak istighfar, lalu sambut $next begitu adzan.',
        'Pasang alarm sebelum $next, jangan sampai terlewat lagi.',
      ]
    : [
        'Alhamdulillah $name sudah diqadha. Besok insyaa Allah tepat waktu.',
        'Perbanyak istighfar, dan pasang alarm untuk Subuh esok.',
        'Semoga esok semua sholat terjaga di awal waktunya.',
      ];

/// Evaluasi 7 hari: [name] sering terlambat (rata-rata [avgDelay] menit).
List<String> weeklyLate(String name, int avgDelay) => [
  'Rata-rata $avgDelay menit setelah adzan. Sedikit lagi, insyaa Allah '
      'bisa di awal waktu.',
  'Rata-rata $avgDelay menit setelah adzan. Coba siap-siap 5 menit '
      'sebelum adzan $name.',
  'Rata-rata $avgDelay menit setelah adzan. Jadikan $name sholat '
      'pertama yang kamu perbaiki pekan ini.',
];

/// Evaluasi 7 hari: [name] [qadha] kali qadha.
List<String> weeklyQadha(String name, int qadha) => [
  '${qadha}x di antaranya qadha. Pasang niat & alarm sebelum adzan '
      '$name - semangat!',
  '${qadha}x di antaranya qadha. Minta keluarga atau teman saling '
      'mengingatkan saat $name.',
  '${qadha}x di antaranya qadha. Tidur lebih awal & pasang alarm - '
      'insyaa Allah $name terjaga.',
];

/// Evaluasi 7 hari: [onTime] dari [total] sholat di awal waktu.
List<String> weeklyPraise(int onTime, int total) => [
  '$onTime dari $total sholat seminggu terakhir dikerjakan di awal '
      'waktu. Pertahankan!',
  '$onTime dari $total sholat di awal waktu. Barakallahu fik, '
      'istiqamah ya!',
  '$onTime dari $total sholat di awal waktu. Semoga Allah jaga '
      'semangat ini.',
];
