// DIBUAT OTOMATIS oleh tool/gen_bilal.py - jangan diedit langsung.
//
// Bacaan bilal tarawih 11 rakaat, sama dengan web Bilal Tarawih.

import '../services/bilal_tarawih.dart';

const bilalSections = <BilalSection>[
  BilalSection(
    title: 'Sebelum Rakaat ke - 1&2',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْمَعْبُوْدِ',
        latin: 'Subhaanal-malikil-ma’buud',
        arti: 'Maha Suci Allah Yang Merajai (alam) lagi Yang Disembah',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْمَوْجُوْدِ',
        latin: 'Subhaanal-malikil-maujuud',
        arti: 'Maha Suci Allah Yang Merajai (alam) lagi Maha Ada',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لَا يَنَامُ وَلَا يَمُوْتُ وَلَا يَفُوْتُ اَبَدًا',
        latin:
            'Subhaanal-Malikil-Hayyil-Ladzi Laa Yanaamu Wa Laa Yamuutu Walaa Yafuutu Abadan',
        arti:
            'Maha Suci Allah Yang Merajai lagi Maha Hidup, Yang tidak tidur, tidak mati, dan tidak lenyap selama-lamanya',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبُّوْحٌ قُدُّوْسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوْحِ',
        latin: 'Subbuuhun Qudduusun Rabbunaa Wa Rabbul-Malaa-ikati War-Ruuh',
        arti:
            'Maha Suci lagi Maha Kudus, Tuhan kami dan Tuhan para malaikat serta Ruh (malaikat Jibril)',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا اِلَهَ اِلَّا اللَّهُ وَاللَّهُ اَكْبَرُ',
        latin:
            'Subhaanallaahi Wal-Hamdu Lillaahi Wa Laa Ilaaha Illallaahu Wallaahu Akbar',
        arti:
            'Maha Suci Allah, segala puji bagi Allah, tidak ada Tuhan selain Allah, dan Allah Maha Besar',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيْمِ',
        latin: 'Wa Laa Haula Wa Laa Quwwata Illaa Billaahil-\'Aliyyil-\'Azhiim',
        arti:
            'Dan tidak ada daya dan kekuatan kecuali dengan pertolongan Allah Yang Maha Tinggi lagi Maha Agung',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ',
        latin: 'Allaahumma Shalli \'Alaa Sayyidinaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin: 'Allaahumma Shalli \'Alaa Sayyidinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَنَبِيِّنَا وَحَبِيْبِنَا وَشَفِيْعِنَا وَذُخْرِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin:
            'Allaahumma Shalli \'Alaa Sayyidinaa Wa Nabiyyinaa Wa Habiibinaa Wa Syafii\'inaa Wa Dzukhrinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami, nabi kami, kekasih kami, pemberi syafaat kami, simpanan (pembela) kami, dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'صَلَاةَ التَّرَاوِيْحِ رَحِمَكُمُ اللَّهُ',
        latin: 'Shalaatat-Taraawiihi Rahimakumullaah',
        arti: '(Kerjakanlah) sholat tarawih, semoga Allah merahmati kalian',
      ),
    ],
  ),
  BilalSection(
    title: 'Sebelum Rakaat ke - 3&4',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'فَضْلًا مِنَ اللَّهِ وَنِعْمَةً وَمَغْفِرَةً وَرَحْمَةً',
        latin: 'Fadhlan Minallaahi Wa Ni\'matan Wa Maghfiratan Wa Rahmah',
        arti:
            '(Semoga) karunia, nikmat, ampunan, dan rahmat dari Allah dilimpahkan kepada kita',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'لَا اِلَهَ اِلَّا اللَّهُ وَحْدَهُ لَا شَرِيْكَ لَهُ',
        latin: 'Laa Ilaaha Illallaahu Wahdahuu Laa Syariika Lah',
        arti:
            'Tidak ada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu bagi-Nya',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيِيْ وَيُمِيْتُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرٌ',
        latin:
            'Lahul-Mulku Wa Lahul-Hamdu Yuhyii Wa Yumiitu Wa Huwa \'Alaa Kulli Syai-in Qadiir',
        arti:
            'Milik-Nya segala kerajaan dan milik-Nya segala puji. Dia menghidupkan dan mematikan, dan Dia Maha Kuasa atas segala sesuatu',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَنَبِيِّنَا وَحَبِيْبِنَا وَشَفِيْعِنَا وَذُخْرِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin:
            'Allaahumma Shalli \'Alaa Sayyidinaa Wa Nabiyyinaa Wa Habiibinaa Wa Syafii\'inaa Wa Dzukhrinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami, nabi kami, kekasih kami, pemberi syafaat kami, simpanan (pembela) kami, dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَلْبَدْرُ الْمُنِيْرُ سَيِّدُنَا مُحَمَّدٌ صَلُّوْا عَلَيْهِ',
        latin: 'Al-Badrul-Muniiru Sayyidunaa Muhammadun, Shalluu \'Alaih',
        arti:
            'Bulan purnama yang bersinar terang, junjungan kita Nabi Muhammad. Bershalawatlah kalian kepadanya',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَلْخَلِيْفَةُ الْأُوْلَى أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا أَبُوْ بَكْرٍ الصِّدِّيْقُ',
        latin:
            'Al-Khaliifatul-Uulaa Amiirul-Mu\'miniina Sayyidunaa Abuu Bakrinish-Shiddiiq',
        arti:
            'Khalifah pertama, Amirul Mu\'minin, junjungan kita Abu Bakar Ash-Shiddiq',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'صَلَاةَ التَّرَاوِيْحِ رَحِمَكُمُ اللَّهُ',
        latin: 'Shalaatat-Taraawiihi Rahimakumullaah',
        arti: '(Kerjakanlah) sholat tarawih, semoga Allah merahmati kalian',
      ),
    ],
  ),
  BilalSection(
    title: 'Sebelum Rakaat ke - 5&6',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْمَعْبُوْدِ',
        latin: 'Subhaanal-malikil-ma’buud',
        arti: 'Maha Suci Allah Yang Merajai (alam) lagi Yang Disembah',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْمَوْجُوْدِ',
        latin: 'Subhaanal-malikil-maujuud',
        arti: 'Maha Suci Allah Yang Merajai (alam) lagi Maha Ada',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لَا يَنَامُ وَلَا يَمُوْتُ وَلَا يَفُوْتُ اَبَدًا',
        latin:
            'Subhaanal-Malikil-Hayyil-Ladzi Laa Yanaamu Wa Laa Yamuutu Walaa Yafuutu Abadan',
        arti:
            'Maha Suci Allah Yang Merajai lagi Maha Hidup, Yang tidak tidur, tidak mati, dan tidak lenyap selama-lamanya',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبُّوْحٌ قُدُّوْسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوْحِ',
        latin: 'Subbuuhun Qudduusun Rabbunaa Wa Rabbul-Malaa-ikati War-Ruuh',
        arti:
            'Maha Suci lagi Maha Kudus, Tuhan kami dan Tuhan para malaikat serta Ruh (malaikat Jibril)',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا اِلَهَ اِلَّا اللَّهُ وَاللَّهُ اَكْبَرُ',
        latin:
            'Subhaanallaahi Wal-Hamdu Lillaahi Wa Laa Ilaaha Illallaahu Wallaahu Akbar',
        arti:
            'Maha Suci Allah, segala puji bagi Allah, tidak ada Tuhan selain Allah, dan Allah Maha Besar',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيْمِ',
        latin: 'Wa Laa Haula Wa Laa Quwwata Illaa Billaahil-\'Aliyyil-\'Azhiim',
        arti:
            'Dan tidak ada daya dan kekuatan kecuali dengan pertolongan Allah Yang Maha Tinggi lagi Maha Agung',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ',
        latin: 'Allaahumma Shalli \'Alaa Sayyidinaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin: 'Allaahumma Shalli \'Alaa Sayyidinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَنَبِيِّنَا وَحَبِيْبِنَا وَشَفِيْعِنَا وَذُخْرِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin:
            'Allaahumma Shalli \'Alaa Sayyidinaa Wa Nabiyyinaa Wa Habiibinaa Wa Syafii\'inaa Wa Dzukhrinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami, nabi kami, kekasih kami, pemberi syafaat kami, simpanan (pembela) kami, dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيْمِ',
        latin: 'Bismillaahir-Rahmaanir-Rahiim',
        arti:
            'Dengan menyebut nama Allah Yang Maha Pengasih lagi Maha Penyayang',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'اَللَّهُمَّ اجْعَلْنَا يَا مَوْلَانَا فِيْ شَهْرِنَا هَذَا وَفِيْ لَيْلَتِنَا هَذِهِ مِنْ عُتَقَائِكَ مِنَ النَّارِ أَجْمَعِيْنَ',
        latin:
            'Allaahummaj\'alnaa Yaa Maulaanaa Fii Syahrinaa Haadzaa Wa Fii Lailatinaa Haadzihii Min \'Utaqaa-ika Minan-Naari Ajma\'iin',
        arti:
            'Ya Allah, wahai Tuhan kami, jadikanlah kami semua pada bulan ini dan malam ini termasuk orang-orang yang Engkau bebaskan dari neraka',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِيْنَ',
        latin: 'Walhamdu Lillaahi Rabbil-\'Aalamiin',
        arti: 'Dan segala puji bagi Allah, Tuhan semesta alam',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَلْخَلِيْفَةُ الثَّانِيَةُ أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا عُمَرُ بْنُ الْخَطَّابِ',
        latin:
            'Al-Khaliifatuts-Tsaaniyatu Amiirul-Mu\'miniina Sayyidunaa \'Umarubnul-Khaththaab',
        arti:
            'Khalifah kedua, Amirul Mu\'minin, junjungan kita Umar bin Khaththab',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'صَلَاةَ التَّرَاوِيْحِ رَحِمَكُمُ اللَّهُ',
        latin: 'Shalaatat-Taraawiihi Rahimakumullaah',
        arti: '(Kerjakanlah) sholat tarawih, semoga Allah merahmati kalian',
      ),
    ],
  ),
  BilalSection(
    title: 'Sebelum Rakaat ke - 7&8',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'فَضْلًا مِنَ اللَّهِ وَنِعْمَةً وَمَغْفِرَةً وَرَحْمَةً',
        latin: 'Fadhlan Minallaahi Wa Ni\'matan Wa Maghfiratan Wa Rahmah',
        arti:
            '(Semoga) karunia, nikmat, ampunan, dan rahmat dari Allah dilimpahkan kepada kita',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'لَا اِلَهَ اِلَّا اللَّهُ وَحْدَهُ لَا شَرِيْكَ لَهُ',
        latin: 'Laa Ilaaha Illallaahu Wahdahuu Laa Syariika Lah',
        arti:
            'Tidak ada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu bagi-Nya',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيِيْ وَيُمِيْتُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرٌ',
        latin:
            'Lahul-Mulku Wa Lahul-Hamdu Yuhyii Wa Yumiitu Wa Huwa \'Alaa Kulli Syai-in Qadiir',
        arti:
            'Milik-Nya segala kerajaan dan milik-Nya segala puji. Dia menghidupkan dan mematikan, dan Dia Maha Kuasa atas segala sesuatu',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَنَبِيِّنَا وَحَبِيْبِنَا وَشَفِيْعِنَا وَذُخْرِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin:
            'Allaahumma Shalli \'Alaa Sayyidinaa Wa Nabiyyinaa Wa Habiibinaa Wa Syafii\'inaa Wa Dzukhrinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami, nabi kami, kekasih kami, pemberi syafaat kami, simpanan (pembela) kami, dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَلْخَلِيْفَةُ الثَّالِثَةُ أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا عُثْمَانُ بْنُ عَفَّانَ',
        latin:
            'Al-Khaliifatuts-Tsaalitsatu Amiirul-Mu\'miniina Sayyidunaa \'Utsmaanubnu \'Affaan',
        arti:
            'Khalifah ketiga, Amirul Mu\'minin, junjungan kita Utsman bin Affan',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'صَلَاةَ التَّرَاوِيْحِ رَحِمَكُمُ اللَّهُ',
        latin: 'Shalaatat-Taraawiihi Rahimakumullaah',
        arti: '(Kerjakanlah) sholat tarawih, semoga Allah merahmati kalian',
      ),
    ],
  ),
  BilalSection(
    title: 'Sebelum Shalat Witir Rakaat ke - 1&2',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْمَعْبُوْدِ',
        latin: 'Subhaanal-malikil-ma’buud',
        arti: 'Maha Suci Allah Yang Merajai (alam) lagi Yang Disembah',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْمَوْجُوْدِ',
        latin: 'Subhaanal-malikil-maujuud',
        arti: 'Maha Suci Allah Yang Merajai (alam) lagi Maha Ada',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لَا يَنَامُ وَلَا يَمُوْتُ وَلَا يَفُوْتُ اَبَدًا',
        latin:
            'Subhaanal-Malikil-Hayyil-Ladzi Laa Yanaamu Wa Laa Yamuutu Walaa Yafuutu Abadan',
        arti:
            'Maha Suci Allah Yang Merajai lagi Maha Hidup, Yang tidak tidur, tidak mati, dan tidak lenyap selama-lamanya',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبُّوْحٌ قُدُّوْسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوْحِ',
        latin: 'Subbuuhun Qudduusun Rabbunaa Wa Rabbul-Malaa-ikati War-Ruuh',
        arti:
            'Maha Suci lagi Maha Kudus, Tuhan kami dan Tuhan para malaikat serta Ruh (malaikat Jibril)',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا اِلَهَ اِلَّا اللَّهُ وَاللَّهُ اَكْبَرُ',
        latin:
            'Subhaanallaahi Wal-Hamdu Lillaahi Wa Laa Ilaaha Illallaahu Wallaahu Akbar',
        arti:
            'Maha Suci Allah, segala puji bagi Allah, tidak ada Tuhan selain Allah, dan Allah Maha Besar',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيْمِ',
        latin: 'Wa Laa Haula Wa Laa Quwwata Illaa Billaahil-\'Aliyyil-\'Azhiim',
        arti:
            'Dan tidak ada daya dan kekuatan kecuali dengan pertolongan Allah Yang Maha Tinggi lagi Maha Agung',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ',
        latin: 'Allaahumma Shalli \'Alaa Sayyidinaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin: 'Allaahumma Shalli \'Alaa Sayyidinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَنَبِيِّنَا وَحَبِيْبِنَا وَشَفِيْعِنَا وَذُخْرِنَا وَمَوْلَانَا مُحَمَّدٍ',
        latin:
            'Allaahumma Shalli \'Alaa Sayyidinaa Wa Nabiyyinaa Wa Habiibinaa Wa Syafii\'inaa Wa Dzukhrinaa Wa Maulaanaa Muhammad',
        arti:
            'Ya Allah, limpahkanlah rahmat kepada junjungan kami, nabi kami, kekasih kami, pemberi syafaat kami, simpanan (pembela) kami, dan pemimpin kami Nabi Muhammad',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيْمِ',
        latin: 'Bismillaahir-Rahmaanir-Rahiim',
        arti:
            'Dengan menyebut nama Allah Yang Maha Pengasih lagi Maha Penyayang',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'شَهْرُ رَمَضَانَ الَّذِي أُنْزِلَ فِيهِ الْقُرْآنُ هُدًى لِلنَّاسِ وَبَيِّنَاتٍ مِنَ الْهُدَىٰ وَالْفُرْقَانِ',
        latin:
            'Syahru Ramadhaanal-ladzii Unzila Fiihil-Qur-aanu Hudal Linnaasi Wa Bayyinaatim Minal-Hudaa Wal-Furqaan',
        arti:
            'Bulan Ramadhan adalah (bulan) yang di dalamnya diturunkan Al-Qur\'an sebagai petunjuk bagi manusia dan penjelasan-penjelasan mengenai petunjuk itu serta pembeda (antara yang benar dan yang batil). (QS. Al-Baqarah: 185)',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'بِجُوْدِكَ آمِيْنَ وَبِامْتِنَانِكَ آمِيْنَ يَا خَيْرَ الْمَسْئُوْلِيْنَ يَا اَللَّهُ',
        latin:
            'Bijuudika Aamiin, Wa Bimtinaanika Aamiin, Yaa Khairal-Mas-uuliin, Yaa Allaah',
        arti:
            'Dengan kemurahan-Mu, kabulkanlah. Dengan karunia-Mu, kabulkanlah. Wahai sebaik-baik Dzat yang dimintai, ya Allah',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'اَللَّهُمَّ أَعْتِقْ رِقَابَنَا وَرِقَابَ آبَائِنَا وَأُمَّهَاتِنَا وَأَوْلَادِنَا وَإِخْوَانِنَا وَالْمُسْلِمِيْنَ وَالْمُسْلِمَاتِ مِنَ النَّارِ أَجْمَعِيْنَ',
        latin:
            'Allaahumma A\'tiq Riqaabanaa Wa Riqaaba Aabaa-inaa Wa Ummahaatinaa Wa Aulaadinaa Wa Ikhwaaninaa Wal-Muslimiina Wal-Muslimaati Minan-Naari Ajma\'iin',
        arti:
            'Ya Allah, bebaskanlah diri kami, diri bapak-bapak kami, ibu-ibu kami, anak-anak kami, saudara-saudara kami, serta kaum muslimin dan muslimat dari neraka semuanya',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'اَللَّهُمَّ اغْفِرْ لَنَا بِكَرَمِكَ أَجْمَعِيْنَ وَتُبْ وَزَكِّ وَاعْفُ عَمَّنْ يَقُوْلُ آمِيْنَ آمِيْنَ وَصَلَّى اللَّهُ وَسَلَّمَ عَلَيْهِ',
        latin:
            'Allaahummaghfir Lanaa Bikaramika Ajma\'iin, Wa Tub Wa Zakki Wa\'fu \'Amman Yaquulu Aamiin Aamiin, Wa Shallallaahu Wa Sallama \'Alaih',
        arti:
            'Ya Allah, ampunilah kami semua dengan kemurahan-Mu, terimalah taubat, sucikanlah, dan maafkanlah orang yang mengucapkan aamiin, aamiin. Semoga Allah melimpahkan shalawat dan salam kepadanya (Nabi Muhammad)',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِيْنَ',
        latin: 'Walhamdu Lillaahi Rabbil-\'Aalamiin',
        arti: 'Dan segala puji bagi Allah, Tuhan semesta alam',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَلْخَلِيْفَةُ الرَّابِعَةُ أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا عَلِيُّ بْنُ أَبِيْ طَالِبٍ',
        latin:
            'Al-Khaliifatur-Raabi\'atu Amiirul-Mu\'miniina Sayyidunaa \'Aliyyubnu Abii Thaalib',
        arti:
            'Khalifah keempat, Amirul Mu\'minin, junjungan kita Ali bin Abi Thalib',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'رَضِيَ اللَّهُ عَنْهُ، وَعَنْ كُلِّ صَحَابَةِ رَسُوْلِ اللَّهِ أَجْمَعِيْنَ',
        latin:
            'Radhiyallaahu \'Anhu, Wa \'An Kulli Shahaabati Rasuulillaahi Ajma\'iin',
        arti:
            'Semoga Allah meridhainya dan meridhai seluruh sahabat Rasulullah',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'صَلَاةَ الْوِتْرِ أَثَابَكُمُ اللَّهُ',
        latin: 'Shalaatal-Witri Atsaabakumullaah',
        arti:
            '(Kerjakanlah) sholat witir, semoga Allah memberi pahala kepada kalian',
      ),
    ],
  ),
  BilalSection(
    title: 'Sebelum Shalat Witir Rakaat ke - 3',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'صَلَاةَ الْوِتْرِ رَكْعَةً رَحِمَكُمُ اللَّهُ',
        latin: 'Shalaatal-Witri Rak\'atan Rahimakumullaah',
        arti:
            '(Kerjakanlah) sholat witir satu rakaat, semoga Allah merahmati kalian',
      ),
    ],
  ),
  BilalSection(
    title: 'Dzikir & Do\'a',
    items: [
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْقُدُّوْسِ',
        latin: 'Subhaanal-Malikil-Qudduus',
        arti: 'Maha Suci Allah, Raja Yang Maha Suci',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْقُدُّوْسِ',
        latin: 'Subhaanal-Malikil-Qudduus',
        arti: 'Maha Suci Allah, Raja Yang Maha Suci',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'سُبْحَانَ الْمَلِكِ الْقُدُّوْسِ',
        latin: 'Subhaanal-Malikil-Qudduus',
        arti: 'Maha Suci Allah, Raja Yang Maha Suci',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبُّوْحٌ قُدُّوْسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوْحِ',
        latin: 'Subbuuhun Qudduusun Rabbunaa Wa Rabbul-Malaa-ikati War-Ruuh',
        arti:
            'Maha Suci lagi Maha Kudus, Tuhan kami dan Tuhan para malaikat serta Ruh (malaikat Jibril)',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا اِلَهَ اِلَّا اللَّهُ وَاللَّهُ اَكْبَرُ',
        latin:
            'Subhaanallaahi Wal-Hamdu Lillaahi Wa Laa Ilaaha Illallaahu Wallaahu Akbar',
        arti:
            'Maha Suci Allah, segala puji bagi Allah, tidak ada Tuhan selain Allah, dan Allah Maha Besar',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيْمِ',
        latin: 'Wa Laa Haula Wa Laa Quwwata Illaa Billaahil-\'Aliyyil-\'Azhiim',
        arti:
            'Dan tidak ada daya dan kekuatan kecuali dengan pertolongan Allah Yang Maha Tinggi lagi Maha Agung',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيْمِ',
        latin: 'Bismillaahir-Rahmaanir-Rahiim',
        arti:
            'Dengan menyebut nama Allah Yang Maha Pengasih lagi Maha Penyayang',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'رَبَّنَا آمَنَّا بِمَا أَنْزَلْتَ وَاتَّبَعْنَا الرَّسُوْلَ فَاكْتُبْنَا مَعَ الشَّاهِدِيْنَ',
        latin:
            'Rabbanaa Aamannaa Bimaa Anzalta Wattaba\'nar-Rasuula Faktubnaa Ma\'asy-Syaahidiin',
        arti:
            'Ya Tuhan kami, kami telah beriman kepada apa yang Engkau turunkan dan kami telah mengikuti Rasul, maka catatlah kami bersama orang-orang yang bersaksi. (QS. Ali \'Imran: 53)',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'اَللَّهُمَّ يَا مُجِيْبَ السَّائِلِيْنَ، وَيَا قَابِلَ التَّائِبِيْنَ',
        latin: 'Allaahumma Yaa Mujiibas-Saa-iliin, Wa Yaa Qaabilat-Taa-ibiin',
        arti:
            'Ya Allah, wahai Dzat yang mengabulkan permintaan orang-orang yang meminta, wahai Dzat yang menerima taubat orang-orang yang bertaubat',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'وَيَا رَاحِمَ الضُّعَفَاءِ وَالْفُقَرَاءِ وَالْمَسَاكِيْنِ',
        latin: 'Wa Yaa Raahimadh-Dhu\'afaa-i Wal-Fuqaraa-i Wal-Masaakiin',
        arti:
            'Dan wahai Dzat yang mengasihi orang-orang lemah, fakir, dan miskin',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic:
            'اَللَّهُمَّ اغْفِرْ لَنَا بِكَرَمِكَ أَجْمَعِيْنَ وَتُبْ وَزَكِّ وَاعْفُ عَمَّنْ يَقُوْلُ آمِيْنَ آمِيْنَ وَصَلَّى اللَّهُ وَسَلَّمَ عَلَيْهِ',
        latin:
            'Allaahummaghfir Lanaa Bikaramika Ajma\'iin, Wa Tub Wa Zakki Wa\'fu \'Amman Yaquulu Aamiin Aamiin, Wa Shallallaahu Wa Sallama \'Alaih',
        arti:
            'Ya Allah, ampunilah kami semua dengan kemurahan-Mu, terimalah taubat, sucikanlah, dan maafkanlah orang yang mengucapkan aamiin, aamiin. Semoga Allah melimpahkan shalawat dan salam kepadanya (Nabi Muhammad)',
      ),
      BilalItem(
        kind: BilalKind.doa,
        arabic: 'وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِيْنَ',
        latin: 'Walhamdu Lillaahi Rabbil-\'Aalamiin',
        arti: 'Dan segala puji bagi Allah, Tuhan semesta alam',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'أَشْهَدُ أَنْ لَا اِلَهَ اِلَّا اللَّهُ، أَسْتَغْفِرُ اللَّهَ، نَسْأَلُكَ الْجَنَّةَ وَنَعُوْذُ بِكَ مِنَ النَّارِ',
        latin:
            'Asyhadu Allaa Ilaaha Illallaah, Astaghfirullaah, Nas-alukal Jannata Wa Na\'uudzu Bika Minan-Naar',
        arti:
            'Aku bersaksi bahwa tidak ada Tuhan selain Allah, aku memohon ampun kepada Allah. Kami memohon surga kepada-Mu dan berlindung kepada-Mu dari neraka',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'أَشْهَدُ أَنْ لَا اِلَهَ اِلَّا اللَّهُ، أَسْتَغْفِرُ اللَّهَ، نَسْأَلُكَ الْجَنَّةَ وَنَعُوْذُ بِكَ مِنَ النَّارِ',
        latin:
            'Asyhadu Allaa Ilaaha Illallaah, Astaghfirullaah, Nas-alukal Jannata Wa Na\'uudzu Bika Minan-Naar',
        arti:
            'Aku bersaksi bahwa tidak ada Tuhan selain Allah, aku memohon ampun kepada Allah. Kami memohon surga kepada-Mu dan berlindung kepada-Mu dari neraka',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'أَشْهَدُ أَنْ لَا اِلَهَ اِلَّا اللَّهُ، أَسْتَغْفِرُ اللَّهَ، نَسْأَلُكَ الْجَنَّةَ وَنَعُوْذُ بِكَ مِنْ سَخَطِكَ وَالنَّارِ',
        latin:
            'Asyhadu Allaa Ilaaha Illallaah, Astaghfirullaah, Nas-alukal Jannata Wa Na\'uudzu Bika Min Sakhathika Wan-Naar',
        arti:
            'Aku bersaksi bahwa tidak ada Tuhan selain Allah, aku memohon ampun kepada Allah. Kami memohon surga kepada-Mu dan berlindung kepada-Mu dari murka-Mu dan dari neraka',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ اِنَّكَ عَفُوٌّ كَرِيْمٌ، تُحِبُّ الْعَفْوَ فَاعْفُ عَنَّا',
        latin:
            'Allaahumma Innaka \'Afuwwun Kariim, Tuhibbul-\'Afwa Fa\'fu \'Annaa',
        arti:
            'Ya Allah, sesungguhnya Engkau Maha Pemaaf lagi Maha Mulia, Engkau suka memaafkan, maka maafkanlah kami',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ اِنَّكَ عَفُوٌّ كَرِيْمٌ، تُحِبُّ الْعَفْوَ فَاعْفُ عَنَّا',
        latin:
            'Allaahumma Innaka \'Afuwwun Kariim, Tuhibbul-\'Afwa Fa\'fu \'Annaa',
        arti:
            'Ya Allah, sesungguhnya Engkau Maha Pemaaf lagi Maha Mulia, Engkau suka memaafkan, maka maafkanlah kami',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic:
            'اَللَّهُمَّ اِنَّكَ عَفُوٌّ كَرِيْمٌ، تُحِبُّ الْعَفْوَ فَاعْفُ عَنَّا يَا كَرِيْمُ',
        latin:
            'Allaahumma Innaka \'Afuwwun Kariim, Tuhibbul-\'Afwa Fa\'fu \'Annaa Yaa Kariim',
        arti:
            'Ya Allah, sesungguhnya Engkau Maha Pemaaf lagi Maha Mulia, Engkau suka memaafkan, maka maafkanlah kami, wahai Dzat Yang Maha Mulia',
      ),
      BilalItem(
        kind: BilalKind.seruan,
        arabic: 'اِنْوُوا الصِّيَامَ رَحِمَكُمُ اللَّهُ',
        latin: 'Inwush-Shiyaama Rahimakumullaah',
        arti: 'Berniatlah kalian untuk berpuasa, semoga Allah merahmati kalian',
      ),
      BilalItem(
        kind: BilalKind.niat,
        arabic:
            'نَوَيْتُ صَوْمَ غَدٍ عَنْ اَدَاءِ فَرْضِ شَهْرِ رَمَضَانَ هَذِهِ السَّنَةِ لِلَّهِ تَعَالَى',
        latin:
            'Nawaitu Shauma Ghadin \'An Adaa-i Fardhi Syahri Ramadhaana Haadzihis-Sanati Lillaahi Ta\'aalaa',
        arti:
            'Aku berniat puasa esok hari untuk menunaikan kewajiban bulan Ramadhan tahun ini karena Allah Ta\'ala',
      ),
      BilalItem(
        kind: BilalKind.dzikir,
        arabic: 'اَفْضَلُ الذِّكْرِ فَاعْلَمْ اَنَّهُ',
        latin: 'Afdlaludz dzikri fa’lam annahuu',
        arti: 'Ketahuilah bahwa dzikir yang paling utama adalah',
      ),
      BilalItem(
        kind: BilalKind.dzikir,
        arabic: 'لَا اِلَهَ اِلَّا اللَّهُ (حَيٌّ مَوْجُوْدٌ)',
        latin: 'Laa ilaaha illaallaahu (hayyum maujuud)',
        arti: 'Tidak ada Tuhan selain Allah (Maha Hidup lagi Ada)',
      ),
      BilalItem(
        kind: BilalKind.dzikir,
        arabic: 'لَا اِلَهَ اِلَّا اللَّهُ (حَيٌّ مَعْبُوْدٌ)',
        latin: 'Laa ilaaha illaallaahu (hayyum ma’buud)',
        arti: 'Tidak ada Tuhan selain Allah (Maha Hidup lagi Disembah)',
      ),
      BilalItem(
        kind: BilalKind.dzikir,
        arabic: 'لَا اِلَهَ اِلَّا اللَّهُ (حَيٌّ بَاقٍ)',
        latin: 'Laa ilaaha illaallaahu (hayyum baaqin)',
        arti: 'Tidak ada Tuhan selain Allah (Maha Hidup lagi Kekal)',
      ),
      BilalItem(
        kind: BilalKind.dzikir,
        arabic: 'لَا اِلَهَ اِلَّا اللَّهُ (33×)',
        latin: 'Laa ilaaha illaallaahu 33x',
        arti: 'Tidak ada Tuhan selain Allah 33x',
      ),
      BilalItem(
        kind: BilalKind.dzikir,
        arabic:
            'لَا اِلَهَ اِلَّا اللَّهُ مُحَمَّدٌ رَسُوْلُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، كَلِمَةُ حَقٍّ عَلَيْهَا نَحْيَا وَعَلَيْهَا نَمُوْتُ وَبِهَا نُبْعَثُ اِنْ شَاءَ اللَّهُ مِنَ الْآمِنِيْنَ',
        latin:
            'Laa Ilaaha Illallaahu Muhammadur-Rasuulullaahi Shallallaahu \'Alaihi Wa Sallam, Kalimatu Haqqin \'Alaihaa Nahyaa Wa \'Alaihaa Namuutu Wa Bihaa Nub\'atsu Insyaa-allaahu Minal-Aaminiin',
        arti:
            'Tidak ada Tuhan selain Allah, Muhammad utusan Allah, semoga Allah melimpahkan shalawat dan salam kepadanya. (Itulah) kalimat yang benar; di atasnya kami hidup, di atasnya kami mati, dan dengannya kami dibangkitkan, insya Allah termasuk orang-orang yang aman',
      ),
    ],
  ),
];
