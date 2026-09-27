# Membuat assets/quran/quran.json - teks Al-Qur'an Mushaf Standar Indonesia
# (rasm Kemenag, cocok dengan font LPMQ) + terjemahan Kemenag, sama dengan
# yang dipakai web Bilal Tarawih.
#
#   python3 tool/gen_quran_text.py /path/ke/IrmamStorage.sqlite
#
# Hanya dibaca dari basis data web (tabel surah & surah_detail).
# Isi: {"surah": [[nama, nama arab, arti, jenis, jumlah ayat, keterangan]],
#       "ayah": [[teks arab, terjemahan, juz, halaman], ...]} - urut global
# (ayat ke-1..6236), jadi indeksnya = ayahIndex(surah, ayat) - 1.
import json
import re
import sqlite3
import sys

db = sqlite3.connect(f'file:{sys.argv[1]}?mode=ro', uri=True)

# penanda sisa sumber data (bukan bagian teks mushaf): U+0608 ؈, U+0609 ؉,
# U+06D4 ۔ (penanda akhir juz - juz sudah ada di kolom sendiri)
JUNK = dict.fromkeys(map(ord, '؈؉۔'))


def clean(t):
    t = (t or '').translate(JUNK)
    return re.sub(r'\s+', ' ', t).strip()


surah = [
    [clean(n), clean(a), clean(t), (k or '').strip().lower(), c, clean(ket)]
    for n, a, t, k, c, ket in db.execute(
        'SELECT name, arab_name, translate, type, count_ayat, keterangan '
        'FROM surah ORDER BY id')
]
assert len(surah) == 114

ayah = []
for sid, (count) in enumerate([s[4] for s in surah], start=1):
    rows = db.execute(
        'SELECT ayat_number, ayat_text, translate, juz_id, page_number '
        'FROM surah_detail WHERE surah_id = ? ORDER BY ayat_number', (sid,),
    ).fetchall()
    assert [r[0] for r in rows] == list(range(1, count + 1)), sid
    ayah += [[clean(t), clean(tr), j, p] for _, t, tr, j, p in rows]
assert len(ayah) == 6236

json.dump({'surah': surah, 'ayah': ayah},
          open('assets/quran/quran.json', 'w'), ensure_ascii=False,
          separators=(',', ':'))
print('ok', len(surah), len(ayah))
