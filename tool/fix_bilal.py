# Perbaikan salah ketik & terjemahan bacaan bilal tarawih - diterapkan ke
# database web Bilal Tarawih (IrmamStorage.sqlite) supaya web & aplikasi
# memakai teks yang sama:
#
#   python3 tool/fix_bilal.py /path/ke/IrmamStorage.sqlite
#   # lalu ekspor ulang tool/bilal_tarawih.json (lihat tool/gen_bilal.py)
#
# Kunci = id baris bilal_detail. Hanya kolom yang disebut yang diubah.
# Aman dijalankan berulang (nilai ditimpa, bukan ditambah).
import sqlite3
import sys

SUBHANA_MAWJUD = dict(
    arabic='سُبْحَانَ الْمَلِكِ الْمَوْجُوْدِ',
    latin='Subhaanal-malikil-maujuud',
    indo='Maha Suci Allah Yang Merajai (alam) lagi Maha Ada',
)
SUBHANA_MABUD = dict(
    indo='Maha Suci Allah Yang Merajai (alam) lagi Yang Disembah',
)
SUBHANA_HAYY = dict(
    arabic='سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لَا يَنَامُ وَلَا يَمُوْتُ '
           'وَلَا يَفُوْتُ اَبَدًا',
    indo='Maha Suci Allah Yang Merajai lagi Maha Hidup, Yang tidak tidur, '
         'tidak mati, dan tidak lenyap selama-lamanya',
)
SUBBUHUN = dict(
    arabic='سُبُّوْحٌ قُدُّوْسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوْحِ',
    latin='Subbuuhun Qudduusun Rabbunaa Wa Rabbul-Malaa-ikati War-Ruuh',
    indo='Maha Suci lagi Maha Kudus, Tuhan kami dan Tuhan para malaikat '
         'serta Ruh (malaikat Jibril)',
)
TASBIH = dict(
    arabic='سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا اِلَهَ اِلَّا اللَّهُ '
           'وَاللَّهُ اَكْبَرُ',
    indo='Maha Suci Allah, segala puji bagi Allah, tidak ada Tuhan selain '
         'Allah, dan Allah Maha Besar',
)
HAWQALAH = dict(
    arabic='وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيْمِ',
    latin="Wa Laa Haula Wa Laa Quwwata Illaa Billaahil-'Aliyyil-'Azhiim",
    indo='Dan tidak ada daya dan kekuatan kecuali dengan pertolongan Allah '
         'Yang Maha Tinggi lagi Maha Agung',
)
SHALAWAT_1 = dict(
    arabic='اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ',
    latin="Allaahumma Shalli 'Alaa Sayyidinaa Muhammad",
    indo='Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad',
)
SHALAWAT_2 = dict(
    arabic='اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَمَوْلَانَا مُحَمَّدٍ',
    latin="Allaahumma Shalli 'Alaa Sayyidinaa Wa Maulaanaa Muhammad",
    indo='Ya Allah, limpahkanlah rahmat kepada junjungan dan pemimpin kami '
         'Nabi Muhammad',
)
SHALAWAT_3 = dict(
    arabic='اَللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا وَنَبِيِّنَا وَحَبِيْبِنَا '
           'وَشَفِيْعِنَا وَذُخْرِنَا وَمَوْلَانَا مُحَمَّدٍ',
    latin="Allaahumma Shalli 'Alaa Sayyidinaa Wa Nabiyyinaa Wa Habiibinaa "
          "Wa Syafii'inaa Wa Dzukhrinaa Wa Maulaanaa Muhammad",
    indo='Ya Allah, limpahkanlah rahmat kepada junjungan kami, nabi kami, '
         'kekasih kami, pemberi syafaat kami, simpanan (pembela) kami, dan '
         'pemimpin kami Nabi Muhammad',
)
TARAWIH = dict(
    arabic='صَلَاةَ التَّرَاوِيْحِ رَحِمَكُمُ اللَّهُ',
    latin='Shalaatat-Taraawiihi Rahimakumullaah',
    indo='(Kerjakanlah) sholat tarawih, semoga Allah merahmati kalian',
)
FADHLAN = dict(
    latin="Fadhlan Minallaahi Wa Ni'matan Wa Maghfiratan Wa Rahmah",
    indo='(Semoga) karunia, nikmat, ampunan, dan rahmat dari Allah '
         'dilimpahkan kepada kita',
)
TAHLIL = dict(
    arabic='لَا اِلَهَ اِلَّا اللَّهُ وَحْدَهُ لَا شَرِيْكَ لَهُ',
    indo='Tidak ada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu '
         'bagi-Nya',
)
LAHUL_MULKU = dict(
    arabic='لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيِيْ وَيُمِيْتُ وَهُوَ عَلَى '
           'كُلِّ شَيْءٍ قَدِيْرٌ',
    latin="Lahul-Mulku Wa Lahul-Hamdu Yuhyii Wa Yumiitu Wa Huwa 'Alaa Kulli "
          "Syai-in Qadiir",
    indo='Milik-Nya segala kerajaan dan milik-Nya segala puji. Dia '
         'menghidupkan dan mematikan, dan Dia Maha Kuasa atas segala sesuatu',
)
BASMALAH = dict(
    arabic='بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيْمِ',
    latin='Bismillaahir-Rahmaanir-Rahiim',
    indo='Dengan menyebut nama Allah Yang Maha Pengasih lagi Maha Penyayang',
)
HAMDALAH = dict(
    arabic='وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِيْنَ',
    latin="Walhamdu Lillaahi Rabbil-'Aalamiin",
    indo='Dan segala puji bagi Allah, Tuhan semesta alam',
)
IGHFIR = dict(
    arabic='اَللَّهُمَّ اغْفِرْ لَنَا بِكَرَمِكَ أَجْمَعِيْنَ وَتُبْ وَزَكِّ '
           'وَاعْفُ عَمَّنْ يَقُوْلُ آمِيْنَ آمِيْنَ وَصَلَّى اللَّهُ وَسَلَّمَ '
           'عَلَيْهِ',
    latin="Allaahummaghfir Lanaa Bikaramika Ajma'iin, Wa Tub Wa Zakki Wa'fu "
          "'Amman Yaquulu Aamiin Aamiin, Wa Shallallaahu Wa Sallama 'Alaih",
    indo='Ya Allah, ampunilah kami semua dengan kemurahan-Mu, terimalah '
         'taubat, sucikanlah, dan maafkanlah orang yang mengucapkan aamiin, '
         'aamiin. Semoga Allah melimpahkan shalawat dan salam kepadanya '
         '(Nabi Muhammad)',
)
SUBHANA_QUDDUS = dict(
    arabic='سُبْحَانَ الْمَلِكِ الْقُدُّوْسِ',
    latin='Subhaanal-Malikil-Qudduus',
    indo='Maha Suci Allah, Raja Yang Maha Suci',
)
SYAHADAT_ISTIGHFAR = dict(
    arabic='أَشْهَدُ أَنْ لَا اِلَهَ اِلَّا اللَّهُ، أَسْتَغْفِرُ اللَّهَ، '
           'نَسْأَلُكَ الْجَنَّةَ وَنَعُوْذُ بِكَ مِنَ النَّارِ',
    latin="Asyhadu Allaa Ilaaha Illallaah, Astaghfirullaah, Nas-alukal "
          "Jannata Wa Na'uudzu Bika Minan-Naar",
    indo='Aku bersaksi bahwa tidak ada Tuhan selain Allah, aku memohon '
         'ampun kepada Allah. Kami memohon surga kepada-Mu dan berlindung '
         'kepada-Mu dari neraka',
)
AFUWWUN = dict(
    arabic='اَللَّهُمَّ اِنَّكَ عَفُوٌّ كَرِيْمٌ، تُحِبُّ الْعَفْوَ فَاعْفُ '
           'عَنَّا',
    latin="Allaahumma Innaka 'Afuwwun Kariim, Tuhibbul-'Afwa Fa'fu 'Annaa",
    indo='Ya Allah, sesungguhnya Engkau Maha Pemaaf lagi Maha Mulia, Engkau '
         'suka memaafkan, maka maafkanlah kami',
)
LAILAHA = 'لَا اِلَهَ اِلَّا اللَّهُ'

FIXES = {
    **{i: SUBHANA_MABUD for i in (1, 18, 38)},
    **{i: SUBHANA_MAWJUD for i in (2, 19, 39)},
    **{i: SUBHANA_HAYY for i in (3, 20, 40)},
    **{i: SUBBUHUN for i in (4, 21, 41, 60)},
    **{i: TASBIH for i in (5, 22, 42)},
    **{i: HAWQALAH for i in (6, 23, 43, 62)},
    **{i: SHALAWAT_1 for i in (7, 24, 44)},
    **{i: SHALAWAT_2 for i in (8, 25, 45)},
    **{i: SHALAWAT_3 for i in (9, 14, 26, 35, 46)},
    **{i: TARAWIH for i in (10, 17, 31, 37)},
    **{i: FADHLAN for i in (11, 32)},
    **{i: TAHLIL for i in (12, 33)},
    **{i: LAHUL_MULKU for i in (13, 34)},
    **{i: BASMALAH for i in (27, 47, 63)},
    **{i: HAMDALAH for i in (29, 52, 68)},
    **{i: IGHFIR for i in (51, 67)},
    **{i: SUBHANA_QUDDUS for i in (57, 58, 59)},
    **{i: SYAHADAT_ISTIGHFAR for i in (69, 70)},
    **{i: AFUWWUN for i in (72, 73)},
    15: dict(
        arabic='اَلْبَدْرُ الْمُنِيْرُ سَيِّدُنَا مُحَمَّدٌ صَلُّوْا عَلَيْهِ',
        latin="Al-Badrul-Muniiru Sayyidunaa Muhammadun, Shalluu 'Alaih",
        indo='Bulan purnama yang bersinar terang, junjungan kita Nabi '
             'Muhammad. Bershalawatlah kalian kepadanya',
    ),
    16: dict(
        arabic='اَلْخَلِيْفَةُ الْأُوْلَى أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا '
               'أَبُوْ بَكْرٍ الصِّدِّيْقُ',
        latin="Al-Khaliifatul-Uulaa Amiirul-Mu'miniina Sayyidunaa Abuu "
              'Bakrinish-Shiddiiq',
        indo="Khalifah pertama, Amirul Mu'minin, junjungan kita Abu Bakar "
             'Ash-Shiddiq',
    ),
    28: dict(
        arabic='اَللَّهُمَّ اجْعَلْنَا يَا مَوْلَانَا فِيْ شَهْرِنَا هَذَا '
               'وَفِيْ لَيْلَتِنَا هَذِهِ مِنْ عُتَقَائِكَ مِنَ النَّارِ '
               'أَجْمَعِيْنَ',
        latin="Allaahummaj'alnaa Yaa Maulaanaa Fii Syahrinaa Haadzaa Wa Fii "
              "Lailatinaa Haadzihii Min 'Utaqaa-ika Minan-Naari Ajma'iin",
        indo='Ya Allah, wahai Tuhan kami, jadikanlah kami semua pada bulan '
             'ini dan malam ini termasuk orang-orang yang Engkau bebaskan '
             'dari neraka',
    ),
    30: dict(
        arabic='اَلْخَلِيْفَةُ الثَّانِيَةُ أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا '
               'عُمَرُ بْنُ الْخَطَّابِ',
        latin="Al-Khaliifatuts-Tsaaniyatu Amiirul-Mu'miniina Sayyidunaa "
              "'Umarubnul-Khaththaab",
        indo="Khalifah kedua, Amirul Mu'minin, junjungan kita Umar bin "
             'Khaththab',
    ),
    36: dict(
        arabic='اَلْخَلِيْفَةُ الثَّالِثَةُ أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا '
               'عُثْمَانُ بْنُ عَفَّانَ',
        latin="Al-Khaliifatuts-Tsaalitsatu Amiirul-Mu'miniina Sayyidunaa "
              "'Utsmaanubnu 'Affaan",
        indo="Khalifah ketiga, Amirul Mu'minin, junjungan kita Utsman bin "
             'Affan',
    ),
    48: dict(
        latin='Syahru Ramadhaanal-ladzii Unzila Fiihil-Qur-aanu Hudal '
              'Linnaasi Wa Bayyinaatim Minal-Hudaa Wal-Furqaan',
        indo='Bulan Ramadhan adalah (bulan) yang di dalamnya diturunkan '
             'Al-Qur\'an sebagai petunjuk bagi manusia dan penjelasan-'
             'penjelasan mengenai petunjuk itu serta pembeda (antara yang '
             'benar dan yang batil). (QS. Al-Baqarah: 185)',
    ),
    49: dict(
        arabic='بِجُوْدِكَ آمِيْنَ وَبِامْتِنَانِكَ آمِيْنَ يَا خَيْرَ '
               'الْمَسْئُوْلِيْنَ يَا اَللَّهُ',
        latin='Bijuudika Aamiin, Wa Bimtinaanika Aamiin, Yaa Khairal-'
              "Mas-uuliin, Yaa Allaah",
        indo='Dengan kemurahan-Mu, kabulkanlah. Dengan karunia-Mu, '
             'kabulkanlah. Wahai sebaik-baik Dzat yang dimintai, ya Allah',
    ),
    50: dict(
        arabic='اَللَّهُمَّ أَعْتِقْ رِقَابَنَا وَرِقَابَ آبَائِنَا '
               'وَأُمَّهَاتِنَا وَأَوْلَادِنَا وَإِخْوَانِنَا وَالْمُسْلِمِيْنَ '
               'وَالْمُسْلِمَاتِ مِنَ النَّارِ أَجْمَعِيْنَ',
        latin="Allaahumma A'tiq Riqaabanaa Wa Riqaaba Aabaa-inaa Wa "
              'Ummahaatinaa Wa Aulaadinaa Wa Ikhwaaninaa Wal-Muslimiina '
              "Wal-Muslimaati Minan-Naari Ajma'iin",
        indo='Ya Allah, bebaskanlah diri kami, diri bapak-bapak kami, ibu-ibu '
             'kami, anak-anak kami, saudara-saudara kami, serta kaum '
             'muslimin dan muslimat dari neraka semuanya',
    ),
    53: dict(
        arabic='اَلْخَلِيْفَةُ الرَّابِعَةُ أَمِيْرُ الْمُؤْمِنِيْنَ سَيِّدُنَا '
               'عَلِيُّ بْنُ أَبِيْ طَالِبٍ',
        latin="Al-Khaliifatur-Raabi'atu Amiirul-Mu'miniina Sayyidunaa "
              "'Aliyyubnu Abii Thaalib",
        indo="Khalifah keempat, Amirul Mu'minin, junjungan kita Ali bin Abi "
             'Thalib',
    ),
    54: dict(
        arabic='رَضِيَ اللَّهُ عَنْهُ، وَعَنْ كُلِّ صَحَابَةِ رَسُوْلِ اللَّهِ '
               'أَجْمَعِيْنَ',
        latin="Radhiyallaahu 'Anhu, Wa 'An Kulli Shahaabati Rasuulillaahi "
              "Ajma'iin",
        indo='Semoga Allah meridhainya dan meridhai seluruh sahabat '
             'Rasulullah',
    ),
    55: dict(
        arabic='صَلَاةَ الْوِتْرِ أَثَابَكُمُ اللَّهُ',
        latin='Shalaatal-Witri Atsaabakumullaah',
        indo='(Kerjakanlah) sholat witir, semoga Allah memberi pahala kepada '
             'kalian',
    ),
    56: dict(
        arabic='صَلَاةَ الْوِتْرِ رَكْعَةً رَحِمَكُمُ اللَّهُ',
        latin="Shalaatal-Witri Rak'atan Rahimakumullaah",
        indo='(Kerjakanlah) sholat witir satu rakaat, semoga Allah merahmati '
             'kalian',
    ),
    61: dict(
        arabic=TASBIH['arabic'],
        latin='Subhaanallaahi Wal-Hamdu Lillaahi Wa Laa Ilaaha Illallaahu '
              'Wallaahu Akbar',
        indo=TASBIH['indo'],
    ),
    64: dict(
        arabic='رَبَّنَا آمَنَّا بِمَا أَنْزَلْتَ وَاتَّبَعْنَا الرَّسُوْلَ '
               'فَاكْتُبْنَا مَعَ الشَّاهِدِيْنَ',
        latin="Rabbanaa Aamannaa Bimaa Anzalta Wattaba'nar-Rasuula "
              "Faktubnaa Ma'asy-Syaahidiin",
        indo='Ya Tuhan kami, kami telah beriman kepada apa yang Engkau '
             'turunkan dan kami telah mengikuti Rasul, maka catatlah kami '
             'bersama orang-orang yang bersaksi. (QS. Ali \'Imran: 53)',
    ),
    65: dict(
        arabic='اَللَّهُمَّ يَا مُجِيْبَ السَّائِلِيْنَ، وَيَا قَابِلَ '
               'التَّائِبِيْنَ',
        latin="Allaahumma Yaa Mujiibas-Saa-iliin, Wa Yaa Qaabilat-Taa-ibiin",
        indo='Ya Allah, wahai Dzat yang mengabulkan permintaan orang-orang '
             'yang meminta, wahai Dzat yang menerima taubat orang-orang yang '
             'bertaubat',
    ),
    66: dict(
        arabic='وَيَا رَاحِمَ الضُّعَفَاءِ وَالْفُقَرَاءِ وَالْمَسَاكِيْنِ',
        latin="Wa Yaa Raahimadh-Dhu'afaa-i Wal-Fuqaraa-i Wal-Masaakiin",
        indo='Dan wahai Dzat yang mengasihi orang-orang lemah, fakir, dan '
             'miskin',
    ),
    71: dict(
        arabic='أَشْهَدُ أَنْ لَا اِلَهَ اِلَّا اللَّهُ، أَسْتَغْفِرُ اللَّهَ، '
               'نَسْأَلُكَ الْجَنَّةَ وَنَعُوْذُ بِكَ مِنْ سَخَطِكَ وَالنَّارِ',
        latin="Asyhadu Allaa Ilaaha Illallaah, Astaghfirullaah, Nas-alukal "
              "Jannata Wa Na'uudzu Bika Min Sakhathika Wan-Naar",
        indo='Aku bersaksi bahwa tidak ada Tuhan selain Allah, aku memohon '
             'ampun kepada Allah. Kami memohon surga kepada-Mu dan berlindung '
             'kepada-Mu dari murka-Mu dan dari neraka',
    ),
    74: dict(
        arabic=AFUWWUN['arabic'] + ' يَا كَرِيْمُ',
        latin=AFUWWUN['latin'] + ' Yaa Kariim',
        indo=AFUWWUN['indo'] + ', wahai Dzat Yang Maha Mulia',
    ),
    75: dict(
        arabic='اِنْوُوا الصِّيَامَ رَحِمَكُمُ اللَّهُ',
        latin='Inwush-Shiyaama Rahimakumullaah',
        indo='Berniatlah kalian untuk berpuasa, semoga Allah merahmati kalian',
    ),
    76: dict(
        arabic='نَوَيْتُ صَوْمَ غَدٍ عَنْ اَدَاءِ فَرْضِ شَهْرِ رَمَضَانَ '
               'هَذِهِ السَّنَةِ لِلَّهِ تَعَالَى',
        latin="Nawaitu Shauma Ghadin 'An Adaa-i Fardhi Syahri Ramadhaana "
              "Haadzihis-Sanati Lillaahi Ta'aalaa",
        indo='Aku berniat puasa esok hari untuk menunaikan kewajiban bulan '
             "Ramadhan tahun ini karena Allah Ta'ala",
    ),
    77: dict(indo='Ketahuilah bahwa dzikir yang paling utama adalah'),
    78: dict(arabic=f'{LAILAHA} (حَيٌّ مَوْجُوْدٌ)'),
    79: dict(arabic=f'{LAILAHA} (حَيٌّ مَعْبُوْدٌ)'),
    80: dict(arabic=f'{LAILAHA} (حَيٌّ بَاقٍ)'),
    81: dict(arabic=f'{LAILAHA} (33×)'),
    82: dict(
        arabic='لَا اِلَهَ اِلَّا اللَّهُ مُحَمَّدٌ رَسُوْلُ اللَّهِ صَلَّى '
               'اللَّهُ عَلَيْهِ وَسَلَّمَ، كَلِمَةُ حَقٍّ عَلَيْهَا نَحْيَا '
               'وَعَلَيْهَا نَمُوْتُ وَبِهَا نُبْعَثُ اِنْ شَاءَ اللَّهُ مِنَ '
               'الْآمِنِيْنَ',
        latin='Laa Ilaaha Illallaahu Muhammadur-Rasuulullaahi '
              "Shallallaahu 'Alaihi Wa Sallam, Kalimatu Haqqin 'Alaihaa "
              "Nahyaa Wa 'Alaihaa Namuutu Wa Bihaa Nub'atsu Insyaa-allaahu "
              "Minal-Aaminiin",
        indo='Tidak ada Tuhan selain Allah, Muhammad utusan Allah, semoga '
             'Allah melimpahkan shalawat dan salam kepadanya. (Itulah) '
             'kalimat yang benar; di atasnya kami hidup, di atasnya kami '
             'mati, dan dengannya kami dibangkitkan, insya Allah termasuk '
             'orang-orang yang aman',
    ),
}

if __name__ == '__main__':
    db = sqlite3.connect(sys.argv[1])
    ids = {r[0] for r in db.execute('SELECT id FROM bilal_detail')}
    assert set(FIXES) <= ids, set(FIXES) - ids
    for rid, cols in sorted(FIXES.items()):
        sets = ', '.join(f'{c} = ?' for c in cols)
        db.execute(f'UPDATE bilal_detail SET {sets} WHERE id = ?',
                   [*cols.values(), rid])
    db.commit()
    print('diperbaiki', len(FIXES), 'baris')
