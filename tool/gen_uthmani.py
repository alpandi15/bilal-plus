# Membuat assets/quran/uthmani.json - teks Rasm Utsmani riwayat Hafs dari
# Kompleks Percetakan Al-Qur'an Raja Fahd (KFGQPC), pasangan font
# assets/fonts/UthmanicHafs_V18.ttf. Dipakai mode Mushaf.
#
#   python3 tool/gen_uthmani.py
#
# Sumber: tool/kfgqpc/hafsData_v18.json (qurancomplex.gov.sa/techquran/dev,
# salinan github.com/thetruetruth/quran-data-kfgqpc). Teks tidak diubah;
# hanya nomor ayat di ujung (NBSP + angka Arab) dibuang karena mushaf
# menggambar medali ayatnya sendiri.
import json
import re

data = json.load(open('tool/kfgqpc/hafsData_v18.json', encoding='utf-8'))
assert len(data) == 6236
data.sort(key=lambda x: x['id'])
out = []
for i, a in enumerate(data):
    assert a['id'] == i + 1
    t = re.sub(r' [٠-٩]+$', '', a['aya_text']).strip()
    assert not re.search(r'[٠-٩]', t), (a['id'], t)
    out.append(t)
json.dump(out, open('assets/quran/uthmani.json', 'w', encoding='utf-8'),
          ensure_ascii=False, separators=(',', ':'))
print('ok', len(out))
