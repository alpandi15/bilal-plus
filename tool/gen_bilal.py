# Membuat lib/data/bilal_data.dart - bacaan bilal tarawih 11 rakaat.
#
#   python3 tool/gen_bilal.py && dart format lib/data/bilal_data.dart
#
# Sumber: tool/bilal_tarawih.json, ekspor tabel bilal & bilal_detail dari
# IrmamStorage.sqlite milik web Bilal Tarawih (sama dengan
# /bacaan/bilal-tarawih-11rakaat), urut per bagian lalu id baris:
#
#   sqlite3 -readonly -json IrmamStorage.sqlite "select b.id as bagian,
#     b.keterangan, d.id, d.bilal_number, d.type, d.arabic, d.latin, d.indo
#     from bilal b left join bilal_detail d on b.id=d.bilal_id
#     order by b.id, d.id" > tool/bilal_tarawih.json
#
# Teks dipakai apa adanya (hanya spasi dirapikan) supaya sama dengan web.
import json
import re

rows = json.load(open('tool/bilal_tarawih.json'))


def clean(s):
    return re.sub(r'\s+', ' ', s or '').strip()


def lit(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


sections = {}
for r in rows:
    sections.setdefault(r['bagian'], (clean(r['keterangan']), []))[1].append(r)

out = [
    '// DIBUAT OTOMATIS oleh tool/gen_bilal.py - jangan diedit langsung.',
    '//',
    '// Bacaan bilal tarawih 11 rakaat, sama dengan web Bilal Tarawih.',
    '',
    "import '../services/bilal_tarawih.dart';",
    '',
    'const bilalSections = <BilalSection>[',
]
for _, (title, items) in sorted(sections.items()):
    out.append('  BilalSection(')
    out.append(f'    title: {lit(title)},')
    out.append('    items: [')
    for r in items:
        kind = {'doa': 'BilalKind.doa', 'niat': 'BilalKind.niat',
                'dzikir': 'BilalKind.dzikir'}.get(r['type'], 'BilalKind.seruan')
        out.append('      BilalItem(')
        out.append(f'        kind: {kind},')
        out.append(f'        arabic: {lit(clean(r["arabic"]))},')
        out.append(f'        latin: {lit(clean(r["latin"]))},')
        out.append(f'        arti: {lit(clean(r["indo"]))},')
        out.append('      ),')
    out.append('    ],')
    out.append('  ),')
out.append('];')
open('lib/data/bilal_data.dart', 'w').write('\n'.join(out) + '\n')
print('ok', len(sections), len(rows))
