// DIBUAT OTOMATIS oleh tool/gen_zakat.py dari naskah web Bilal Tarawih
// (src/data/zakat-fitrah.ts) - jangan diedit langsung.

import '../pages/zakat_fitrah_page.dart';

const zakatSyaratWajib = <ZakatPoin>[
  ZakatPoin(
    'Beragama Islam',
    'Zakat fitrah hanya diwajibkan atas seorang muslim, baik laki-laki maupun perempuan, tua maupun muda.',
  ),
  ZakatPoin(
    'Menjumpai akhir Ramadhan',
    'Yaitu masih hidup saat matahari terbenam pada hari terakhir Ramadhan (malam takbiran). Bayi yang lahir sebelum maghrib itu tetap wajib dizakati; yang lahir sesudahnya tidak.',
  ),
  ZakatPoin(
    'Punya kelebihan makanan',
    'Memiliki kelebihan bahan makanan untuk dirinya dan orang yang ditanggungnya pada malam dan hari raya Idulfitri. Yang tidak punya kelebihan justru termasuk pihak yang berhak menerima.',
  ),
];

const zakatDitanggung = <ZakatPoin>[
  ZakatPoin(
    'Anak yang belum baligh',
    'Dibayarkan oleh orang tua atau walinya, termasuk bayi yang baru lahir sebelum maghrib akhir Ramadhan.',
  ),
  ZakatPoin(
    'Istri dan anggota keluarga',
    'Seluruh orang yang nafkahnya menjadi tanggungan kepala keluarga secara syar\'i - inilah sebabnya penyerahan di masjid biasanya disebutkan satu per satu.',
  ),
  ZakatPoin(
    'Pembantu yang ditanggung nafkahnya',
    'Bila nafkahnya memang menjadi tanggungan, zakat fitrahnya ikut dibayarkan.',
  ),
];

const fidyahSiapa = <ZakatPoin>[
  ZakatPoin(
    'Orang tua renta',
    'Yang sudah tidak sanggup berpuasa dan tidak diharapkan mampu mengqadhanya.',
  ),
  ZakatPoin(
    'Sakit menahun',
    'Yang menurut keterangan medis kecil kemungkinan sembuh sehingga tidak mampu mengqadha.',
  ),
  ZakatPoin(
    'Ibu hamil dan menyusui',
    'Bila tidak berpuasa karena mengkhawatirkan keselamatan bayinya. Jika yang dikhawatirkan hanya dirinya sendiri, cukup mengqadha tanpa fidyah.',
  ),
  ZakatPoin(
    'Menunda qadha hingga Ramadhan berikutnya',
    'Tanpa uzur yang dibenarkan - ia mengqadha puasanya sekaligus membayar fidyah.',
  ),
];

const zakatKadar = <String, String>{
  'utama': '2,5 kg',
  'setara': '3,5 liter',
  'satuan': 'beras atau makanan pokok, per jiwa',
  'dasar':
      'Ukuran ini adalah konversi dari satu sha\' yang disebut dalam hadits. Sebagian daerah memakai 2,7 kg untuk kehati-hatian - keduanya sama-sama dipakai ulama.',
  'uang':
      'Membayar dengan uang senilai harga makanan pokok dibolehkan menurut mazhab Hanafi dan difatwakan boleh oleh MUI. Nominalnya mengikuti ketetapan panitia atau BAZNAS setempat karena berbeda tiap tahun dan tiap daerah.',
  'mutu':
      'Bila berupa beras, mutunya hendaknya sama dengan yang biasa dimakan sehari-hari - bukan yang lebih buruk.',
};

const fidyahKadar = <String, String>{
  'utama': '1 mud',
  'setara': '± 675 gram (0,7 liter)',
  'satuan': 'makanan pokok, untuk setiap hari puasa yang ditinggalkan',
  'detail':
      'Diberikan kepada fakir atau miskin. Boleh dibayarkan sekaligus untuk seluruh hari yang ditinggalkan, dan boleh diserahkan lewat panitia atau lembaga amil.',
};

const zakatWaktu = <ZakatWaktu>[
  ZakatWaktu(
    'Boleh',
    'netral',
    'Sejak awal Ramadhan',
    'Boleh ditunaikan lebih awal, sejak hari pertama Ramadhan. Inilah yang umum dipakai panitia masjid agar penyaluran sempat rapi.',
  ),
  ZakatWaktu(
    'Wajib',
    'wajib',
    'Maghrib akhir Ramadhan',
    'Kewajiban mulai mengikat begitu matahari terbenam pada malam takbiran.',
  ),
  ZakatWaktu(
    'Paling utama',
    'utama',
    'Subuh hingga sebelum shalat Id',
    'Waktu paling afdal: setelah shalat Subuh dan sebelum berangkat shalat Idulfitri.',
  ),
  ZakatWaktu(
    'Makruh',
    'makruh',
    'Setelah shalat Id, sebelum maghrib',
    'Masih sah, tetapi kehilangan keutamaannya karena tujuan zakat fitrah adalah mencukupi fakir miskin pada hari raya.',
  ),
  ZakatWaktu(
    'Tidak sah',
    'haram',
    'Setelah maghrib 1 Syawal',
    'Tidak lagi terhitung zakat fitrah pada waktunya; statusnya menjadi utang yang wajib diqadha dan berdosa bila ditunda tanpa uzur.',
  ),
];

const zakatTataCara = <ZakatLangkah>[
  ZakatLangkah(
    'Niatkan di dalam hati',
    'Niat adalah rukunnya dan letaknya di dalam hati saat menyerahkan. Melafalkannya hanya penguat, tidak wajib. Lafal niat lengkapnya tersedia di menu Do\'a.',
    peran: null,
    ucapan: null,
  ),
  ZakatLangkah(
    'Serahkan sambil menyebutkan nama',
    'Kepala keluarga menyerahkan zakat sambil menyebutkan siapa saja yang dizakati, agar panitia dapat mencatatnya dengan benar.',
    peran: 'pemberi',
    ucapan:
        'Bapak/Ibu panitia, saya serahkan zakat fitrah atas nama saya, {nama kepala keluarga}, beserta seluruh keluarga yang menjadi tanggungan saya, yaitu {sebutkan nama satu per satu}, kepada panitia zakat fitrah Masjid {nama masjid} untuk tahun ini, Lillahi ta\'ala.',
  ),
  ZakatLangkah(
    'Panitia menerima dan mendoakan',
    'Panitia menyebutkan kembali nama dan bentuk zakat yang diterima sebagai bentuk kejelasan, lalu mendoakan pemberinya.',
    peran: 'penerima',
    ucapan:
        'Kami terima zakat fitrah Bapak/Ibu {nama kepala keluarga} beserta seluruh tanggungannya, berupa {beras/uang}, melalui panitia zakat fitrah Masjid {nama masjid}. Semoga Allah menerima amal Bapak/Ibu sekeluarga, mensucikan harta dan jiwa, serta melimpahkan keberkahan. Insyaa Allah akan kami salurkan kepada yang berhak menerimanya.',
  ),
  ZakatLangkah(
    'Panitia membacakan doa untuk pemberi zakat',
    'Mengikuti sunnah Nabi shallallaahu \'alaihi wa sallam yang selalu mendoakan orang yang menyerahkan zakat kepada beliau.',
    peran: null,
    ucapan: null,
  ),
  ZakatLangkah(
    'Tutup dengan doa kebaikan dunia dan akhirat',
    'Lazim dibaca bersama sebagai penutup penyerahan.',
    peran: null,
    ucapan: null,
  ),
];

const zakatCatatanAdat =
    'Susunan ucapan serah terima di atas adalah adat yang lazim dipakai panitia masjid di berbagai daerah agar penyerahan jelas dan tercatat rapi, bukan syarat sah zakat. Yang menentukan sahnya adalah niat di dalam hati serta sampainya zakat kepada yang berhak. Karena itu redaksinya boleh disesuaikan dengan kebiasaan masjid masing-masing.';

const zakatDoaPenutup = <String, String>{
  'arabic':
      'رَبَّنَآ اٰتِنَا فِى الدُّنْيَا حَسَنَةً وَّفِى الْاٰخِرَةِ حَسَنَةً وَّقِنَا عَذَابَ النَّارِ',
  'latin':
      'Rabbanaa aatinaa fid dunyaa hasanah, wa fil aakhirati hasanah, wa qinaa \'adzaaban naar.',
  'indonesia':
      'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat, dan lindungilah kami dari azab neraka.',
  'sumber': 'Potongan doa dalam QS. Al-Baqarah: 201',
};

const zakatDoaPanitia = <String, String>{
  'arabic':
      'آجَرَكَ اللَّهُ فِيمَا أَعْطَيْتَ، وَبَارَكَ فِيمَا أَبْقَيْتَ، وَجَعَلَهُ لَكَ طَهُورًا',
  'latin':
      'Aajarakallaahu fiimaa a\'thaita, wa baaraka fiimaa abqaita, wa ja\'alahu laka thahuuran.',
  'indonesia':
      'Semoga Allah memberi ganjaran atas apa yang telah engkau berikan, memberkahi harta yang engkau sisakan, dan menjadikan (zakat itu) sebagai penyuci bagimu.',
  'catatan':
      'Lafal ini luas diamalkan lembaga amil zakat di Indonesia. Rujukan hadits untuk redaksi persisnya tidak dapat dipastikan; yang berdasar hadits shahih adalah anjuran mendoakan pemberi zakat - Rasulullah shallallaahu \'alaihi wa sallam mendoakan keluarga Abu Aufa ketika menerima zakat mereka (HR. Bukhari no. 4166 dan Muslim no. 1078).',
};
