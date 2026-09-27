# Membuat lib/data/zakat_fitrah_data.dart dari naskah panduan web Bilal
# Tarawih (src/data/zakat-fitrah.ts) - isi teks sama persis dengan web.
#
#   python3 tool/gen_zakat.py /path/ke/web-bilal-tarawih/src/data/zakat-fitrah.ts
import re
import sys

src = open(sys.argv[1], encoding='utf-8').read()


def block(name):
    m = re.search(r'export const ' + name + r'\b[^=]*=\s*', src)
    assert m, name
    i = m.end()
    opener = src[i]
    closer = {'[': ']', '{': '}'}[opener]
    depth, j, in_str = 0, i, None
    while True:
        c = src[j]
        if in_str:
            if c == '\\':
                j += 2
                continue
            if c == in_str:
                in_str = None
        elif c in '"\'`':
            in_str = c
        elif c == opener:
            depth += 1
        elif c == closer:
            depth -= 1
            if depth == 0:
                return src[i:j + 1]
        j += 1


def strings(text, key):
    return [s for s in re.findall(key + r':\s*"((?:[^"\\]|\\.)*)"', text)]


def const_string(name):
    m = re.search(r'export const ' + name + r'\s*=\s*\n?\s*"((?:[^"\\]|\\.)*)"', src)
    assert m, name
    return m.group(1)


def lit(s):
    s = s.replace('\\"', '"')
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def poin(name):
    b = block(name)
    return list(zip(strings(b, 'judul'), strings(b, 'detail')))


out = ['// DIBUAT OTOMATIS oleh tool/gen_zakat.py dari naskah web Bilal Tarawih',
       '// (src/data/zakat-fitrah.ts) - jangan diedit langsung.',
       '',
       "import '../pages/zakat_fitrah_page.dart';",
       '']
for name, var in [('SYARAT_WAJIB', 'zakatSyaratWajib'),
                  ('DITANGGUNGKAN', 'zakatDitanggung'),
                  ('FIDYAH_SIAPA', 'fidyahSiapa')]:
    out.append(f'const {var} = <ZakatPoin>[')
    for j, d in poin(name):
        out.append(f'  ZakatPoin({lit(j)}, {lit(d)}),')
    out.append('];')
    out.append('')

for name, var in [('KADAR', 'zakatKadar'), ('FIDYAH_KADAR', 'fidyahKadar')]:
    b = block(name)
    out.append(f'const {var} = <String, String>{{')
    for k, v in re.findall(r'(\w+):\s*"((?:[^"\\]|\\.)*)"', b):
        out.append(f'  {lit(k)}: {lit(v)},')
    out.append('};')
    out.append('')

b = block('WAKTU')
items = re.findall(r'hukum:\s*"([^"]*)",\s*tone:\s*"([^"]*)",\s*kapan:\s*"([^"]*)",\s*detail:\s*"((?:[^"\\]|\\.)*)"', b)
assert len(items) == 5, items
out.append('const zakatWaktu = <ZakatWaktu>[')
for h, t, k, d in items:
    out.append(f'  ZakatWaktu({lit(h)}, {lit(t)}, {lit(k)}, {lit(d)}),')
out.append('];')
out.append('')

ijab, qabul = const_string('IJAB'), const_string('QABUL')
b = block('TATA_CARA')
steps = re.findall(r'\{\s*judul:\s*"([^"]*)",\s*detail:\s*"((?:[^"\\]|\\.)*)",?(?:\s*peran:\s*"(\w+)",\s*ucapan:\s*(IJAB|QABUL),?)?\s*\}', b)
assert len(steps) == 5, steps
out.append('const zakatTataCara = <ZakatLangkah>[')
for j, d, peran, uc in steps:
    ucapan = {'IJAB': ijab, 'QABUL': qabul}.get(uc)
    out.append(f'  ZakatLangkah({lit(j)}, {lit(d)}, '
               f'peran: {lit(peran) if peran else "null"}, '
               f'ucapan: {lit(ucapan) if ucapan else "null"}),')
out.append('];')
out.append('')
out.append(f'const zakatCatatanAdat = {lit(const_string("CATATAN_ADAT"))};')
out.append('')
for name, var in [('PENUTUP', 'zakatDoaPenutup'), ('DOA_PANITIA', 'zakatDoaPanitia')]:
    b = block(name)
    out.append(f'const {var} = <String, String>{{')
    for k, v in re.findall(r'(\w+):\s*\n?\s*"((?:[^"\\]|\\.)*)"', b):
        out.append(f'  {lit(k)}: {lit(v)},')
    out.append('};')
    out.append('')
open('lib/data/zakat_fitrah_data.dart', 'w').write('\n'.join(out))
print('ok')
