# Panduan Rilis Bilal+

Langkah setiap kali merilis versi baru. Semua pekerjaan dilakukan di branch
`main`.

## 1. Tentukan nomor versi

Format di `pubspec.yaml`: `version: X.Y.Z+N`

| Bagian | Kapan dinaikkan |
|---|---|
| `Z` (patch) | Perbaikan, polesan tampilan, dan fitur kecil/tunggal |
| `Y` (minor) | Banyak fitur baru sekaligus (reset `Z` ke 0) |
| `X` (major) | Hanya bila perlu pembaruan wajib |
| `N` (build) | Selalu naik 1 setiap rilis |

## 2. Tulis catatan rilis

Tambahkan bagian baru di **paling atas** [`CHANGELOG.md`](../CHANGELOG.md):

```markdown
## 1.9.2 (build 17) · 1 Oktober 2026

- Poin singkat dari sudut pandang pengguna, bukan detail kode.
```

## 3. Uji

```bash
flutter analyze
flutter test
```

## 4. Commit & tag

```bash
git add -A
git commit -m "Ringkasan perubahan - versi 1.9.2+17"

# tag beranotasi di commit kenaikan versi; isi = catatan rilisnya
git tag -a v1.9.2 -m "Bilal+ 1.9.2 (build 17)" -m "- Poin catatan rilis ..."
```

Nama tag selalu `vX.Y.Z` (tanpa nomor build).

## 5. Build APK rilis

```bash
flutter build apk --release
```

Hasilnya `build/app/outputs/flutter-apk/app-release.apk`, ditandatangani
dengan kunci dari `android/key.properties` (tidak disimpan di repo). Cek
tanda tangannya:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

## 6. Push

```bash
git push origin main
git push origin v1.9.2      # atau semua tag sekaligus: git push --tags
```

Di GitHub, tag ini bisa dijadikan **Release** (Releases → Draft a new
release → pilih tag), isi catatannya dari CHANGELOG, dan lampirkan APK.

## Riwayat tag

Tag `v1.1.0` sampai `v1.9.1` menunjuk ke commit tempat versi tersebut
pertama kali dinaikkan. Lihat daftarnya dengan:

```bash
git tag -n1
```
