# Peta Jalan Bilal+ (M0 - M7)

Rencana 11 fitur berikutnya, dikerjakan **per fase (milestone)**. Satu fase
selesai (diuji, dicek di emulator, di-commit, diberi catatan rilis & tag)
sebelum fase berikutnya dimulai.

> Status per **31 Oktober 2026** · versi saat ini **1.15.0+26** · skema
> database **v9** · baseline analyzer **57 isu** · semua tes lulus.

## Ringkasan & urutan

Urutan mengikuti prioritas: tiga fitur kecil berdampak besar dulu
(#1, #6, #8), lalu fitur yang menambah kedalaman, dan yang paling
berisiko/menyeluruh di akhir.

| Fase | Isi | Fitur | Perkiraan usaha | Usulan versi |
|---|---|---|---|---|
| **M0** | Fondasi bersama | infrastruktur pengingat, pengaturan, deep link | kecil | digabung ke M1 |
| **M1** | Paket cepat | #1 Muhasabah malam · #6 Waktu penting · #8 Ayat harian | kecil-sedang | 1.16.0 |
| **M2** | Kebiasaan & kewajiban | #3 Pengingat sunnah hijriah · #4 Hutang sholat | sedang | 1.17.0 |
| **M3** | Hafalan lanjutan | #2 Muraja'ah (pengulangan terjadwal) | sedang | 1.18.0 |
| **M4** | Keamanan data | #5 Cadangan otomatis | sedang (ada spike) | 1.18.x / 1.19.0 |
| **M5** | Cari & hitung | #9 Pencarian global · #11 Kalkulator zakat mal | sedang | 1.19.0 |
| **M6** | Motivasi | #7 Lencana & pencapaian | sedang | 1.20.0 |
| **M7** | Tampilan | #10 Mode gelap | besar | 1.21.0 |

Nomor versi hanya usulan; ditetapkan saat commit mengikuti aturan versi
(angka terakhir untuk perbaikan & fitur kecil, angka tengah bila banyak
fitur sekaligus, angka pertama hanya untuk pembaruan wajib).

**Belum dijadwalkan:** *Pola tidur untuk ibadah* - konsep sudah dibahas,
tetapi cara mencatat, batas begadang, dan letak fiturnya belum diputuskan
(lihat bagian [Backlog](#backlog--tidak-dijadwalkan)).

## Aturan kerja setiap fase

1. **Awal fase:** baca bagian fasenya di sini; tanyakan keputusan terbuka
   (bagian "Keputusan") sebelum menulis kode.
2. **Selama fase:** rujukan hadits/dalil **diverifikasi ke kitab di
   aplikasi** (nomor & matan), seperti pada fitur qadha/Jumat/laporan.
   Tidak ada ikon hati; teks harus netral bagi laki-laki & perempuan.
3. **Uji:** tes baru untuk setiap logika, `flutter analyze` tidak boleh
   melebihi baseline (57), `flutter test` hijau, dan tes Kotlin
   (`./gradlew :app:testReleaseUnitTest`) bila menyentuh widget Android.
4. **Cek visual** di emulator memakai build **release** (build debug ANR),
   lalu tutup emulatornya.
5. **Selesai fase:** `CHANGELOG.md` (bahasa Indonesia, untuk pengguna), naikkan
   `pubspec.yaml`, commit, tag `vX.Y.Z` beranotasi. **Commit & push hanya bila
   diminta.** Build & rilis ke GitHub dilakukan manual (`tool/release.sh`).
6. Setiap fase menandai dirinya **[x] selesai** di dokumen ini.

## Peta kode yang dipakai ulang

| Kebutuhan | Letak |
|---|---|
| Notifikasi terjadwal (id: adzan `day*16+i`, pengingat `+8`, puasa `900+day`, Jumat `950+day`, `990`, `999`) | `lib/services/adzan_notifications.dart` |
| Pengaturan & bagian halamannya | `lib/services/app_settings.dart`, `lib/pages/settings_page.dart` |
| Analisis laporan harian/mingguan/bulanan | `lib/services/ibadah_insight.dart`, `lib/pages/ibadah_*_report_page.dart` |
| Waktu sholat & jendela waktu | `lib/services/prayer_calculator.dart`, `lib/services/sholat_time.dart` |
| Kalender hijriah & hari penting | `lib/services/hijri_calendar.dart` (`eventsOn`), `ibadah_day.dart` |
| Widget layar utama (Flutter ↔ Kotlin) | `lib/services/tracker_widget_*.dart`, `android/.../*WidgetProvider.kt`, `lib/pages/widgets_page.dart` |
| Teks Al-Qur'an & font pilihan | `lib/services/quran_text.dart`, `lib/widgets/quran/quran_ayah_text.dart` |
| Database (skema **v9**) & cadangan | `lib/db/app_database.dart`, `lib/services/backup_service.dart` |
| Komponen laporan & ekspor gambar/PDF | `lib/widgets/report/*`, `lib/services/report_export.dart` |

---

## M0 - Fondasi bersama

**Tujuan:** menyiapkan landasan yang dipakai M1-M4 supaya fitur berikutnya
tidak saling menimpa.

**Ruang lingkup**
- [x] **Registri id notifikasi:** kamus kecil rentang id per jenis pengingat
      (adzan/pengingat/puasa/Jumat yang sudah ada, ditambah muhasabah,
      laporan mingguan, tahajud, sunnah hijriah, muraja'ah, ayat harian)
      supaya tidak bentrok. Usulan: muhasabah `1000+day`, laporan mingguan
      `1100+minggu`, tahajud `1200+day`, ayat harian `1300+day`, sunnah
      hijriah `1400+n`, muraja'ah `1500+day`.
- [x] **`reschedule()` modular:** pecah menjadi fungsi per jenis
      (`_scheduleAdzan`, `_scheduleFriday`, ...) dengan satu pintu
      pemeriksaan "ada pengingat aktif?" - penambahan jenis baru tidak
      menyentuh fungsi lama.
- [x] **Deep link notifikasi → halaman:** perluas `onOpen` di `main.dart`
      (payload `laporan|YYYY-MM-DD`, `laporan-minggu|YYYY-MM-DD`,
      `ayat|S:A`, `muraja'ah`), selain `alarm|...` & tab Ibadah yang ada.
- [x] **Pengaturan:** bagian **"Pengingat"** terpusat di halaman Pengaturan
      (yang sudah ada tersebar di "Notifikasi adzan" dan "Pengingat puasa &
      Jumat"); tiap pengingat baru menambah satu saklar + jam.

**Selesai bila:** adzan, pengingat, puasa, dan Jumat berjalan persis seperti
sebelumnya (tes menjaga ini), dan menambah jenis pengingat baru cukup satu
fungsi + satu entri id.

**Uji:** tes jadwal tidak tumpang tindih id; tes payload → rute.

**Risiko:** perubahan pada penjadwalan adzan adalah jalur kritis - rilis
bersama M1 setelah diuji di HP asli (jangan hanya emulator).

---

## M1 - Paket cepat (#1, #6, #8) → usulan 1.16.0

> Prioritas utama. Ketiganya kecil, langsung terasa, dan memanfaatkan data
> yang sudah ada.

### #1 Muhasabah malam
**Tujuan:** laporan yang sudah dibuat benar-benar dipakai, tanpa perlu
mengingat membukanya.

- [x] Notifikasi harian (bawaan **21.00**, dapat diatur & dimatikan):
      "Saatnya muhasabah - lihat laporan hari ini" → membuka laporan harian.
- [x] Notifikasi **laporan mingguan** (bawaan Minggu **20.00**) → membuka
      laporan mingguan.
- [x] **Teks dinamis dengan batas yang jujur:** notifikasi terjadwal berisi
      teks tetap, tidak bisa menghitung ulang saat berbunyi. Maka teks
      "Hari ini 72%, 2 ibadah belum tercatat" disusun **ulang setiap data
      berubah** (hook yang sama dengan sinkron widget, juga dari callback
      widget) lalu dijadwalkan ulang. Bila aplikasi tidak pernah dibuka dan
      tidak ada centang dari widget, teks cadangannya generik.
- [x] Hari berhalangan: teks netral ("Semoga harimu ringan").
- [x] Tetap berbunyi saat semua ibadah tuntas (keputusan pengguna): teks berubah menjadi ucapan syukur.

**Keputusan:** jam bawaan; tetap berbunyi saat semua tuntas (sebagai
apresiasi) atau diam.

**Selesai bila:** notifikasi muncul tepat waktu di HP asli, teks mengikuti
catatan terbaru, ketukan membuka laporan yang benar.

### #6 Waktu penting di jadwal sholat
**Tujuan:** menampilkan waktu ibadah yang sering ditanyakan, dihitung dari
jadwal yang sudah ada.

- [x] **Sepertiga malam terakhir:** malam = Maghrib → Subuh berikutnya;
      sepertiga terakhir dimulai pada `Subuh − (malam ÷ 3)`.
- [x] **Waktu Dhuha:** mulai ±15-20 menit setelah terbit sampai ±10 menit
      sebelum Dzuhur (istiwa').
- [x] **Waktu terlarang untuk sholat sunnah mutlak:** sesudah Subuh sampai
      terbit + ±15 menit, saat istiwa', dan setelah Ashar sampai Maghrib
      (dengan catatan fiqih: sholat yang punya sebab, mis. qadha, tidak
      termasuk menurut sebagian ulama). **Dalil diverifikasi dulu** (kandidat:
      hadits 'Uqbah bin 'Amir & Abu Sa'id di Muslim/Bukhari).
- [x] Tampil di **lembar "Waktu penting hari ini"** yang dibuka dari kartu
      jadwal, plus baris ringkas di halaman Imsakiyah bila muat.
- [x] Notifikasi opsional **sepertiga malam** (mati secara bawaan).

**Keputusan:** sudut Dhuha mengikuti Kemenag (±15 menit) atau pilihan
pengguna; teks fiqih waktu terlarang diberi "tanyakan ustadz".

**Selesai bila:** tiga waktu muncul benar untuk beberapa lokasi (uji
Medan, Jakarta, Jayapura) dan tidak ada angka yang melompat di pergantian
hari; tes menjaga batas-batasnya.

### #8 Ayat harian
**Tujuan:** satu ayat per hari, mudah dibaca, memperkuat kebiasaan membuka
aplikasi.

- [x] **Daftar ayat terkurasi** (rujukan `surah:ayat`, sekitar 100-366)
      di satu berkas Dart; teks Arab & terjemahan **diambil dari
      `quran.json`** (bukan diketik ulang, menghindari salah tulis). Daftar
      ditinjau pengguna sebelum dipakai.
- [x] Pilihan harian deterministik dari tanggal (sama di semua perangkat).
- [x] **Widget "Ayat Harian"** (3x2/4x2) memakai penggambar bitmap font
      mushaf milik widget Hafalan (`HafalanWidgetProvider.renderAyah`) dengan
      font pilihan pengguna; ketuk → membuka ayatnya di pembaca.
- [x] **Notifikasi** opsional (bawaan pagi, mati) berisi ayat + terjemahan.
- [x] Kartu "Ayat hari ini" di Beranda (opsional, ringkas).

**Keputusan:** sumber daftar (saya usulkan; Anda tinjau); kartu di Beranda
atau cukup widget + notifikasi.

**Selesai bila:** widget terpasang menampilkan ayat yang sama dengan
notifikasi & kartu, berganti saat tengah malam, dan terlihat benar pada
kedua font.

**Penutup M1:** satu rilis 1.16.0 (tiga fitur → angka tengah naik).

---

## M2 - Kebiasaan & kewajiban (#3, #4) → usulan 1.17.0

### #3 Pengingat sunnah berdasarkan kalender hijriah
- [x] Generalisasi pola Tarwiyah-Arafah yang sudah ada menjadi **daftar
      amalan sunnah hijriah**: puasa **Senin-Kamis**, **Ayyamul Bidh**
      (13-15 tiap bulan hijriah), **Tasu'a-Asyura** (9-10 Muharram),
      **Syawal 6 hari**, plus yang sudah ada.
- [x] Muncul di checklist harinya (item bergantung hari/tanggal hijriah),
      kartu pengingat, dan notifikasi malam sebelumnya (bawaan mati kecuali
      yang sudah aktif; **satu saklar per amalan**).
- [x] Tidak menggandakan checklist "Puasa sunnah" yang sudah ada: itemnya
      dipetakan, bukan diganti.
- [x] **Dalil per amalan** diverifikasi ke kitab (Muslim: Senin-Kamis,
      Syawal, Asyura; Tirmidzi/Nasa'i: Ayyamul Bidh).

**Keputusan (diputuskan):** Senin-Kamis/Ayyamul Bidh **disembunyikan** pada
Hari Raya & tasyrik (dalil larangan: Muslim 1921 & 1926, diverifikasi).
Dibuat: `services/puasa_sunnah.dart` (satu saklar per amalan, bawaan mati),
kartu Beranda hanya untuk amalan yang diaktifkan, lembar dalil. Catatan:
Syawal diingatkan malam sebelum tiap hari Syawal sesudah 1 Syawal.

**Selesai bila:** tanggal-tanggal jatuh benar pada beberapa tahun hijriah
(uji lintas tahun & perubahan metode), tidak muncul pada hari terlarang.

### #4 Hutang sholat (qadha) yang terlacak
- [x] Tabel baru **`sholat_qadha`** (skema **v10**): jumlah per waktu
      sholat yang masih harus diqadha + riwayat pembayaran; diisi manual
      (mis. 100 Subuh) atau **dari catatan**: sholat berstatus *Terlewat*
      / *Qadha tanpa uzur* menambah hutang (pilihan, bukan otomatis).
- [x] Kartu & halaman "Hutang sholat" (sisa, progres, perkiraan lunas pada
      kecepatan sekarang) - polanya mengikuti `QadhaStatus` puasa.
- [x] Tombol **"Bayar 1"** (catat qadha) dan pilihan "bayar bersamaan
      sholat wajib" (qadha setelah fardhu).
- [x] Masuk ke **cadangan** (skema `backup_service`), ke laporan (angka
      hutang), dan ke rekomendasi.
- [x] Penjelasan singkat + dalil taubat & qadha (sudah ada di
      `sholat_dalil.dart`); **tidak memvonis** jumlah hutang.

**Keputusan (diputuskan):** hutang hanya dari pilihan pengguna. Dibuat:
tabel `sholat_qadha_entries` (buku besar: tambah/bayar, bukan jumlah
tunggal), halaman Hutang Sholat (menu "Lainnya"), "Dari catatan" menawarkan
sholat belum tercatat 60 hari terakhir untuk DIPILIH, saran mencicil di
laporan harian. Belum: pilihan "bayar bersamaan sholat wajib" dari
checklist (hanya tombol Bayar 1 di halaman) dan angka hutang di laporan
mingguan/bulanan.

**Selesai bila:** migrasi v9→v10 teruji (pola `pragma_table_info`),
cadangan lama tetap terbaca, hutang bertambah/berkurang konsisten dengan
catatan harian.

---

## M3 - Hafalan lanjutan (#2) → usulan 1.18.0

### #2 Muraja'ah (pengulangan terjadwal)
- [ ] Tabel baru **`hafalan_reviews`** (skema **v11**, atau v10 bila M2
      belum menaikkan): jadwal ulang per unit hafalan dengan jarak
      **1, 3, 7, 14, 30 hari** (pengulangan berjarak); hasil "lancar/ragu"
      memajukan atau menunda jadwal.
- [ ] Halaman **"Muraja'ah hari ini"**: daftar unit yang jatuh tempo,
      mode tutup ayat (yang sudah ada), tombol *Lancar* / *Ragu* / *Lupa*.
- [ ] **Widget Hafalan** dan notifikasi (bawaan mati) menampilkan
      "N muraja'ah hari ini".
- [ ] **Kuis sambung ayat:** tampil beberapa kata → pilih/ketik kelanjutan
      (pilihan ganda dari ayat lain sebagai pengecoh).
- [ ] Ringkasan di laporan (muraja'ah terjaga/tertunggak).

**Keputusan (tanyakan di awal fase):** **unit** muraja'ah = per surah,
per rentang ayat yang berurutan, atau per ayat; saya sarankan **rentang
berurutan** (lebih nyata untuk hafalan) dengan batas ukuran.

**Selesai bila:** jadwal tertib selama berminggu-minggu (uji dengan jam
disimulasikan), widget & halaman satu pendapat, tidak ada muraja'ah ganda
setelah cadangan dipulihkan.

---

## M4 - Keamanan data (#5) → usulan 1.18.x / 1.19.0

### #5 Cadangan otomatis
Cadangan sekarang hanya lewat lembar bagikan (manual).

- [ ] **Spike dulu (setengah hari):** pastikan cara menyimpan yang tahan
      di Android 11+:
      1. **Folder pilihan lewat SAF** (`file_picker` memilih folder; akses
         persisten) - pilihan utama, tanpa akun;
      2. folder khusus aplikasi + tombol "salin ke Unduhan";
      3. Google Drive **ditunda**: butuh OAuth, layanan Google, dan
         pengungkapan privasi - bertentangan dengan prinsip "tanpa akun".
- [ ] Penjadwal **mingguan** (saat aplikasi dibuka bila sudah lewat 7 hari;
      WorkManager hanya bila terbukti perlu), simpan **5 salinan terakhir**.
- [ ] Setelan: aktif/mati, pilih folder, "Cadangkan sekarang", waktu
      cadangan terakhir (sudah ada di halaman Cadangan).
- [ ] Pemulihan memilih salinan dari daftar.
- [ ] **Isi cadangan bertambah** seiring fitur baru (hutang sholat,
      muraja'ah) - uji impor lintas versi.

**Keputusan:** SAF (usulan) vs sekadar pengingat "sudah seminggu belum
mencadangkan".

**Selesai bila:** cadangan tersimpan sendiri tanpa dibuka manual, bisa
dipulihkan di HP lain, dan gagal-izin ditangani dengan pesan yang jelas.

---

## M5 - Cari & hitung (#9, #11) → usulan 1.19.0

### #9 Pencarian global
- [ ] Satu kolom cari untuk **Al-Qur'an + hadits + doa** (+ Asmaul Husna);
      hasil dikelompokkan per sumber, kata dicari disorot (komponen
      `HighlightText` sudah ada), ketuk membuka tempat aslinya.
- [ ] **Spike:** hadits ada di basis data terpisah (`hadits_database`) dan
      hanya kitab yang diunduh; ukur kecepatan pencarian di 9 kitab (butuh
      indeks teks / FTS?) sebelum menetapkan desain.
- [ ] Letak: ikon cari di Beranda/menu; riwayat pencarian lokal.

**Selesai bila:** hasil kurang dari ±1 detik di HP kelas menengah, tidak
memuat seluruh kitab ke memori sekaligus.

### #11 Kalkulator zakat mal & penghasilan
- [ ] Zakat **mal** (nisab setara **85 gram emas**, 2,5%, haul 1 tahun),
      zakat **penghasilan**, emas & perak bila perlu; **harga emas diisi
      manual** (tetap offline) dengan pengingat memperbaruinya.
- [ ] Hasil yang bisa **dibagikan sebagai gambar** (teknik ekspor laporan).
- [ ] Penjelasan syarat & dalil; tautan ke Zakat Fitrah yang sudah ada.
- [ ] **Bukan fatwa:** catatan "tanyakan lembaga zakat/ustadz" di setiap
      hasil.

**Keputusan:** satuan nisab dari emas saja atau ikut opsi perak; sumber
rujukan fiqih yang dipakai (mis. fatwa MUI/BAZNAS) dicantumkan.

---

## M6 - Lencana & pencapaian (#7) → usulan 1.20.0

- [ ] Kumpulan lencana lokal: streak **7/30/100** hari, **Subuh tepat waktu
      30 hari**, **khatam**, **hafalan 1 juz**, **Jumat penuh sebulan**.
- [ ] Dihitung dari catatan yang ada (tanpa tabel baru; cukup tanggal
      pertama diraih, disimpan agar tidak hilang).
- [ ] Halaman "Pencapaian" + animasi saat meraih; **bisa dibagikan sebagai
      gambar** (opsional, mati bawaan).
- [ ] **Hati-hati niat:** teks dan tampilan tidak menyuruh pamer; berbagi
      adalah pilihan; tidak ada papan peringkat atau perbandingan antar
      pengguna.

**Keputusan:** daftar lencana final (saya usulkan 12-15) & namanya.

---

## M7 - Mode gelap (#10) → usulan 1.21.0

**Fase terbesar & paling menyeluruh** - banyak warna ditulis langsung
(`Color(0xFF...)`) di hampir semua halaman.

- [ ] **Desain token warna** (`ThemeExtension`): latar, kartu, teks, garis,
      aksen; pemetaan dari warna krem/amber saat ini.
- [ ] **Migrasi bertahap per area** (tiap area diuji sendiri): komponen
      bersama → Beranda → Ibadah → Laporan → Qur'an (mushaf tetap tema
      kertas bila dipilih) → sisa halaman.
- [ ] Pilihan **Ikuti sistem / Terang / Gelap** di Pengaturan.
- [ ] Widget layar utama sudah gelap-hijau; kartu jadwal (langit) tidak
      berubah.
- [ ] Ekspor laporan **tetap latar krem** (gambar/PDF dibaca di mana pun).
- [ ] Tes: tangkapan golden/visual untuk halaman utama di dua tema.

**Keputusan:** warna mushaf dalam mode gelap (tema kertas vs gelap), dan
apakah fase ini dipecah jadi **M7a/M7b** (komponen+Beranda+Ibadah dulu).

---

## Backlog / tidak dijadwalkan

- **Pola tidur untuk ibadah.** Konsep: catat jam tidur/bangun & qailulah,
  laporan "begadang" dan kaitannya dengan Subuh. Menunggu keputusan:
  (1) cara mencatat (tombol "Sudah bangun" di notifikasi Subuh + kartu pagi,
  atau otomatis), (2) batas begadang, (3) bagian dari checklist atau
  halaman sendiri, (4) qailulah ikut tahap pertama atau tidak.
- **Murottal / tafsir / terjemahan tambahan:** hanya bila ada sumber yang
  jelas berlisensi bebas (tidak bisa dipastikan sekarang).
- **iOS, fitur sosial (teman istiqamah):** butuh server/akun - di luar
  prinsip aplikasi saat ini.

## Catatan risiko lintas fase

| Risiko | Mitigasi |
|---|---|
| Notifikasi dengan teks dinamis tidak bisa dihitung saat berbunyi | jadwalkan ulang saat data berubah; teks cadangan generik (M1) |
| Migrasi basis data (v10, v11) merusak data pengguna | selalu cek `pragma_table_info`, tes migrasi dari versi sebelumnya & cadangan lama |
| Penjadwalan adzan terganggu refaktor (M0) | tes menjaga perilaku lama; uji di HP asli sebelum rilis |
| Perhitungan waktu (sepertiga malam, Dhuha) beda di lintang tinggi | uji beberapa lokasi; tampilkan "tidak tersedia" bila malam tak wajar |
| Dalil keliru | verifikasi tiap nomor & matan ke kitab di aplikasi; ragu → tidak ditulis |
| Mode gelap menyentuh semua layar | fase terakhir, bertahap, dengan tes visual |
| APK membesar (sudah +4 MB karena paket PDF) | pantau ukuran tiap rilis; hindari paket baru bila tidak perlu |

## Riwayat fase

| Fase | Status | Rilis | Tanggal |
|---|---|---|---|
| M0 Fondasi | selesai (belum dirilis) | 1.16.0 | 2026-10-31 |
| M1 Paket cepat | selesai (belum dirilis) | 1.16.0 | 2026-10-31 |
| M2 Kebiasaan & kewajiban | selesai (belum dirilis) | 1.17.0 | 2026-11-01 |
| M3 Hafalan lanjutan | belum | - | - |
| M4 Keamanan data | belum | - | - |
| M5 Cari & hitung | belum | - | - |
| M6 Lencana | belum | - | - |
| M7 Mode gelap | belum | - | - |
