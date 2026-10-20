/// Dalil peringatan meninggalkan sholat, pintu taubat & qadha karena uzur,
/// serta panduan qashar & jamak saat safar.
///
/// Nomor hadits mengikuti kitab hadits di aplikasi (penomoran Lidwa Pusaka,
/// sama dengan yang terbuka saat rujukan diketuk) - setiap teks sudah
/// dicocokkan dengan matan Arabnya. Ayat diambil dari teks Al-Qur'an
/// aplikasi (Mushaf Standar Indonesia & terjemahan Kemenag).
library;

class Dalil {
  const Dalil({required this.text, required this.source, this.arabic});

  /// Teks Arab (ayat) - hadits cukup terjemahannya.
  final String? arabic;
  final String text;

  /// "QS. Maryam: 59" / "HR. Muslim no. 116" - rujukan hadits menjadi
  /// tautan ke kitab di aplikasi.
  final String source;
}

/// Ancaman umum meninggalkan / menyia-nyiakan sholat.
const peringatanUmum = [
  Dalil(
    arabic:
        'فَخَلَفَ مِنْۢ بَعْدِهِمْ خَلْفٌ اَضَاعُوا الصَّلٰوةَ وَاتَّبَعُوا '
        'الشَّهَوٰتِ فَسَوْفَ يَلْقَوْنَ غَيًّا',
    text:
        'Kemudian datanglah setelah mereka pengganti yang mengabaikan salat '
        'dan mengikuti keinginannya, maka mereka kelak akan tersesat.',
    source: 'QS. Maryam: 59',
  ),
  Dalil(
    arabic:
        'فَوَيْلٌ لِّلْمُصَلِّيْنَ ۙ الَّذِيْنَ هُمْ عَنْ صَلَاتِهِمْ سَاهُوْنَ',
    text:
        'Maka celakalah orang yang salat, (yaitu) orang-orang yang lalai '
        'terhadap salatnya.',
    source: "QS. Al-Ma'un: 4-5",
  ),
  Dalil(
    arabic:
        'مَا سَلَكَكُمْ فِيْ سَقَرَ ۙ قَالُوْا لَمْ نَكُ مِنَ الْمُصَلِّيْنَ',
    text:
        '"Apa yang menyebabkan kamu masuk ke dalam (neraka) Saqar?" Mereka '
        'menjawab, "Dahulu kami tidak termasuk orang-orang yang melaksanakan '
        'salat."',
    source: 'QS. Al-Muddatstsir: 42-43',
  ),
  Dalil(
    text:
        '"Sungguh, (batas) antara seseorang dengan kesyirikan dan kekufuran '
        'adalah meninggalkan shalat."',
    source: 'HR. Muslim no. 116',
  ),
  Dalil(
    text:
        '"Perjanjian antara kami dan mereka adalah shalat; barangsiapa '
        'meninggalkannya, sungguh ia telah kafir." (Kata At-Tirmidzi: hasan '
        'shahih gharib)',
    source: 'HR. Tirmidzi no. 2545',
  ),
  Dalil(
    text:
        'Dalam mimpi Nabi ﷺ (mimpi para nabi adalah wahyu): seseorang '
        'dihantam kepalanya dengan batu hingga pecah, lalu kepalanya pulih '
        'dan dihantam lagi. Ia adalah orang yang mengambil Al-Qur\'an lalu '
        'menolaknya, dan tidur meninggalkan shalat wajib.',
    source: 'HR. Bukhari no. 6525',
  ),
];

/// Peringatan khusus per sholat ('subuh'..'isya'). Dzuhur & Maghrib tidak
/// memiliki hadits shahih khusus - yang berlaku ancaman umum di atas.
const peringatanKhusus = <String, List<Dalil>>{
  'subuh': [
    Dalil(
      text:
          '"Tidak ada shalat yang lebih berat bagi orang-orang munafik '
          'daripada shalat Subuh dan Isya. Seandainya mereka mengetahui '
          '(kebaikan) yang ada pada keduanya, tentulah mereka mendatanginya '
          'walau harus merangkak."',
      source: 'HR. Bukhari no. 617',
    ),
    Dalil(
      text:
          'Diceritakan kepada Nabi ﷺ seseorang yang tidur semalaman hingga '
          'pagi. Beliau bersabda, "Itulah orang yang dikencingi setan pada '
          'kedua telinganya."',
      source: 'HR. Bukhari no. 3030',
    ),
  ],
  'dzuhur': [
    Dalil(
      arabic:
          'حٰفِظُوْا عَلَى الصَّلَوٰتِ وَالصَّلٰوةِ الْوُسْطٰى وَقُوْمُوْا '
          'لِلّٰهِ قٰنِتِيْنَ',
      text:
          'Peliharalah semua salat dan salat wustha. Dan laksanakanlah '
          '(salat) karena Allah dengan khusyuk.',
      source: 'QS. Al-Baqarah: 238',
    ),
  ],
  'ashar': [
    Dalil(
      text:
          '"Barangsiapa meninggalkan shalat Ashar, sungguh hapuslah amalnya."',
      source: 'HR. Bukhari no. 520',
    ),
    Dalil(
      text:
          '"Orang yang terluput shalat Ashar, seakan-akan ia kehilangan '
          'keluarga dan hartanya."',
      source: 'HR. Bukhari no. 519',
    ),
  ],
  'maghrib': [
    Dalil(
      arabic:
          'اِنَّ الصَّلٰوةَ كَانَتْ عَلَى الْمُؤْمِنِيْنَ كِتٰبًا مَّوْقُوْتًا',
      text:
          'Sungguh, salat itu adalah kewajiban yang ditentukan waktunya atas '
          'orang-orang yang beriman.',
      source: "QS. An-Nisa': 103",
    ),
  ],
  'isya': [
    Dalil(
      text:
          '"Tidak ada shalat yang lebih berat bagi orang-orang munafik '
          'daripada shalat Subuh dan Isya. Seandainya mereka mengetahui '
          '(kebaikan) yang ada pada keduanya, tentulah mereka mendatanginya '
          'walau harus merangkak."',
      source: 'HR. Bukhari no. 617',
    ),
  ],
};

/// Keutamaan yang dijanjikan - penyeimbang ancaman.
const keutamaanSubuh = Dalil(
  text: '"Barangsiapa shalat Subuh, maka ia berada dalam jaminan Allah."',
  source: 'HR. Muslim no. 1050',
);

/// Qadha karena uzur & pintu taubat.
const pintuTaubat = [
  Dalil(
    text:
        '"Barangsiapa lupa shalat atau tertidur darinya, maka kaffaratnya '
        'adalah menunaikannya ketika ia ingat."',
    source: 'HR. Muslim no. 1103',
  ),
  Dalil(
    text:
        '"Sungguh, tidak ada kelalaian karena tidur. Kelalaian itu hanyalah '
        'bagi orang yang tidak shalat hingga datang waktu shalat yang lain."',
    source: 'HR. Muslim no. 1099',
  ),
];

/// Satu bagian panduan: judul + butir-butir.
class PanduanBagian {
  const PanduanBagian(this.title, this.points, {this.dalil = const []});
  final String title;
  final List<String> points;
  final List<Dalil> dalil;
}

/// Panduan qashar & jamak saat safar (fiqih ringkas, mengikuti pendapat
/// jumhur / mazhab Syafi'i yang umum di Indonesia).
const panduanQashar = [
  PanduanBagian(
    'Apa itu qashar?',
    [
      'Meringkas sholat empat rakaat menjadi dua rakaat saat safar '
          '(bepergian).',
      'Yang boleh diqashar: Dzuhur, Ashar & Isya. Maghrib (3 rakaat) & '
          'Subuh (2 rakaat) tetap - tidak diqashar.',
      'Qashar adalah keringanan (rukhshah) dari Allah, bukan sholat yang '
          'kurang - pahalanya penuh.',
    ],
    dalil: [
      Dalil(
        arabic:
            'وَاِذَا ضَرَبْتُمْ فِى الْاَرْضِ فَلَيْسَ عَلَيْكُمْ جُنَاحٌ اَنْ '
            'تَقْصُرُوْا مِنَ الصَّلٰوةِ',
        text:
            'Dan apabila kamu bepergian di bumi, maka tidaklah berdosa kamu '
            'meng-qasar salat.',
        source: "QS. An-Nisa': 101",
      ),
      Dalil(
        text:
            '"(Qashar) itu sedekah yang Allah berikan kepada kalian, maka '
            'terimalah sedekah-Nya."',
        source: 'HR. Muslim no. 1108',
      ),
      Dalil(
        text:
            '"Awal mula shalat diwajibkan dua rakaat, kemudian ketentuan ini '
            'ditetapkan untuk shalat safar dan disempurnakan bagi shalat '
            'mukim." (\'Aisyah)',
        source: 'HR. Bukhari no. 1028',
      ),
    ],
  ),
  PanduanBagian(
    'Syarat',
    [
      'Perjalanan bukan untuk maksiat.',
      'Jarak: menurut jumhur ulama (Syafi\'i, Maliki, Hanbali) sekitar 4 '
          "burud ≈ 80-89 km - Ibnu 'Umar & Ibnu 'Abbas mengqashar pada jarak "
          "itu (disebut Al-Bukhari dalam bab qashar). Sebagian ulama "
          "mengembalikannya pada kebiasaan ('urf) sesuatu disebut safar.",
      'Mulai mengqashar setelah keluar dari batas kota/permukiman, bukan '
          'sejak di rumah.',
      'Bila bermakmum kepada imam yang tidak safar, sholat sempurna empat '
          'rakaat mengikuti imam.',
    ],
    dalil: [
      Dalil(
        text:
            '"Aku shalat Zhuhur bersama Nabi ﷺ di Madinah empat rakaat, '
            'sedangkan di Dzul Hulaifah dua rakaat." (Anas bin Malik)',
        source: 'HR. Bukhari no. 1027',
      ),
    ],
  ),
  PanduanBagian(
    'Berapa lama?',
    [
      "Mazhab Syafi'i: bila berniat menetap 4 hari atau lebih (selain hari "
          'datang & pergi) di tujuan, sholat kembali sempurna sejak tiba.',
      'Bila tidak pasti kapan pulang (urusan bisa selesai kapan saja), boleh '
          'terus mengqashar - Nabi ﷺ pernah menetap 19 hari dan mengqashar.',
    ],
    dalil: [
      Dalil(
        text:
            '"Nabi ﷺ pernah menetap (dalam bepergian) selama sembilan belas '
            'hari dengan mengqashar shalat." (Ibnu \'Abbas)',
        source: 'HR. Bukhari no. 1018',
      ),
    ],
  ),
  PanduanBagian('Cara sholat qashar', [
    'Niat dalam hati, mis. "Aku niat sholat Dzuhur dua rakaat qashar karena '
        'Allah Ta\'ala."',
    'Sholat dua rakaat seperti sholat Subuh: takbiratul ihram, Al-Fatihah & '
        'surah, ruku\', i\'tidal, sujud dua kali - rakaat kedua lalu '
        'tasyahud akhir & salam.',
    'Tanpa tasyahud awal, karena hanya dua rakaat.',
  ]),
  PanduanBagian(
    'Jamak: menggabungkan dua sholat',
    [
      'Pasangan jamak: Dzuhur dengan Ashar, Maghrib dengan Isya. Subuh '
          'tidak bisa dijamak.',
      "Jamak taqdim: dikerjakan di waktu sholat pertama (Ashar di waktu "
          'Dzuhur, Isya di waktu Maghrib) - berurutan & bersambung.',
      "Jamak ta'khir: dikerjakan di waktu sholat kedua (Dzuhur di waktu "
          'Ashar, Maghrib di waktu Isya) - niat menta\'khir sebelum waktu '
          'sholat pertama habis.',
      'Kerjakan sholat pertama lebih dulu (Dzuhur lalu Ashar, Maghrib lalu '
          'Isya). Boleh sekaligus diqashar: Dzuhur 2 + Ashar 2, Maghrib 3 + '
          'Isya 2.',
      "Sholat yang dijamak ta'khir bukan qadha - di aplikasi dicatat sebagai "
          'Jamak, nilainya penuh.',
    ],
    dalil: [
      Dalil(
        text:
            '"Nabi ﷺ bila berangkat bepergian sebelum matahari condong, '
            'beliau mengakhirkan shalat Zhuhur hingga waktu Ashar lalu '
            'menjamak keduanya. Bila berangkat setelah matahari condong, '
            'beliau shalat Zhuhur dulu kemudian berangkat." (Anas bin Malik)',
        source: 'HR. Bukhari no. 1044',
      ),
    ],
  ),
  PanduanBagian('Bukan alasan menunda', [
    'Safar memberi keringanan qashar & jamak, bukan izin menunda sholat '
        'sampai habis waktunya.',
    'Bila benar-benar tidak bisa turun dari kendaraan (mis. di pesawat), '
        'sholat sebisanya di tempat agar waktunya tidak terlewat - rinciannya '
        'ditanyakan kepada ustadz.',
  ]),
];
