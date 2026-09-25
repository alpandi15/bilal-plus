// DIBUAT OTOMATIS oleh tool/gen_sholat.py - jangan diedit langsung.
//
// Bacaan sholat wajib beberapa versi. Teks Arab dari Hisnul Muslim
// (hisnmuslim.com) & mushaf (api.alquran.cloud); teks pendek yang
// tidak ada di sumber tersebut ditandai typed() di generator. Latin &
// terjemahan bersifat bantuan - rujukan utama teks Arab.

import '../services/sholat_guide.dart';

const sholatSteps = <SholatStep>[
  SholatStep(
    id: 'takbir',
    title: 'Takbiratul Ihram',
    when: 'Membuka sholat sambil mengangkat kedua tangan.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Takbir',
        madzhab: {
          Madzhab.syafii,
          Madzhab.hanafi,
          Madzhab.maliki,
          Madzhab.hanbali,
        },
        arabic: 'اللَّهُ أَكْبَرُ',
        latin: 'Allaahu akbar.',
        arti: 'Allah Mahabesar.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'iftitah',
    title: 'Doa Iftitah',
    when: 'Sesudah takbiratul ihram, sebelum Al-Fatihah, pada rakaat pertama.',
    note:
        'Sunnah. Menurut pendapat masyhur madzhab Maliki, doa iftitah tidak dibaca dalam sholat fardhu - langsung membaca Al-Fatihah.',
    variants: [
      SholatVariant(
        label: 'Lazim di Indonesia',
        madzhab: {Madzhab.syafii},
        arabic:
            'اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا. وَجَّهْتُ وَجْهِيَ لِلَّذِي فَطَرَ السَّمَوَاتِ وَالأَرْضَ حَنِيفَاً وَمَا أَنَا مِنَ الْمُشْرِكِينَ، إِنَّ صَلاَتِي، وَنُسُكِي، وَمَحْيَايَ، وَمَمَاتِي لِلَّهِ رَبِّ الْعَالَمِينَ، لاَ شَرِيكَ لَهُ وَبِذَلِكَ أُمِرْتُ وَأَنَا مِنَ الْمُسْلِمِينَ',
        latin:
            'Allaahu akbar kabiiraa, walhamdu lillaahi katsiiraa, wa subhaanallaahi bukratan wa ashiilaa. Wajjahtu wajhiya lilladzii fatharas samaawaati wal ardha haniifaa, wa maa ana minal musyrikiin. Inna shalaatii wa nusukii wa mahyaaya wa mamaatii lillaahi rabbil \'aalamiin, laa syariika lahuu wa bidzaalika umirtu wa ana minal muslimiin.',
        arti:
            'Allah Mahabesar dengan sebesar-besarnya, segala puji bagi Allah dengan sebanyak-banyaknya, dan Mahasuci Allah pagi dan petang. Aku hadapkan wajahku kepada Dzat yang menciptakan langit dan bumi dengan lurus, dan aku bukan termasuk orang-orang musyrik. Sesungguhnya sholatku, ibadahku, hidupku, dan matiku hanya untuk Allah, Tuhan semesta alam, tiada sekutu bagi-Nya. Dengan itulah aku diperintah, dan aku termasuk orang-orang muslim.',
        source: 'HR. Muslim (gabungan riwayat Ibnu Umar & Ali)',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Pendek (Subhanaka)',
        madzhab: {Madzhab.hanafi, Madzhab.hanbali},
        arabic:
            'سُبْحانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلاَ إِلَهَ غَيْرُكَ',
        latin:
            'Subhaanakallaahumma wa bihamdika, wa tabaarakasmuka, wa ta\'aalaa jadduka, wa laa ilaaha ghairuk.',
        arti:
            'Mahasuci Engkau ya Allah, dan dengan memuji-Mu. Mahaberkah nama-Mu, Mahatinggi keagungan-Mu, dan tidak ada tuhan selain Engkau.',
        source: 'HR. Abu Dawud & At-Tirmidzi',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Allaahumma baa\'id',
        madzhab: {},
        arabic:
            'اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ، اللَّهُمَّ نَقِّنِي مِنْ خَطَايَايَ كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ، اللَّهُمَّ اغْسِلْني مِنْ خَطَايَايَ، بِالثَّلْجِ وَالْماءِ وَالْبَرَدِ',
        latin:
            'Allaahumma baa\'id bainii wa baina khathaayaaya kamaa baa\'adta bainal masyriqi wal maghrib. Allaahumma naqqinii min khathaayaaya kamaa yunaqqats tsaubul abyadhu minad danas. Allaahummaghsilnii min khathaayaaya bits tsalji wal maa-i wal barad.',
        arti:
            'Ya Allah, jauhkanlah antara aku dan kesalahan-kesalahanku sebagaimana Engkau menjauhkan antara timur dan barat. Ya Allah, bersihkanlah aku dari kesalahan-kesalahanku sebagaimana kain putih dibersihkan dari kotoran. Ya Allah, cucilah kesalahan-kesalahanku dengan salju, air, dan embun.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Panjang (Wajjahtu lengkap)',
        madzhab: {},
        arabic:
            'وَجَّهْتُ وَجْهِيَ لِلَّذِي فَطَرَ السَّمَوَاتِ وَالأَرْضَ حَنِيفَاً وَمَا أَنَا مِنَ الْمُشْرِكِينَ، إِنَّ صَلاَتِي، وَنُسُكِي، وَمَحْيَايَ، وَمَمَاتِي لِلَّهِ رَبِّ الْعَالَمِينَ، لاَ شَرِيكَ لَهُ وَبِذَلِكَ أُمِرْتُ وَأَنَا مِنَ الْمُسْلِمِينَ. اللَّهُمَّ أَنْتَ المَلِكُ لاَ إِلَهَ إِلاَّ أَنْتَ، أَنْتَ رَبِّي وَأَنَا عَبْدُكَ، ظَلَمْتُ نَفْسِي وَاعْتَرَفْتُ بِذَنْبِي فَاغْفِرْ لِي ذُنُوبي جَمِيعَاً إِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ. وَاهْدِنِي لِأَحْسَنِ الأَخْلاقِ لاَ يَهْدِي لِأَحْسَنِها إِلاَّ أَنْتَ، وَاصْرِفْ عَنِّي سَيِّئَهَا، لاَ يَصْرِفُ عَنِّي سَيِّئَهَا إِلاَّ أَنْتَ، لَبَّيْكَ وَسَعْدَيْكَ، وَالخَيْرُ كُلُّهُ بِيَدَيْكَ، وَالشَّرُّ لَيْسَ إِلَيْكَ، أَنَا بِكَ وَإِلَيْكَ، تَبارَكْتَ وَتَعَالَيْتَ، أَسْتَغْفِرُكَ وَأَتوبُ إِلَيْكَ',
        latin:
            'Wajjahtu wajhiya lilladzii fatharas samaawaati wal ardha haniifaa, wa maa ana minal musyrikiin. Inna shalaatii wa nusukii wa mahyaaya wa mamaatii lillaahi rabbil \'aalamiin, laa syariika lahuu wa bidzaalika umirtu wa ana minal muslimiin. Allaahumma antal maliku laa ilaaha illaa anta, anta rabbii wa ana \'abduka, zhalamtu nafsii wa\'taraftu bidzanbii faghfir lii dzunuubii jamii\'aa, innahuu laa yaghfirudz dzunuuba illaa anta. Wahdinii li-ahsanil akhlaaqi laa yahdii li-ahsanihaa illaa anta, washrif \'annii sayyi-ahaa laa yashrifu \'annii sayyi-ahaa illaa anta. Labbaika wa sa\'daika, wal khairu kulluhuu biyadaika, wasy syarru laisa ilaika. Ana bika wa ilaika, tabaarakta wa ta\'aalaita, astaghfiruka wa atuubu ilaik.',
        arti:
            'Aku hadapkan wajahku kepada Dzat yang menciptakan langit dan bumi dengan lurus, dan aku bukan termasuk orang musyrik. Sesungguhnya sholatku, ibadahku, hidupku, dan matiku untuk Allah, Tuhan semesta alam, tiada sekutu bagi-Nya; dengan itu aku diperintah dan aku termasuk orang muslim. Ya Allah, Engkaulah Raja, tidak ada tuhan selain Engkau. Engkau Tuhanku dan aku hamba-Mu. Aku telah menzalimi diriku dan aku mengakui dosaku, maka ampunilah seluruh dosaku; tidak ada yang mengampuni dosa selain Engkau. Tunjukilah aku kepada akhlak terbaik, tidak ada yang menunjukkan kepadanya selain Engkau. Jauhkanlah dariku akhlak yang buruk, tidak ada yang menjauhkannya selain Engkau. Aku penuhi panggilan-Mu dengan senang hati. Kebaikan seluruhnya ada di tangan-Mu, dan keburukan tidak disandarkan kepada-Mu. Aku bersama-Mu dan kembali kepada-Mu. Mahaberkah dan Mahatinggi Engkau, aku memohon ampun dan bertaubat kepada-Mu.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'fatihah',
    title: 'Ta\'awudz & Al-Fatihah',
    when: 'Setiap rakaat. Diakhiri "Aamiin" sesudah Al-Fatihah.',
    note:
        'Basmalah: menurut Syafi\'iyah termasuk ayat Al-Fatihah dan dibaca (dikeraskan pada sholat jahr); Hanafiyah & Hanabilah membacanya pelan; menurut pendapat masyhur Malikiyah tidak dibaca pada sholat fardhu.',
    variants: [
      SholatVariant(
        label: 'Al-Fatihah',
        madzhab: {
          Madzhab.syafii,
          Madzhab.hanafi,
          Madzhab.maliki,
          Madzhab.hanbali,
        },
        arabic:
            'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ﴿١﴾ الْحَمْدُ لِلَّهِ رَبِّ الْعَٰلَمِينَ ﴿٢﴾ الرَّحْمَٰنِ الرَّحِيمِ ﴿٣﴾ مَٰلِكِ يَوْمِ الدِّينِ ﴿٤﴾ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ﴿٥﴾ اهْدِنَا الصِّرَٰطَ الْمُسْتَقِيمَ ﴿٦﴾ صِرَٰطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّآلِّينَ ﴿٧﴾',
        latin:
            'A\'uudzu billaahi minasy syaithaanir rajiim.\nBismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil \'aalamiin. Arrahmaanir rahiim. Maaliki yaumid diin. Iyyaaka na\'budu wa iyyaaka nasta\'iin. Ihdinash shiraathal mustaqiim. Shiraathal ladziina an\'amta \'alaihim ghairil maghdhuubi \'alaihim wa ladh dhaalliin. Aamiin.',
        arti:
            'Aku berlindung kepada Allah dari setan yang terkutuk.\nDengan nama Allah Yang Maha Pengasih, Maha Penyayang. Segala puji bagi Allah, Tuhan seluruh alam. Yang Maha Pengasih, Maha Penyayang. Pemilik hari pembalasan. Hanya kepada-Mu kami menyembah dan hanya kepada-Mu kami memohon pertolongan. Tunjukilah kami jalan yang lurus, (yaitu) jalan orang-orang yang telah Engkau beri nikmat, bukan (jalan) mereka yang dimurkai dan bukan (pula jalan) mereka yang sesat. Aamiin.',
        source: 'QS. Al-Fatihah: 1-7',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'surat',
    title: 'Membaca Surat',
    when: 'Sesudah Al-Fatihah pada rakaat pertama dan kedua.',
    note:
        'Boleh surat atau ayat apa saja yang dihafal - di atas beberapa contoh surat pendek.',
    variants: [
      SholatVariant(
        label: 'Al-Ikhlas',
        madzhab: {
          Madzhab.syafii,
          Madzhab.hanafi,
          Madzhab.maliki,
          Madzhab.hanbali,
        },
        arabic:
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ ﴿٤﴾',
        latin:
            'Bismillaahir rahmaanir rahiim. Qul huwallaahu ahad. Allaahush shamad. Lam yalid wa lam yuulad. Wa lam yakul lahuu kufuwan ahad.',
        arti:
            'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Katakanlah: Dialah Allah Yang Maha Esa. Allah tempat meminta segala sesuatu. Dia tidak beranak dan tidak diperanakkan. Dan tidak ada sesuatu pun yang setara dengan-Nya.',
        source: 'QS. Al-Ikhlas: 1-4',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Al-\'Ashr',
        madzhab: {},
        arabic:
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nوَالْعَصْرِ ﴿١﴾ إِنَّ الْإِنسَٰنَ لَفِى خُسْرٍ ﴿٢﴾ إِلَّا الَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ الصَّٰلِحَٰتِ وَتَوَاصَوْا۟ بِالْحَقِّ وَتَوَاصَوْا۟ بِالصَّبْرِ ﴿٣﴾',
        latin:
            'Bismillaahir rahmaanir rahiim. Wal \'ashr. Innal insaana lafii khusr. Illal ladziina aamanuu wa \'amilush shaalihaati wa tawaashau bil haqqi wa tawaashau bish shabr.',
        arti:
            'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Demi masa. Sungguh, manusia berada dalam kerugian, kecuali orang-orang yang beriman dan mengerjakan kebajikan serta saling menasihati untuk kebenaran dan saling menasihati untuk kesabaran.',
        source: 'QS. Al-\'Ashr: 1-3',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Al-Kautsar',
        madzhab: {},
        arabic:
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nإِنَّآ أَعْطَيْنَٰكَ الْكَوْثَرَ ﴿١﴾ فَصَلِّ لِرَبِّكَ وَانْحَرْ ﴿٢﴾ إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ ﴿٣﴾',
        latin:
            'Bismillaahir rahmaanir rahiim. Innaa a\'thainaakal kautsar. Fashalli lirabbika wanhar. Inna syaani-aka huwal abtar.',
        arti:
            'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Sungguh, Kami telah memberimu nikmat yang banyak. Maka laksanakanlah sholat karena Tuhanmu dan berkurbanlah. Sungguh, orang-orang yang membencimu, dialah yang terputus.',
        source: 'QS. Al-Kautsar: 1-3',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'ruku',
    title: 'Ruku\'',
    when: 'Membungkuk dengan tuma\'ninah, punggung lurus.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Dengan "wa bihamdih"',
        madzhab: {Madzhab.syafii},
        arabic: 'سُبْحانَ رَبِّيَ الْعَظِيمِ وَبِحَمْدِهِ',
        latin: 'Subhaana rabbiyal \'azhiimi wa bihamdih.',
        arti: 'Mahasuci Tuhanku Yang Mahaagung dan dengan memuji-Nya.',
        source: 'HR. Abu Dawud',
        repeat: 3,
      ),
      SholatVariant(
        label: 'Pendek',
        madzhab: {Madzhab.hanafi, Madzhab.maliki, Madzhab.hanbali},
        arabic: 'سُبْحانَ رَبِّيَ الْعَظِيمِ',
        latin: 'Subhaana rabbiyal \'azhiim.',
        arti: 'Mahasuci Tuhanku Yang Mahaagung.',
        source: 'HR. Muslim',
        repeat: 3,
      ),
      SholatVariant(
        label: 'Subhaanakallaahumma',
        madzhab: {},
        arabic:
            'سُبْحَانَكَ اللَّهُمَّ رَبَّنَا وَبِحَمْدِكَ، اللَّهُمَّ اغْفِرْ لِي',
        latin:
            'Subhaanakallaahumma rabbanaa wa bihamdika, allaahummaghfir lii.',
        arti:
            'Mahasuci Engkau ya Allah, Tuhan kami, dan dengan memuji-Mu. Ya Allah, ampunilah aku.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Subbuuhun quddus',
        madzhab: {},
        arabic: 'سُبُّوُحٌ، قُدُّوسٌ، رَبُّ المَلاَئِكَةِ وَالرُّوحِ',
        latin: 'Subbuuhun qudduusun, rabbul malaa-ikati war ruuh.',
        arti: 'Mahasuci, Mahaqudus, Tuhan para malaikat dan Ruh (Jibril).',
        source: 'HR. Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Panjang',
        madzhab: {},
        arabic:
            'اللَّهُمَّ لَكَ رَكَعْتُ، وَبِكَ آمَنْتُ، وَلَكَ أَسْلَمْتُ، خَشَعَ لَكَ سَمْعِي، وَبَصَرِي، وَمُخِّي، وَعَظْمِي، وَعَصَبِي، وَمَا استَقَلَّتْ بِهِ قَدَمِي',
        latin:
            'Allaahumma laka raka\'tu, wa bika aamantu, wa laka aslamtu, khasya\'a laka sam\'ii wa basharii wa mukhkhii wa \'azhmii wa \'ashabii, wa mastaqallat bihii qadamii.',
        arti:
            'Ya Allah, kepada-Mu aku ruku\', kepada-Mu aku beriman, dan kepada-Mu aku berserah diri. Tunduk kepada-Mu pendengaranku, penglihatanku, otakku, tulangku, urat sarafku, dan apa yang ditopang oleh kakiku.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'itidal',
    title: 'I\'tidal',
    when:
        'Bangkit dari ruku\' sambil membaca "Sami\'allaahu liman hamidah", lalu berdiri tegak.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Lazim di Indonesia',
        madzhab: {Madzhab.syafii},
        arabic:
            'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ. رَبَّنَا لَكَ الْحَمْدُ مِلْءَ السَّمَوَاتِ وَمِلْءَ الأَرْضِ، وَمَا بَيْنَهُمَا، وَمِلْءَ مَا شِئْتَ مِنْ شَيءٍ بَعْدُ',
        latin:
            'Sami\'allaahu liman hamidah. Rabbanaa lakal hamdu mil-as samaawaati wa mil-al ardhi wa maa bainahumaa, wa mil-a maa syi\'ta min syai-in ba\'d.',
        arti:
            'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, bagi-Mu segala puji, sepenuh langit dan sepenuh bumi dan apa yang ada di antara keduanya, dan sepenuh apa saja yang Engkau kehendaki sesudah itu.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Pendek',
        madzhab: {Madzhab.hanafi, Madzhab.maliki, Madzhab.hanbali},
        arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ. رَبَّنَا وَلَكَ الْحَمْدُ',
        latin: 'Sami\'allaahu liman hamidah. Rabbanaa wa lakal hamd.',
        arti:
            'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, dan bagi-Mu segala puji.',
        source: 'HR. Al-Bukhari',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Hamdan katsiiran',
        madzhab: {},
        arabic:
            'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ. رَبَّنَا وَلَكَ الْحَمْدُ، حَمْداً كَثيراً طَيِّباً مُبارَكاً فِيهِ',
        latin:
            'Sami\'allaahu liman hamidah. Rabbanaa wa lakal hamdu hamdan katsiiran thayyiban mubaarakan fiih.',
        arti:
            'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, bagi-Mu segala puji, pujian yang banyak, baik, dan penuh berkah.',
        source: 'HR. Al-Bukhari',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Panjang',
        madzhab: {},
        arabic:
            'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ. رَبَّنَا لَكَ الْحَمْدُ مِلْءَ السَّمَوَاتِ وَمِلْءَ الأَرْضِ، وَمَا بَيْنَهُمَا، وَمِلْءَ مَا شِئْتَ مِنْ شَيءٍ بَعْدُ. أَهلَ الثَّناءِ وَالْمَجْدِ، أَحَقُّ مَا قَالَ الْعَبْدُ، وَكُلُّنَا لَكَ عَبْدٌ. اللَّهُمَّ لاَ مَانِعَ لِمَا أَعْطَيْتَ، وَلاَ مُعْطِيَ لِمَا مَنَعْتَ، وَلاَ يَنْفَعُ ذَا الجَدِّ مِنْكَ الجَدُّ',
        latin:
            'Sami\'allaahu liman hamidah. Rabbanaa lakal hamdu mil-as samaawaati wa mil-al ardhi wa maa bainahumaa, wa mil-a maa syi\'ta min syai-in ba\'d. Ahlats tsanaa-i wal majdi, ahaqqu maa qaalal \'abdu, wa kullunaa laka \'abd. Allaahumma laa maani\'a limaa a\'thaita, wa laa mu\'thiya limaa mana\'ta, wa laa yanfa\'u dzal jaddi minkal jadd.',
        arti:
            'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, bagi-Mu segala puji sepenuh langit, bumi, dan apa yang di antara keduanya, dan sepenuh apa saja yang Engkau kehendaki sesudah itu. Engkaulah yang berhak dipuji dan diagungkan; itulah perkataan paling benar yang diucapkan seorang hamba, dan kami semua adalah hamba-Mu. Ya Allah, tidak ada yang dapat menghalangi apa yang Engkau berikan, tidak ada yang dapat memberi apa yang Engkau halangi, dan kekayaan tidak bermanfaat bagi pemiliknya di hadapan-Mu.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'sujud',
    title: 'Sujud',
    when:
        'Dahi, hidung, kedua telapak tangan, kedua lutut, dan ujung kaki menempel di lantai. Dilakukan dua kali tiap rakaat.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Dengan "wa bihamdih"',
        madzhab: {Madzhab.syafii},
        arabic: 'سُبْحَانَ رَبِّيَ الأَعْلَى وَبِحَمْدِهِ',
        latin: 'Subhaana rabbiyal a\'laa wa bihamdih.',
        arti: 'Mahasuci Tuhanku Yang Mahatinggi dan dengan memuji-Nya.',
        source: 'HR. Abu Dawud',
        repeat: 3,
      ),
      SholatVariant(
        label: 'Pendek',
        madzhab: {Madzhab.hanafi, Madzhab.maliki, Madzhab.hanbali},
        arabic: 'سُبْحَانَ رَبِّيَ الأَعْلَى',
        latin: 'Subhaana rabbiyal a\'laa.',
        arti: 'Mahasuci Tuhanku Yang Mahatinggi.',
        source: 'HR. Muslim',
        repeat: 3,
      ),
      SholatVariant(
        label: 'Subhaanakallaahumma',
        madzhab: {},
        arabic:
            'سُبْحَانَكَ اللَّهُمَّ رَبَّنَا وَبِحَمْدِكَ، اللَّهُمَّ اغْفِرْ لِي',
        latin:
            'Subhaanakallaahumma rabbanaa wa bihamdika, allaahummaghfir lii.',
        arti:
            'Mahasuci Engkau ya Allah, Tuhan kami, dan dengan memuji-Mu. Ya Allah, ampunilah aku.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Panjang',
        madzhab: {},
        arabic:
            'اللَّهُمَّ لَكَ سَجَدْتُ وَبِكَ آمَنْتُ، وَلَكَ أَسْلَمْتُ، سَجَدَ وَجْهِيَ لِلَّذِي خَلَقَهُ، وَصَوَّرَهُ، وَشَقَّ سَمْعَهُ وَبَصَرَهُ، تَبَارَكَ اللَّهُ أَحْسنُ الْخَالِقينَ',
        latin:
            'Allaahumma laka sajadtu, wa bika aamantu, wa laka aslamtu, sajada wajhiya lilladzii khalaqahuu wa shawwarahuu wa syaqqa sam\'ahuu wa basharahuu, tabaarakallaahu ahsanul khaaliqiin.',
        arti:
            'Ya Allah, kepada-Mu aku bersujud, kepada-Mu aku beriman, dan kepada-Mu aku berserah diri. Wajahku bersujud kepada Dzat yang menciptakannya, membentuknya, dan membuka pendengaran serta penglihatannya. Mahasuci Allah, sebaik-baik Pencipta.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Mohon ampun',
        madzhab: {},
        arabic:
            'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ: دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ، وَعَلاَنِيَّتَهُ وَسِرَّهُ',
        latin:
            'Allaahummaghfir lii dzanbii kullahuu, diqqahuu wa jillahuu, wa awwalahuu wa aakhirahuu, wa \'alaaniyatahuu wa sirrahuu.',
        arti:
            'Ya Allah, ampunilah seluruh dosaku, yang kecil dan yang besar, yang awal dan yang akhir, yang terang-terangan dan yang tersembunyi.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'duduk',
    title: 'Duduk di Antara Dua Sujud',
    when: 'Duduk iftirasy dengan tuma\'ninah sesudah sujud pertama.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Lazim di Indonesia',
        madzhab: {Madzhab.syafii},
        arabic:
            'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي',
        latin:
            'Rabbighfir lii warhamnii wajburnii warfa\'nii warzuqnii wahdinii wa \'aafinii wa\'fu \'annii.',
        arti:
            'Wahai Tuhanku, ampunilah aku, rahmatilah aku, cukupkanlah aku, angkatlah derajatku, berilah aku rezeki, berilah aku petunjuk, sehatkanlah aku, dan maafkanlah aku.',
        source: 'Gabungan riwayat Abu Dawud, At-Tirmidzi & Ibnu Majah',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Pendek',
        madzhab: {Madzhab.hanafi, Madzhab.maliki, Madzhab.hanbali},
        arabic: 'رَبِّ اغْفِرْ لِي، رَبِّ اغْفِرْ لِي',
        latin: 'Rabbighfir lii, rabbighfir lii.',
        arti: 'Wahai Tuhanku, ampunilah aku. Wahai Tuhanku, ampunilah aku.',
        source: 'HR. Abu Dawud & Ibnu Majah',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Riwayat Abu Dawud',
        madzhab: {},
        arabic:
            'اللَّهُمَّ اغْفِرْ لِي، وَارْحَمْنِي، وَاهْدِنِي، وَاجْبُرْنِي، وَعَافِنِي، وَارْزُقْنِي، وَارْفَعْنِي',
        latin:
            'Allaahummaghfir lii warhamnii wahdinii wajburnii wa \'aafinii warzuqnii warfa\'nii.',
        arti:
            'Ya Allah, ampunilah aku, rahmatilah aku, berilah aku petunjuk, cukupkanlah aku, sehatkanlah aku, berilah aku rezeki, dan angkatlah derajatku.',
        source: 'HR. Abu Dawud & At-Tirmidzi',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'tasyahud_awal',
    title: 'Tasyahud Awal',
    when:
        'Sesudah sujud kedua rakaat kedua, pada sholat 3 dan 4 rakaat (Dzuhur, Ashar, Maghrib, Isya).',
    note:
        'Menurut Syafi\'iyah, disunnahkan menambah shalawat kepada Nabi sesudah tasyahud awal.',
    variants: [
      SholatVariant(
        label: 'Riwayat Ibnu Abbas',
        madzhab: {Madzhab.syafii},
        arabic:
            'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ. اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
        latin:
            'Attahiyyaatul mubaarakaatush shalawaatuth thayyibaatu lillaah. Assalaamu \'alaika ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu \'alainaa wa \'alaa \'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna muhammadar rasuulullaah. Allaahumma shalli \'alaa muhammad.',
        arti:
            'Segala penghormatan, keberkahan, shalawat, dan kebaikan adalah milik Allah. Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah utusan Allah. Ya Allah, limpahkanlah shalawat kepada Muhammad.',
        source: 'HR. Muslim (tasyahud)',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Riwayat Ibnu Mas\'ud',
        madzhab: {Madzhab.hanafi, Madzhab.hanbali},
        arabic:
            'التَّحِيَّاتُ لِلَّهِ، وَالصَّلَواتُ، وَالطَّيِّباتُ، السَّلاَمُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلاَمُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ. أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّداً عَبْدُهُ وَرَسولُهُ',
        latin:
            'Attahiyyaatu lillaahi wash shalawaatu wath thayyibaat. Assalaamu \'alaika ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu \'alainaa wa \'alaa \'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna muhammadan \'abduhuu wa rasuuluh.',
        arti:
            'Segala penghormatan, shalawat, dan kebaikan adalah milik Allah. Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Riwayat Umar',
        madzhab: {Madzhab.maliki},
        arabic:
            'التَّحِيَّاتُ لِلَّهِ، الزَّاكِيَاتُ لِلَّهِ، الطَّيِّبَاتُ الصَّلَوَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
        latin:
            'Attahiyyaatu lillaah, azzaakiyaatu lillaah, aththayyibaatush shalawaatu lillaah. Assalaamu \'alaika ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu \'alainaa wa \'alaa \'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna muhammadan \'abduhuu wa rasuuluh.',
        arti:
            'Segala penghormatan milik Allah, amal-amal yang suci milik Allah, kebaikan dan shalawat milik Allah. Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.',
        source: 'Al-Muwaththa\' (Imam Malik)',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'tasyahud_akhir',
    title: 'Tasyahud Akhir & Shalawat',
    when:
        'Duduk tawarruk pada rakaat terakhir: tasyahud, lalu shalawat Ibrahimiyah.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Riwayat Ibnu Abbas + shalawat',
        madzhab: {Madzhab.syafii},
        arabic:
            'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ.\nاللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
        latin:
            'Attahiyyaatul mubaarakaatush shalawaatuth thayyibaatu lillaah. Assalaamu \'alaika ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu \'alainaa wa \'alaa \'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna muhammadar rasuulullaah.\nAllaahumma shalli \'alaa muhammadin wa \'alaa aali muhammad, kamaa shallaita \'alaa ibraahiima wa \'alaa aali ibraahiim, innaka hamiidum majiid. Allaahumma baarik \'alaa muhammadin wa \'alaa aali muhammad, kamaa baarakta \'alaa ibraahiima wa \'alaa aali ibraahiim, innaka hamiidum majiid.',
        arti:
            'Segala penghormatan, keberkahan, shalawat, dan kebaikan adalah milik Allah. Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah utusan Allah.\nYa Allah, limpahkanlah shalawat kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau melimpahkan shalawat kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia. Ya Allah, limpahkanlah keberkahan kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau melimpahkan keberkahan kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.',
        source: 'HR. Muslim; shalawat HR. Al-Bukhari',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Riwayat Ibnu Mas\'ud + shalawat',
        madzhab: {Madzhab.hanafi, Madzhab.hanbali},
        arabic:
            'التَّحِيَّاتُ لِلَّهِ، وَالصَّلَواتُ، وَالطَّيِّباتُ، السَّلاَمُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلاَمُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ. أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّداً عَبْدُهُ وَرَسولُهُ.\nاللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
        latin:
            'Attahiyyaatu lillaahi wash shalawaatu wath thayyibaat. Assalaamu \'alaika ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu \'alainaa wa \'alaa \'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna muhammadan \'abduhuu wa rasuuluh.\nAllaahumma shalli \'alaa muhammadin wa \'alaa aali muhammad, kamaa shallaita \'alaa ibraahiima wa \'alaa aali ibraahiim, innaka hamiidum majiid. Allaahumma baarik \'alaa muhammadin wa \'alaa aali muhammad, kamaa baarakta \'alaa ibraahiima wa \'alaa aali ibraahiim, innaka hamiidum majiid.',
        arti:
            'Segala penghormatan, shalawat, dan kebaikan adalah milik Allah. Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.\nYa Allah, limpahkanlah shalawat kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau melimpahkan shalawat kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia. Ya Allah, limpahkanlah keberkahan kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau melimpahkan keberkahan kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Riwayat Umar + shalawat',
        madzhab: {Madzhab.maliki},
        arabic:
            'التَّحِيَّاتُ لِلَّهِ، الزَّاكِيَاتُ لِلَّهِ، الطَّيِّبَاتُ الصَّلَوَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ.\nاللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
        latin:
            'Attahiyyaatu lillaah, azzaakiyaatu lillaah, aththayyibaatush shalawaatu lillaah. Assalaamu \'alaika ayyuhan nabiyyu wa rahmatullaahi wa barakaatuh. Assalaamu \'alainaa wa \'alaa \'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna muhammadan \'abduhuu wa rasuuluh.\nAllaahumma shalli \'alaa muhammadin wa \'alaa aali muhammad, kamaa shallaita \'alaa ibraahiima wa \'alaa aali ibraahiim, innaka hamiidum majiid. Allaahumma baarik \'alaa muhammadin wa \'alaa aali muhammad, kamaa baarakta \'alaa ibraahiima wa \'alaa aali ibraahiim, innaka hamiidum majiid.',
        arti:
            'Segala penghormatan milik Allah, amal-amal yang suci milik Allah, kebaikan dan shalawat milik Allah. Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.\nYa Allah, limpahkanlah shalawat kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau melimpahkan shalawat kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia. Ya Allah, limpahkanlah keberkahan kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau melimpahkan keberkahan kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.',
        source: 'Al-Muwaththa\'; shalawat HR. Al-Bukhari',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Shalawat versi lain',
        madzhab: {},
        arabic:
            'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى أَزْوَاجِهِ وَذُرِّيَّتِهِ، كَمَا صَلَّيْتَ عَلَى آلِ إِبْرَاهِيمَ. وَبَارِكْ عَلَى مُحَمَّدٍ وَعَلَى أَزْواجِهِ وَذُرِّيَّتِهِ، كَمَا بَارَكْتَ عَلَى آلِ إِبْرَاهِيمَ. إِنَّكَ حَمِيدٌ مَجِيدٌ',
        latin:
            'Allaahumma shalli \'alaa muhammadin wa \'alaa azwaajihii wa dzurriyyatihii, kamaa shallaita \'alaa aali ibraahiim. Wa baarik \'alaa muhammadin wa \'alaa azwaajihii wa dzurriyyatihii, kamaa baarakta \'alaa aali ibraahiim, innaka hamiidum majiid.',
        arti:
            'Ya Allah, limpahkanlah shalawat kepada Muhammad, istri-istrinya, dan keturunannya, sebagaimana Engkau melimpahkan shalawat kepada keluarga Ibrahim. Limpahkanlah keberkahan kepada Muhammad, istri-istrinya, dan keturunannya, sebagaimana Engkau melimpahkan keberkahan kepada keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'doa_salam',
    title: 'Doa Sebelum Salam',
    when: 'Sesudah shalawat pada tasyahud akhir, sebelum salam.',
    note: null,
    variants: [
      SholatVariant(
        label: 'Empat perlindungan',
        madzhab: {
          Madzhab.syafii,
          Madzhab.hanafi,
          Madzhab.maliki,
          Madzhab.hanbali,
        },
        arabic:
            'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، وَمِنْ عَذَابِ جَهَنَّمَ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ',
        latin:
            'Allaahumma innii a\'uudzu bika min \'adzaabil qabri, wa min \'adzaabi jahannam, wa min fitnatil mahyaa wal mamaat, wa min syarri fitnatil masiihid dajjaal.',
        arti:
            'Ya Allah, aku berlindung kepada-Mu dari siksa kubur, dari siksa Jahanam, dari fitnah kehidupan dan kematian, dan dari keburukan fitnah Al-Masih Ad-Dajjal.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Doa Abu Bakar',
        madzhab: {},
        arabic:
            'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْماً كَثِيراً، وَلاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ وَارْحَمْنِي، إِنَّكَ أَنْتَ الغَفورُ الرَّحيمُ',
        latin:
            'Allaahumma innii zhalamtu nafsii zhulman katsiiraa, wa laa yaghfirudz dzunuuba illaa anta, faghfir lii maghfiratam min \'indika warhamnii, innaka antal ghafuurur rahiim.',
        arti:
            'Ya Allah, sungguh aku telah banyak menzalimi diriku, dan tidak ada yang mengampuni dosa selain Engkau. Maka ampunilah aku dengan ampunan dari sisi-Mu dan rahmatilah aku; sesungguhnya Engkau Maha Pengampun lagi Maha Penyayang.',
        source: 'HR. Al-Bukhari & Muslim',
        repeat: 1,
      ),
      SholatVariant(
        label: 'A\'innii \'alaa dzikrika',
        madzhab: {},
        arabic:
            'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ، وَشُكْرِكَ، وَحُسْنِ عِبادَتِكَ',
        latin:
            'Allaahumma a\'innii \'alaa dzikrika wa syukrika wa husni \'ibaadatik.',
        arti:
            'Ya Allah, tolonglah aku untuk berdzikir kepada-Mu, bersyukur kepada-Mu, dan beribadah kepada-Mu dengan baik.',
        source: 'HR. Abu Dawud & An-Nasa\'i',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Panjang',
        madzhab: {},
        arabic:
            'اللَّهُمَّ اغْفِرْ لِي مَا قَدَّمْتُ، وَمَا أَخَّرْتُ، وَمَا أَسْرَرْتُ، وَمَا أَعْلَنْتُ، وَمَا أَسْرَفْتُ، وَمَا أَنْتَ أَعْلَمُ بِهِ مِنِّي. أَنْتَ الْمُقَدِّمُ، وَأَنْتَ الْمُؤَخِّرُ لاَ إِلَهَ إِلاَّ أَنْتَ',
        latin:
            'Allaahummaghfir lii maa qaddamtu wa maa akhkhartu, wa maa asrartu wa maa a\'lantu, wa maa asraftu, wa maa anta a\'lamu bihii minnii. Antal muqaddimu wa antal mu-akhkhiru, laa ilaaha illaa anta.',
        arti:
            'Ya Allah, ampunilah dosaku yang telah lalu dan yang akan datang, yang tersembunyi dan yang terang-terangan, yang melampaui batas, dan yang Engkau lebih mengetahuinya daripada aku. Engkaulah yang mendahulukan dan mengakhirkan, tidak ada tuhan selain Engkau.',
        source: 'HR. Muslim',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'salam',
    title: 'Salam',
    when: 'Menoleh ke kanan, lalu ke kiri.',
    note: 'Menurut Malikiyah, satu kali salam sudah mencukupi.',
    variants: [
      SholatVariant(
        label: 'Salam',
        madzhab: {
          Madzhab.syafii,
          Madzhab.hanafi,
          Madzhab.maliki,
          Madzhab.hanbali,
        },
        arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
        latin: 'Assalaamu \'alaikum wa rahmatullaah.',
        arti: 'Semoga keselamatan dan rahmat Allah tercurah kepada kalian.',
        source: 'HR. Abu Dawud & At-Tirmidzi',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Dengan "wa barakaatuh"',
        madzhab: {},
        arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ',
        latin: 'Assalaamu \'alaikum wa rahmatullaahi wa barakaatuh.',
        arti:
            'Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah kepada kalian.',
        source: 'HR. Abu Dawud (pada salam pertama)',
        repeat: 1,
      ),
    ],
  ),
  SholatStep(
    id: 'qunut',
    title: 'Qunut Subuh',
    when: 'Pada rakaat kedua sholat Subuh, sesudah i\'tidal (Syafi\'iyah).',
    note:
        'Qunut Subuh disunnahkan menurut Syafi\'iyah (sesudah ruku\') dan Malikiyah (pelan, sebelum ruku\'). Menurut Hanafiyah dan Hanabilah, tidak ada qunut pada sholat Subuh - qunut dibaca pada witir atau ketika ada musibah (nazilah).',
    variants: [
      SholatVariant(
        label: 'Lazim di Indonesia',
        madzhab: {Madzhab.syafii},
        arabic:
            'اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لِي فِيمَا أَعْطَيْتَ، وَقِنِي شَرَّ مَا قَضَيْتَ؛ فَإِنَّكَ تَقْضِي وَلاَ يُقْضَى عَلَيْكَ، إِنَّهُ لاَ يَذِلُّ مَنْ وَالَيْتَ، وَلاَ يَعِزُّ مَنْ عَادَيْتَ، تَبارَكْتَ رَبَّنا وَتَعَالَيْتَ، فَلَكَ الْحَمْدُ عَلَى مَا قَضَيْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ، وَصَلَّى اللَّهُ عَلَى سَيِّدِنَا مُحَمَّدٍ النَّبِيِّ الْأُمِّيِّ وَعَلَى آلِهِ وَصَحْبِهِ وَسَلَّمَ',
        latin:
            'Allaahummahdinii fiiman hadait, wa \'aafinii fiiman \'aafait, wa tawallanii fiiman tawallait, wa baarik lii fiimaa a\'thait, wa qinii syarra maa qadhait, fa innaka taqdhii wa laa yuqdhaa \'alaik, innahuu laa yadzillu man waalait, wa laa ya\'izzu man \'aadait, tabaarakta rabbanaa wa ta\'aalait. Fa lakal hamdu \'alaa maa qadhait, astaghfiruka wa atuubu ilaik, wa shallallaahu \'alaa sayyidinaa muhammadinin nabiyyil ummiyyi wa \'alaa aalihii wa shahbihii wa sallam.',
        arti:
            'Ya Allah, berilah aku petunjuk bersama orang-orang yang Engkau beri petunjuk, berilah aku keselamatan bersama orang-orang yang Engkau beri keselamatan, uruslah aku bersama orang-orang yang Engkau urus, berkahilah apa yang Engkau berikan kepadaku, dan jagalah aku dari keburukan yang Engkau takdirkan. Sesungguhnya Engkaulah yang menetapkan dan tidak ada yang menetapkan atas-Mu. Tidak akan hina orang yang Engkau lindungi, dan tidak akan mulia orang yang Engkau musuhi. Mahaberkah Engkau wahai Tuhan kami dan Mahatinggi. Bagi-Mu segala puji atas apa yang Engkau tetapkan. Aku memohon ampun dan bertaubat kepada-Mu. Semoga Allah melimpahkan shalawat dan salam kepada junjungan kami Nabi Muhammad yang ummi, beserta keluarga dan sahabatnya.',
        source:
            'Riwayat Al-Hasan bin Ali (Abu Dawud, At-Tirmidzi); tambahan penutup dari ulama Syafi\'iyah',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Riwayat Al-Hasan bin Ali',
        madzhab: {},
        arabic:
            'اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لِي فِيمَا أَعْطَيْتَ، وَقِنِي شَرَّ مَا قَضَيْتَ؛ فَإِنَّكَ تَقْضِي وَلاَ يُقْضَى عَلَيْكَ، إِنَّهُ لاَ يَذِلُّ مَنْ وَالَيْتَ، وَلاَ يَعِزُّ مَنْ عَادَيْتَ، تَبارَكْتَ رَبَّنا وَتَعَالَيْتَ',
        latin:
            'Allaahummahdinii fiiman hadait, wa \'aafinii fiiman \'aafait, wa tawallanii fiiman tawallait, wa baarik lii fiimaa a\'thait, wa qinii syarra maa qadhait, fa innaka taqdhii wa laa yuqdhaa \'alaik, innahuu laa yadzillu man waalait, wa laa ya\'izzu man \'aadait, tabaarakta rabbanaa wa ta\'aalait.',
        arti:
            'Ya Allah, berilah aku petunjuk bersama orang-orang yang Engkau beri petunjuk, berilah aku keselamatan bersama orang-orang yang Engkau beri keselamatan, uruslah aku bersama orang-orang yang Engkau urus, berkahilah apa yang Engkau berikan kepadaku, dan jagalah aku dari keburukan yang Engkau takdirkan. Sesungguhnya Engkaulah yang menetapkan dan tidak ada yang menetapkan atas-Mu. Tidak akan hina orang yang Engkau lindungi, dan tidak akan mulia orang yang Engkau musuhi. Mahaberkah Engkau wahai Tuhan kami dan Mahatinggi.',
        source: 'HR. Abu Dawud & At-Tirmidzi',
        repeat: 1,
      ),
      SholatVariant(
        label: 'Qunut Umar (Malikiyah)',
        madzhab: {Madzhab.maliki},
        arabic:
            'اللَّهُمَّ إِيَّاكَ نعْبُدُ، وَلَكَ نُصَلِّي وَنَسْجُدُ، وَإِلَيْكَ نَسْعَى وَنَحْفِدُ، نَرْجُو رَحْمَتَكَ، وَنَخْشَى عَذَابَكَ، إِنَّ عَذَابَكَ بِالكَافِرِينَ مُلْحَقٌ. اللَّهُمَّ إِنَّا نَسْتَعينُكَ، وَنَسْتَغْفِرُكَ، وَنُثْنِي عَلَيْكَ الْخَيْرَ، وَلاَ نَكْفُرُكَ، وَنُؤْمِنُ بِكَ، وَنَخْضَعُ لَكَ، وَنَخْلَعُ مَنْ يَكْفرُكَ',
        latin:
            'Allaahumma iyyaaka na\'budu, wa laka nushallii wa nasjudu, wa ilaika nas\'aa wa nahfidu, narjuu rahmataka wa nakhsyaa \'adzaabaka, inna \'adzaabaka bil kaafiriina mulhaq. Allaahumma innaa nasta\'iinuka wa nastaghfiruka, wa nutsnii \'alaikal khaira wa laa nakfuruka, wa nu\'minu bika wa nakhdha\'u laka, wa nakhla\'u man yakfuruk.',
        arti:
            'Ya Allah, hanya kepada-Mu kami menyembah, untuk-Mu kami sholat dan bersujud, kepada-Mu kami bersegera dan bergegas. Kami mengharap rahmat-Mu dan takut akan azab-Mu; sesungguhnya azab-Mu pasti menimpa orang-orang kafir. Ya Allah, kami memohon pertolongan dan ampunan-Mu, kami memuji-Mu dengan kebaikan dan tidak mengingkari-Mu, kami beriman kepada-Mu dan tunduk kepada-Mu, serta kami berlepas diri dari orang yang mengingkari-Mu.',
        source: 'Riwayat Umar bin Al-Khaththab (Al-Baihaqi)',
        repeat: 1,
      ),
    ],
  ),
];

/// Lafaz niat per sholat: [sendiri, makmum, imam].
const sholatNiat = <String, List<(String, String)>>{
  'subuh': [
    (
      'أُصَلِّي فَرْضَ الصُّبْحِ رَكْعَتَيْنِ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً لِلَّهِ تَعَالَى',
      'Ushallii fardhash shubhi rak\'ataini mustaqbilal qiblati adaa-an lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الصُّبْحِ رَكْعَتَيْنِ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً مَأْمُومًا لِلَّهِ تَعَالَى',
      'Ushallii fardhash shubhi rak\'ataini mustaqbilal qiblati adaa-an ma\'muuman lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الصُّبْحِ رَكْعَتَيْنِ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً إِمَامًا لِلَّهِ تَعَالَى',
      'Ushallii fardhash shubhi rak\'ataini mustaqbilal qiblati adaa-an imaaman lillaahi ta\'aalaa.',
    ),
  ],
  'dzuhur': [
    (
      'أُصَلِّي فَرْضَ الظُّهْرِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً لِلَّهِ تَعَالَى',
      'Ushallii fardhazh zhuhri arba\'a raka\'aatin mustaqbilal qiblati adaa-an lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الظُّهْرِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً مَأْمُومًا لِلَّهِ تَعَالَى',
      'Ushallii fardhazh zhuhri arba\'a raka\'aatin mustaqbilal qiblati adaa-an ma\'muuman lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الظُّهْرِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً إِمَامًا لِلَّهِ تَعَالَى',
      'Ushallii fardhazh zhuhri arba\'a raka\'aatin mustaqbilal qiblati adaa-an imaaman lillaahi ta\'aalaa.',
    ),
  ],
  'ashar': [
    (
      'أُصَلِّي فَرْضَ الْعَصْرِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً لِلَّهِ تَعَالَى',
      'Ushallii fardhal \'ashri arba\'a raka\'aatin mustaqbilal qiblati adaa-an lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الْعَصْرِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً مَأْمُومًا لِلَّهِ تَعَالَى',
      'Ushallii fardhal \'ashri arba\'a raka\'aatin mustaqbilal qiblati adaa-an ma\'muuman lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الْعَصْرِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً إِمَامًا لِلَّهِ تَعَالَى',
      'Ushallii fardhal \'ashri arba\'a raka\'aatin mustaqbilal qiblati adaa-an imaaman lillaahi ta\'aalaa.',
    ),
  ],
  'maghrib': [
    (
      'أُصَلِّي فَرْضَ الْمَغْرِبِ ثَلَاثَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً لِلَّهِ تَعَالَى',
      'Ushallii fardhal maghribi tsalaatsa raka\'aatin mustaqbilal qiblati adaa-an lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الْمَغْرِبِ ثَلَاثَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً مَأْمُومًا لِلَّهِ تَعَالَى',
      'Ushallii fardhal maghribi tsalaatsa raka\'aatin mustaqbilal qiblati adaa-an ma\'muuman lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الْمَغْرِبِ ثَلَاثَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً إِمَامًا لِلَّهِ تَعَالَى',
      'Ushallii fardhal maghribi tsalaatsa raka\'aatin mustaqbilal qiblati adaa-an imaaman lillaahi ta\'aalaa.',
    ),
  ],
  'isya': [
    (
      'أُصَلِّي فَرْضَ الْعِشَاءِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً لِلَّهِ تَعَالَى',
      'Ushallii fardhal \'isyaa-i arba\'a raka\'aatin mustaqbilal qiblati adaa-an lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الْعِشَاءِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً مَأْمُومًا لِلَّهِ تَعَالَى',
      'Ushallii fardhal \'isyaa-i arba\'a raka\'aatin mustaqbilal qiblati adaa-an ma\'muuman lillaahi ta\'aalaa.',
    ),
    (
      'أُصَلِّي فَرْضَ الْعِشَاءِ أَرْبَعَ رَكَعَاتٍ مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً إِمَامًا لِلَّهِ تَعَالَى',
      'Ushallii fardhal \'isyaa-i arba\'a raka\'aatin mustaqbilal qiblati adaa-an imaaman lillaahi ta\'aalaa.',
    ),
  ],
};
