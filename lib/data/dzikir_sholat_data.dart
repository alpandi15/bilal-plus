// DIBUAT OTOMATIS oleh tool/gen_dzikir_sholat.py - jangan diedit langsung.
//
// Dzikir & doa setelah sholat wajib - Hisnul Muslim (bab dzikir setelah
// salam). Ayat Kursi & surah perlindungan dari teks Mushaf Standar
// Indonesia (assets/quran/quran.json). Latin & terjemahan bersifat bantuan.

import '../services/dzikir.dart';

const dzikirSholatList = <Dzikir>[
  Dzikir(
    id: 66,
    title: 'Istighfar & Allaahumma antas salaam',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'أَسْتَغْفِرُ اللّٰهَ، أَسْتَغْفِرُ اللّٰهَ، أَسْتَغْفِرُ اللّٰهَ. اَللّٰهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    latin:
        'Astaghfirullaah (3×). Allaahumma antas salaam wa minkas salaam, tabaarakta yaa dzal jalaali wal ikraam.',
    arti:
        'Aku memohon ampun kepada Allah (3×). Ya Allah, Engkaulah As-Salaam (Yang Maha Sejahtera) dan dari-Mu segala kesejahteraan. Mahaberkah Engkau, wahai Pemilik keagungan dan kemuliaan.',
    note: 'Dibaca segera setelah salam.',
    source: 'HR. Muslim no. 591',
  ),
  Dzikir(
    id: 67,
    title: 'Laa maani\'a limaa a\'thaita',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ. اَللّٰهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'alaa kulli syai-in qadiir. Allaahumma laa maani\'a limaa a\'thaita, wa laa mu\'thiya limaa mana\'ta, wa laa yanfa\'u dzal jaddi minkal jadd.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu. Ya Allah, tidak ada yang dapat menghalangi apa yang Engkau berikan, tidak ada yang dapat memberi apa yang Engkau halangi, dan tidak berguna kekayaan pemiliknya di hadapan-Mu.',
    source: 'HR. Bukhari no. 844 & Muslim no. 593',
  ),
  Dzikir(
    id: 68,
    title: 'Laa haula wa laa quwwata illaa billaah',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ، لَا إِلٰهَ إِلَّا اللّٰهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلٰهَ إِلَّا اللّٰهُ مُخْلِصِيْنَ لَهُ الدِّيْنَ وَلَوْ كَرِهَ الْكَافِرُوْنَ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'alaa kulli syai-in qadiir, laa haula wa laa quwwata illaa billaah, laa ilaaha illallaah, wa laa na\'budu illaa iyyaah, lahun ni\'matu wa lahul fadhlu wa lahuts tsanaa-ul hasan, laa ilaaha illallaahu mukhlishiina lahud diin walau karihal kaafiruun.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu. Tidak ada daya dan kekuatan kecuali dengan (pertolongan) Allah. Tidak ada tuhan selain Allah, dan kami tidak menyembah selain kepada-Nya. Milik-Nya segala nikmat, karunia, dan pujian yang baik. Tidak ada tuhan selain Allah, dengan memurnikan agama hanya bagi-Nya, meskipun orang-orang kafir membenci.',
    source: 'HR. Muslim no. 594',
  ),
  Dzikir(
    id: 691,
    title: 'Tasbih',
    repeat: 33,
    time: DzikirTime.sholat,
    arabic: 'سُبْحَانَ اللّٰهِ',
    latin: 'Subhaanallaah',
    arti: 'Mahasuci Allah',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 692,
    title: 'Tahmid',
    repeat: 33,
    time: DzikirTime.sholat,
    arabic: 'اَلْحَمْدُ لِلّٰهِ',
    latin: 'Alhamdulillaah',
    arti: 'Segala puji bagi Allah',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 693,
    title: 'Takbir',
    repeat: 33,
    time: DzikirTime.sholat,
    arabic: 'اَللّٰهُ أَكْبَرُ',
    latin: 'Allaahu akbar',
    arti: 'Allah Mahabesar',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 694,
    title: 'Tahlil penutup (genap 100)',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'alaa kulli syai-in qadiir.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu.',
    note:
        'Menggenapkan seratus - diampuni kesalahannya walau sebanyak buih di lautan.',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 70,
    title: 'Ayat Kursi',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'اَللّٰهُ لَآ اِلٰهَ اِلَّا هُوَۚ اَلْحَيُّ الْقَيُّوْمُ ەۚ لَا تَأْخُذُهٗ سِنَةٌ وَّلَا نَوْمٌۗ لَهٗ مَا فِى السَّمٰوٰتِ وَمَا فِى الْاَرْضِۗ مَنْ ذَا الَّذِيْ يَشْفَعُ عِنْدَهٗٓ اِلَّا بِاِذْنِهٖۗ يَعْلَمُ مَا بَيْنَ اَيْدِيْهِمْ وَمَا خَلْفَهُمْۚ وَلَا يُحِيْطُوْنَ بِشَيْءٍ مِّنْ عِلْمِهٖٓ اِلَّا بِمَا شَاۤءَۚ وَسِعَ كُرْسِيُّهُ السَّمٰوٰتِ وَالْاَرْضَۚ وَلَا يَـُٔوْدُهٗ حِفْظُهُمَاۚ وَهُوَ الْعَلِيُّ الْعَظِيْمُ',
    latin:
        'Allaahu laa ilaaha illaa huwal hayyul qayyuum, laa ta\'khudzuhuu sinatuw wa laa naum, lahuu maa fis samaawaati wa maa fil ardh, man dzal ladzii yasyfa\'u \'indahuu illaa bi-idznih, ya\'lamu maa baina aidiihim wa maa khalfahum, wa laa yuhiithuuna bisyai-im min \'ilmihii illaa bimaa syaa\', wasi\'a kursiyyuhus samaawaati wal ardh, wa laa ya-uuduhuu hifzhuhumaa, wa huwal \'aliyyul \'azhiim.',
    arti:
        'Allah, tidak ada tuhan selain Dia. Yang Mahahidup, Yang terus menerus mengurus (makhluk-Nya), tidak mengantuk dan tidak tidur. Milik-Nya apa yang ada di langit dan apa yang ada di bumi. Tidak ada yang dapat memberi syafaat di sisi-Nya tanpa izin-Nya. Dia mengetahui apa yang di hadapan mereka dan apa yang di belakang mereka, dan mereka tidak mengetahui sesuatu apa pun tentang ilmu-Nya melainkan apa yang Dia kehendaki. Kursi-Nya meliputi langit dan bumi. Dan Dia tidak merasa berat memelihara keduanya, dan Dia Mahatinggi, Mahabesar.',
    note: 'Tidak ada yang menghalanginya masuk surga kecuali kematian.',
    source: 'HR. An-Nasa\'i (As-Sunan Al-Kubra), dishahihkan Al-Albani',
  ),
  Dzikir(
    id: 71,
    title: 'Al-Ikhlas, Al-Falaq & An-Nas',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿قُلْ هُوَ اللّٰهُ اَحَدٌۚ ۝ اَللّٰهُ الصَّمَدُۚ ۝ لَمْ يَلِدْ وَلَمْ يُوْلَدْۙ ۝ وَلَمْ يَكُنْ لَّهٗ كُفُوًا اَحَدٌ ࣖ﴾\nبِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿قُلْ اَعُوْذُ بِرَبِّ الْفَلَقِۙ ۝ مِنْ شَرِّ مَا خَلَقَۙ ۝ وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ ۝ وَمِنْ شَرِّ النَّفّٰثٰتِ فِى الْعُقَدِۙ ۝ وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ ࣖ﴾\nبِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿قُلْ اَعُوْذُ بِرَبِّ النَّاسِۙ ۝ مَلِكِ النَّاسِۙ ۝ اِلٰهِ النَّاسِۙ ۝ مِنْ شَرِّ الْوَسْوَاسِ ەۙ الْخَنَّاسِۖ ۝ الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِۙ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ ࣖ﴾',
    latin:
        'Qul huwallaahu ahad. Allaahush shamad. Lam yalid wa lam yuulad. Wa lam yakul lahuu kufuwan ahad.\nQul a\'uudzu birabbil falaq. Min syarri maa khalaq. Wa min syarri ghaasiqin idzaa waqab. Wa min syarrin naffaatsaati fil \'uqad. Wa min syarri haasidin idzaa hasad.\nQul a\'uudzu birabbin naas. Malikin naas. Ilaahin naas. Min syarril waswaasil khannaas. Alladzii yuwaswisu fii shuduurin naas. Minal jinnati wan naas.',
    arti:
        'Katakanlah (Muhammad), “Dialah Allah, Yang Maha Esa. Allah tempat meminta segala sesuatu. (Allah) tidak beranak dan tidak pula diperanakkan. Dan tidak ada sesuatu yang setara dengan Dia.”\nKatakanlah, “Aku berlindung kepada Tuhan yang menguasai subuh (fajar), dari kejahatan (makhluk yang) Dia ciptakan, dan dari kejahatan malam apabila telah gelap gulita, dan dari kejahatan (perempuan-perempuan) penyihir yang meniup pada buhul-buhul (talinya), dan dari kejahatan orang yang dengki apabila dia dengki.”\nKatakanlah, “Aku berlindung kepada Tuhannya manusia, Raja manusia, sembahan manusia, dari kejahatan (bisikan) setan yang bersembunyi, yang membisikkan (kejahatan) ke dalam dada manusia, dari (golongan) jin dan manusia.”',
    note: 'Setelah Subuh & Maghrib dianjurkan masing-masing 3×.',
    source: 'HR. Abu Daud no. 1523 & At-Tirmidzi no. 2903',
  ),
  Dzikir(
    id: 72,
    title: 'Allaahumma a\'innii',
    repeat: 1,
    time: DzikirTime.sholat,
    arabic:
        'اَللّٰهُمَّ أَعِنِّيْ عَلٰى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    latin:
        'Allaahumma a\'innii \'alaa dzikrika wa syukrika wa husni \'ibaadatik.',
    arti:
        'Ya Allah, tolonglah aku untuk berdzikir kepada-Mu, bersyukur kepada-Mu, dan beribadah kepada-Mu dengan baik.',
    note:
        'Wasiat Nabi ﷺ kepada Mu\'adz bin Jabal agar tidak ditinggalkan di akhir setiap sholat.',
    source: 'HR. Abu Daud no. 1522 & An-Nasa\'i no. 1303',
  ),
  Dzikir(
    id: 73,
    title: 'Tahlil 10× (Subuh & Maghrib)',
    repeat: 10,
    time: DzikirTime.sholatSubuhMaghrib,
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِيْ وَيُمِيْتُ، وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu, yuhyii wa yumiit, wa huwa \'alaa kulli syai-in qadiir.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan pujian, Dia menghidupkan dan mematikan, dan Dia Mahakuasa atas segala sesuatu.',
    note: 'Khusus setelah Subuh & Maghrib.',
    source: 'HR. At-Tirmidzi no. 3474 (hasan)',
  ),
  Dzikir(
    id: 74,
    title: '\'Ilman naafi\'aa (Subuh)',
    repeat: 1,
    time: DzikirTime.sholatSubuh,
    arabic:
        'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
    latin:
        'Allaahumma innii as-aluka \'ilman naafi\'aa, wa rizqan thayyibaa, wa \'amalan mutaqabbalaa.',
    arti:
        'Ya Allah, sesungguhnya aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang baik, dan amal yang diterima.',
    note: 'Khusus setelah salam sholat Subuh.',
    source: 'HR. Ibnu Majah no. 925',
  ),
];
