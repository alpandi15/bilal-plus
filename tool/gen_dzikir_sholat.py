"""Membuat lib/data/dzikir_sholat_data.dart - dzikir & doa setelah sholat
wajib (Hisnul Muslim bab dzikir setelah salam). Ayat Kursi & tiga surah
perlindungan diambil dari assets/quran/quran.json (Mushaf Standar
Indonesia) supaya sama persis dengan mushaf di aplikasi.

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

items = [
    dict(
        id=66,
        title="Istighfar & Allaahumma antas salaam",
        repeat=1,
        time="sholat",
        arabic="أَسْتَغْفِرُ اللّٰهَ، أَسْتَغْفِرُ اللّٰهَ، أَسْتَغْفِرُ اللّٰهَ. "
        "اَللّٰهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا "
        "الْجَلَالِ وَالْإِكْرَامِ",
        latin="Astaghfirullaah (3×). Allaahumma antas salaam wa minkas salaam, "
        "tabaarakta yaa dzal jalaali wal ikraam.",
        arti="Aku memohon ampun kepada Allah (3×). Ya Allah, Engkaulah "
        "As-Salaam (Yang Maha Sejahtera) dan dari-Mu segala kesejahteraan. "
        "Mahaberkah Engkau, wahai Pemilik keagungan dan kemuliaan.",
        note="Dibaca segera setelah salam.",
        source="HR. Muslim no. 591",
    ),
    dict(
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
        id=691,
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
        id=692,
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
        id=693,
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
        id=694,
        title="Tahlil penutup (genap 100)",
        repeat=1,
        time="sholat",
        arabic=TAHLIL,
        latin=TAHLIL_LATIN + ".",
        arti=TAHLIL_ARTI + ".",
        note="Menggenapkan seratus - diampuni kesalahannya walau sebanyak buih "
        "di lautan.",
        source="HR. Muslim no. 597",
    ),
    dict(
        id=70,
        title="Ayat Kursi",
        repeat=1,
        time="sholat",
        arabic=ayah(2, 255),
        latin="Allaahu laa ilaaha illaa huwal hayyul qayyuum, laa "
        "ta'khudzuhuu sinatuw wa laa naum, lahuu maa fis samaawaati wa maa "
        "fil ardh, man dzal ladzii yasyfa'u 'indahuu illaa bi-idznih, "
        "ya'lamu maa baina aidiihim wa maa khalfahum, wa laa yuhiithuuna "
        "bisyai-im min 'ilmihii illaa bimaa syaa', wasi'a kursiyyuhus "
        "samaawaati wal ardh, wa laa ya-uuduhuu hifzhuhumaa, wa huwal "
        "'aliyyul 'azhiim.",
        arti=Q["ayah"][sum(counts[:1]) + 254][1].strip(),
        note="Tidak ada yang menghalanginya masuk surga kecuali kematian.",
        source="HR. An-Nasa'i (As-Sunan Al-Kubra), dishahihkan Al-Albani",
    ),
    dict(
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
        id=73,
        title="Tahlil 10× (Subuh & Maghrib)",
        repeat=10,
        time="sholatSubuhMaghrib",
        arabic="لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ "
        "الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِيْ وَيُمِيْتُ، وَهُوَ عَلٰى كُلِّ "
        "شَيْءٍ قَدِيْرٌ",
        latin="Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku "
        "wa lahul hamdu, yuhyii wa yumiit, wa huwa 'alaa kulli syai-in "
        "qadiir.",
        arti="Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. "
        "Milik-Nya kerajaan dan pujian, Dia menghidupkan dan mematikan, dan "
        "Dia Mahakuasa atas segala sesuatu.",
        note="Khusus setelah Subuh & Maghrib.",
        source="HR. At-Tirmidzi no. 3474 (hasan)",
    ),
    dict(
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
    "// Dzikir & doa setelah sholat wajib - Hisnul Muslim (bab dzikir setelah",
    "// salam). Ayat Kursi & surah perlindungan dari teks Mushaf Standar",
    "// Indonesia (assets/quran/quran.json). Latin & terjemahan bersifat bantuan.",
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
        f"    arabic: {dart_str(d['arabic'])},",
        f"    latin: {dart_str(d['latin'])},",
        f"    arti: {dart_str(d['arti'])},",
    ]
    if d["note"]:
        out.append(f"    note: {dart_str(d['note'])},")
    out += [f"    source: {dart_str(d['source'])},", "  ),"]
out += ["];", ""]
(ROOT / "lib/data/dzikir_sholat_data.dart").write_text("\n".join(out))
print("dzikir setelah sholat:", len(items))
