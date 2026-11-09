// DIBUAT OTOMATIS oleh tool/gen_dzikir_sholat.py - jangan diedit langsung.
//
// Dzikir & doa setelah sholat wajib: urutan bacaan yang lazim di masjid
// Indonesia, doa yang sering dibaca imam, dan dzikir sunnah Hisnul Muslim.
// Ayat Al-Qur'an dari Mushaf Standar Indonesia (assets/quran/quran.json).
// Latin & terjemahan bersifat bantuan.

import '../services/dzikir.dart';

const dzikirSholatList = <Dzikir>[
  Dzikir(
    id: 101,
    title: 'Istighfar',
    repeat: 3,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic:
        'أَسْتَغْفِرُ اللّٰهَ الْعَظِيْمَ الَّذِيْ لَا إِلٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّوْمُ وَأَتُوْبُ إِلَيْهِ',
    latin:
        'Astaghfirullaahal \'azhiim, alladzii laa ilaaha illaa huwal hayyul qayyuumu wa atuubu ilaih.',
    arti:
        'Aku memohon ampun kepada Allah Yang Mahaagung, yang tiada tuhan selain Dia, Yang Mahahidup lagi terus-menerus mengurus (makhluk-Nya), dan aku bertobat kepada-Nya.',
    note:
        'Dibaca segera setelah salam. Nabi ﷺ beristighfar tiga kali setiap selesai sholat.',
    source:
        'Istighfar 3× setelah salam: HR. Muslim no. 591. Lafaz ini: HR. Abu Daud no. 1517 & At-Tirmidzi no. 3577',
  ),
  Dzikir(
    id: 102,
    title: 'Tahlil',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِيْ وَيُمِيْتُ، وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu, yuhyii wa yumiit, wa huwa \'alaa kulli syai-in qadiir.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan pujian, Dia menghidupkan dan mematikan, dan Dia Mahakuasa atas segala sesuatu.',
    note: 'Setelah Subuh & Maghrib dianjurkan 10×.',
    source: 'HR. At-Tirmidzi no. 3474 (hasan)',
  ),
  Dzikir(
    id: 103,
    title: 'Mohon perlindungan dari neraka',
    repeat: 3,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic: 'اَللّٰهُمَّ أَجِرْنِيْ مِنَ النَّارِ',
    latin: 'Allaahumma ajirnii minan naar.',
    arti: 'Ya Allah, lindungilah aku dari api neraka.',
    note:
        'Riwayatnya menyebut 7× setelah Subuh & Maghrib; di masjid umumnya dibaca 3×.',
    source: 'HR. Abu Daud no. 5079 (sanadnya diperselisihkan)',
  ),
  Dzikir(
    id: 104,
    title: 'Allaahumma antas salaam',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic:
        'اَللّٰهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، وَإِلَيْكَ يَعُوْدُ السَّلَامُ، فَحَيِّنَا رَبَّنَا بِالسَّلَامِ، وَأَدْخِلْنَا الْجَنَّةَ دَارَ السَّلَامِ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    latin:
        'Allaahumma antas salaam, wa minkas salaam, wa ilaika ya\'uudus salaam, fahayyinaa rabbanaa bis salaam, wa adkhilnal jannata daaras salaam, tabaarakta rabbanaa wa ta\'aalaita yaa dzal jalaali wal ikraam.',
    arti:
        'Ya Allah, Engkaulah As-Salaam (Yang Maha Sejahtera), dari-Mu segala kesejahteraan, dan kepada-Mu kembali segala kesejahteraan. Hidupkanlah kami, ya Tuhan kami, dengan sejahtera, dan masukkanlah kami ke surga, negeri kesejahteraan. Mahaberkah Engkau, ya Tuhan kami, dan Mahatinggi, wahai Pemilik keagungan dan kemuliaan.',
    note:
        'Inti doa (Allaahumma antas salaam wa minkas salaam, tabaarakta yaa dzal jalaali wal ikraam) dari hadits; kalimat di antaranya adalah tambahan yang masyhur dibaca.',
    source: 'Inti doa: HR. Muslim no. 591',
  ),
  Dzikir(
    id: 105,
    title: 'Al-Fatihah',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic:
        '﴿بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ۝ اَلْحَمْدُ لِلّٰهِ رَبِّ الْعٰلَمِيْنَۙ ۝ الرَّحْمٰنِ الرَّحِيْمِۙ ۝ مٰلِكِ يَوْمِ الدِّيْنِۗ ۝ اِيَّاكَ نَعْبُدُ وَاِيَّاكَ نَسْتَعِيْنُۗ ۝ اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيْمَ ۙ ۝ صِرَاطَ الَّذِيْنَ اَنْعَمْتَ عَلَيْهِمْ ەۙ غَيْرِ الْمَغْضُوْبِ عَلَيْهِمْ وَلَا الضَّاۤلِّيْنَ ࣖ﴾',
    latin:
        'Bismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil \'aalamiin. Ar-rahmaanir rahiim. Maaliki yaumid diin. Iyyaaka na\'budu wa iyyaaka nasta\'iin. Ihdinash shiraathal mustaqiim. Shiraathal ladziina an\'amta \'alaihim ghairil maghdhuubi \'alaihim wa ladh-dhaalliin.',
    arti:
        'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Segala puji bagi Allah, Tuhan seluruh alam, Yang Maha Pengasih, Maha Penyayang, Pemilik hari pembalasan. Hanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami mohon pertolongan. Tunjukilah kami jalan yang lurus, (yaitu) jalan orang-orang yang telah Engkau beri nikmat kepadanya; bukan (jalan) mereka yang dimurkai, dan bukan (pula jalan) mereka yang sesat.',
    note: 'Dibaca sebelum Ayat Kursi, sebagaimana kebiasaan di masjid.',
    source:
        'Bacaan yang lazim dibaca imam di masjid-masjid Indonesia (QS. Al-Fatihah: 1-7)',
  ),
  Dzikir(
    id: 106,
    title: 'Ayat Kursi',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic:
        'أَعُوْذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيْمِ ﴿اَللّٰهُ لَآ اِلٰهَ اِلَّا هُوَۚ اَلْحَيُّ الْقَيُّوْمُ ەۚ لَا تَأْخُذُهٗ سِنَةٌ وَّلَا نَوْمٌۗ لَهٗ مَا فِى السَّمٰوٰتِ وَمَا فِى الْاَرْضِۗ مَنْ ذَا الَّذِيْ يَشْفَعُ عِنْدَهٗٓ اِلَّا بِاِذْنِهٖۗ يَعْلَمُ مَا بَيْنَ اَيْدِيْهِمْ وَمَا خَلْفَهُمْۚ وَلَا يُحِيْطُوْنَ بِشَيْءٍ مِّنْ عِلْمِهٖٓ اِلَّا بِمَا شَاۤءَۚ وَسِعَ كُرْسِيُّهُ السَّمٰوٰتِ وَالْاَرْضَۚ وَلَا يَـُٔوْدُهٗ حِفْظُهُمَاۚ وَهُوَ الْعَلِيُّ الْعَظِيْمُ﴾',
    latin:
        'A\'uudzu billaahi minasy syaithaanir rajiim. Allaahu laa ilaaha illaa huwal hayyul qayyuum, laa ta\'khudzuhuu sinatuw wa laa naum, lahuu maa fis samaawaati wa maa fil ardh, man dzal ladzii yasyfa\'u \'indahuu illaa bi-idznih, ya\'lamu maa baina aidiihim wa maa khalfahum, wa laa yuhiithuuna bisyai-im min \'ilmihii illaa bimaa syaa\', wasi\'a kursiyyuhus samaawaati wal ardh, wa laa ya-uuduhuu hifzhuhumaa, wa huwal \'aliyyul \'azhiim.',
    arti:
        'Allah, tidak ada tuhan selain Dia. Yang Mahahidup, Yang terus menerus mengurus (makhluk-Nya), tidak mengantuk dan tidak tidur. Milik-Nya apa yang ada di langit dan apa yang ada di bumi. Tidak ada yang dapat memberi syafaat di sisi-Nya tanpa izin-Nya. Dia mengetahui apa yang di hadapan mereka dan apa yang di belakang mereka, dan mereka tidak mengetahui sesuatu apa pun tentang ilmu-Nya melainkan apa yang Dia kehendaki. Kursi-Nya meliputi langit dan bumi. Dan Dia tidak merasa berat memelihara keduanya, dan Dia Mahatinggi, Mahabesar.',
    note: 'Tidak ada yang menghalanginya masuk surga kecuali kematian.',
    source: 'HR. An-Nasa\'i (As-Sunan Al-Kubra), dishahihkan Al-Albani',
  ),
  Dzikir(
    id: 107,
    title: 'Tasbih',
    repeat: 33,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic: 'سُبْحَانَ اللّٰهِ',
    latin: 'Subhaanallaah',
    arti: 'Mahasuci Allah',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 108,
    title: 'Tahmid',
    repeat: 33,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic: 'اَلْحَمْدُ لِلّٰهِ',
    latin: 'Alhamdulillaah',
    arti: 'Segala puji bagi Allah',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 109,
    title: 'Takbir',
    repeat: 33,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic: 'اَللّٰهُ أَكْبَرُ',
    latin: 'Allaahu akbar',
    arti: 'Allah Mahabesar',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 110,
    title: 'Tahlil penutup (genap 100)',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir',
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'alaa kulli syai-in qadiir.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu.',
    note:
        'Menggenapkan seratus - diampuni kesalahannya walau sebanyak buih di lautan. Di sebagian masjid dilanjutkan dengan laa ilaaha illallaah berulang kali.',
    source: 'HR. Muslim no. 597',
  ),
  Dzikir(
    id: 121,
    title: 'Pembuka doa: hamdalah',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ. اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِيْنَ، حَمْدًا يُوَافِيْ نِعَمَهُ وَيُكَافِئُ مَزِيْدَهُ، يَا رَبَّنَا لَكَ الْحَمْدُ كَمَا يَنْبَغِيْ لِجَلَالِ وَجْهِكَ وَعَظِيْمِ سُلْطَانِكَ',
    latin:
        'Bismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil \'aalamiin, hamdan yuwaafii ni\'amahuu wa yukaafi-u maziidah, yaa rabbanaa lakal hamdu kamaa yambaghii lijalaali wajhika wa \'azhiimi sulthaanik.',
    arti:
        'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Segala puji bagi Allah, Tuhan seluruh alam, pujian yang sebanding dengan nikmat-Nya dan mencukupi tambahan-Nya. Ya Tuhan kami, bagi-Mu segala puji sebagaimana layak bagi keagungan wajah-Mu dan kebesaran kekuasaan-Mu.',
    source: 'Bacaan yang lazim dibaca imam di masjid-masjid Indonesia',
  ),
  Dzikir(
    id: 122,
    title: 'Shalawat',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى آلِ سَيِّدِنَا مُحَمَّدٍ',
    latin:
        'Allaahumma shalli \'alaa sayyidinaa Muhammad, wa \'alaa aali sayyidinaa Muhammad.',
    arti:
        'Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad dan keluarga junjungan kami Nabi Muhammad.',
    note: 'Doa dibuka dengan pujian kepada Allah lalu shalawat.',
    source: 'Perintah bershalawat: QS. Al-Ahzab: 56',
  ),
  Dzikir(
    id: 123,
    title: 'Mohon diterima ibadah',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'اَللّٰهُمَّ رَبَّنَا تَقَبَّلْ مِنَّا صَلَاتَنَا وَصِيَامَنَا وَرُكُوْعَنَا وَسُجُوْدَنَا وَقُعُوْدَنَا وَتَضَرُّعَنَا وَتَخَشُّعَنَا وَتَعَبُّدَنَا، وَتَمِّمْ تَقْصِيْرَنَا يَا اَللّٰهُ يَا رَبَّ الْعَالَمِيْنَ',
    latin:
        'Allaahumma rabbanaa taqabbal minnaa shalaatanaa wa shiyaamanaa wa rukuu\'anaa wa sujuudanaa wa qu\'uudanaa wa tadharru\'anaa wa takhasysyu\'anaa wa ta\'abbudanaa, wa tammim taqshiiranaa yaa Allaah yaa rabbal \'aalamiin.',
    arti:
        'Ya Allah, Tuhan kami, terimalah dari kami sholat kami, puasa kami, rukuk kami, sujud kami, duduk kami, kerendahan hati kami, kekhusyukan kami, dan ibadah kami, serta sempurnakanlah kekurangan kami, ya Allah, wahai Tuhan seluruh alam.',
    source: 'Bacaan yang lazim dibaca imam di masjid-masjid Indonesia',
  ),
  Dzikir(
    id: 124,
    title: 'Rabbanaa zhalamnaa',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'رَبَّنَا ظَلَمْنَآ اَنْفُسَنَا وَاِنْ لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُوْنَنَّ مِنَ الْخٰسِرِيْنَ',
    latin:
        'Rabbanaa zhalamnaa anfusanaa wa illam taghfir lanaa wa tarhamnaa lanakuunanna minal khaasiriin.',
    arti:
        'Ya Tuhan kami, kami telah menzalimi diri kami sendiri. Jika Engkau tidak mengampuni kami dan memberi rahmat kepada kami, niscaya kami termasuk orang-orang yang rugi.',
    source: 'QS. Al-A\'raf: 23',
  ),
  Dzikir(
    id: 125,
    title: 'Rabbanaa wa laa tahmil',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ اِصْرًا كَمَا حَمَلْتَهٗ عَلَى الَّذِيْنَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهٖۚ وَاعْفُ عَنَّاۗ وَاغْفِرْ لَنَاۗ وَارْحَمْنَا ۗ اَنْتَ مَوْلٰىنَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكٰفِرِيْنَ',
    latin:
        'Rabbanaa wa laa tahmil \'alainaa ishran kamaa hamaltahuu \'alalladziina min qablinaa, rabbanaa wa laa tuhammilnaa maa laa thaaqata lanaa bih, wa\'fu \'annaa, waghfir lanaa, warhamnaa, anta maulaanaa fanshurnaa \'alal qaumil kaafiriin.',
    arti:
        'Ya Tuhan kami, janganlah Engkau bebani kami dengan beban yang berat sebagaimana Engkau bebankan kepada orang-orang sebelum kami. Ya Tuhan kami, janganlah Engkau pikulkan kepada kami apa yang tidak sanggup kami memikulnya. Maafkanlah kami, ampunilah kami, dan rahmatilah kami. Engkaulah pelindung kami, maka tolonglah kami menghadapi orang-orang kafir.',
    source: 'QS. Al-Baqarah: 286',
  ),
  Dzikir(
    id: 126,
    title: 'Rabbanaa laa tuzigh quluubanaa',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'رَبَّنَا لَا تُزِغْ قُلُوْبَنَا بَعْدَ اِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَّدُنْكَ رَحْمَةً ۚاِنَّكَ اَنْتَ الْوَهَّابُ',
    latin:
        'Rabbanaa laa tuzigh quluubanaa ba\'da idz hadaitanaa wa hab lanaa min ladunka rahmah, innaka antal wahhaab.',
    arti:
        'Ya Tuhan kami, janganlah Engkau condongkan hati kami kepada kesesatan setelah Engkau berikan petunjuk kepada kami, dan karuniakanlah kepada kami rahmat dari sisi-Mu, sesungguhnya Engkau Maha Pemberi.',
    source: 'QS. Ali \'Imran: 8',
  ),
  Dzikir(
    id: 127,
    title: 'Ampunan untuk orang tua & kaum muslimin',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'رَبَّنَا اغْفِرْ لَنَا وَلِوَالِدِيْنَا وَلِجَمِيْعِ الْمُسْلِمِيْنَ وَالْمُسْلِمَاتِ وَالْمُؤْمِنِيْنَ وَالْمُؤْمِنَاتِ، اَلْأَحْيَاءِ مِنْهُمْ وَالْأَمْوَاتِ، إِنَّكَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ',
    latin:
        'Rabbanaghfir lanaa wa liwaalidiinaa wa lijamii\'il muslimiina wal muslimaat, wal mu\'miniina wal mu\'minaat, al-ahyaa-i minhum wal amwaat, innaka \'alaa kulli syai-in qadiir.',
    arti:
        'Ya Tuhan kami, ampunilah kami, kedua orang tua kami, dan semua muslimin dan muslimat, mukminin dan mukminat, yang masih hidup maupun yang telah wafat. Sesungguhnya Engkau Mahakuasa atas segala sesuatu.',
    note:
        'Senada dengan doa Nabi Ibrahim (QS. Ibrahim: 41) dan Nabi Nuh (QS. Nuh: 28).',
    source: 'Bacaan yang lazim dibaca imam di masjid-masjid Indonesia',
  ),
  Dzikir(
    id: 128,
    title: 'Doa sapu jagat',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'رَبَّنَآ اٰتِنَا فِى الدُّنْيَا حَسَنَةً وَّفِى الْاٰخِرَةِ حَسَنَةً وَّقِنَا عَذَابَ النَّارِ',
    latin:
        'Rabbanaa aatinaa fid dunyaa hasanah, wa fil aakhirati hasanah, wa qinaa \'adzaaban naar.',
    arti:
        'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat, dan lindungilah kami dari azab neraka.',
    note: 'Doa yang paling sering dibaca Nabi ﷺ.',
    source: 'QS. Al-Baqarah: 201; HR. Bukhari no. 6389 & Muslim no. 2690',
  ),
  Dzikir(
    id: 129,
    title: 'Mohon ampunan & husnul khatimah',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'اَللّٰهُمَّ اغْفِرْ لَنَا ذُنُوْبَنَا، وَكَفِّرْ عَنَّا سَيِّئَاتِنَا، وَتَوَفَّنَا مَعَ الْأَبْرَارِ',
    latin:
        'Allaahummaghfir lanaa dzunuubanaa, wa kaffir \'annaa sayyi-aatinaa, wa tawaffanaa ma\'al abraar.',
    arti:
        'Ya Allah, ampunilah dosa-dosa kami, hapuskanlah kesalahan-kesalahan kami, dan wafatkanlah kami bersama orang-orang yang berbakti.',
    source: 'Diambil dari QS. Ali \'Imran: 193',
  ),
  Dzikir(
    id: 130,
    title: 'Penutup: Subhaana rabbika',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa setelah sholat',
    arabic:
        'سُبْحٰنَ رَبِّكَ رَبِّ الْعِزَّةِ عَمَّا يَصِفُوْنَۚ وَسَلٰمٌ عَلَى الْمُرْسَلِيْنَۚ وَالْحَمْدُ لِلّٰهِ رَبِّ الْعٰلَمِيْنَ',
    latin:
        'Subhaana rabbika rabbil \'izzati \'ammaa yashifuun, wa salaamun \'alal mursaliin, wal hamdu lillaahi rabbil \'aalamiin.',
    arti:
        'Mahasuci Tuhanmu, Tuhan Yang Mahaperkasa dari sifat yang mereka katakan. Dan selamat sejahtera bagi para rasul. Dan segala puji bagi Allah Tuhan seluruh alam.',
    source: 'QS. Ash-Shaffat: 180-182',
  ),
  Dzikir(
    id: 141,
    title: 'Doa keselamatan',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'اَللّٰهُمَّ إِنَّا نَسْأَلُكَ سَلَامَةً فِي الدِّيْنِ، وَعَافِيَةً فِي الْجَسَدِ، وَزِيَادَةً فِي الْعِلْمِ، وَبَرَكَةً فِي الرِّزْقِ، وَتَوْبَةً قَبْلَ الْمَوْتِ، وَرَحْمَةً عِنْدَ الْمَوْتِ، وَمَغْفِرَةً بَعْدَ الْمَوْتِ. اَللّٰهُمَّ هَوِّنْ عَلَيْنَا فِيْ سَكَرَاتِ الْمَوْتِ، وَالنَّجَاةَ مِنَ النَّارِ، وَالْعَفْوَ عِنْدَ الْحِسَابِ',
    latin:
        'Allaahumma innaa nas-aluka salaamatan fid diin, wa \'aafiyatan fil jasad, wa ziyaadatan fil \'ilm, wa barakatan fir rizq, wa taubatan qablal maut, wa rahmatan \'indal maut, wa maghfiratan ba\'dal maut. Allaahumma hawwin \'alainaa fii sakaraatil maut, wan najaata minan naar, wal \'afwa \'indal hisaab.',
    arti:
        'Ya Allah, kami memohon kepada-Mu keselamatan dalam agama, kesehatan badan, tambahan ilmu, keberkahan rezeki, tobat sebelum mati, rahmat ketika mati, dan ampunan sesudah mati. Ya Allah, mudahkanlah kami dalam sakaratul maut, (berilah) keselamatan dari neraka dan ampunan ketika hisab.',
    optional: true,
    source: 'Bacaan yang lazim dibaca imam di masjid-masjid Indonesia',
  ),
  Dzikir(
    id: 142,
    title: 'Petunjuk, takwa, iffah & kecukupan',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ الْهُدٰى وَالتُّقٰى وَالْعَفَافَ وَالْغِنٰى',
    latin:
        'Allaahumma innii as-alukal hudaa wat tuqaa wal \'afaafa wal ghinaa.',
    arti:
        'Ya Allah, aku memohon kepada-Mu petunjuk, ketakwaan, terjaganya diri (dari yang haram), dan kecukupan.',
    optional: true,
    source: 'HR. Muslim no. 2721',
  ),
  Dzikir(
    id: 143,
    title: 'Perbaikan agama, dunia & akhirat',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'اَللّٰهُمَّ أَصْلِحْ لِيْ دِيْنِيَ الَّذِيْ هُوَ عِصْمَةُ أَمْرِيْ، وَأَصْلِحْ لِيْ دُنْيَايَ الَّتِيْ فِيْهَا مَعَاشِيْ، وَأَصْلِحْ لِيْ آخِرَتِي الَّتِيْ فِيْهَا مَعَادِيْ، وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِيْ فِيْ كُلِّ خَيْرٍ، وَاجْعَلِ الْمَوْتَ رَاحَةً لِيْ مِنْ كُلِّ شَرٍّ',
    latin:
        'Allaahumma ashlih lii diiniyalladzii huwa \'ishmatu amrii, wa ashlih lii dunyaayallatii fiihaa ma\'aasyii, wa ashlih lii aakhiratiyallatii fiihaa ma\'aadii, waj\'alil hayaata ziyaadatan lii fii kulli khair, waj\'alil mauta raahatan lii min kulli syarr.',
    arti:
        'Ya Allah, perbaikilah agamaku yang menjadi penjaga urusanku, perbaikilah duniaku tempat hidupku, dan perbaikilah akhiratku tempat kembaliku. Jadikanlah hidup ini tambahan bagiku dalam setiap kebaikan, dan jadikanlah kematian sebagai istirahat bagiku dari setiap keburukan.',
    optional: true,
    source: 'HR. Muslim no. 2720',
  ),
  Dzikir(
    id: 144,
    title: 'Ya muqallibal quluub',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic: 'يَا مُقَلِّبَ الْقُلُوْبِ ثَبِّتْ قَلْبِيْ عَلٰى دِيْنِكَ',
    latin: 'Yaa muqallibal quluub, tsabbit qalbii \'alaa diinik.',
    arti:
        'Wahai Zat yang membolak-balikkan hati, teguhkanlah hatiku di atas agama-Mu.',
    optional: true,
    source: 'HR. At-Tirmidzi no. 2140',
  ),
  Dzikir(
    id: 145,
    title: 'Rabbij\'alnii muqiimash shalaah',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'رَبِّ اجْعَلْنِيْ مُقِيْمَ الصَّلٰوةِ وَمِنْ ذُرِّيَّتِيْۖ رَبَّنَا وَتَقَبَّلْ دُعَاۤءِ رَبَّنَا اغْفِرْ لِيْ وَلِوَالِدَيَّ وَلِلْمُؤْمِنِيْنَ يَوْمَ يَقُوْمُ الْحِسَابُ',
    latin:
        'Rabbij\'alnii muqiimash shalaati wa min dzurriyyatii, rabbanaa wa taqabbal du\'aa\'. Rabbanaghfir lii wa liwaalidayya wa lil mu\'miniina yauma yaquumul hisaab.',
    arti:
        'Ya Tuhanku, jadikanlah aku dan anak cucuku orang yang tetap melaksanakan sholat. Ya Tuhan kami, perkenankanlah doaku. Ya Tuhan kami, ampunilah aku, kedua ibu bapakku, dan semua orang yang beriman pada hari diadakan perhitungan (hari Kiamat).',
    optional: true,
    source: 'QS. Ibrahim: 40-41',
  ),
  Dzikir(
    id: 146,
    title: 'Keluarga penyejuk hati',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'رَبَّنَا هَبْ لَنَا مِنْ اَزْوَاجِنَا وَذُرِّيّٰتِنَا قُرَّةَ اَعْيُنٍ وَّاجْعَلْنَا لِلْمُتَّقِيْنَ اِمَامًا',
    latin:
        'Rabbanaa hab lanaa min azwaajinaa wa dzurriyyaatinaa qurrata a\'yun, waj\'alnaa lil muttaqiina imaamaa.',
    arti:
        'Ya Tuhan kami, anugerahkanlah kepada kami pasangan kami dan keturunan kami sebagai penyenang hati (kami), dan jadikanlah kami pemimpin bagi orang-orang yang bertakwa.',
    optional: true,
    source: 'QS. Al-Furqan: 74',
  ),
  Dzikir(
    id: 147,
    title: 'Ampunan untuk saudara seiman',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'رَبَّنَا اغْفِرْ لَنَا وَلِاِخْوَانِنَا الَّذِيْنَ سَبَقُوْنَا بِالْاِيْمَانِ وَلَا تَجْعَلْ فِيْ قُلُوْبِنَا غِلًّا لِّلَّذِيْنَ اٰمَنُوْا رَبَّنَآ اِنَّكَ رَءُوْفٌ رَّحِيْمٌ',
    latin:
        'Rabbanaghfir lanaa wa li-ikhwaaninalladziina sabaquunaa bil iimaan, wa laa taj\'al fii quluubinaa ghillal lilladziina aamanuu, rabbanaa innaka ra-uufur rahiim.',
    arti:
        'Ya Tuhan kami, ampunilah kami dan saudara-saudara kami yang telah beriman lebih dahulu dari kami, dan janganlah Engkau tanamkan kedengkian dalam hati kami terhadap orang-orang yang beriman. Ya Tuhan kami, sungguh Engkau Maha Penyantun, Maha Penyayang.',
    optional: true,
    source: 'QS. Al-Hasyr: 10',
  ),
  Dzikir(
    id: 148,
    title: 'Penutup: Rabbanaa taqabbal minnaa',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Doa lain yang sering dibaca imam',
    arabic:
        'رَبَّنَا تَقَبَّلْ مِنَّا ۗ اِنَّكَ اَنْتَ السَّمِيْعُ الْعَلِيْمُ وَتُبْ عَلَيْنَا ۚ اِنَّكَ اَنْتَ التَّوَّابُ الرَّحِيْمُ',
    latin:
        'Rabbanaa taqabbal minnaa innaka antas samii\'ul \'aliim, wa tub \'alainaa innaka antat tawwaabur rahiim.',
    arti:
        'Ya Tuhan kami, terimalah (amal) dari kami. Sungguh, Engkaulah Yang Maha Mendengar, Maha Mengetahui. Dan terimalah tobat kami. Sungguh, Engkaulah Yang Maha Penerima tobat, Maha Penyayang.',
    optional: true,
    note: 'Sering dibaca imam sebelum menutup doa dengan Subhaana rabbika.',
    source: 'QS. Al-Baqarah: 127-128',
  ),
  Dzikir(
    id: 67,
    title: 'Laa maani\'a limaa a\'thaita',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir sunnah lainnya',
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ. اَللّٰهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'alaa kulli syai-in qadiir. Allaahumma laa maani\'a limaa a\'thaita, wa laa mu\'thiya limaa mana\'ta, wa laa yanfa\'u dzal jaddi minkal jadd.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu. Ya Allah, tidak ada yang dapat menghalangi apa yang Engkau berikan, tidak ada yang dapat memberi apa yang Engkau halangi, dan tidak berguna kekayaan pemiliknya di hadapan-Mu.',
    optional: true,
    source: 'HR. Bukhari no. 844 & Muslim no. 593',
  ),
  Dzikir(
    id: 68,
    title: 'Laa haula wa laa quwwata illaa billaah',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir sunnah lainnya',
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ، لَا إِلٰهَ إِلَّا اللّٰهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلٰهَ إِلَّا اللّٰهُ مُخْلِصِيْنَ لَهُ الدِّيْنَ وَلَوْ كَرِهَ الْكَافِرُوْنَ',
    latin:
        'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa huwa \'alaa kulli syai-in qadiir, laa haula wa laa quwwata illaa billaah, laa ilaaha illallaah, wa laa na\'budu illaa iyyaah, lahun ni\'matu wa lahul fadhlu wa lahuts tsanaa-ul hasan, laa ilaaha illallaahu mukhlishiina lahud diin walau karihal kaafiruun.',
    arti:
        'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu. Tidak ada daya dan kekuatan kecuali dengan (pertolongan) Allah. Tidak ada tuhan selain Allah, dan kami tidak menyembah selain kepada-Nya. Milik-Nya segala nikmat, karunia, dan pujian yang baik. Tidak ada tuhan selain Allah, dengan memurnikan agama hanya bagi-Nya, meskipun orang-orang kafir membenci.',
    optional: true,
    source: 'HR. Muslim no. 594',
  ),
  Dzikir(
    id: 71,
    title: 'Al-Ikhlas, Al-Falaq & An-Nas',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir sunnah lainnya',
    arabic:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿قُلْ هُوَ اللّٰهُ اَحَدٌۚ ۝ اَللّٰهُ الصَّمَدُۚ ۝ لَمْ يَلِدْ وَلَمْ يُوْلَدْۙ ۝ وَلَمْ يَكُنْ لَّهٗ كُفُوًا اَحَدٌ ࣖ﴾\nبِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿قُلْ اَعُوْذُ بِرَبِّ الْفَلَقِۙ ۝ مِنْ شَرِّ مَا خَلَقَۙ ۝ وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ ۝ وَمِنْ شَرِّ النَّفّٰثٰتِ فِى الْعُقَدِۙ ۝ وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ ࣖ﴾\nبِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿قُلْ اَعُوْذُ بِرَبِّ النَّاسِۙ ۝ مَلِكِ النَّاسِۙ ۝ اِلٰهِ النَّاسِۙ ۝ مِنْ شَرِّ الْوَسْوَاسِ ەۙ الْخَنَّاسِۖ ۝ الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِۙ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ ࣖ﴾',
    latin:
        'Qul huwallaahu ahad. Allaahush shamad. Lam yalid wa lam yuulad. Wa lam yakul lahuu kufuwan ahad.\nQul a\'uudzu birabbil falaq. Min syarri maa khalaq. Wa min syarri ghaasiqin idzaa waqab. Wa min syarrin naffaatsaati fil \'uqad. Wa min syarri haasidin idzaa hasad.\nQul a\'uudzu birabbin naas. Malikin naas. Ilaahin naas. Min syarril waswaasil khannaas. Alladzii yuwaswisu fii shuduurin naas. Minal jinnati wan naas.',
    arti:
        'Katakanlah (Muhammad), “Dialah Allah, Yang Maha Esa. Allah tempat meminta segala sesuatu. (Allah) tidak beranak dan tidak pula diperanakkan. Dan tidak ada sesuatu yang setara dengan Dia.”\nKatakanlah, “Aku berlindung kepada Tuhan yang menguasai subuh (fajar), dari kejahatan (makhluk yang) Dia ciptakan, dan dari kejahatan malam apabila telah gelap gulita, dan dari kejahatan (perempuan-perempuan) penyihir yang meniup pada buhul-buhul (talinya), dan dari kejahatan orang yang dengki apabila dia dengki.”\nKatakanlah, “Aku berlindung kepada Tuhannya manusia, Raja manusia, sembahan manusia, dari kejahatan (bisikan) setan yang bersembunyi, yang membisikkan (kejahatan) ke dalam dada manusia, dari (golongan) jin dan manusia.”',
    optional: true,
    note: 'Setelah Subuh & Maghrib dianjurkan masing-masing 3×.',
    source: 'HR. Abu Daud no. 1523 & At-Tirmidzi no. 2903',
  ),
  Dzikir(
    id: 72,
    title: 'Allaahumma a\'innii',
    repeat: 1,
    time: DzikirTime.sholat,
    group: 'Dzikir sunnah lainnya',
    arabic:
        'اَللّٰهُمَّ أَعِنِّيْ عَلٰى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    latin:
        'Allaahumma a\'innii \'alaa dzikrika wa syukrika wa husni \'ibaadatik.',
    arti:
        'Ya Allah, tolonglah aku untuk berdzikir kepada-Mu, bersyukur kepada-Mu, dan beribadah kepada-Mu dengan baik.',
    optional: true,
    note:
        'Wasiat Nabi ﷺ kepada Mu\'adz bin Jabal agar tidak ditinggalkan di akhir setiap sholat.',
    source: 'HR. Abu Daud no. 1522 & An-Nasa\'i no. 1303',
  ),
  Dzikir(
    id: 74,
    title: '\'Ilman naafi\'aa (Subuh)',
    repeat: 1,
    time: DzikirTime.sholatSubuh,
    group: 'Dzikir sunnah lainnya',
    arabic:
        'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
    latin:
        'Allaahumma innii as-aluka \'ilman naafi\'aa, wa rizqan thayyibaa, wa \'amalan mutaqabbalaa.',
    arti:
        'Ya Allah, sesungguhnya aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang baik, dan amal yang diterima.',
    optional: true,
    note: 'Khusus setelah salam sholat Subuh.',
    source: 'HR. Ibnu Majah no. 925',
  ),
];
