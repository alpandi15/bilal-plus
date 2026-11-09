# Catatan: Penomoran Rujukan Hadits (untuk update nanti)

> Status: **belum dikerjakan**, menunggu keputusan pendekatan (lihat
> [Pilihan perbaikan](#pilihan-perbaikan)). Diaudit 9 November 2026, versi
> 1.18.2+31. Kode belum diubah.

## Masalah

Rujukan seperti "HR. Muslim no. 2720" bisa diketuk (`HadithRefText`,
`lib/widgets/hadith_ref_text.dart`) dan langsung membuka **nomor yang sama**
di kitab hadits dalam aplikasi. Kitab itu diunduh dari
`https://bilal-tarawih.vercel.app/api/hadits/{kitab}` dan memakai
**penomoran Lidwa**. Sebagian rujukan di kode justru memakai **penomoran
umum**, sehingga saat diketuk yang terbuka hadits lain, atau muncul "tidak
ditemukan" kalau nomornya tidak ada.

### Apa itu Lidwa

Lidwa Pusaka i-Software membuat *Ensiklopedi Hadits Kitab 9 Imam* (teks Arab
dan terjemahan Indonesia). Lidwa memberi nomor urut sendiri pada setiap
riwayat. Terjemahannya banyak dipakai situs dan API hadits di Indonesia.

Penomoran umum (sunnah.com, dorar.net, kebanyakan buku) berasal dari para
pentahqiq, misalnya Muhammad Fuad Abdul Baqi untuk Muslim dan Ibnu Majah,
dan *Fathul Bari* untuk Bukhari.

| Hadits | Penomoran umum | Lidwa |
|---|---|---|
| Amal paling dicintai: sholat tepat waktu | Bukhari 527 | Bukhari 496 |
| Doa *ashlih lii diinii* | Muslim 2720 | Muslim 4897 |
| Doa sapu jagat | Muslim 2690 | Muslim 4856 |

Nomor tertinggi di kitab aplikasi cocok dengan Lidwa: Bukhari 7008, Muslim
5362, Tirmidzi 3891, Abu Daud 4590, Nasa'i 5662, Ibnu Majah 4331. Ada nomor
yang kosong (Muslim hanya berisi 4.930 hadits).

## Hasil audit per file

### Sudah benar (nomor Lidwa)

Dicek manual lewat terjemahan, dan cocok:

- `lib/data/sholat_dalil.dart`: dalil sholat, Jumat, qashar/jamak, zakat,
  puasa sunnah. Contoh: Bukhari 609 (jama'ah 27 derajat), Muslim 1050 (Subuh
  dalam jaminan Allah), Muslim 1626 (nisab), Nasa'i 2404, Abu Daud 888,
  Tirmidzi 2545.
- `lib/services/ibadah_insight.dart`: saran laporan. Contoh: Bukhari 496,
  609, 617; Muslim 116, 1103, 1181, 1982; Tirmidzi 2835.
- Muslim 1103 di `lib/services/sholat_time.dart` dan
  `lib/widgets/ibadah/sholat_log_sheet.dart`.
- Di `assets/doa/doa.json`: Abu Daud 2010/2011 (doa berbuka) dan Tirmidzi
  3348 (doa keluar rumah).

Catatan: sebagian nomor Lidwa hanya berisi "dengan hadits yang serupa"
(sanad tambahan), misalnya Muslim 1926, 1977, 1984, 1108. Nomornya benar,
tapi matannya ada di nomor sebelumnya, jadi halaman yang terbuka tidak
menampilkan isi hadits. Pertimbangkan merujuk ke nomor yang memuat matan.

### Salah (penomoran umum)

"Kandidat Lidwa" adalah hasil pencocokan teks Arab otomatis. **✓** berarti
skor tinggi (≥ 0,85) dan teksnya cukup panjang. **?** berarti perlu dicek
manual (skor rendah atau doanya terlalu pendek sehingga banyak hadits mirip).
**–** berarti tidak ada teks Arab untuk dicocokkan.

**`lib/data/dzikir_sholat_data.dart`** (dibuat oleh
`tool/gen_dzikir_sholat.py`; ubah di generator, bukan di file `.dart`):

| Bacaan | Rujukan sekarang | Kandidat Lidwa |
|---|---|---|
| Istighfar | Muslim 591; Abu Daud 1517; Tirmidzi 3577 | Muslim ? (sekitar 932); Abu Daud ?; Tirmidzi 3319 ✓ |
| Tahlil (*yuhyii wa yumiit*) | Tirmidzi 3474 (nomor tidak ada) | ? |
| *Allaahumma ajirnii minan naar* | Abu Daud 5079 (nomor tidak ada) | ? |
| *Allaahumma antas salaam* | Muslim 591 | ? (sekitar 932) |
| Tasbih/tahmid/takbir/tahlil penutup | Muslim 597 | 4901 ? (perlu dicek; hadits 33× ada di bab dzikir setelah sholat, sekitar 936-940) |
| Doa sapu jagat | Bukhari 6389; Muslim 2690 | Bukhari ?; Muslim 4856 ✓ |
| *Laa maani'a* | Bukhari 844; Muslim 593 | Bukhari 799 ✓; Muslim 933 ✓ |
| *Laa haula … mukhlishiina* | Muslim 594 | 935 ✓ |
| Al-Ikhlas, Al-Falaq, An-Nas | Abu Daud 1523; Tirmidzi 2903 (nomor tidak ada) | – |
| *Allaahumma a'innii* | Abu Daud 1522 (nomor tidak ada); Nasa'i 1303 | Abu Daud 1301 ?; Nasa'i – |
| *'Ilman naafi'aa* (Subuh) | Ibnu Majah 925 | 915 ? |
| *Ashlih lii diinii* | Muslim 2720 | 4897 ✓ |
| *As-alukal hudaa wat tuqaa* | Muslim 2721 | 4898 ✓ |
| *Yaa muqallibal quluub* | Tirmidzi 2140 | ? |

**`lib/pages/asmaul_husna_page.dart`**: keutamaan 99 nama, Bukhari 2736,
Muslim 2677, Tirmidzi 3507. Kandidat Lidwa: – (cari manual).

**Silsilah**: Muslim 2276 di `lib/data/silsilah_data.dart` (Kinanah) dan
`lib/pages/silsilah_page.dart`. Kandidat Lidwa: – (cari manual).

**`lib/data/zakat_fitrah_data.dart`** (doa amil): Bukhari 4166, Muslim 1078.
Kandidat Lidwa: ?.

**`assets/doa/doa.json`** (sebagian besar penomoran umum):

| Doa | Rujukan sekarang | Kandidat Lidwa |
|---|---|---|
| Masuk rumah | Abu Daud 5096 (nomor tidak ada) | 4432 ✓ |
| Kafaratul majelis | Abu Daud 4859 (nomor tidak ada); Tirmidzi 3433 | Abu Daud 4217 ✓; Tirmidzi 3355 ✓ |
| Melihat hilal | Tirmidzi 3451 (nomor tidak ada) | 3373 ✓ |
| Sebelum & bangun tidur | Bukhari 6314; Muslim 2711 (nomor tidak ada) | Bukhari 6845 ✓; Muslim 4886 ✓ |
| Memohon ilmu yang bermanfaat | Ibnu Majah 925 | 915 ✓ |
| Malam Lailatul Qadar | Ibnu Majah 3850; Tirmidzi 3513 | Ibnu Majah 3840 ✓; Tirmidzi 3413 ? |
| Sebelum makan | Abu Daud 3767; Ibnu Majah 3264; Tirmidzi 1858 | ? (bismillah terlalu pendek) |
| Sesudah makan | Bukhari 5458; Muslim 2734; Ibnu Majah 3285; Tirmidzi 3458 | ? |
| Masuk WC | Tirmidzi 606 | ? |
| Keluar WC | Abu Daud 30; Ibnu Majah 300; Tirmidzi 7 | – (Tirmidzi 7 kebetulan berisi komentar hadits yang sama) |
| Nabi Yunus | Tirmidzi 3505 | ? |
| Menerima zakat fitrah | Bukhari 4166; Muslim 1078 | ? |

## Pilihan perbaikan

1. **Ganti semua ke nomor Lidwa** (disarankan). Konsisten dengan
   `sholat_dalil.dart` dan saran laporan; nomor yang tertulis sama dengan yang
   terbuka. Kekurangannya, nomornya tidak cocok dengan sunnah.com atau buku
   berbahasa Arab.
2. **Tampilkan nomor umum, tautan dipetakan ke Lidwa.** Nomor cocok dengan
   rujukan internasional. Butuh tabel pemetaan per rujukan (tidak ada rumus
   konversi), misalnya `standard -> lidwa` per kitab yang dipakai
   `HadithRefText`.

Apa pun pilihannya:

- Cocokkan setiap nomor ke teks Arab di kitab aplikasi. Yang ragu tidak
  ditulis (aturan dalil di `docs/ROADMAP.md`).
- Untuk `dzikir_sholat_data.dart`, ubah `tool/gen_dzikir_sholat.py` lalu
  jalankan ulang generatornya.
- `doa.json` berasal dari data web; perbaikannya bisa lewat skrip yang
  mengganti nomor di file itu.
- Pertimbangkan tes yang memastikan setiap rujukan di kode ada di daftar yang
  sudah diverifikasi, supaya rujukan baru tidak meleset lagi.

## Cara mengaudit ulang

```bash
python3 tool/audit_hadits_refs.py            # unduh kitab sekali ke build/hadits_cache/, lalu laporan
python3 tool/audit_hadits_refs.py --refresh  # unduh ulang
```

Kolom laporan: status, kitab, nomor, file dan item, lalu kandidat terbaik
`(nomor Lidwa, skor kecocokan teks Arab, skor di nomor sekarang)`. Status
`tanpa-teks-arab` dan `meleset` di `sholat_dalil.dart` muncul karena tidak
ada teks Arab hadits di dekatnya; bagian itu sudah dicek manual dan benar.

API `keyword` di server tidak berfungsi (selalu mengembalikan semua hadits),
jadi pencarian dilakukan di salinan lokal.
