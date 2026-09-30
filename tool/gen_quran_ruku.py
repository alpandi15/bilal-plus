"""Membuat lib/services/quran_ruku.dart dari data Tanzil (quran-data.js,
https://tanzil.net/res/text/metadata/quran-data.js, lisensi CC BY 3.0 -
salinannya di tool/quran-data.js).

Isinya nomor ayat global (1..6236) awal tiap ruku' (556 ruku'), dasar tanda
'ain di akhir ruku'.

    python3 tool/gen_quran_ruku.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
src = (ROOT / "tool" / "quran-data.js").read_text()


def block(name):
    s = src[src.index(f"QuranData.{name} = [") :]
    return s[: s.index("];")]


# jumlah ayat per surah: QuranData.Sura = [[start, ayas, ...], ...]
suras = [
    int(m[1])
    for m in re.findall(r"\[(\d+),\s*(\d+),\s*\d+,\s*\d+,", block("Sura"))
]
assert len(suras) == 114, len(suras)
first = [1]
for n in suras[:-1]:
    first.append(first[-1] + n)

rukus = [tuple(map(int, m)) for m in re.findall(r"\[(\d+),\s*(\d+)\]", block("Ruku"))]
assert len(rukus) == 556, len(rukus)
starts = [first[s - 1] + a - 1 for s, a in rukus]
assert starts == sorted(starts) and starts[0] == 1

lines = []
for i in range(0, len(starts), 12):
    lines.append("  " + ", ".join(str(x) for x in starts[i : i + 12]) + ",")

out = f"""// DIBUAT OTOMATIS oleh tool/gen_quran_ruku.py - jangan diubah manual.
// Sumber: Tanzil quran-data.js (CC BY 3.0), https://tanzil.net

/// Nomor ayat global (1..6236) awal tiap ruku' - {len(starts)} ruku'. Tanda
/// 'ain diletakkan di ayat terakhir tiap ruku'.
const rukuStarts = <int>[
{chr(10).join(lines)}
];
"""
(ROOT / "lib" / "services" / "quran_ruku.dart").write_text(out)
print("ruku:", len(starts))
