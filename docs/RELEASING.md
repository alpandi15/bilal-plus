# Panduan Rilis Bilal+ (Tag & Release)

Cara menaikkan versi, membuat **tag**, dan menerbitkan **Release** di GitHub.
Semua pekerjaan dilakukan di branch `main`.

- **Tag** (`v1.9.2`) = penanda di git bahwa commit ini adalah versi 1.9.2.
- **Release** = halaman unduhan di GitHub yang dibangun dari tag itu, berisi
  catatan rilis + berkas APK.

---

## Persiapan (sekali saja)

```bash
brew install gh          # GitHub CLI
gh auth login            # pilih GitHub.com → SSH → login lewat browser
gh auth status           # pastikan: Logged in to github.com account alpandi15
```

---

## Cara cepat (disarankan)

### 1. Naikkan versi di `pubspec.yaml`

```yaml
version: 1.9.2+17
```

| Bagian | Kapan dinaikkan | Contoh |
|---|---|---|
| angka terakhir (patch) | perbaikan & fitur kecil | 1.9.1 → **1.9.2** |
| angka tengah (minor) | banyak fitur baru sekaligus | 1.9.2 → **1.10.0** |
| angka pertama (major) | hanya bila perlu pembaruan wajib | 1.10.0 → **2.0.0** |
| angka setelah `+` (build) | **selalu** naik 1 setiap rilis | +16 → **+17** |

### 2. Tulis catatan rilis di `CHANGELOG.md`

Tambahkan di **paling atas** (di bawah paragraf pembuka). Judulnya harus
persis `## X.Y.Z (build N) · tanggal` - skrip mencari judul ini:

```markdown
## 1.9.2 (build 17) · 1 Oktober 2026

- Poin singkat dari sudut pandang pengguna.
- Satu baris per perubahan.
```

### 3. Uji & commit

```bash
flutter analyze
flutter test

git add -A
git commit -m "Ringkasan perubahan - versi 1.9.2+17"
```

### 4. Jalankan skrip rilis

Coba dulu tanpa mengubah apa pun:

```bash
tool/release.sh --dry-run
```

Kalau daftar langkahnya sudah benar, jalankan sungguhan:

```bash
tool/release.sh
```

Skrip ini otomatis:

1. membaca versi dari `pubspec.yaml` dan catatan dari `CHANGELOG.md`,
2. membuat tag `v1.9.2` di commit terakhir,
3. build APK rilis dan mengecek versinya,
4. menyalin APK ke `build/release/bilal-plus-1.9.2.apk` + membuat
   `build/release/notes-v1.9.2.md`,
5. push `main` dan tag ke GitHub,
6. membuat Release **Bilal+ 1.9.2** (ditandai *Latest*) dengan APK terlampir.
   Bila Release-nya sudah ada (mis. draft dari web), isinya diperbarui lalu
   diterbitkan.

Pilihan tambahan: `tool/release.sh --no-build` memakai APK yang sudah ada
(versinya tetap dicek).

Skrip berhenti dengan pesan jelas bila: bukan di branch `main`, masih ada
perubahan belum di-commit, atau `CHANGELOG.md` belum punya bagian versi itu.

---

## Cara manual (tanpa skrip)

```bash
# 1. tag di commit kenaikan versi
git tag -a v1.9.2 -m "Bilal+ 1.9.2 (build 17)" -m "- Poin catatan rilis"

# 2. build & siapkan berkas
flutter build apk --release
mkdir -p build/release
cp build/app/outputs/flutter-apk/app-release.apk build/release/bilal-plus-1.9.2.apk

# 3. push
git push origin main
git push origin v1.9.2

# 4. release
gh release create v1.9.2 build/release/bilal-plus-1.9.2.apk \
  --repo alpandi15/bilal-plus \
  --title "Bilal+ 1.9.2" \
  --notes "- Poin catatan rilis" \
  --latest
```

**Lewat web:** buka
`https://github.com/alpandi15/bilal-plus/releases/new` → pilih tag `v1.9.2` →
judul `Bilal+ 1.9.2` → tempel catatan → seret APK ke kotak lampiran →
centang **Set as the latest release** → **Publish release**.

---

## Kalau ada yang salah

**Lupa sesuatu sebelum push** (tag belum dikirim) - pindahkan tag ke commit
terbaru:

```bash
git tag -d v1.9.2
git tag -a v1.9.2 -m "Bilal+ 1.9.2 (build 17)" -m "- ..."
```

**Tag sudah terlanjur di-push** - lebih aman naikkan versi saja (1.9.3).
Kalau tetap mau memindahkan tag yang sudah publik:

```bash
git tag -d v1.9.2
git push origin :refs/tags/v1.9.2       # hapus tag di GitHub
git tag -a v1.9.2 -m "..."              # buat ulang di commit yang benar
git push origin v1.9.2
```

(Release yang terhubung perlu dibuat ulang atau diperbarui dengan
`tool/release.sh --no-build`.)

**Ganti APK atau catatan di Release yang sudah terbit:**

```bash
gh release upload v1.9.2 build/release/bilal-plus-1.9.2.apk --clobber --repo alpandi15/bilal-plus
gh release edit v1.9.2 --notes-file build/release/notes-v1.9.2.md --repo alpandi15/bilal-plus
```

**Hapus Release** (tagnya tetap ada):

```bash
gh release delete v1.9.2 --repo alpandi15/bilal-plus
```

---

## Cek hasil

```bash
git tag -n1                                       # daftar tag lokal
gh release list --repo alpandi15/bilal-plus       # daftar Release di GitHub
```

Tautan unduhan versi terbaru selalu
`https://github.com/alpandi15/bilal-plus/releases/latest`.

Tag `v1.1.0` sampai `v1.9.1` menunjuk ke commit tempat versi tersebut pertama
kali dinaikkan.
