"""Membuat lib/data/dzikir_sholat_data.dart - dzikir & doa setelah sholat
wajib: urutan bacaan yang lazim di masjid Indonesia (istighfar, tahlil,
Allahumma ajirni, antas salam, Al-Fatihah, Ayat Kursi, tasbih-tahmid-takbir,
lalu doa), doa lain yang sering dibaca imam, dan dzikir sunnah Hisnul Muslim
lainnya (pilihan). Semua ayat diambil dari assets/quran/quran.json (Mushaf
Standar Indonesia) supaya sama persis dengan mushaf di aplikasi.

    python3 tool/gen_dzikir_sholat.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
Q = json.loads((ROOT / "assets/quran/quran.json").read_text())
counts = [s[4] for s in Q["surah"]]


def ayah(surah, n):
    return Q["ayah"][sum(counts[: surah - 1]) + n - 1][0].strip()


def surah_text(s):
    body = " ۝ ".join(ayah(s, n) for n in range(1, counts[s - 1] + 1))
    return f"بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿{body}﴾"


TAHLIL = (
    "لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ "
    "وَلَهُ الْحَمْدُ وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ"
)
TAHLIL_LATIN = (
    "Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul "
    "hamdu wa huwa 'alaa kulli syai-in qadiir"
)
TAHLIL_ARTI = (
    "Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. Milik-Nya "
    "kerajaan dan milik-Nya pujian, dan Dia Mahakuasa atas segala sesuatu"
)


def tr(surah, n):
    return Q["ayah"][sum(counts[: surah - 1]) + n - 1][1].strip()


def clean(t):
    """Tanpa tanda ruku' (ࣖ) di ujung ayat."""
    return t.replace("ࣖ", "").strip()


def bare(word):
    """Huruf dasar saja (tanpa harakat & tanda waqaf) untuk mencocokkan."""
    import unicodedata

    return "".join(
        c
        for c in unicodedata.normalize("NFD", word)
        if not unicodedata.category(c).startswith("M")
    ).replace("ٰ", "").replace("ـ", "")


def part(surah, n, start):
    """Potongan ayat mulai dari kata-kata [start] sampai akhir ayat
    (dicocokkan tanpa harakat, karena urutan harakat di mushaf berbeda)."""
    words = clean(ayah(surah, n)).split(" ")
    want = [bare(w) for w in start.split(" ")]
    for k in range(len(words)):
        if [bare(w) for w in words[k : k + len(want)]] == want:
            return " ".join(words[k:]).strip()
    raise ValueError(f"{start} tidak ditemukan di {surah}:{n}")


TRADISI = "Bacaan yang lazim dibaca imam di masjid-masjid Indonesia"
D, DOA, IMAM, SUNNAH = (
    "Dzikir",
    "Doa setelah sholat",
    "Doa lain yang sering dibaca imam",
    "Dzikir sunnah lainnya",
)

items = [
    # ---------------- dzikir (urutan bacaan di masjid) ----------------
    dict(
        id=101,
        group=D,
        title="Istighfar",
        repeat=3,
        time="sholat",
        arabic="أَسْتَغْفِرُ اللّٰهَ الْعَظِيْمَ الَّذِيْ لَا إِلٰهَ إِلَّا هُوَ "
        "الْحَيُّ الْقَيُّوْمُ وَأَتُوْبُ إِلَيْهِ",
        latin="Astaghfirullaahal 'azhiim, alladzii laa ilaaha illaa huwal "
        "hayyul qayyuumu wa atuubu ilaih.",
        arti="Aku memohon ampun kepada Allah Yang Mahaagung, yang tiada tuhan "
        "selain Dia, Yang Mahahidup lagi terus-menerus mengurus (makhluk-Nya), "
        "dan aku bertobat kepada-Nya.",
        note="Dibaca segera setelah salam. Nabi ﷺ beristighfar tiga kali "
        "setiap selesai sholat.",
        source="Istighfar 3× setelah salam: HR. Muslim no. 591. Lafaz ini: "
        "HR. Abu Daud no. 1517 & At-Tirmidzi no. 3577",
    ),
    dict(
        id=102,
        group=D,
        title="Tahlil",
        repeat=1,
        time="sholat",
        arabic="لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ "
        "الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِيْ وَيُمِيْتُ، وَهُوَ عَلٰى كُلِّ "
        "شَيْءٍ قَدِيْرٌ",
        latin="Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku "
        "wa lahul hamdu, yuhyii wa yumiit, wa huwa 'alaa kulli syai-in "
        "qadiir.",
        arti="Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. "
        "Milik-Nya kerajaan dan pujian, Dia menghidupkan dan mematikan, dan "
        "Dia Mahakuasa atas segala sesuatu.",
        note="Setelah Subuh & Maghrib dianjurkan 10×.",
        source="HR. At-Tirmidzi no. 3474 (hasan)",
    ),
    dict(
        id=103,
        group=D,
        title="Mohon perlindungan dari neraka",
        repeat=3,
        time="sholat",
        arabic="اَللّٰهُمَّ أَجِرْنِيْ مِنَ النَّارِ",
        latin="Allaahumma ajirnii minan naar.",
        arti="Ya Allah, lindungilah aku dari api neraka.",
        note="Riwayatnya menyebut 7× setelah Subuh & Maghrib; di masjid "
        "umumnya dibaca 3×.",
        source="HR. Abu Daud no. 5079 (sanadnya diperselisihkan)",
    ),
    dict(
        id=104,
        group=D,
        title="Allaahumma antas salaam",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، وَإِلَيْكَ "
        "يَعُوْدُ السَّلَامُ، فَحَيِّنَا رَبَّنَا بِالسَّلَامِ، وَأَدْخِلْنَا "
        "الْجَنَّةَ دَارَ السَّلَامِ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ يَا "
        "ذَا الْجَلَالِ وَالْإِكْرَامِ",
        latin="Allaahumma antas salaam, wa minkas salaam, wa ilaika ya'uudus "
        "salaam, fahayyinaa rabbanaa bis salaam, wa adkhilnal jannata daaras "
        "salaam, tabaarakta rabbanaa wa ta'aalaita yaa dzal jalaali wal "
        "ikraam.",
        arti="Ya Allah, Engkaulah As-Salaam (Yang Maha Sejahtera), dari-Mu "
        "segala kesejahteraan, dan kepada-Mu kembali segala kesejahteraan. "
        "Hidupkanlah kami, ya Tuhan kami, dengan sejahtera, dan masukkanlah "
        "kami ke surga, negeri kesejahteraan. Mahaberkah Engkau, ya Tuhan "
        "kami, dan Mahatinggi, wahai Pemilik keagungan dan kemuliaan.",
        note="Inti doa (Allaahumma antas salaam wa minkas salaam, tabaarakta "
        "yaa dzal jalaali wal ikraam) dari hadits; kalimat di antaranya adalah "
        "tambahan yang masyhur dibaca.",
        source="Inti doa: HR. Muslim no. 591",
    ),
    dict(
        id=105,
        group=D,
        title="Al-Fatihah",
        repeat=1,
        time="sholat",
        arabic=surah_text(1).replace("بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿", "﴿", 1),
        latin="Bismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil "
        "'aalamiin. Ar-rahmaanir rahiim. Maaliki yaumid diin. Iyyaaka "
        "na'budu wa iyyaaka nasta'iin. Ihdinash shiraathal mustaqiim. "
        "Shiraathal ladziina an'amta 'alaihim ghairil maghdhuubi 'alaihim "
        "wa ladh-dhaalliin.",
        arti=" ".join(tr(1, n) for n in range(1, 8)),
        note="Dibaca sebelum Ayat Kursi, sebagaimana kebiasaan di masjid.",
        source=TRADISI + " (QS. Al-Fatihah: 1-7)",
    ),
    dict(
        id=106,
        group=D,
        title="Ayat Kursi",
        repeat=1,
        time="sholat",
        arabic="أَعُوْذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيْمِ ﴿"
        + ayah(2, 255)
        + "﴾",
        latin="A'uudzu billaahi minasy syaithaanir rajiim. Allaahu laa "
        "ilaaha illaa huwal hayyul qayyuum, laa ta'khudzuhuu sinatuw wa laa "
        "naum, lahuu maa fis samaawaati wa maa fil ardh, man dzal ladzii "
        "yasyfa'u 'indahuu illaa bi-idznih, ya'lamu maa baina aidiihim wa "
        "maa khalfahum, wa laa yuhiithuuna bisyai-im min 'ilmihii illaa "
        "bimaa syaa', wasi'a kursiyyuhus samaawaati wal ardh, wa laa "
        "ya-uuduhuu hifzhuhumaa, wa huwal 'aliyyul 'azhiim.",
        arti=tr(2, 255),
        note="Tidak ada yang menghalanginya masuk surga kecuali kematian.",
        source="HR. An-Nasa'i (As-Sunan Al-Kubra), dishahihkan Al-Albani",
    ),
    dict(
        id=107,
        group=D,
        title="Tasbih",
        repeat=33,
        time="sholat",
        arabic="سُبْحَانَ اللّٰهِ",
        latin="Subhaanallaah",
        arti="Mahasuci Allah",
        note=None,
        source="HR. Muslim no. 597",
    ),
    dict(
        id=108,
        group=D,
        title="Tahmid",
        repeat=33,
        time="sholat",
        arabic="اَلْحَمْدُ لِلّٰهِ",
        latin="Alhamdulillaah",
        arti="Segala puji bagi Allah",
        note=None,
        source="HR. Muslim no. 597",
    ),
    dict(
        id=109,
        group=D,
        title="Takbir",
        repeat=33,
        time="sholat",
        arabic="اَللّٰهُ أَكْبَرُ",
        latin="Allaahu akbar",
        arti="Allah Mahabesar",
        note=None,
        source="HR. Muslim no. 597",
    ),
    dict(
        id=110,
        group=D,
        title="Tahlil penutup (genap 100)",
        repeat=1,
        time="sholat",
        arabic=TAHLIL,
        latin=TAHLIL_LATIN + ".",
        arti=TAHLIL_ARTI + ".",
        note="Menggenapkan seratus - diampuni kesalahannya walau sebanyak buih "
        "di lautan. Di sebagian masjid dilanjutkan dengan laa ilaaha "
        "illallaah berulang kali.",
        source="HR. Muslim no. 597",
    ),
    # ---------------- doa setelah sholat (dibaca imam) ----------------
    dict(
        id=121,
        group=DOA,
        title="Pembuka doa: hamdalah",
        repeat=1,
        time="sholat",
        arabic="بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ. اَلْحَمْدُ لِلّٰهِ رَبِّ "
        "الْعَالَمِيْنَ، حَمْدًا يُوَافِيْ نِعَمَهُ وَيُكَافِئُ مَزِيْدَهُ، يَا "
        "رَبَّنَا لَكَ الْحَمْدُ كَمَا يَنْبَغِيْ لِجَلَالِ وَجْهِكَ "
        "وَعَظِيْمِ سُلْطَانِكَ",
        latin="Bismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil "
        "'aalamiin, hamdan yuwaafii ni'amahuu wa yukaafi-u maziidah, yaa "
        "rabbanaa lakal hamdu kamaa yambaghii lijalaali wajhika wa 'azhiimi "
        "sulthaanik.",
        arti="Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Segala "
        "puji bagi Allah, Tuhan seluruh alam, pujian yang sebanding dengan "
        "nikmat-Nya dan mencukupi tambahan-Nya. Ya Tuhan kami, bagi-Mu segala "
        "puji sebagaimana layak bagi keagungan wajah-Mu dan kebesaran "
        "kekuasaan-Mu.",
        note=None,
        source=TRADISI,
    ),
    dict(
        id=122,
        group=DOA,
        title="Shalawat",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى آلِ "
        "سَيِّدِنَا مُحَمَّدٍ",
        latin="Allaahumma shalli 'alaa sayyidinaa Muhammad, wa 'alaa aali "
        "sayyidinaa Muhammad.",
        arti="Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi "
        "Muhammad dan keluarga junjungan kami Nabi Muhammad.",
        note="Doa dibuka dengan pujian kepada Allah lalu shalawat.",
        source="Perintah bershalawat: QS. Al-Ahzab: 56",
    ),
    dict(
        id=123,
        group=DOA,
        title="Mohon diterima ibadah",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ رَبَّنَا تَقَبَّلْ مِنَّا صَلَاتَنَا وَصِيَامَنَا "
        "وَرُكُوْعَنَا وَسُجُوْدَنَا وَقُعُوْدَنَا وَتَضَرُّعَنَا وَتَخَشُّعَنَا "
        "وَتَعَبُّدَنَا، وَتَمِّمْ تَقْصِيْرَنَا يَا اَللّٰهُ يَا رَبَّ "
        "الْعَالَمِيْنَ",
        latin="Allaahumma rabbanaa taqabbal minnaa shalaatanaa wa "
        "shiyaamanaa wa rukuu'anaa wa sujuudanaa wa qu'uudanaa wa "
        "tadharru'anaa wa takhasysyu'anaa wa ta'abbudanaa, wa tammim "
        "taqshiiranaa yaa Allaah yaa rabbal 'aalamiin.",
        arti="Ya Allah, Tuhan kami, terimalah dari kami sholat kami, puasa "
        "kami, rukuk kami, sujud kami, duduk kami, kerendahan hati kami, "
        "kekhusyukan kami, dan ibadah kami, serta sempurnakanlah kekurangan "
        "kami, ya Allah, wahai Tuhan seluruh alam.",
        note=None,
        source=TRADISI,
    ),
    dict(
        id=124,
        group=DOA,
        title="Rabbanaa zhalamnaa",
        repeat=1,
        time="sholat",
        arabic=part(7, 23, "رَبَّنَا"),
        latin="Rabbanaa zhalamnaa anfusanaa wa illam taghfir lanaa wa "
        "tarhamnaa lanakuunanna minal khaasiriin.",
        arti="Ya Tuhan kami, kami telah menzalimi diri kami sendiri. Jika "
        "Engkau tidak mengampuni kami dan memberi rahmat kepada kami, niscaya "
        "kami termasuk orang-orang yang rugi.",
        note=None,
        source="QS. Al-A'raf: 23",
    ),
    dict(
        id=125,
        group=DOA,
        title="Rabbanaa wa laa tahmil",
        repeat=1,
        time="sholat",
        arabic=part(2, 286, "رَبَّنَا وَلَا تَحْمِلْ"),
        latin="Rabbanaa wa laa tahmil 'alainaa ishran kamaa hamaltahuu "
        "'alalladziina min qablinaa, rabbanaa wa laa tuhammilnaa maa laa "
        "thaaqata lanaa bih, wa'fu 'annaa, waghfir lanaa, warhamnaa, anta "
        "maulaanaa fanshurnaa 'alal qaumil kaafiriin.",
        arti="Ya Tuhan kami, janganlah Engkau bebani kami dengan beban yang "
        "berat sebagaimana Engkau bebankan kepada orang-orang sebelum kami. "
        "Ya Tuhan kami, janganlah Engkau pikulkan kepada kami apa yang tidak "
        "sanggup kami memikulnya. Maafkanlah kami, ampunilah kami, dan "
        "rahmatilah kami. Engkaulah pelindung kami, maka tolonglah kami "
        "menghadapi orang-orang kafir.",
        note=None,
        source="QS. Al-Baqarah: 286",
    ),
    dict(
        id=126,
        group=DOA,
        title="Rabbanaa laa tuzigh quluubanaa",
        repeat=1,
        time="sholat",
        arabic=clean(ayah(3, 8)),
        latin="Rabbanaa laa tuzigh quluubanaa ba'da idz hadaitanaa wa hab "
        "lanaa min ladunka rahmah, innaka antal wahhaab.",
        arti="Ya Tuhan kami, janganlah Engkau condongkan hati kami kepada "
        "kesesatan setelah Engkau berikan petunjuk kepada kami, dan "
        "karuniakanlah kepada kami rahmat dari sisi-Mu, sesungguhnya Engkau "
        "Maha Pemberi.",
        note=None,
        source="QS. Ali 'Imran: 8",
    ),
    dict(
        id=127,
        group=DOA,
        title="Ampunan untuk orang tua & kaum muslimin",
        repeat=1,
        time="sholat",
        arabic="رَبَّنَا اغْفِرْ لَنَا وَلِوَالِدِيْنَا وَلِجَمِيْعِ "
        "الْمُسْلِمِيْنَ وَالْمُسْلِمَاتِ وَالْمُؤْمِنِيْنَ وَالْمُؤْمِنَاتِ، "
        "اَلْأَحْيَاءِ مِنْهُمْ وَالْأَمْوَاتِ، إِنَّكَ عَلٰى كُلِّ شَيْءٍ "
        "قَدِيْرٌ",
        latin="Rabbanaghfir lanaa wa liwaalidiinaa wa lijamii'il muslimiina "
        "wal muslimaat, wal mu'miniina wal mu'minaat, al-ahyaa-i minhum wal "
        "amwaat, innaka 'alaa kulli syai-in qadiir.",
        arti="Ya Tuhan kami, ampunilah kami, kedua orang tua kami, dan semua "
        "muslimin dan muslimat, mukminin dan mukminat, yang masih hidup "
        "maupun yang telah wafat. Sesungguhnya Engkau Mahakuasa atas segala "
        "sesuatu.",
        note="Senada dengan doa Nabi Ibrahim (QS. Ibrahim: 41) dan Nabi Nuh "
        "(QS. Nuh: 28).",
        source=TRADISI,
    ),
    dict(
        id=128,
        group=DOA,
        title="Doa sapu jagat",
        repeat=1,
        time="sholat",
        arabic=part(2, 201, "رَبَّنَآ"),
        latin="Rabbanaa aatinaa fid dunyaa hasanah, wa fil aakhirati "
        "hasanah, wa qinaa 'adzaaban naar.",
        arti="Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di "
        "akhirat, dan lindungilah kami dari azab neraka.",
        note="Doa yang paling sering dibaca Nabi ﷺ.",
        source="QS. Al-Baqarah: 201; HR. Bukhari no. 6389 & Muslim no. 2690",
    ),
    dict(
        id=129,
        group=DOA,
        title="Mohon ampunan & husnul khatimah",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ اغْفِرْ لَنَا ذُنُوْبَنَا، وَكَفِّرْ عَنَّا "
        "سَيِّئَاتِنَا، وَتَوَفَّنَا مَعَ الْأَبْرَارِ",
        latin="Allaahummaghfir lanaa dzunuubanaa, wa kaffir 'annaa "
        "sayyi-aatinaa, wa tawaffanaa ma'al abraar.",
        arti="Ya Allah, ampunilah dosa-dosa kami, hapuskanlah kesalahan-"
        "kesalahan kami, dan wafatkanlah kami bersama orang-orang yang "
        "berbakti.",
        note=None,
        source="Diambil dari QS. Ali 'Imran: 193",
    ),
    dict(
        id=130,
        group=DOA,
        title="Penutup: Subhaana rabbika",
        repeat=1,
        time="sholat",
        arabic=" ".join(clean(ayah(37, n)) for n in (180, 181, 182)),
        latin="Subhaana rabbika rabbil 'izzati 'ammaa yashifuun, wa "
        "salaamun 'alal mursaliin, wal hamdu lillaahi rabbil 'aalamiin.",
        arti=" ".join(tr(37, n) for n in (180, 181, 182)),
        note=None,
        source="QS. Ash-Shaffat: 180-182",
    ),
    # ---------- doa lain yang sering dibaca imam (pilihan) ----------
    dict(
        id=141,
        group=IMAM,
        title="Doa keselamatan",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ إِنَّا نَسْأَلُكَ سَلَامَةً فِي الدِّيْنِ، "
        "وَعَافِيَةً فِي الْجَسَدِ، وَزِيَادَةً فِي الْعِلْمِ، وَبَرَكَةً فِي "
        "الرِّزْقِ، وَتَوْبَةً قَبْلَ الْمَوْتِ، وَرَحْمَةً عِنْدَ الْمَوْتِ، "
        "وَمَغْفِرَةً بَعْدَ الْمَوْتِ. اَللّٰهُمَّ هَوِّنْ عَلَيْنَا فِيْ "
        "سَكَرَاتِ الْمَوْتِ، وَالنَّجَاةَ مِنَ النَّارِ، وَالْعَفْوَ عِنْدَ "
        "الْحِسَابِ",
        latin="Allaahumma innaa nas-aluka salaamatan fid diin, wa "
        "'aafiyatan fil jasad, wa ziyaadatan fil 'ilm, wa barakatan fir "
        "rizq, wa taubatan qablal maut, wa rahmatan 'indal maut, wa "
        "maghfiratan ba'dal maut. Allaahumma hawwin 'alainaa fii sakaraatil "
        "maut, wan najaata minan naar, wal 'afwa 'indal hisaab.",
        arti="Ya Allah, kami memohon kepada-Mu keselamatan dalam agama, "
        "kesehatan badan, tambahan ilmu, keberkahan rezeki, tobat sebelum "
        "mati, rahmat ketika mati, dan ampunan sesudah mati. Ya Allah, "
        "mudahkanlah kami dalam sakaratul maut, (berilah) keselamatan dari "
        "neraka dan ampunan ketika hisab.",
        note=None,
        source=TRADISI,
    ),
    dict(
        id=142,
        group=IMAM,
        title="Petunjuk, takwa, iffah & kecukupan",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ الْهُدٰى وَالتُّقٰى "
        "وَالْعَفَافَ وَالْغِنٰى",
        latin="Allaahumma innii as-alukal hudaa wat tuqaa wal 'afaafa wal "
        "ghinaa.",
        arti="Ya Allah, aku memohon kepada-Mu petunjuk, ketakwaan, "
        "terjaganya diri (dari yang haram), dan kecukupan.",
        note=None,
        source="HR. Muslim no. 2721",
    ),
    dict(
        id=143,
        group=IMAM,
        title="Perbaikan agama, dunia & akhirat",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ أَصْلِحْ لِيْ دِيْنِيَ الَّذِيْ هُوَ عِصْمَةُ "
        "أَمْرِيْ، وَأَصْلِحْ لِيْ دُنْيَايَ الَّتِيْ فِيْهَا مَعَاشِيْ، "
        "وَأَصْلِحْ لِيْ آخِرَتِي الَّتِيْ فِيْهَا مَعَادِيْ، وَاجْعَلِ "
        "الْحَيَاةَ زِيَادَةً لِيْ فِيْ كُلِّ خَيْرٍ، وَاجْعَلِ الْمَوْتَ "
        "رَاحَةً لِيْ مِنْ كُلِّ شَرٍّ",
        latin="Allaahumma ashlih lii diiniyalladzii huwa 'ishmatu amrii, wa "
        "ashlih lii dunyaayallatii fiihaa ma'aasyii, wa ashlih lii "
        "aakhiratiyallatii fiihaa ma'aadii, waj'alil hayaata ziyaadatan lii "
        "fii kulli khair, waj'alil mauta raahatan lii min kulli syarr.",
        arti="Ya Allah, perbaikilah agamaku yang menjadi penjaga urusanku, "
        "perbaikilah duniaku tempat hidupku, dan perbaikilah akhiratku tempat "
        "kembaliku. Jadikanlah hidup ini tambahan bagiku dalam setiap "
        "kebaikan, dan jadikanlah kematian sebagai istirahat bagiku dari "
        "setiap keburukan.",
        note=None,
        source="HR. Muslim no. 2720",
    ),
    dict(
        id=144,
        group=IMAM,
        title="Ya muqallibal quluub",
        repeat=1,
        time="sholat",
        arabic="يَا مُقَلِّبَ الْقُلُوْبِ ثَبِّتْ قَلْبِيْ عَلٰى دِيْنِكَ",
        latin="Yaa muqallibal quluub, tsabbit qalbii 'alaa diinik.",
        arti="Wahai Zat yang membolak-balikkan hati, teguhkanlah hatiku di "
        "atas agama-Mu.",
        note=None,
        source="HR. At-Tirmidzi no. 2140",
    ),
    dict(
        id=145,
        group=IMAM,
        title="Rabbij'alnii muqiimash shalaah",
        repeat=1,
        time="sholat",
        arabic=clean(ayah(14, 40)) + " " + clean(ayah(14, 41)),
        latin="Rabbij'alnii muqiimash shalaati wa min dzurriyyatii, "
        "rabbanaa wa taqabbal du'aa'. Rabbanaghfir lii wa liwaalidayya wa "
        "lil mu'miniina yauma yaquumul hisaab.",
        arti="Ya Tuhanku, jadikanlah aku dan anak cucuku orang yang tetap "
        "melaksanakan sholat. Ya Tuhan kami, perkenankanlah doaku. Ya Tuhan "
        "kami, ampunilah aku, kedua ibu bapakku, dan semua orang yang beriman "
        "pada hari diadakan perhitungan (hari Kiamat).",
        note=None,
        source="QS. Ibrahim: 40-41",
    ),
    dict(
        id=146,
        group=IMAM,
        title="Keluarga penyejuk hati",
        repeat=1,
        time="sholat",
        arabic=part(25, 74, "رَبَّنَا"),
        latin="Rabbanaa hab lanaa min azwaajinaa wa dzurriyyaatinaa qurrata "
        "a'yun, waj'alnaa lil muttaqiina imaamaa.",
        arti="Ya Tuhan kami, anugerahkanlah kepada kami pasangan kami dan "
        "keturunan kami sebagai penyenang hati (kami), dan jadikanlah kami "
        "pemimpin bagi orang-orang yang bertakwa.",
        note=None,
        source="QS. Al-Furqan: 74",
    ),
    dict(
        id=147,
        group=IMAM,
        title="Ampunan untuk saudara seiman",
        repeat=1,
        time="sholat",
        arabic=part(59, 10, "رَبَّنَا اغْفِرْ"),
        latin="Rabbanaghfir lanaa wa li-ikhwaaninalladziina sabaquunaa bil "
        "iimaan, wa laa taj'al fii quluubinaa ghillal lilladziina aamanuu, "
        "rabbanaa innaka ra-uufur rahiim.",
        arti="Ya Tuhan kami, ampunilah kami dan saudara-saudara kami yang "
        "telah beriman lebih dahulu dari kami, dan janganlah Engkau tanamkan "
        "kedengkian dalam hati kami terhadap orang-orang yang beriman. Ya "
        "Tuhan kami, sungguh Engkau Maha Penyantun, Maha Penyayang.",
        note=None,
        source="QS. Al-Hasyr: 10",
    ),
    dict(
        id=148,
        group=IMAM,
        title="Penutup: Rabbanaa taqabbal minnaa",
        repeat=1,
        time="sholat",
        arabic=part(2, 127, "رَبَّنَا تَقَبَّلْ") + " "
        + part(2, 128, "وَتُبْ عَلَيْنَا"),
        latin="Rabbanaa taqabbal minnaa innaka antas samii'ul 'aliim, wa "
        "tub 'alainaa innaka antat tawwaabur rahiim.",
        arti="Ya Tuhan kami, terimalah (amal) dari kami. Sungguh, Engkaulah "
        "Yang Maha Mendengar, Maha Mengetahui. Dan terimalah tobat kami. "
        "Sungguh, Engkaulah Yang Maha Penerima tobat, Maha Penyayang.",
        note="Sering dibaca imam sebelum menutup doa dengan Subhaana "
        "rabbika.",
        source="QS. Al-Baqarah: 127-128",
    ),
    # ---------- dzikir sunnah lainnya (Hisnul Muslim, pilihan) ----------
    dict(
        group=SUNNAH,
        id=67,
        title="Laa maani'a limaa a'thaita",
        repeat=1,
        time="sholat",
        arabic=TAHLIL + ". اَللّٰهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا "
        "مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ",
        latin=TAHLIL_LATIN + ". Allaahumma laa maani'a limaa a'thaita, wa laa "
        "mu'thiya limaa mana'ta, wa laa yanfa'u dzal jaddi minkal jadd.",
        arti=TAHLIL_ARTI + ". Ya Allah, tidak ada yang dapat menghalangi apa "
        "yang Engkau berikan, tidak ada yang dapat memberi apa yang Engkau "
        "halangi, dan tidak berguna kekayaan pemiliknya di hadapan-Mu.",
        note=None,
        source="HR. Bukhari no. 844 & Muslim no. 593",
    ),
    dict(
        group=SUNNAH,
        id=68,
        title="Laa haula wa laa quwwata illaa billaah",
        repeat=1,
        time="sholat",
        arabic=TAHLIL + "، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ، لَا "
        "إِلٰهَ إِلَّا اللّٰهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ "
        "النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلٰهَ "
        "إِلَّا اللّٰهُ مُخْلِصِيْنَ لَهُ الدِّيْنَ وَلَوْ كَرِهَ الْكَافِرُوْنَ",
        latin=TAHLIL_LATIN + ", laa haula wa laa quwwata illaa billaah, laa "
        "ilaaha illallaah, wa laa na'budu illaa iyyaah, lahun ni'matu wa "
        "lahul fadhlu wa lahuts tsanaa-ul hasan, laa ilaaha illallaahu "
        "mukhlishiina lahud diin walau karihal kaafiruun.",
        arti=TAHLIL_ARTI + ". Tidak ada daya dan kekuatan kecuali dengan "
        "(pertolongan) Allah. Tidak ada tuhan selain Allah, dan kami tidak "
        "menyembah selain kepada-Nya. Milik-Nya segala nikmat, karunia, dan "
        "pujian yang baik. Tidak ada tuhan selain Allah, dengan memurnikan "
        "agama hanya bagi-Nya, meskipun orang-orang kafir membenci.",
        note=None,
        source="HR. Muslim no. 594",
    ),
    dict(
        group=SUNNAH,
        id=71,
        title="Al-Ikhlas, Al-Falaq & An-Nas",
        repeat=1,
        time="sholat",
        arabic="\n".join(surah_text(s) for s in (112, 113, 114)),
        latin="Qul huwallaahu ahad. Allaahush shamad. Lam yalid wa lam "
        "yuulad. Wa lam yakul lahuu kufuwan ahad.\nQul a'uudzu birabbil "
        "falaq. Min syarri maa khalaq. Wa min syarri ghaasiqin idzaa waqab. "
        "Wa min syarrin naffaatsaati fil 'uqad. Wa min syarri haasidin idzaa "
        "hasad.\nQul a'uudzu birabbin naas. Malikin naas. Ilaahin naas. Min "
        "syarril waswaasil khannaas. Alladzii yuwaswisu fii shuduurin naas. "
        "Minal jinnati wan naas.",
        arti="\n".join(
            " ".join(
                Q["ayah"][sum(counts[: s - 1]) + n][1].strip()
                for n in range(counts[s - 1])
            )
            for s in (112, 113, 114)
        ),
        note="Setelah Subuh & Maghrib dianjurkan masing-masing 3×.",
        source="HR. Abu Daud no. 1523 & At-Tirmidzi no. 2903",
    ),
    dict(
        group=SUNNAH,
        id=72,
        title="Allaahumma a'innii",
        repeat=1,
        time="sholat",
        arabic="اَللّٰهُمَّ أَعِنِّيْ عَلٰى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ "
        "عِبَادَتِكَ",
        latin="Allaahumma a'innii 'alaa dzikrika wa syukrika wa husni "
        "'ibaadatik.",
        arti="Ya Allah, tolonglah aku untuk berdzikir kepada-Mu, bersyukur "
        "kepada-Mu, dan beribadah kepada-Mu dengan baik.",
        note="Wasiat Nabi ﷺ kepada Mu'adz bin Jabal agar tidak ditinggalkan "
        "di akhir setiap sholat.",
        source="HR. Abu Daud no. 1522 & An-Nasa'i no. 1303",
    ),
    dict(
        group=SUNNAH,
        id=74,
        title="'Ilman naafi'aa (Subuh)",
        repeat=1,
        time="sholatSubuh",
        arabic="اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا "
        "طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا",
        latin="Allaahumma innii as-aluka 'ilman naafi'aa, wa rizqan "
        "thayyibaa, wa 'amalan mutaqabbalaa.",
        arti="Ya Allah, sesungguhnya aku memohon kepada-Mu ilmu yang "
        "bermanfaat, rezeki yang baik, dan amal yang diterima.",
        note="Khusus setelah salam sholat Subuh.",
        source="HR. Ibnu Majah no. 925",
    ),
]


def dart_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("$", "\\$") + "'"


out = [
    "// DIBUAT OTOMATIS oleh tool/gen_dzikir_sholat.py - jangan diedit langsung.",
    "//",
    "// Dzikir & doa setelah sholat wajib: urutan bacaan yang lazim di masjid",
    "// Indonesia, doa yang sering dibaca imam, dan dzikir sunnah Hisnul Muslim.",
    "// Ayat Al-Qur'an dari Mushaf Standar Indonesia (assets/quran/quran.json).",
    "// Latin & terjemahan bersifat bantuan.",
    "",
    "import '../services/dzikir.dart';",
    "",
    "const dzikirSholatList = <Dzikir>[",
]
for d in items:
    out += [
        "  Dzikir(",
        f"    id: {d['id']},",
        f"    title: {dart_str(d['title'])},",
        f"    repeat: {d['repeat']},",
        f"    time: DzikirTime.{d['time']},",
        f"    group: {dart_str(d['group'])},",
        f"    arabic: {dart_str(d['arabic'])},",
        f"    latin: {dart_str(d['latin'])},",
        f"    arti: {dart_str(d['arti'])},",
    ]
    if d["group"] in (IMAM, SUNNAH):
        out.append("    optional: true,")
    if d["note"]:
        out.append(f"    note: {dart_str(d['note'])},")
    out += [f"    source: {dart_str(d['source'])},", "  ),"]
out += ["];", ""]
(ROOT / "lib/data/dzikir_sholat_data.dart").write_text("\n".join(out))
print("dzikir setelah sholat:", len(items))
