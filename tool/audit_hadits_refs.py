"""Audit rujukan hadits ("HR. Kitab no. N") terhadap kitab hadits di aplikasi.

Kitab di aplikasi (API bilal-tarawih.vercel.app/api/hadits) memakai penomoran
Lidwa, sedangkan sebagian rujukan di kode memakai penomoran umum. Skrip ini
mengunduh enam kitab (sekali, ke build/hadits_cache/), lalu untuk setiap
rujukan mencocokkan teks Arab di dekatnya dengan hadits di nomor itu dan
mencari nomor Lidwa yang paling cocok. Lihat docs/HADITS_RUJUKAN.md.

    python3 tool/audit_hadits_refs.py            # laporan ke layar
    python3 tool/audit_hadits_refs.py --refresh  # unduh ulang kitab

Skor = bagian kata Arab (tanpa harakat) di sekitar rujukan yang ada di
hadits tersebut. Rujukan tanpa teks Arab di dekatnya (mis. dalil berupa
terjemahan) harus dicek manual lewat terjemahan.
"""
import concurrent.futures as cf
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "build/hadits_cache"
API = "https://bilal-tarawih.vercel.app/api/hadits"
BOOKS = {"bukhari": 6638, "muslim": 4930, "tirmidzi": 3625, "abu-daud": 4419,
         "nasai": 5364, "ibnu-majah": 4285}
PAGE = 300


def _page(book, p):
    url = f"{API}/{book}?page={p}&limit={PAGE}"
    for _ in range(3):
        try:
            return json.load(urllib.request.urlopen(url, timeout=90))["data"]
        except Exception as e:  # noqa: BLE001 - coba lagi
            err = e
    raise err


def download(refresh=False):
    CACHE.mkdir(parents=True, exist_ok=True)
    for book, total in BOOKS.items():
        out = CACHE / f"{book}.json"
        if out.exists() and not refresh:
            continue
        with cf.ThreadPoolExecutor(6) as ex:
            pages = ex.map(lambda p: _page(book, p), range(1, total // PAGE + 2))
            data = [h for page in pages for h in page]
        out.write_text(json.dumps(data, ensure_ascii=False))
        print(f"unduh {book}: {len(data)} hadits")


import re,glob,unicodedata,sys,collections,os
os.chdir(ROOT)
download('--refresh' in sys.argv)
K={"bukhari":"bukhari","muslim":"muslim","tirmidzi":"tirmidzi","abu daud":"abu-daud","abu dawud":"abu-daud","nasai":"nasai","nasa'i":"nasai","ibnu majah":"ibnu-majah"}
kit={b:{h["number"]:h for h in json.loads((CACHE / f"{b}.json").read_text())} for b in set(K.values())}
def norm(t):
    t=unicodedata.normalize("NFD",t)
    t="".join(c for c in t if not unicodedata.category(c).startswith("M"))
    t=re.sub("[إأآٱا]","ا",t).replace("ى","ي").replace("ة","ه").replace("ـ","").replace("ٰ","")
    return re.sub(r"[^ء-ي ]"," ",t)
def words(t): return [w for w in norm(t).split() if len(w)>=3]
idx={b:{n:set(words(h["arab"])) for n,h in d.items()} for b,d in kit.items()}
pat=re.compile(r"(Bukhari|Muslim|Abu Daud|Abu Dawud|Tirmidzi|Nasa'?i|Ibnu Majah)\s+no\.\s*(?:<a[^>]*>)?\s*(\d+)",re.I)
files=sorted(glob.glob('lib/**/*.dart',recursive=True))+['assets/doa/doa.json']
rows=[]
for f in files:
    s=open(f,encoding='utf-8').read()
    if f.endswith('.json'):
        # doa.json: per objek
        data=json.load(open(f))
        items=data if isinstance(data,list) else next(v for v in data.values() if isinstance(v,list))
        for it in items:
            txt=json.dumps(it,ensure_ascii=False)
            for m in pat.finditer(txt):
                rows.append((f,it.get('judul') or it.get('title') or '',m[1],int(m[2]),txt))
        continue
    for m in pat.finditer(s):
        ctx=s[max(0,m.start()-1500):m.start()]
        # konteks: teks Arab terdekat sebelum rujukan
        title=re.findall(r"title:\s*'([^']{0,60})",ctx) or re.findall(r"'([A-Z][^']{3,50})'",ctx)
        rows.append((f,title[-1] if title else '',m[1],int(m[2]),ctx))
out=collections.Counter()
for f,title,book,n,ctx in rows:
    b=K[book.lower().replace("’","'")]
    ar=set(words(ctx[-1200:]))
    if len(ar)<3:
        status,best="tanpa-teks-arab",None
    else:
        def score(nn): 
            w=idx[b].get(nn); 
            return len(ar&w)/len(ar) if w else 0
        here=score(n)
        bestn=max(idx[b],key=lambda nn:len(ar&idx[b][nn]))
        bs=score(bestn)
        if n not in kit[b]: status="nomor-tidak-ada"
        elif here>=0.5: status="cocok"
        else: status="meleset"
        best=(bestn,round(bs,2),round(here,2))
    out[status]+=1
    print(f"{status:16} {book:10} {n:5} | {f.replace('lib/','')}: {title[:38]} | terbaik(lidwa,skor,skor-di-nomor)={best}")
print(out)
