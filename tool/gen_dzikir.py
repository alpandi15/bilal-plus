# Membuat lib/data/dzikir_data.dart dari Hisnul Muslim bab 27 "Adzkar pagi
# dan petang" (tool/hisnmuslim_27_ar.json, https://www.hisnmuslim.com/api/ar/27.json).
#
#   python3 tool/gen_dzikir.py && dart format lib/data/dzikir_data.dart
#
# Teks Arab sumber (hisnmuslim.com) hanya dipakai sebagai rujukan; teks yang
# dipakai aplikasi ditulis ulang di bawah (ejaan mushaf Indonesia, ayat dari
# assets/quran/quran.json). Versi petang disusun dari catatan sumber "وإذا أمسى قال"
# dengan penggantian kata yang diperiksa (gagal bila kata asalnya tidak ada).
# Latin & terjemahan Indonesia ditulis manual di bawah.
import json
import re

src = json.loads(open('tool/hisnmuslim_27_ar.json', encoding='utf-8-sig').read())
items = {int(x['ID']): x for x in list(src.values())[0]}


def clean(t):
    t = re.sub(r'\[[^\]]*\]', '', t)
    t = re.sub(r'،\s*أَوْ\s*\(مرَّةً واحدةً عندَ الكَسَلِ\)', '', t)
    t = re.sub(r'\((?:ثلاثَ|أربعَ|سَبْعَ|عشرَ|مائة|مائةَ|مِائَةَ|إذا)[^)]*\)', '', t)
    t = t.replace('((', '').replace('))', '')
    t = re.sub(r'\s+', ' ', t).strip().rstrip('.').strip()
    return t


_MARKS = set(range(0x064B, 0x0653)) | {0x0670}


def norm(t):
    """Urutan tanda harakat baku (syaddah dulu, lalu menurut kode) - sumber
    & teks ketikan kadang berbeda urutan meski tampil sama."""
    out, run = [], []
    for c in t:
        if ord(c) in _MARKS:
            run.append(c)
            continue
        out.extend(sorted(run, key=lambda m: (m != '\u0651', ord(m))))
        run = []
        out.append(c)
    out.extend(sorted(run, key=lambda m: (m != '\u0651', ord(m))))
    return ''.join(out)


def swap(text, pairs):
    text = norm(text)
    for a, b in pairs:
        a, b = norm(a), norm(b)
        assert a in text, a
        text = text.replace(a, b)
    return text


arabic = {k: norm(clean(v['ARABIC_TEXT'])) for k, v in items.items()}
# tiga surat: satu surat per baris, penanda ayat
arabic[76] = arabic[76].replace('*', ' ۝').replace('﴾. ', '﴾\n')
# salah ketik di sumber: نَبَيِّنَا -> نَبِيِّنَا
arabic[98] = swap(arabic[98], [(
    '\u0646\u064e\u0628\u064e\u064a\u0651\u0650\u0646\u064e\u0627',
    '\u0646\u064e\u0628\u0650\u064a\u0651\u0650\u0646\u064e\u0627',
)])

petang = {
    77: swap(arabic[77], [
        ('أَصْبَحْنَا وَأَصْبَحَ', 'أَمْسَيْنَا وَأَمْسَى'),
        ('خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيرَ مَا بَعْدَهُ',
         'خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا'),
        ('شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ',
         'شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا'),
    ]),
    78: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، '
        'وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
    80: swap(arabic[80], [('أَصْبَحْتُ', 'أَمْسَيْتُ')]),
    81: swap(arabic[81], [('أَصْبَحَ بِي', 'أَمْسَى بِي')]),
    89: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ '
        'إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ: فَتْحَهَا، وَنَصْرَهَا، '
        'وَنُورَهَا، وَبَرَكَتَهَا، وَهُدَاهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا '
        'فِيهَا وَشَرِّ مَا بَعْدَهَا',
    90: swap(arabic[90], [('أَصْبَحْنا', 'أَمْسَيْنَا')]),
}

# id: (judul, jumlah, waktu, latin, [latin petang], arti, [arti petang],
#      keterangan, sumber)
B, P, M = 'both', 'pagi', 'petang'

# ---------------------------------------------------------------------------
# Teks Arab yang dipakai aplikasi. Sumber hisnmuslim.com memakai ejaan biasa
# yang banyak kehilangan harakat/madd (mis. بِمَا شَاء, إلاَّ, عَلَيهِ تَوَكَّلتُ)
# dan ada salah harakat (وَمَلاَئِكَتِكَ). Di sini ditulis ulang dengan ejaan
# gaya mushaf Indonesia (sama dengan dzikir setelah sholat); ayat Al-Qur'an
# diambil dari assets/quran/quran.json supaya sama persis dengan mushaf.
# ---------------------------------------------------------------------------
import unicodedata

Q = json.loads(open('assets/quran/quran.json', encoding='utf-8').read())
_counts = [x[4] for x in Q['surah']]


def ayah(surah, n):
    return Q['ayah'][sum(_counts[: surah - 1]) + n - 1][0].replace('ࣖ', '').strip()


def surah_text(s):
    body = ' ۝ '.join(ayah(s, n) for n in range(1, _counts[s - 1] + 1))
    return f'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ ﴿{body}﴾'


def _bare(w):
    return ''.join(
        c for c in unicodedata.normalize('NFD', w)
        if not unicodedata.category(c).startswith('M')
    ).replace('ٰ', '').replace('ـ', '')


def part(surah, n, start):
    words = ayah(surah, n).split(' ')
    want = [_bare(w) for w in start.split(' ')]
    for k in range(len(words)):
        if [_bare(w) for w in words[k: k + len(want)]] == want:
            return ' '.join(words[k:])
    raise ValueError(f'{start} tidak ada di {surah}:{n}')


SAW = 'صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ'
TAHLIL = ('لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ '
          'وَلَهُ الْحَمْدُ، وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدِيْرٌ')


def _pagi_petang(pagi, pairs):
    p = pagi
    for a, b in pairs:
        assert a in p, a
        p = p.replace(a, b)
    return pagi, p


A77 = _pagi_petang(
    'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلّٰهِ، وَالْحَمْدُ لِلّٰهِ، لَا إِلٰهَ إِلَّا '
    'اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلٰى '
    'كُلِّ شَيْءٍ قَدِيْرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِيْ هٰذَا الْيَوْمِ وَخَيْرَ '
    'مَا بَعْدَهُ، وَأَعُوْذُ بِكَ مِنْ شَرِّ مَا فِيْ هٰذَا الْيَوْمِ وَشَرِّ مَا '
    'بَعْدَهُ، رَبِّ أَعُوْذُ بِكَ مِنَ الْكَسَلِ وَسُوْءِ الْكِبَرِ، رَبِّ أَعُوْذُ '
    'بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
    [('أَصْبَحْنَا وَأَصْبَحَ', 'أَمْسَيْنَا وَأَمْسَى'),
     ('خَيْرَ مَا فِيْ هٰذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ',
      'خَيْرَ مَا فِيْ هٰذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا'),
     ('شَرِّ مَا فِيْ هٰذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ',
      'شَرِّ مَا فِيْ هٰذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا')])
A80 = _pagi_petang(
    'اَللّٰهُمَّ إِنِّيْ أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، '
    'وَمَلَائِكَتَكَ، وَجَمِيْعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللّٰهُ لَا إِلٰهَ إِلَّا '
    'أَنْتَ وَحْدَكَ لَا شَرِيْكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُوْلُكَ',
    [('أَصْبَحْتُ', 'أَمْسَيْتُ')])
A81 = _pagi_petang(
    'اَللّٰهُمَّ مَا أَصْبَحَ بِيْ مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ '
    'فَمِنْكَ وَحْدَكَ لَا شَرِيْكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
    [('أَصْبَحَ بِيْ', 'أَمْسَى بِيْ')])
A89 = _pagi_petang(
    'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلّٰهِ رَبِّ الْعَالَمِيْنَ، اَللّٰهُمَّ إِنِّيْ '
    'أَسْأَلُكَ خَيْرَ هٰذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنُوْرَهُ، وَبَرَكَتَهُ، '
    'وَهُدَاهُ، وَأَعُوْذُ بِكَ مِنْ شَرِّ مَا فِيْهِ وَشَرِّ مَا بَعْدَهُ',
    [('أَصْبَحْنَا وَأَصْبَحَ', 'أَمْسَيْنَا وَأَمْسَى'),
     ('خَيْرَ هٰذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنُوْرَهُ، وَبَرَكَتَهُ، وَهُدَاهُ',
      'خَيْرَ هٰذِهِ اللَّيْلَةِ: فَتْحَهَا، وَنَصْرَهَا، وَنُوْرَهَا، وَبَرَكَتَهَا، وَهُدَاهَا'),
     ('مَا فِيْهِ وَشَرِّ مَا بَعْدَهُ', 'مَا فِيْهَا وَشَرِّ مَا بَعْدَهَا')])
A90 = _pagi_petang(
    'أَصْبَحْنَا عَلٰى فِطْرَةِ الْإِسْلَامِ، وَعَلٰى كَلِمَةِ الْإِخْلَاصِ، وَعَلٰى '
    f'دِيْنِ نَبِيِّنَا مُحَمَّدٍ {SAW}، وَعَلٰى مِلَّةِ أَبِيْنَا إِبْرَاهِيْمَ، '
    'حَنِيْفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِيْنَ',
    [('أَصْبَحْنَا', 'أَمْسَيْنَا')])

arabic = {
    75: 'أَعُوْذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيْمِ ﴿' + ayah(2, 255) + '﴾',
    76: '\n'.join(surah_text(x) for x in (112, 113, 114)),
    77: A77[0],
    78: 'اَللّٰهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، '
        'وَبِكَ نَمُوْتُ، وَإِلَيْكَ النُّشُوْرُ',
    79: 'اَللّٰهُمَّ أَنْتَ رَبِّيْ لَا إِلٰهَ إِلَّا أَنْتَ، خَلَقْتَنِيْ وَأَنَا '
        'عَبْدُكَ، وَأَنَا عَلٰى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوْذُ بِكَ '
        'مِنْ شَرِّ مَا صَنَعْتُ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوْءُ '
        'بِذَنْبِيْ، فَاغْفِرْ لِيْ، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوْبَ إِلَّا أَنْتَ',
    80: A80[0],
    81: A81[0],
    82: 'اَللّٰهُمَّ عَافِنِيْ فِيْ بَدَنِيْ، اَللّٰهُمَّ عَافِنِيْ فِيْ سَمْعِيْ، '
        'اَللّٰهُمَّ عَافِنِيْ فِيْ بَصَرِيْ، لَا إِلٰهَ إِلَّا أَنْتَ. اَللّٰهُمَّ '
        'إِنِّيْ أَعُوْذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوْذُ بِكَ مِنْ '
        'عَذَابِ الْقَبْرِ، لَا إِلٰهَ إِلَّا أَنْتَ',
    83: part(9, 129, 'حَسْبِيَ'),
    84: 'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا '
        'وَالْآخِرَةِ، اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِيْ '
        'دِيْنِيْ وَدُنْيَايَ وَأَهْلِيْ وَمَالِيْ، اَللّٰهُمَّ اسْتُرْ عَوْرَاتِيْ، '
        'وَآمِنْ رَوْعَاتِيْ، اَللّٰهُمَّ احْفَظْنِيْ مِنْ بَيْنِ يَدَيَّ، وَمِنْ '
        'خَلْفِيْ، وَعَنْ يَمِيْنِيْ، وَعَنْ شِمَالِيْ، وَمِنْ فَوْقِيْ، وَأَعُوْذُ '
        'بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِيْ',
    85: 'اَللّٰهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، فَاطِرَ السَّمٰوَاتِ '
        'وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيْكَهُ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا '
        'أَنْتَ، أَعُوْذُ بِكَ مِنْ شَرِّ نَفْسِيْ، وَمِنْ شَرِّ الشَّيْطَانِ '
        'وَشَرَكِهِ، وَأَنْ أَقْتَرِفَ عَلٰى نَفْسِيْ سُوْءًا، أَوْ أَجُرَّهُ إِلٰى '
        'مُسْلِمٍ',
    86: 'بِسْمِ اللّٰهِ الَّذِيْ لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا '
        'فِي السَّمَاءِ، وَهُوَ السَّمِيْعُ الْعَلِيْمُ',
    87: f'رَضِيْتُ بِاللّٰهِ رَبًّا، وَبِالْإِسْلَامِ دِيْنًا، وَبِمُحَمَّدٍ {SAW} '
        'نَبِيًّا',
    88: 'يَا حَيُّ يَا قَيُّوْمُ، بِرَحْمَتِكَ أَسْتَغِيْثُ، أَصْلِحْ لِيْ شَأْنِيْ '
        'كُلَّهُ، وَلَا تَكِلْنِيْ إِلٰى نَفْسِيْ طَرْفَةَ عَيْنٍ',
    89: A89[0],
    90: A90[0],
    91: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ',
    92: TAHLIL,
    93: TAHLIL,
    94: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ '
        'عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
    95: 'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، '
        'وَعَمَلًا مُتَقَبَّلًا',
    96: 'أَسْتَغْفِرُ اللّٰهَ وَأَتُوْبُ إِلَيْهِ',
    97: 'أَعُوْذُ بِكَلِمَاتِ اللّٰهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    98: 'اَللّٰهُمَّ صَلِّ وَسَلِّمْ عَلٰى نَبِيِّنَا مُحَمَّدٍ',
}
petang = {
    77: A77[1],
    78: 'اَللّٰهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، '
        'وَبِكَ نَمُوْتُ، وَإِلَيْكَ الْمَصِيْرُ',
    80: A80[1],
    81: A81[1],
    89: A89[1],
    90: A90[1],
}
assert set(arabic) == set(items), set(items) ^ set(arabic)

# Versi singkat (waktu sedikit): bacaan pendek yang keutamaannya besar.
BRIEF = {75, 76, 79, 83, 86, 87, 88, 94, 97, 98}

meta = {
    75: ('Ayat Kursi', 1, B,
         "A'uudzu billaahi minasy syaithaanir rajiim. Allaahu laa ilaaha "
         "illaa huwal hayyul qayyuum, laa ta'khudzuhuu sinatuw wa laa naum, "
         "lahuu maa fis samaawaati wa maa fil ardh, man dzal ladzii yasyfa'u "
         "'indahuu illaa bi-idznih, ya'lamu maa baina aidiihim wa maa "
         "khalfahum, wa laa yuhiithuuna bisyai-im min 'ilmihii illaa bimaa "
         "syaa', wasi'a kursiyyuhus samaawaati wal ardh, wa laa ya-uuduhuu "
         "hifzhuhumaa, wa huwal 'aliyyul 'azhiim.", None,
         'Aku berlindung kepada Allah dari setan yang terkutuk. Allah, tidak '
         'ada tuhan selain Dia, Yang Mahahidup, Yang terus-menerus mengurus '
         '(makhluk-Nya), tidak mengantuk dan tidak tidur. Milik-Nya apa yang '
         'ada di langit dan di bumi. Tidak ada yang dapat memberi syafaat di '
         'sisi-Nya tanpa izin-Nya. Dia mengetahui apa yang di hadapan mereka '
         'dan di belakang mereka, dan mereka tidak mengetahui sesuatu pun '
         'dari ilmu-Nya melainkan apa yang Dia kehendaki. Kursi-Nya meliputi '
         'langit dan bumi, dan Dia tidak merasa berat memelihara keduanya. '
         'Dia Mahatinggi, Mahabesar.', None,
         'Dijaga dari gangguan setan hingga petang (bila dibaca pagi) atau '
         'hingga pagi (bila dibaca petang).', 'HR. Al-Hakim'),
    76: ('Al-Ikhlas, Al-Falaq & An-Nas', 3, B,
         'Bismillaahir rahmaanir rahiim. Qul huwallaahu ahad. Allaahush '
         'shamad. Lam yalid wa lam yuulad. Wa lam yakul lahuu kufuwan ahad.\n'
         "Bismillaahir rahmaanir rahiim. Qul a'uudzu birabbil falaq. Min "
         'syarri maa khalaq. Wa min syarri ghaasiqin idzaa waqab. Wa min '
         "syarrin naffaatsaati fil 'uqad. Wa min syarri haasidin idzaa hasad.\n"
         "Bismillaahir rahmaanir rahiim. Qul a'uudzu birabbin naas. Malikin "
         'naas. Ilaahin naas. Min syarril waswaasil khannaas. Alladzii '
         'yuwaswisu fii shuduurin naas. Minal jinnati wan naas.', None,
         'Katakanlah: Dialah Allah Yang Maha Esa. Allah tempat meminta '
         'segala sesuatu. Dia tidak beranak dan tidak diperanakkan, dan tidak '
         'ada sesuatu pun yang setara dengan-Nya.\n'
         'Katakanlah: Aku berlindung kepada Tuhan yang menguasai subuh, dari '
         'kejahatan makhluk yang Dia ciptakan, dari kejahatan malam apabila '
         'telah gelap gulita, dari kejahatan penyihir yang meniup pada '
         'buhul-buhul, dan dari kejahatan orang yang dengki apabila ia '
         'dengki.\n'
         'Katakanlah: Aku berlindung kepada Tuhannya manusia, Raja manusia, '
         'sembahan manusia, dari kejahatan bisikan setan yang bersembunyi, '
         'yang membisikkan ke dalam dada manusia, dari golongan jin dan '
         'manusia.', None,
         'Mencukupkan (melindungi) dari segala sesuatu.',
         'HR. Abu Dawud & At-Tirmidzi'),
    77: ('Ashbahnaa wa ashbahal mulku lillaah', 1, B,
         'Ashbahnaa wa ashbahal mulku lillaah, walhamdu lillaah, laa ilaaha '
         'illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa '
         "huwa 'alaa kulli syai-in qadiir. Rabbi as-aluka khaira maa fii "
         "haadzal yaumi wa khaira maa ba'dah, wa a'uudzu bika min syarri maa "
         "fii haadzal yaumi wa syarri maa ba'dah. Rabbi a'uudzu bika minal "
         "kasali wa suu-il kibar. Rabbi a'uudzu bika min 'adzaabin fin naari "
         "wa 'adzaabin fil qabr.",
         'Amsainaa wa amsal mulku lillaah, walhamdu lillaah, laa ilaaha '
         'illallaahu wahdahuu laa syariika lah, lahul mulku wa lahul hamdu wa '
         "huwa 'alaa kulli syai-in qadiir. Rabbi as-aluka khaira maa fii "
         "haadzihil lailati wa khaira maa ba'dahaa, wa a'uudzu bika min "
         "syarri maa fii haadzihil lailati wa syarri maa ba'dahaa. Rabbi "
         "a'uudzu bika minal kasali wa suu-il kibar. Rabbi a'uudzu bika min "
         "'adzaabin fin naari wa 'adzaabin fil qabr.",
         'Kami memasuki waktu pagi dan kerajaan hanya milik Allah, segala puji '
         'bagi Allah. Tidak ada tuhan selain Allah semata, tiada sekutu '
         'bagi-Nya. Milik-Nya kerajaan dan pujian, dan Dia Mahakuasa atas '
         'segala sesuatu. Wahai Tuhanku, aku memohon kepada-Mu kebaikan hari '
         'ini dan kebaikan sesudahnya, dan aku berlindung kepada-Mu dari '
         'keburukan hari ini dan keburukan sesudahnya. Wahai Tuhanku, aku '
         'berlindung kepada-Mu dari kemalasan dan keburukan hari tua. Wahai '
         'Tuhanku, aku berlindung kepada-Mu dari siksa neraka dan siksa '
         'kubur.',
         'Kami memasuki waktu petang dan kerajaan hanya milik Allah, segala '
         'puji bagi Allah. Tidak ada tuhan selain Allah semata, tiada sekutu '
         'bagi-Nya. Milik-Nya kerajaan dan pujian, dan Dia Mahakuasa atas '
         'segala sesuatu. Wahai Tuhanku, aku memohon kepada-Mu kebaikan malam '
         'ini dan kebaikan sesudahnya, dan aku berlindung kepada-Mu dari '
         'keburukan malam ini dan keburukan sesudahnya. Wahai Tuhanku, aku '
         'berlindung kepada-Mu dari kemalasan dan keburukan hari tua. Wahai '
         'Tuhanku, aku berlindung kepada-Mu dari siksa neraka dan siksa '
         'kubur.',
         None, 'HR. Muslim'),
    78: ('Allaahumma bika ashbahnaa', 1, B,
         'Allaahumma bika ashbahnaa, wa bika amsainaa, wa bika nahyaa, wa '
         'bika namuutu wa ilaikan nusyuur.',
         'Allaahumma bika amsainaa, wa bika ashbahnaa, wa bika nahyaa, wa '
         'bika namuutu wa ilaikal mashiir.',
         'Ya Allah, dengan-Mu kami memasuki waktu pagi, dengan-Mu kami '
         'memasuki waktu petang, dengan-Mu kami hidup, dengan-Mu kami mati, '
         'dan kepada-Mu kebangkitan.',
         'Ya Allah, dengan-Mu kami memasuki waktu petang, dengan-Mu kami '
         'memasuki waktu pagi, dengan-Mu kami hidup, dengan-Mu kami mati, dan '
         'kepada-Mu tempat kembali.',
         None, 'HR. At-Tirmidzi'),
    79: ('Sayyidul Istighfar', 1, B,
         "Allaahumma anta rabbii laa ilaaha illaa anta, khalaqtanii wa ana "
         "'abduka, wa ana 'alaa 'ahdika wa wa'dika mastatha'tu, a'uudzu bika "
         "min syarri maa shana'tu, abuu-u laka bini'matika 'alayya, wa abuu-u "
         'bidzanbii faghfir lii fa innahuu laa yaghfirudz dzunuuba illaa '
         'anta.', None,
         'Ya Allah, Engkau Tuhanku, tidak ada tuhan selain Engkau. Engkau yang '
         'menciptakanku dan aku hamba-Mu. Aku berada di atas perjanjian dan '
         'janji-Mu semampuku. Aku berlindung kepada-Mu dari keburukan yang '
         'kuperbuat. Aku mengakui nikmat-Mu kepadaku dan aku mengakui dosaku, '
         'maka ampunilah aku; sesungguhnya tidak ada yang mengampuni dosa '
         'selain Engkau.', None,
         'Siapa yang membacanya dengan yakin lalu wafat pada hari/malam itu, '
         'ia termasuk penghuni surga.', 'HR. Al-Bukhari'),
    80: ('Allaahumma innii ashbahtu usyhiduka', 4, B,
         'Allaahumma innii ashbahtu usyhiduka wa usyhidu hamalata '
         "'arsyika wa malaa-ikataka wa jamii'a khalqika, annaka antallaahu "
         'laa ilaaha illaa anta wahdaka laa syariika laka, wa anna '
         "muhammadan 'abduka wa rasuuluk.",
         'Allaahumma innii amsaitu usyhiduka wa usyhidu hamalata '
         "'arsyika wa malaa-ikataka wa jamii'a khalqika, annaka antallaahu "
         'laa ilaaha illaa anta wahdaka laa syariika laka, wa anna '
         "muhammadan 'abduka wa rasuuluk.",
         "Ya Allah, sesungguhnya di pagi ini aku mempersaksikan Engkau, para "
         "pemikul 'Arsy-Mu, para malaikat-Mu, dan seluruh makhluk-Mu, bahwa "
         'Engkau adalah Allah, tidak ada tuhan selain Engkau semata, tiada '
         'sekutu bagi-Mu, dan bahwa Muhammad adalah hamba dan utusan-Mu.',
         "Ya Allah, sesungguhnya di petang ini aku mempersaksikan Engkau, para "
         "pemikul 'Arsy-Mu, para malaikat-Mu, dan seluruh makhluk-Mu, bahwa "
         'Engkau adalah Allah, tidak ada tuhan selain Engkau semata, tiada '
         'sekutu bagi-Mu, dan bahwa Muhammad adalah hamba dan utusan-Mu.',
         'Dibaca 4 kali: Allah membebaskannya dari api neraka.',
         'HR. Abu Dawud'),
    81: ("Allaahumma maa ashbaha bii min ni'matin", 1, B,
         "Allaahumma maa ashbaha bii min ni'matin au bi-ahadin min khalqika "
         'fa minka wahdaka laa syariika laka, fa lakal hamdu wa lakasy '
         'syukru.',
         "Allaahumma maa amsaa bii min ni'matin au bi-ahadin min khalqika fa "
         'minka wahdaka laa syariika laka, fa lakal hamdu wa lakasy syukru.',
         'Ya Allah, nikmat apa pun yang ada padaku atau pada salah satu '
         'makhluk-Mu di pagi ini, semuanya dari-Mu semata, tiada sekutu '
         'bagi-Mu. Maka bagi-Mu segala puji dan syukur.',
         'Ya Allah, nikmat apa pun yang ada padaku atau pada salah satu '
         'makhluk-Mu di petang ini, semuanya dari-Mu semata, tiada sekutu '
         'bagi-Mu. Maka bagi-Mu segala puji dan syukur.',
         'Menunaikan syukur hari itu (pagi) atau malam itu (petang).',
         'HR. Abu Dawud'),
    82: ("Allaahumma 'aafinii fii badanii", 3, B,
         "Allaahumma 'aafinii fii badanii, allaahumma 'aafinii fii sam'ii, "
         "allaahumma 'aafinii fii basharii, laa ilaaha illaa anta. Allaahumma "
         "innii a'uudzu bika minal kufri wal faqri, wa a'uudzu bika min "
         "'adzaabil qabri, laa ilaaha illaa anta.", None,
         'Ya Allah, sehatkanlah badanku. Ya Allah, sehatkanlah pendengaranku. '
         'Ya Allah, sehatkanlah penglihatanku. Tidak ada tuhan selain Engkau. '
         'Ya Allah, aku berlindung kepada-Mu dari kekufuran dan kefakiran, '
         'dan aku berlindung kepada-Mu dari siksa kubur. Tidak ada tuhan '
         'selain Engkau.', None, None, 'HR. Abu Dawud'),
    83: ('Hasbiyallaah', 7, B,
         "Hasbiyallaahu laa ilaaha illaa huwa, 'alaihi tawakkaltu wa huwa "
         "rabbul 'arsyil 'azhiim.", None,
         'Cukuplah Allah bagiku, tidak ada tuhan selain Dia. Hanya kepada-Nya '
         "aku bertawakal, dan Dia Tuhan pemilik 'Arsy yang agung.", None,
         'Allah mencukupkan urusan dunia dan akhiratnya.', 'HR. Abu Dawud'),
    84: ("Al-'Afwa wal 'Aafiyah", 1, B,
         "Allaahumma innii as-alukal 'afwa wal 'aafiyata fid dunyaa wal "
         "aakhirah. Allaahumma innii as-alukal 'afwa wal 'aafiyata fii diinii "
         "wa dunyaaya wa ahlii wa maalii. Allaahummastur 'auraatii wa aamin "
         "rau'aatii. Allaahummahfazhnii min baini yadayya wa min khalfii wa "
         "'an yamiinii wa 'an syimaalii wa min fauqii, wa a'uudzu "
         "bi'azhamatika an ughtaala min tahtii.", None,
         'Ya Allah, aku memohon kepada-Mu ampunan dan keselamatan di dunia '
         'dan akhirat. Ya Allah, aku memohon kepada-Mu ampunan dan '
         'keselamatan dalam agamaku, duniaku, keluargaku, dan hartaku. Ya '
         'Allah, tutupilah aibku dan tenteramkanlah rasa takutku. Ya Allah, '
         'jagalah aku dari depan, belakang, kanan, kiri, dan atasku. Aku '
         'berlindung dengan keagungan-Mu dari disambar (bencana) dari '
         'bawahku.', None, None, 'HR. Abu Dawud & Ibnu Majah'),
    85: ("Allaahumma 'aalimal ghaibi wasy syahaadah", 1, B,
         "Allaahumma 'aalimal ghaibi wasy syahaadah, faathiras samaawaati wal "
         "ardh, rabba kulli syai-in wa maliikah, asyhadu allaa ilaaha illaa "
         "anta, a'uudzu bika min syarri nafsii wa min syarrisy syaithaani wa "
         "syarakih, wa an aqtarifa 'alaa nafsii suu-an au ajurrahuu ilaa "
         'muslim.', None,
         'Ya Allah, Yang Maha Mengetahui yang gaib dan yang nyata, Pencipta '
         'langit dan bumi, Tuhan dan Penguasa segala sesuatu. Aku bersaksi '
         'bahwa tidak ada tuhan selain Engkau. Aku berlindung kepada-Mu dari '
         'keburukan diriku, dari keburukan setan dan jeratnya, dan dari '
         'berbuat keburukan terhadap diriku atau menimpakannya kepada seorang '
         'muslim.', None, None, 'HR. At-Tirmidzi & Abu Dawud'),
    86: ('Bismillaahil ladzii laa yadhurru', 3, B,
         "Bismillaahil ladzii laa yadhurru ma'asmihii syai-un fil ardhi wa "
         "laa fis samaa-i wa huwas samii'ul 'aliim.", None,
         'Dengan nama Allah yang bersama nama-Nya tidak ada sesuatu pun di '
         'bumi maupun di langit yang dapat membahayakan, dan Dia Maha '
         'Mendengar lagi Maha Mengetahui.', None,
         'Tidak akan ditimpa bahaya apa pun (hingga pagi/petang).',
         'HR. Abu Dawud & At-Tirmidzi'),
    87: ('Radhiitu billaahi rabbaa', 3, B,
         'Radhiitu billaahi rabbaa, wa bil islaami diinaa, wa bi muhammadin '
         "shallallaahu 'alaihi wa sallama nabiyyaa.", None,
         "Aku rida Allah sebagai Tuhan, Islam sebagai agama, dan Muhammad "
         "shallallahu 'alaihi wa sallam sebagai nabi.", None,
         'Allah pasti meridainya pada hari kiamat.',
         'HR. Abu Dawud & At-Tirmidzi'),
    88: ('Yaa hayyu yaa qayyuum', 1, B,
         'Yaa hayyu yaa qayyuum, birahmatika astaghiits, ashlih lii sya-nii '
         "kullahuu wa laa takilnii ilaa nafsii tharfata 'ain.", None,
         'Wahai Yang Mahahidup, wahai Yang terus-menerus mengurus '
         '(makhluk-Nya), dengan rahmat-Mu aku memohon pertolongan. '
         'Perbaikilah seluruh urusanku dan jangan Engkau serahkan aku kepada '
         'diriku sendiri walau sekejap mata.', None, None, 'HR. Al-Hakim'),
    89: ("Ashbahnaa ... rabbil 'aalamiin", 1, B,
         "Ashbahnaa wa ashbahal mulku lillaahi rabbil 'aalamiin. Allaahumma "
         'innii as-aluka khaira haadzal yaum, fathahuu wa nashrahuu wa '
         "nuurahuu wa barakatahuu wa hudaah, wa a'uudzu bika min syarri maa "
         "fiihi wa syarri maa ba'dah.",
         "Amsainaa wa amsal mulku lillaahi rabbil 'aalamiin. Allaahumma innii "
         'as-aluka khaira haadzihil lailah, fathahaa wa nashrahaa wa nuurahaa '
         "wa barakatahaa wa hudaahaa, wa a'uudzu bika min syarri maa fiihaa "
         "wa syarri maa ba'dahaa.",
         'Kami memasuki waktu pagi dan kerajaan milik Allah, Tuhan semesta '
         'alam. Ya Allah, aku memohon kepada-Mu kebaikan hari ini: '
         'kemenangannya, pertolongannya, cahayanya, keberkahannya, dan '
         'petunjuknya. Aku berlindung kepada-Mu dari keburukan yang ada di '
         'dalamnya dan keburukan sesudahnya.',
         'Kami memasuki waktu petang dan kerajaan milik Allah, Tuhan semesta '
         'alam. Ya Allah, aku memohon kepada-Mu kebaikan malam ini: '
         'kemenangannya, pertolongannya, cahayanya, keberkahannya, dan '
         'petunjuknya. Aku berlindung kepada-Mu dari keburukan yang ada di '
         'dalamnya dan keburukan sesudahnya.',
         None, 'HR. Abu Dawud'),
    90: ("Ashbahnaa 'alaa fithratil islaam", 1, B,
         "Ashbahnaa 'alaa fithratil islaam, wa 'alaa kalimatil ikhlaash, wa "
         "'alaa diini nabiyyinaa muhammadin shallallaahu 'alaihi wa sallam, wa "
         "'alaa millati abiinaa ibraahiima haniifam muslimaa, wa maa kaana "
         'minal musyrikiin.',
         "Amsainaa 'alaa fithratil islaam, wa 'alaa kalimatil ikhlaash, wa "
         "'alaa diini nabiyyinaa muhammadin shallallaahu 'alaihi wa sallam, wa "
         "'alaa millati abiinaa ibraahiima haniifam muslimaa, wa maa kaana "
         'minal musyrikiin.',
         'Kami memasuki waktu pagi di atas fitrah Islam, di atas kalimat '
         'ikhlas (tauhid), di atas agama nabi kami Muhammad, dan di atas '
         'agama bapak kami Ibrahim yang lurus lagi berserah diri, dan ia '
         'bukan termasuk orang-orang musyrik.',
         'Kami memasuki waktu petang di atas fitrah Islam, di atas kalimat '
         'ikhlas (tauhid), di atas agama nabi kami Muhammad, dan di atas '
         'agama bapak kami Ibrahim yang lurus lagi berserah diri, dan ia '
         'bukan termasuk orang-orang musyrik.',
         None, 'HR. Ahmad'),
    91: ('Subhaanallaahi wa bihamdih', 100, B,
         'Subhaanallaahi wa bihamdih.', None,
         'Mahasuci Allah dan segala puji bagi-Nya.', None,
         'Tidak ada yang datang pada hari kiamat dengan amalan lebih utama, '
         'kecuali yang membaca seperti itu atau lebih.', 'HR. Muslim'),
    92: ('Tahlil (10×)', 10, B,
         'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa '
         "lahul hamdu wa huwa 'alaa kulli syai-in qadiir.", None,
         'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. '
         'Milik-Nya kerajaan dan segala puji, dan Dia Mahakuasa atas segala '
         'sesuatu.', None,
         '10 kali, atau sekali ketika sedang malas.', 'HR. An-Nasa\'i'),
    93: ('Tahlil (100×)', 100, P,
         'Laa ilaaha illallaahu wahdahuu laa syariika lah, lahul mulku wa '
         "lahul hamdu wa huwa 'alaa kulli syai-in qadiir.", None,
         'Tidak ada tuhan selain Allah semata, tiada sekutu bagi-Nya. '
         'Milik-Nya kerajaan dan segala puji, dan Dia Mahakuasa atas segala '
         'sesuatu.', None,
         'Setara memerdekakan 10 budak, dicatat 100 kebaikan, dihapus 100 '
         'keburukan, dan terjaga dari setan hari itu hingga petang.',
         'HR. Al-Bukhari & Muslim'),
    94: ("Subhaanallaahi wa bihamdihii 'adada khalqih", 3, P,
         "Subhaanallaahi wa bihamdihii 'adada khalqihii wa ridhaa nafsihii wa "
         "zinata 'arsyihii wa midaada kalimaatih.", None,
         'Mahasuci Allah dan segala puji bagi-Nya, sebanyak jumlah makhluk-Nya, '
         "seridha diri-Nya, seberat 'Arsy-Nya, dan sebanyak tinta "
         'kalimat-Nya.', None, None, 'HR. Muslim'),
    95: ("'Ilman naafi'aa", 1, P,
         "Allaahumma innii as-aluka 'ilman naafi'aa, wa rizqan thayyibaa, wa "
         "'amalan mutaqabbalaa.", None,
         'Ya Allah, aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang '
         'baik, dan amal yang diterima.', None, None, 'HR. Ibnu Majah'),
    96: ('Astaghfirullaaha wa atuubu ilaih', 100, P,
         'Astaghfirullaaha wa atuubu ilaih.', None,
         'Aku memohon ampun kepada Allah dan bertaubat kepada-Nya.', None,
         '100 kali dalam sehari.', 'HR. Al-Bukhari & Muslim'),
    97: ("A'uudzu bikalimaatillaahit taammaat", 3, M,
         "A'uudzu bikalimaatillaahit taammaati min syarri maa khalaq.", None,
         'Aku berlindung dengan kalimat-kalimat Allah yang sempurna dari '
         'keburukan makhluk yang Dia ciptakan.', None,
         'Tidak akan dicelakai oleh sengatan binatang malam itu.',
         'HR. Ahmad & At-Tirmidzi'),
    98: ('Shalawat kepada Nabi', 10, B,
         "Allaahumma shalli wa sallim 'alaa nabiyyinaa muhammad.", None,
         'Ya Allah, limpahkanlah shalawat dan salam kepada nabi kami '
         'Muhammad.', None,
         'Mendapat syafaat Nabi pada hari kiamat.', 'HR. Ath-Thabrani'),
}


petang = {k: norm(v) for k, v in petang.items()}


def lit(s):
    if s is None:
        return 'null'
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n') + "'"


out = ['// DIBUAT OTOMATIS oleh tool/gen_dzikir.py - jangan diedit langsung.',
       '//',
       "// Dzikir pagi & petang - Hisnul Muslim (Sa'id bin Wahf Al-Qahthani),",
       '// bab 27. Teks Arab ditulis ulang dengan ejaan mushaf Indonesia',
       '// (rujukan: hisnmuslim.com, tool/hisnmuslim_27_ar.json); ayat dari',
       '// assets/quran/quran.json. `brief` = termasuk versi singkat. Latin &',
       '// terjemahan Indonesia bersifat bantuan - rujukan utama teks Arab.',
       '',
       "import '../services/dzikir.dart';",
       '',
       'const dzikirList = <Dzikir>[']
for k in sorted(meta):
    title, rep, when, latin, latinP, arti, artiP, note, source = meta[k]
    out.append('  Dzikir(')
    out.append(f'    id: {k},')
    out.append(f'    title: {lit(title)},')
    out.append(f'    repeat: {rep},')
    out.append(f'    time: DzikirTime.{ {"both": "both", "pagi": "pagi", "petang": "petang"}[when] },')
    out.append(f'    arabic: {lit(arabic[k])},')
    out.append(f'    arabicPetang: {lit(petang.get(k))},')
    out.append(f'    latin: {lit(latin)},')
    out.append(f'    latinPetang: {lit(latinP)},')
    out.append(f'    arti: {lit(arti)},')
    out.append(f'    artiPetang: {lit(artiP)},')
    out.append(f'    note: {lit(note)},')
    out.append(f'    source: {lit(source)},')
    if k in BRIEF:
        out.append('    brief: true,')
    out.append('  ),')
out.append('];')
open('lib/data/dzikir_data.dart', 'w').write('\n'.join(out) + '\n')
print('ok', len(meta))
