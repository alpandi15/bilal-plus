# Membuat lib/data/sholat_data.dart - bacaan sholat wajib, beberapa versi
# (pendek/panjang/pilihan madzhab).
#
#   python3 tool/gen_sholat.py && dart format lib/data/sholat_data.dart
#
# Sumber teks Arab:
# - Hisnul Muslim (tool/sholat/h<bab>_ar.json dari hisnmuslim.com): bab 16
#   iftitah, 17 ruku', 18 i'tidal, 19 sujud, 20 duduk di antara dua sujud,
#   22 tasyahud, 23 shalawat, 24 doa sebelum salam, 32 qunut - dirujuk
#   lewat nomor (hm(<id>)).
# - Al-Fatihah & surat pendek: teks Utsmani api.alquran.cloud
#   (tool/sholat/*.json); alif washal ditulis alif biasa seperti Mushaf
#   Standar Indonesia (font LPMQ tidak memuat ٱ).
# - typed(...): teks pendek yang sangat dikenal & tidak ada di sumber di
#   atas (lafaz niat, takbir, ta'awudz, salam, tasyahud riwayat Ibnu
#   Abbas & Umar, tambahan qunut yang lazim di Indonesia). Perlu ditinjau.
# Latin & terjemahan Indonesia ditulis manual - bantuan; rujukan teks Arab.
import json
import re

hm_src = {}
for bab in [16, 17, 18, 19, 20, 22, 23, 24, 32]:
    d = json.loads(open(f'tool/sholat/h{bab}_ar.json', encoding='utf-8-sig').read())
    for x in list(d.values())[0]:
        hm_src[int(x['ID'])] = x['ARABIC_TEXT']

_MARKS = set(range(0x064B, 0x0653)) | {0x0670}


def norm(t):
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


def hm(i):
    t = hm_src[i]
    t = re.sub(r'\)\)\s*ثَ?لاثاً?.*$', '))', t)  # "ثلاثاً ..." sesudah teks
    t = re.sub(r'ثلاث مرَّاتٍ\.?', '', t)
    t = t.replace('((', '').replace('))', '').replace('[', '').replace(']', '')
    t = t.replace('\u0640', '')  # kasyidah
    t = re.sub(r'\.?\s*ثلاث مر\S*', '', t)
    t = re.sub(r'\s+', ' ', t).strip().rstrip('.').strip()
    return norm(t)


def cut(text, end):
    """Potong [text] sampai & termasuk [end] (harus ada)."""
    end = norm(end)
    assert end in text, end
    return text[: text.index(end) + len(end)]


def typed(t):
    return norm(t)


def quran(file, basmalah=False):
    ayahs = json.load(open(f'tool/sholat/{file}'))['data']['ayahs']
    out = []
    for a in ayahs:
        t = a['text'].replace('\ufeff', '').replace('\u0671', '\u0627')
        out.append(norm(t))
    return out


def ayah_join(ayahs):
    arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩']
    num = lambda n: ''.join(arabic[int(c)] for c in str(n))
    return norm(' '.join(f'{t} ﴿{num(i + 1)}﴾' for i, t in enumerate(ayahs)))


BASMALAH = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'


def surah(file):
    ayahs = quran(file)
    # ayat pertama diawali basmalah (bukan bagian ayat kecuali Al-Fatihah)
    first, basmalah = ayahs[0], norm(BASMALAH)
    assert first.startswith(basmalah), first[:20]
    ayahs[0] = first[len(basmalah):].strip()
    return norm(BASMALAH) + '\n' + ayah_join(ayahs)


S, H, M, B = 'syafii', 'hanafi', 'maliki', 'hanbali'

# ---------------------------------------------------------------- teks
takbir = typed('اللَّهُ أَكْبَرُ')
iftitah_kabira = typed(
    'اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ '
    'بُكْرَةً وَأَصِيلًا')
wajjahtu_short = cut(hm(29), 'وَأَنَا مِنَ الْمُسْلِمِينَ')
fatihah = ayah_join(quran('fatihah.json'))
rabbana_lakal_hamd = typed('رَبَّنَا وَلَكَ الْحَمْدُ')
sami = hm(38)
tasyahud_ibnu_abbas = typed(
    'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ، السَّلَامُ '
    'عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ '
    'عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ '
    'إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ')
tasyahud_umar = typed(
    'التَّحِيَّاتُ لِلَّهِ، الزَّاكِيَاتُ لِلَّهِ، الطَّيِّبَاتُ الصَّلَوَاتُ '
    'لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ '
    'وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، '
    'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ '
    'وَرَسُولُهُ')
shalawat_pendek = typed('اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ')

# ------------------------------------------------------------- langkah
# langkah: (id, judul, kapan, catatan, [varian])
# varian: (label, [madzhab], arab, latin, arti, sumber, jumlah)
steps = [
    ('takbir', 'Takbiratul Ihram',
     'Membuka sholat sambil mengangkat kedua tangan.',
     None,
     [('Takbir', [S, H, M, B], takbir, 'Allaahu akbar.',
       'Allah Mahabesar.', 'HR. Al-Bukhari & Muslim', 1)]),

    ('iftitah', 'Doa Iftitah',
     'Sesudah takbiratul ihram, sebelum Al-Fatihah, pada rakaat pertama.',
     'Sunnah. Menurut pendapat masyhur madzhab Maliki, doa iftitah tidak '
     'dibaca dalam sholat fardhu - langsung membaca Al-Fatihah.',
     [
         ('Lazim di Indonesia', [S], iftitah_kabira + '. ' + wajjahtu_short,
          "Allaahu akbar kabiiraa, walhamdu lillaahi katsiiraa, wa "
          "subhaanallaahi bukratan wa ashiilaa. Wajjahtu wajhiya lilladzii "
          "fatharas samaawaati wal ardha haniifaa, wa maa ana minal "
          "musyrikiin. Inna shalaatii wa nusukii wa mahyaaya wa mamaatii "
          "lillaahi rabbil 'aalamiin, laa syariika lahuu wa bidzaalika "
          "umirtu wa ana minal muslimiin.",
          'Allah Mahabesar dengan sebesar-besarnya, segala puji bagi Allah '
          'dengan sebanyak-banyaknya, dan Mahasuci Allah pagi dan petang. '
          'Aku hadapkan wajahku kepada Dzat yang menciptakan langit dan '
          'bumi dengan lurus, dan aku bukan termasuk orang-orang musyrik. '
          'Sesungguhnya sholatku, ibadahku, hidupku, dan matiku hanya untuk '
          'Allah, Tuhan semesta alam, tiada sekutu bagi-Nya. Dengan itulah '
          'aku diperintah, dan aku termasuk orang-orang muslim.',
          'HR. Muslim (gabungan riwayat Ibnu Umar & Ali)', 1),
         ('Pendek (Subhanaka)', [H, B], hm(28),
          "Subhaanakallaahumma wa bihamdika, wa tabaarakasmuka, wa ta'aalaa "
          'jadduka, wa laa ilaaha ghairuk.',
          'Mahasuci Engkau ya Allah, dan dengan memuji-Mu. Mahaberkah '
          'nama-Mu, Mahatinggi keagungan-Mu, dan tidak ada tuhan selain '
          'Engkau.',
          'HR. Abu Dawud & At-Tirmidzi', 1),
         ("Allaahumma baa'id", [], hm(27),
          "Allaahumma baa'id bainii wa baina khathaayaaya kamaa baa'adta "
          'bainal masyriqi wal maghrib. Allaahumma naqqinii min khathaayaaya '
          'kamaa yunaqqats tsaubul abyadhu minad danas. Allaahummaghsilnii '
          'min khathaayaaya bits tsalji wal maa-i wal barad.',
          'Ya Allah, jauhkanlah antara aku dan kesalahan-kesalahanku '
          'sebagaimana Engkau menjauhkan antara timur dan barat. Ya Allah, '
          'bersihkanlah aku dari kesalahan-kesalahanku sebagaimana kain '
          'putih dibersihkan dari kotoran. Ya Allah, cucilah '
          'kesalahan-kesalahanku dengan salju, air, dan embun.',
          'HR. Al-Bukhari & Muslim', 1),
         ('Panjang (Wajjahtu lengkap)', [], hm(29),
          'Wajjahtu wajhiya lilladzii fatharas samaawaati wal ardha haniifaa, '
          'wa maa ana minal musyrikiin. Inna shalaatii wa nusukii wa '
          "mahyaaya wa mamaatii lillaahi rabbil 'aalamiin, laa syariika lahuu "
          'wa bidzaalika umirtu wa ana minal muslimiin. Allaahumma antal '
          "maliku laa ilaaha illaa anta, anta rabbii wa ana 'abduka, zhalamtu "
          "nafsii wa'taraftu bidzanbii faghfir lii dzunuubii jamii'aa, "
          'innahuu laa yaghfirudz dzunuuba illaa anta. Wahdinii li-ahsanil '
          'akhlaaqi laa yahdii li-ahsanihaa illaa anta, washrif \'annii '
          "sayyi-ahaa laa yashrifu 'annii sayyi-ahaa illaa anta. Labbaika wa "
          "sa'daika, wal khairu kulluhuu biyadaika, wasy syarru laisa "
          "ilaika. Ana bika wa ilaika, tabaarakta wa ta'aalaita, "
          'astaghfiruka wa atuubu ilaik.',
          'Aku hadapkan wajahku kepada Dzat yang menciptakan langit dan bumi '
          'dengan lurus, dan aku bukan termasuk orang musyrik. Sesungguhnya '
          'sholatku, ibadahku, hidupku, dan matiku untuk Allah, Tuhan '
          'semesta alam, tiada sekutu bagi-Nya; dengan itu aku diperintah '
          'dan aku termasuk orang muslim. Ya Allah, Engkaulah Raja, tidak '
          'ada tuhan selain Engkau. Engkau Tuhanku dan aku hamba-Mu. Aku '
          'telah menzalimi diriku dan aku mengakui dosaku, maka ampunilah '
          'seluruh dosaku; tidak ada yang mengampuni dosa selain Engkau. '
          'Tunjukilah aku kepada akhlak terbaik, tidak ada yang menunjukkan '
          'kepadanya selain Engkau. Jauhkanlah dariku akhlak yang buruk, '
          'tidak ada yang menjauhkannya selain Engkau. Aku penuhi '
          'panggilan-Mu dengan senang hati. Kebaikan seluruhnya ada di '
          'tangan-Mu, dan keburukan tidak disandarkan kepada-Mu. Aku '
          'bersama-Mu dan kembali kepada-Mu. Mahaberkah dan Mahatinggi '
          'Engkau, aku memohon ampun dan bertaubat kepada-Mu.',
          'HR. Muslim', 1),
     ]),

    ('fatihah', "Ta'awudz & Al-Fatihah",
     'Setiap rakaat. Diakhiri "Aamiin" sesudah Al-Fatihah.',
     'Basmalah: menurut Syafi\'iyah termasuk ayat Al-Fatihah dan dibaca '
     '(dikeraskan pada sholat jahr); Hanafiyah & Hanabilah membacanya '
     'pelan; menurut pendapat masyhur Malikiyah tidak dibaca pada sholat '
     'fardhu.',
     [('Al-Fatihah', [S, H, M, B],
       typed('أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ') + '\n' + fatihah,
       "A'uudzu billaahi minasy syaithaanir rajiim.\n"
       "Bismillaahir rahmaanir rahiim. Alhamdu lillaahi rabbil 'aalamiin. "
       'Arrahmaanir rahiim. Maaliki yaumid diin. Iyyaaka na\'budu wa '
       "iyyaaka nasta'iin. Ihdinash shiraathal mustaqiim. Shiraathal "
       "ladziina an'amta 'alaihim ghairil maghdhuubi 'alaihim wa ladh "
       'dhaalliin. Aamiin.',
       'Aku berlindung kepada Allah dari setan yang terkutuk.\n'
       'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Segala puji '
       'bagi Allah, Tuhan seluruh alam. Yang Maha Pengasih, Maha Penyayang. '
       'Pemilik hari pembalasan. Hanya kepada-Mu kami menyembah dan hanya '
       'kepada-Mu kami memohon pertolongan. Tunjukilah kami jalan yang '
       'lurus, (yaitu) jalan orang-orang yang telah Engkau beri nikmat, '
       'bukan (jalan) mereka yang dimurkai dan bukan (pula jalan) mereka '
       'yang sesat. Aamiin.',
       'QS. Al-Fatihah: 1-7', 1)]),

    ('surat', 'Membaca Surat',
     'Sesudah Al-Fatihah pada rakaat pertama dan kedua.',
     'Boleh surat atau ayat apa saja yang dihafal - di atas beberapa contoh '
     'surat pendek.',
     [
         ('Al-Ikhlas', [S, H, M, B], surah('surah112.json'),
          'Bismillaahir rahmaanir rahiim. Qul huwallaahu ahad. Allaahush '
          'shamad. Lam yalid wa lam yuulad. Wa lam yakul lahuu kufuwan ahad.',
          'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Katakanlah: '
          'Dialah Allah Yang Maha Esa. Allah tempat meminta segala sesuatu. '
          'Dia tidak beranak dan tidak diperanakkan. Dan tidak ada sesuatu '
          'pun yang setara dengan-Nya.', 'QS. Al-Ikhlas: 1-4', 1),
         ("Al-'Ashr", [], surah('surah103.json'),
          "Bismillaahir rahmaanir rahiim. Wal 'ashr. Innal insaana lafii "
          "khusr. Illal ladziina aamanuu wa 'amilush shaalihaati wa "
          'tawaashau bil haqqi wa tawaashau bish shabr.',
          'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Demi masa. '
          'Sungguh, manusia berada dalam kerugian, kecuali orang-orang yang '
          'beriman dan mengerjakan kebajikan serta saling menasihati untuk '
          'kebenaran dan saling menasihati untuk kesabaran.',
          "QS. Al-'Ashr: 1-3", 1),
         ('Al-Kautsar', [], surah('surah108.json'),
          "Bismillaahir rahmaanir rahiim. Innaa a'thainaakal kautsar. "
          'Fashalli lirabbika wanhar. Inna syaani-aka huwal abtar.',
          'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang. Sungguh, '
          'Kami telah memberimu nikmat yang banyak. Maka laksanakanlah '
          'sholat karena Tuhanmu dan berkurbanlah. Sungguh, orang-orang yang '
          'membencimu, dialah yang terputus.', 'QS. Al-Kautsar: 1-3', 1),
     ]),

    ('ruku', "Ruku'",
     'Membungkuk dengan tuma\'ninah, punggung lurus.',
     None,
     [
         ('Dengan "wa bihamdih"', [S], norm(hm(33) + ' وَبِحَمْدِهِ'),
          "Subhaana rabbiyal 'azhiimi wa bihamdih.",
          'Mahasuci Tuhanku Yang Mahaagung dan dengan memuji-Nya.',
          'HR. Abu Dawud', 3),
         ('Pendek', [H, M, B], hm(33), "Subhaana rabbiyal 'azhiim.",
          'Mahasuci Tuhanku Yang Mahaagung.', 'HR. Muslim', 3),
         ('Subhaanakallaahumma', [], hm(34),
          'Subhaanakallaahumma rabbanaa wa bihamdika, allaahummaghfir lii.',
          'Mahasuci Engkau ya Allah, Tuhan kami, dan dengan memuji-Mu. Ya '
          'Allah, ampunilah aku.', 'HR. Al-Bukhari & Muslim', 1),
         ('Subbuuhun quddus', [], hm(35),
          "Subbuuhun qudduusun, rabbul malaa-ikati war ruuh.",
          'Mahasuci, Mahaqudus, Tuhan para malaikat dan Ruh (Jibril).',
          'HR. Muslim', 1),
         ('Panjang', [], hm(36),
          "Allaahumma laka raka'tu, wa bika aamantu, wa laka aslamtu, "
          "khasya'a laka sam'ii wa basharii wa mukhkhii wa 'azhmii wa "
          "'ashabii, wa mastaqallat bihii qadamii.",
          "Ya Allah, kepada-Mu aku ruku', kepada-Mu aku beriman, dan "
          'kepada-Mu aku berserah diri. Tunduk kepada-Mu pendengaranku, '
          'penglihatanku, otakku, tulangku, urat sarafku, dan apa yang '
          'ditopang oleh kakiku.', 'HR. Muslim', 1),
     ]),

    ('itidal', "I'tidal",
     "Bangkit dari ruku' sambil membaca \"Sami'allaahu liman hamidah\", lalu "
     'berdiri tegak.',
     None,
     [
         ('Lazim di Indonesia', [S],
          norm(sami + '. ' + typed('رَبَّنَا لَكَ الْحَمْدُ') + ' ' +
               cut(hm(40), 'مِنْ شَيءٍ بَعْدُ')),
          "Sami'allaahu liman hamidah. Rabbanaa lakal hamdu mil-as "
          "samaawaati wa mil-al ardhi wa maa bainahumaa, wa mil-a maa "
          "syi'ta min syai-in ba'd.",
          'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, '
          'bagi-Mu segala puji, sepenuh langit dan sepenuh bumi dan apa yang '
          'ada di antara keduanya, dan sepenuh apa saja yang Engkau '
          'kehendaki sesudah itu.', 'HR. Muslim', 1),
         ('Pendek', [H, M, B], norm(sami + '. ' + rabbana_lakal_hamd),
          "Sami'allaahu liman hamidah. Rabbanaa wa lakal hamd.",
          'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, '
          'dan bagi-Mu segala puji.', 'HR. Al-Bukhari', 1),
         ('Hamdan katsiiran', [], norm(sami + '. ' + hm(39)),
          "Sami'allaahu liman hamidah. Rabbanaa wa lakal hamdu hamdan "
          'katsiiran thayyiban mubaarakan fiih.',
          'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, '
          'bagi-Mu segala puji, pujian yang banyak, baik, dan penuh '
          'berkah.', 'HR. Al-Bukhari', 1),
         ('Panjang', [],
          norm(sami + '. ' + typed('رَبَّنَا لَكَ الْحَمْدُ') + ' ' + hm(40)),
          "Sami'allaahu liman hamidah. Rabbanaa lakal hamdu mil-as "
          "samaawaati wa mil-al ardhi wa maa bainahumaa, wa mil-a maa "
          "syi'ta min syai-in ba'd. Ahlats tsanaa-i wal majdi, ahaqqu maa "
          "qaalal 'abdu, wa kullunaa laka 'abd. Allaahumma laa maani'a limaa "
          "a'thaita, wa laa mu'thiya limaa mana'ta, wa laa yanfa'u dzal "
          'jaddi minkal jadd.',
          'Allah Maha Mendengar orang yang memuji-Nya. Wahai Tuhan kami, '
          'bagi-Mu segala puji sepenuh langit, bumi, dan apa yang di antara '
          'keduanya, dan sepenuh apa saja yang Engkau kehendaki sesudah '
          'itu. Engkaulah yang berhak dipuji dan diagungkan; itulah '
          'perkataan paling benar yang diucapkan seorang hamba, dan kami '
          'semua adalah hamba-Mu. Ya Allah, tidak ada yang dapat menghalangi '
          'apa yang Engkau berikan, tidak ada yang dapat memberi apa yang '
          'Engkau halangi, dan kekayaan tidak bermanfaat bagi pemiliknya '
          'di hadapan-Mu.', 'HR. Muslim', 1),
     ]),

    ('sujud', 'Sujud',
     'Dahi, hidung, kedua telapak tangan, kedua lutut, dan ujung kaki '
     'menempel di lantai. Dilakukan dua kali tiap rakaat.',
     None,
     [
         ('Dengan "wa bihamdih"', [S], norm(hm(41) + ' وَبِحَمْدِهِ'),
          "Subhaana rabbiyal a'laa wa bihamdih.",
          'Mahasuci Tuhanku Yang Mahatinggi dan dengan memuji-Nya.',
          'HR. Abu Dawud', 3),
         ('Pendek', [H, M, B], hm(41), "Subhaana rabbiyal a'laa.",
          'Mahasuci Tuhanku Yang Mahatinggi.', 'HR. Muslim', 3),
         ('Subhaanakallaahumma', [], hm(42),
          'Subhaanakallaahumma rabbanaa wa bihamdika, allaahummaghfir lii.',
          'Mahasuci Engkau ya Allah, Tuhan kami, dan dengan memuji-Mu. Ya '
          'Allah, ampunilah aku.', 'HR. Al-Bukhari & Muslim', 1),
         ('Panjang', [], hm(44),
          'Allaahumma laka sajadtu, wa bika aamantu, wa laka aslamtu, '
          'sajada wajhiya lilladzii khalaqahuu wa shawwarahuu wa syaqqa '
          "sam'ahuu wa basharahuu, tabaarakallaahu ahsanul khaaliqiin.",
          'Ya Allah, kepada-Mu aku bersujud, kepada-Mu aku beriman, dan '
          'kepada-Mu aku berserah diri. Wajahku bersujud kepada Dzat yang '
          'menciptakannya, membentuknya, dan membuka pendengaran serta '
          'penglihatannya. Mahasuci Allah, sebaik-baik Pencipta.',
          'HR. Muslim', 1),
         ('Mohon ampun', [], hm(46),
          'Allaahummaghfir lii dzanbii kullahuu, diqqahuu wa jillahuu, wa '
          "awwalahuu wa aakhirahuu, wa 'alaaniyatahuu wa sirrahuu.",
          'Ya Allah, ampunilah seluruh dosaku, yang kecil dan yang besar, '
          'yang awal dan yang akhir, yang terang-terangan dan yang '
          'tersembunyi.', 'HR. Muslim', 1),
     ]),

    ('duduk', 'Duduk di Antara Dua Sujud',
     'Duduk iftirasy dengan tuma\'ninah sesudah sujud pertama.',
     None,
     [
         ('Lazim di Indonesia', [S],
          typed('رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي '
                'وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي'),
          "Rabbighfir lii warhamnii wajburnii warfa'nii warzuqnii wahdinii "
          "wa 'aafinii wa'fu 'annii.",
          'Wahai Tuhanku, ampunilah aku, rahmatilah aku, cukupkanlah aku, '
          'angkatlah derajatku, berilah aku rezeki, berilah aku petunjuk, '
          'sehatkanlah aku, dan maafkanlah aku.',
          'Gabungan riwayat Abu Dawud, At-Tirmidzi & Ibnu Majah', 1),
         ('Pendek', [H, M, B], hm(48), 'Rabbighfir lii, rabbighfir lii.',
          'Wahai Tuhanku, ampunilah aku. Wahai Tuhanku, ampunilah aku.',
          'HR. Abu Dawud & Ibnu Majah', 1),
         ('Riwayat Abu Dawud', [], hm(49),
          "Allaahummaghfir lii warhamnii wahdinii wajburnii wa 'aafinii "
          "warzuqnii warfa'nii.",
          'Ya Allah, ampunilah aku, rahmatilah aku, berilah aku petunjuk, '
          'cukupkanlah aku, sehatkanlah aku, berilah aku rezeki, dan '
          'angkatlah derajatku.', 'HR. Abu Dawud & At-Tirmidzi', 1),
     ]),

    ('tasyahud_awal', 'Tasyahud Awal',
     'Sesudah sujud kedua rakaat kedua, pada sholat 3 dan 4 rakaat '
     '(Dzuhur, Ashar, Maghrib, Isya).',
     "Menurut Syafi'iyah, disunnahkan menambah shalawat kepada Nabi sesudah "
     'tasyahud awal.',
     [
         ('Riwayat Ibnu Abbas', [S],
          norm(tasyahud_ibnu_abbas + '. ' + shalawat_pendek),
          "Attahiyyaatul mubaarakaatush shalawaatuth thayyibaatu lillaah. "
          "Assalaamu 'alaika ayyuhan nabiyyu wa rahmatullaahi wa "
          "barakaatuh. Assalaamu 'alainaa wa 'alaa 'ibaadillaahish "
          'shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna '
          "muhammadar rasuulullaah. Allaahumma shalli 'alaa muhammad.",
          'Segala penghormatan, keberkahan, shalawat, dan kebaikan adalah '
          'milik Allah. Semoga keselamatan, rahmat Allah, dan '
          'keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan '
          'tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku '
          'bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi '
          'bahwa Muhammad adalah utusan Allah. Ya Allah, limpahkanlah '
          'shalawat kepada Muhammad.', 'HR. Muslim (tasyahud)', 1),
         ('Riwayat Ibnu Mas\'ud', [H, B], hm(52),
          "Attahiyyaatu lillaahi wash shalawaatu wath thayyibaat. "
          "Assalaamu 'alaika ayyuhan nabiyyu wa rahmatullaahi wa "
          "barakaatuh. Assalaamu 'alainaa wa 'alaa 'ibaadillaahish "
          'shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna '
          "muhammadan 'abduhuu wa rasuuluh.",
          'Segala penghormatan, shalawat, dan kebaikan adalah milik Allah. '
          'Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah '
          'kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan '
          'hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan '
          'selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan '
          'utusan-Nya.', 'HR. Al-Bukhari & Muslim', 1),
         ('Riwayat Umar', [M], tasyahud_umar,
          "Attahiyyaatu lillaah, azzaakiyaatu lillaah, aththayyibaatush "
          "shalawaatu lillaah. Assalaamu 'alaika ayyuhan nabiyyu wa "
          "rahmatullaahi wa barakaatuh. Assalaamu 'alainaa wa 'alaa "
          "'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa "
          "asyhadu anna muhammadan 'abduhuu wa rasuuluh.",
          'Segala penghormatan milik Allah, amal-amal yang suci milik '
          'Allah, kebaikan dan shalawat milik Allah. Semoga keselamatan, '
          'rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. '
          'Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah '
          'yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan '
          'aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.',
          "Al-Muwaththa' (Imam Malik)", 1),
     ]),

    ('tasyahud_akhir', 'Tasyahud Akhir & Shalawat',
     'Duduk tawarruk pada rakaat terakhir: tasyahud, lalu shalawat '
     'Ibrahimiyah.',
     None,
     [
         ('Riwayat Ibnu Abbas + shalawat', [S],
          norm(tasyahud_ibnu_abbas + '.\n' + hm(53)),
          "Attahiyyaatul mubaarakaatush shalawaatuth thayyibaatu lillaah. "
          "Assalaamu 'alaika ayyuhan nabiyyu wa rahmatullaahi wa "
          "barakaatuh. Assalaamu 'alainaa wa 'alaa 'ibaadillaahish "
          'shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna '
          'muhammadar rasuulullaah.\n' + (
              "Allaahumma shalli 'alaa muhammadin wa 'alaa aali muhammad, "
              "kamaa shallaita 'alaa ibraahiima wa 'alaa aali ibraahiim, "
              'innaka hamiidum majiid. Allaahumma baarik \'alaa muhammadin '
              "wa 'alaa aali muhammad, kamaa baarakta 'alaa ibraahiima wa "
              "'alaa aali ibraahiim, innaka hamiidum majiid."),
          'Segala penghormatan, keberkahan, shalawat, dan kebaikan adalah '
          'milik Allah. Semoga keselamatan, rahmat Allah, dan '
          'keberkahan-Nya tercurah kepadamu wahai Nabi. Semoga keselamatan '
          'tercurah kepada kami dan hamba-hamba Allah yang saleh. Aku '
          'bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi '
          'bahwa Muhammad adalah utusan Allah.\n'
          'Ya Allah, limpahkanlah shalawat kepada Muhammad dan keluarga '
          'Muhammad, sebagaimana Engkau melimpahkan shalawat kepada Ibrahim '
          'dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha '
          'Mulia. Ya Allah, limpahkanlah keberkahan kepada Muhammad dan '
          'keluarga Muhammad, sebagaimana Engkau melimpahkan keberkahan '
          'kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha '
          'Terpuji lagi Maha Mulia.', 'HR. Muslim; shalawat HR. Al-Bukhari',
          1),
         ("Riwayat Ibnu Mas'ud + shalawat", [H, B],
          norm(hm(52) + '.\n' + hm(53)),
          "Attahiyyaatu lillaahi wash shalawaatu wath thayyibaat. "
          "Assalaamu 'alaika ayyuhan nabiyyu wa rahmatullaahi wa "
          "barakaatuh. Assalaamu 'alainaa wa 'alaa 'ibaadillaahish "
          'shaalihiin. Asyhadu allaa ilaaha illallaah, wa asyhadu anna '
          "muhammadan 'abduhuu wa rasuuluh.\n" + (
              "Allaahumma shalli 'alaa muhammadin wa 'alaa aali muhammad, "
              "kamaa shallaita 'alaa ibraahiima wa 'alaa aali ibraahiim, "
              'innaka hamiidum majiid. Allaahumma baarik \'alaa muhammadin '
              "wa 'alaa aali muhammad, kamaa baarakta 'alaa ibraahiima wa "
              "'alaa aali ibraahiim, innaka hamiidum majiid."),
          'Segala penghormatan, shalawat, dan kebaikan adalah milik Allah. '
          'Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah '
          'kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan '
          'hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan '
          'selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan '
          'utusan-Nya.\n'
          'Ya Allah, limpahkanlah shalawat kepada Muhammad dan keluarga '
          'Muhammad, sebagaimana Engkau melimpahkan shalawat kepada Ibrahim '
          'dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha '
          'Mulia. Ya Allah, limpahkanlah keberkahan kepada Muhammad dan '
          'keluarga Muhammad, sebagaimana Engkau melimpahkan keberkahan '
          'kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha '
          'Terpuji lagi Maha Mulia.', 'HR. Al-Bukhari & Muslim', 1),
         ('Riwayat Umar + shalawat', [M], norm(tasyahud_umar + '.\n' + hm(53)),
          "Attahiyyaatu lillaah, azzaakiyaatu lillaah, aththayyibaatush "
          "shalawaatu lillaah. Assalaamu 'alaika ayyuhan nabiyyu wa "
          "rahmatullaahi wa barakaatuh. Assalaamu 'alainaa wa 'alaa "
          "'ibaadillaahish shaalihiin. Asyhadu allaa ilaaha illallaah, wa "
          "asyhadu anna muhammadan 'abduhuu wa rasuuluh.\n" + (
              "Allaahumma shalli 'alaa muhammadin wa 'alaa aali muhammad, "
              "kamaa shallaita 'alaa ibraahiima wa 'alaa aali ibraahiim, "
              'innaka hamiidum majiid. Allaahumma baarik \'alaa muhammadin '
              "wa 'alaa aali muhammad, kamaa baarakta 'alaa ibraahiima wa "
              "'alaa aali ibraahiim, innaka hamiidum majiid."),
          'Segala penghormatan milik Allah, amal-amal yang suci milik '
          'Allah, kebaikan dan shalawat milik Allah. Semoga keselamatan, '
          'rahmat Allah, dan keberkahan-Nya tercurah kepadamu wahai Nabi. '
          'Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah '
          'yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan '
          'aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.\n'
          'Ya Allah, limpahkanlah shalawat kepada Muhammad dan keluarga '
          'Muhammad, sebagaimana Engkau melimpahkan shalawat kepada Ibrahim '
          'dan keluarga Ibrahim; sesungguhnya Engkau Maha Terpuji lagi Maha '
          'Mulia. Ya Allah, limpahkanlah keberkahan kepada Muhammad dan '
          'keluarga Muhammad, sebagaimana Engkau melimpahkan keberkahan '
          'kepada Ibrahim dan keluarga Ibrahim; sesungguhnya Engkau Maha '
          'Terpuji lagi Maha Mulia.', "Al-Muwaththa'; shalawat HR. Al-Bukhari",
          1),
         ('Shalawat versi lain', [], hm(54),
          "Allaahumma shalli 'alaa muhammadin wa 'alaa azwaajihii wa "
          "dzurriyyatihii, kamaa shallaita 'alaa aali ibraahiim. Wa baarik "
          "'alaa muhammadin wa 'alaa azwaajihii wa dzurriyyatihii, kamaa "
          "baarakta 'alaa aali ibraahiim, innaka hamiidum majiid.",
          'Ya Allah, limpahkanlah shalawat kepada Muhammad, istri-istrinya, '
          'dan keturunannya, sebagaimana Engkau melimpahkan shalawat kepada '
          'keluarga Ibrahim. Limpahkanlah keberkahan kepada Muhammad, '
          'istri-istrinya, dan keturunannya, sebagaimana Engkau melimpahkan '
          'keberkahan kepada keluarga Ibrahim; sesungguhnya Engkau Maha '
          'Terpuji lagi Maha Mulia.', 'HR. Al-Bukhari & Muslim', 1),
     ]),

    ('doa_salam', 'Doa Sebelum Salam',
     'Sesudah shalawat pada tasyahud akhir, sebelum salam.',
     None,
     [
         ('Empat perlindungan', [S, H, M, B], hm(55),
          "Allaahumma innii a'uudzu bika min 'adzaabil qabri, wa min "
          "'adzaabi jahannam, wa min fitnatil mahyaa wal mamaat, wa min "
          'syarri fitnatil masiihid dajjaal.',
          'Ya Allah, aku berlindung kepada-Mu dari siksa kubur, dari siksa '
          'Jahanam, dari fitnah kehidupan dan kematian, dan dari keburukan '
          'fitnah Al-Masih Ad-Dajjal.', 'HR. Muslim', 1),
         ('Doa Abu Bakar', [], hm(57),
          'Allaahumma innii zhalamtu nafsii zhulman katsiiraa, wa laa '
          'yaghfirudz dzunuuba illaa anta, faghfir lii maghfiratam min '
          "'indika warhamnii, innaka antal ghafuurur rahiim.",
          'Ya Allah, sungguh aku telah banyak menzalimi diriku, dan tidak '
          'ada yang mengampuni dosa selain Engkau. Maka ampunilah aku dengan '
          'ampunan dari sisi-Mu dan rahmatilah aku; sesungguhnya Engkau Maha '
          'Pengampun lagi Maha Penyayang.', 'HR. Al-Bukhari & Muslim', 1),
         ("A'innii 'alaa dzikrika", [], hm(59),
          "Allaahumma a'innii 'alaa dzikrika wa syukrika wa husni "
          "'ibaadatik.",
          'Ya Allah, tolonglah aku untuk berdzikir kepada-Mu, bersyukur '
          'kepada-Mu, dan beribadah kepada-Mu dengan baik.',
          'HR. Abu Dawud & An-Nasa\'i', 1),
         ('Panjang', [], hm(58),
          "Allaahummaghfir lii maa qaddamtu wa maa akhkhartu, wa maa "
          "asrartu wa maa a'lantu, wa maa asraftu, wa maa anta a'lamu bihii "
          'minnii. Antal muqaddimu wa antal mu-akhkhiru, laa ilaaha illaa '
          'anta.',
          'Ya Allah, ampunilah dosaku yang telah lalu dan yang akan datang, '
          'yang tersembunyi dan yang terang-terangan, yang melampaui batas, '
          'dan yang Engkau lebih mengetahuinya daripada aku. Engkaulah yang '
          'mendahulukan dan mengakhirkan, tidak ada tuhan selain Engkau.',
          'HR. Muslim', 1),
     ]),

    ('salam', 'Salam',
     'Menoleh ke kanan, lalu ke kiri.',
     'Menurut Malikiyah, satu kali salam sudah mencukupi.',
     [
         ('Salam', [S, H, M, B],
          typed('السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ'),
          "Assalaamu 'alaikum wa rahmatullaah.",
          'Semoga keselamatan dan rahmat Allah tercurah kepada kalian.',
          'HR. Abu Dawud & At-Tirmidzi', 1),
         ('Dengan "wa barakaatuh"', [],
          typed('السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ'),
          "Assalaamu 'alaikum wa rahmatullaahi wa barakaatuh.",
          'Semoga keselamatan, rahmat Allah, dan keberkahan-Nya tercurah '
          'kepada kalian.', 'HR. Abu Dawud (pada salam pertama)', 1),
     ]),

    ('qunut', 'Qunut Subuh',
     "Pada rakaat kedua sholat Subuh, sesudah i'tidal (Syafi'iyah).",
     "Qunut Subuh disunnahkan menurut Syafi'iyah (sesudah ruku') dan "
     "Malikiyah (pelan, sebelum ruku'). Menurut Hanafiyah dan Hanabilah, "
     'tidak ada qunut pada sholat Subuh - qunut dibaca pada witir atau '
     'ketika ada musibah (nazilah).',
     [
         ('Lazim di Indonesia', [S],
          norm(hm(116) + '، ' + typed(
              'فَلَكَ الْحَمْدُ عَلَى مَا قَضَيْتَ، أَسْتَغْفِرُكَ '
              'وَأَتُوبُ إِلَيْكَ، وَصَلَّى اللَّهُ عَلَى سَيِّدِنَا مُحَمَّدٍ '
              'النَّبِيِّ الْأُمِّيِّ وَعَلَى آلِهِ وَصَحْبِهِ وَسَلَّمَ')),
          'Allaahummahdinii fiiman hadait, wa \'aafinii fiiman \'aafait, wa '
          'tawallanii fiiman tawallait, wa baarik lii fiimaa a\'thait, wa '
          'qinii syarra maa qadhait, fa innaka taqdhii wa laa yuqdhaa '
          "'alaik, innahuu laa yadzillu man waalait, wa laa ya'izzu man "
          "'aadait, tabaarakta rabbanaa wa ta'aalait. Fa lakal hamdu 'alaa "
          "maa qadhait, astaghfiruka wa atuubu ilaik, wa shallallaahu 'alaa "
          "sayyidinaa muhammadinin nabiyyil ummiyyi wa 'alaa aalihii wa "
          'shahbihii wa sallam.',
          'Ya Allah, berilah aku petunjuk bersama orang-orang yang Engkau '
          'beri petunjuk, berilah aku keselamatan bersama orang-orang yang '
          'Engkau beri keselamatan, uruslah aku bersama orang-orang yang '
          'Engkau urus, berkahilah apa yang Engkau berikan kepadaku, dan '
          'jagalah aku dari keburukan yang Engkau takdirkan. Sesungguhnya '
          'Engkaulah yang menetapkan dan tidak ada yang menetapkan atas-Mu. '
          'Tidak akan hina orang yang Engkau lindungi, dan tidak akan mulia '
          'orang yang Engkau musuhi. Mahaberkah Engkau wahai Tuhan kami dan '
          'Mahatinggi. Bagi-Mu segala puji atas apa yang Engkau tetapkan. '
          'Aku memohon ampun dan bertaubat kepada-Mu. Semoga Allah '
          'melimpahkan shalawat dan salam kepada junjungan kami Nabi '
          'Muhammad yang ummi, beserta keluarga dan sahabatnya.',
          'Riwayat Al-Hasan bin Ali (Abu Dawud, At-Tirmidzi); tambahan '
          "penutup dari ulama Syafi'iyah", 1),
         ('Riwayat Al-Hasan bin Ali', [], hm(116),
          'Allaahummahdinii fiiman hadait, wa \'aafinii fiiman \'aafait, wa '
          'tawallanii fiiman tawallait, wa baarik lii fiimaa a\'thait, wa '
          'qinii syarra maa qadhait, fa innaka taqdhii wa laa yuqdhaa '
          "'alaik, innahuu laa yadzillu man waalait, wa laa ya'izzu man "
          "'aadait, tabaarakta rabbanaa wa ta'aalait.",
          'Ya Allah, berilah aku petunjuk bersama orang-orang yang Engkau '
          'beri petunjuk, berilah aku keselamatan bersama orang-orang yang '
          'Engkau beri keselamatan, uruslah aku bersama orang-orang yang '
          'Engkau urus, berkahilah apa yang Engkau berikan kepadaku, dan '
          'jagalah aku dari keburukan yang Engkau takdirkan. Sesungguhnya '
          'Engkaulah yang menetapkan dan tidak ada yang menetapkan atas-Mu. '
          'Tidak akan hina orang yang Engkau lindungi, dan tidak akan mulia '
          'orang yang Engkau musuhi. Mahaberkah Engkau wahai Tuhan kami dan '
          'Mahatinggi.', 'HR. Abu Dawud & At-Tirmidzi', 1),
         ("Qunut Umar (Malikiyah)", [M], hm(118),
          "Allaahumma iyyaaka na'budu, wa laka nushallii wa nasjudu, wa "
          "ilaika nas'aa wa nahfidu, narjuu rahmataka wa nakhsyaa "
          "'adzaabaka, inna 'adzaabaka bil kaafiriina mulhaq. Allaahumma "
          "innaa nasta'iinuka wa nastaghfiruka, wa nutsnii 'alaikal khaira "
          "wa laa nakfuruka, wa nu'minu bika wa nakhdha'u laka, wa nakhla'u "
          'man yakfuruk.',
          'Ya Allah, hanya kepada-Mu kami menyembah, untuk-Mu kami sholat '
          'dan bersujud, kepada-Mu kami bersegera dan bergegas. Kami '
          'mengharap rahmat-Mu dan takut akan azab-Mu; sesungguhnya azab-Mu '
          'pasti menimpa orang-orang kafir. Ya Allah, kami memohon '
          'pertolongan dan ampunan-Mu, kami memuji-Mu dengan kebaikan dan '
          'tidak mengingkari-Mu, kami beriman kepada-Mu dan tunduk '
          'kepada-Mu, serta kami berlepas diri dari orang yang '
          'mengingkari-Mu.', 'Riwayat Umar bin Al-Khaththab (Al-Baihaqi)', 1),
     ]),
]


def lit(s):
    if s is None:
        return 'null'
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$') + "'"


out = ['// DIBUAT OTOMATIS oleh tool/gen_sholat.py - jangan diedit langsung.',
       '//',
       '// Bacaan sholat wajib beberapa versi. Teks Arab dari Hisnul Muslim',
       '// (hisnmuslim.com) & mushaf (api.alquran.cloud); teks pendek yang',
       '// tidak ada di sumber tersebut ditandai typed() di generator. Latin &',
       '// terjemahan bersifat bantuan - rujukan utama teks Arab.',
       '',
       "import '../services/sholat_guide.dart';",
       '',
       'const sholatSteps = <SholatStep>[']
for sid, title, when, note, variants in steps:
    out.append('  SholatStep(')
    out.append(f'    id: {lit(sid)},')
    out.append(f'    title: {lit(title)},')
    out.append(f'    when: {lit(when)},')
    out.append(f'    note: {lit(note)},')
    out.append('    variants: [')
    for label, mz, ar, la, arti, src, rep in variants:
        out.append('      SholatVariant(')
        out.append(f'        label: {lit(label)},')
        out.append('        madzhab: {' + ', '.join(f'Madzhab.{m}' for m in mz) + '},')
        out.append(f'        arabic: {lit(ar)},')
        out.append(f'        latin: {lit(la)},')
        out.append(f'        arti: {lit(arti)},')
        out.append(f'        source: {lit(src)},')
        out.append(f'        repeat: {rep},')
        out.append('      ),')
    out.append('    ],')
    out.append('  ),')
out.append('];')

# Niat: lafaz lazim madzhab Syafi'i (ketikan). (kunci, nama arab, rakaat arab,
# latin nama, latin rakaat, rakaat)
niat = [
    ('subuh', 'الصُّبْحِ', 'رَكْعَتَيْنِ', 'shubhi', "rak'ataini", 2),
    ('dzuhur', 'الظُّهْرِ', 'أَرْبَعَ رَكَعَاتٍ', 'zhuhri', "arba'a raka'aatin", 4),
    ('ashar', 'الْعَصْرِ', 'أَرْبَعَ رَكَعَاتٍ', "'ashri", "arba'a raka'aatin", 4),
    ('maghrib', 'الْمَغْرِبِ', 'ثَلَاثَ رَكَعَاتٍ', 'maghribi', "tsalaatsa raka'aatin", 3),
    ('isya', 'الْعِشَاءِ', 'أَرْبَعَ رَكَعَاتٍ', "'isyaa-i", "arba'a raka'aatin", 4),
]
roles = [('', ''), (' مَأْمُومًا', " ma'muuman"), (' إِمَامًا', ' imaaman')]
out.append('')
out.append('/// Lafaz niat per sholat: [sendiri, makmum, imam].')
out.append('const sholatNiat = <String, List<(String, String)>>{')
for key, ar, rk, la, lrk, n in niat:
    out.append(f'  {lit(key)}: [')
    for rar, rla in roles:
        a = typed(f'أُصَلِّي فَرْضَ {ar} {rk} مُسْتَقْبِلَ الْقِبْلَةِ أَدَاءً{rar} لِلَّهِ تَعَالَى')
        l = f"Ushallii fardhal {la} {lrk} mustaqbilal qiblati adaa-an{rla} lillaahi ta'aalaa."
        l = l.replace('fardhal shubhi', 'fardhash shubhi').replace('fardhal zhuhri', 'fardhazh zhuhri')
        out.append(f'    ({lit(a)}, {lit(l)}),')
    out.append('  ],')
out.append('};')
open('lib/data/sholat_data.dart', 'w').write('\n'.join(out) + '\n')
print('ok', len(steps), sum(len(s[4]) for s in steps))
