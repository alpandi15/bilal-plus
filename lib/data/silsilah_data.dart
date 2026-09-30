/// Nasab Nabi Muhammad ﷺ dari pihak ayah sampai 'Adnan - bagian nasab yang
/// disepakati ulama nasab, sebagaimana disebut Imam Al-Bukhari dalam
/// Shahih-nya (Kitab Manaqib al-Anshar, Bab Mab'ats an-Nabi ﷺ, sebelum
/// hadits no. 3851). Di atas 'Adnan sampai Nabi Isma'il tidak ada riwayat
/// shahih - nama & jumlahnya diperselisihkan - jadi sengaja tidak dimuat.
library;

class Leluhur {
  const Leluhur(this.arabic, this.latin, {this.note, this.tag});

  final String arabic, latin;

  /// Keterangan singkat (nama asli, peristiwa penting).
  final String? note;

  /// Label penanda cabang/peristiwa, mis. "Quraisy".
  final String? tag;
}

/// Urutan dari Nabi ﷺ (indeks 0) naik sampai 'Adnan (indeks 21).
const silsilahNabi = [
  Leluhur(
    'مُحَمَّدٌ ﷺ',
    'Muhammad ﷺ',
    note: 'Rasulullah, penutup para nabi. Lahir di Makkah pada Tahun Gajah.',
  ),
  Leluhur(
    'عَبْدُ اللّٰهِ',
    'Abdullah',
    note: 'Ayahanda Nabi ﷺ; wafat sebelum beliau lahir.',
  ),
  Leluhur(
    'عَبْدُ الْمُطَّلِبِ',
    'Abdul Muththalib',
    note:
        'Nama aslinya Syaibah. Kakek yang mengasuh Nabi ﷺ setelah ibundanya '
        'wafat; pemuka Quraisy di Makkah.',
  ),
  Leluhur(
    'هَاشِمٌ',
    'Hasyim',
    note: "Nama aslinya 'Amr. Darinya berasal Bani Hasyim.",
    tag: 'Bani Hasyim',
  ),
  Leluhur('عَبْدُ مَنَافٍ', 'Abdu Manaf', note: 'Nama aslinya Al-Mughirah.'),
  Leluhur(
    'قُصَيٌّ',
    'Qushay',
    note:
        'Nama aslinya Zaid. Pemimpin yang menghimpun kabilah Quraisy di '
        'Makkah.',
  ),
  Leluhur(
    'كِلَابٌ',
    'Kilab',
    note: 'Di sini nasab ayah bertemu dengan nasab ibunda, Aminah binti Wahb.',
    tag: 'Bertemu nasab ibu',
  ),
  Leluhur('مُرَّةُ', 'Murrah'),
  Leluhur('كَعْبٌ', "Ka'b"),
  Leluhur('لُؤَيٌّ', "Lu'ay"),
  Leluhur('غَالِبٌ', 'Ghalib'),
  Leluhur(
    'فِهْرٌ',
    'Fihr',
    note:
        'Menurut pendapat yang masyhur, keturunan Fihr-lah yang disebut '
        'Quraisy (sebagian ulama berpendapat An-Nadhr).',
    tag: 'Quraisy',
  ),
  Leluhur('مَالِكٌ', 'Malik'),
  Leluhur('النَّضْرُ', 'An-Nadhr', note: 'Nama aslinya Qais.'),
  Leluhur(
    'كِنَانَةُ',
    'Kinanah',
    note: "Allah memilih Kinanah dari keturunan Isma'il (HR. Muslim no. 2276).",
    tag: 'Kinanah',
  ),
  Leluhur('خُزَيْمَةُ', 'Khuzaimah'),
  Leluhur('مُدْرِكَةُ', 'Mudrikah', note: "Nama aslinya 'Amir."),
  Leluhur('إِلْيَاسُ', 'Ilyas'),
  Leluhur('مُضَرُ', 'Mudhar'),
  Leluhur('نِزَارٌ', 'Nizar'),
  Leluhur("مَعَدٌّ", "Ma'add"),
  Leluhur(
    'عَدْنَانُ',
    "'Adnan",
    note:
        "Batas nasab yang disepakati. 'Adnan termasuk keturunan Nabi Isma'il "
        "bin Ibrahim 'alaihimassalam.",
    tag: 'Batas yang disepakati',
  ),
];

/// Nasab ibunda Nabi ﷺ, bertemu dengan nasab ayah pada Kilab.
const nasabIbu = [
  Leluhur('آمِنَةُ', 'Aminah', note: 'Ibunda Nabi ﷺ'),
  Leluhur('وَهْبٌ', 'Wahb'),
  Leluhur('عَبْدُ مَنَافٍ', 'Abdu Manaf'),
  Leluhur('زُهْرَةُ', 'Zuhrah'),
  Leluhur('كِلَابٌ', 'Kilab'),
];

/// Teks nasab dalam Shahih al-Bukhari (Bab Mab'ats an-Nabi ﷺ).
const nasabBukhari =
    'مُحَمَّدُ بْنُ عَبْدِ اللّٰهِ بْنِ عَبْدِ الْمُطَّلِبِ بْنِ هَاشِمِ بْنِ '
    'عَبْدِ مَنَافِ بْنِ قُصَيِّ بْنِ كِلَابِ بْنِ مُرَّةَ بْنِ كَعْبِ بْنِ '
    'لُؤَيِّ بْنِ غَالِبِ بْنِ فِهْرِ بْنِ مَالِكِ بْنِ النَّضْرِ بْنِ كِنَانَةَ '
    'بْنِ خُزَيْمَةَ بْنِ مُدْرِكَةَ بْنِ إِلْيَاسَ بْنِ مُضَرَ بْنِ نِزَارِ بْنِ '
    'مَعَدِّ بْنِ عَدْنَانَ';
