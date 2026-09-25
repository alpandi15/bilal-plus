/// Buku "Surat Yasin, Tahtim, Tahlil, Doa & Shalat Jenazah" (Drs. Abu Zulfa,
/// Penerbit Su'udiyah Medan). Halamannya diambil dari PDF pindaian
/// (`Surat-Yasin-Medan.pdf` di repo web) dan disimpan sebagai WebP di
/// `assets/kitab/yasin/` - padanan `src/data/yasin.ts` di web.
///
/// Nomor berkas gambar sama persis dengan nomor halaman cetaknya - sudah
/// dicocokkan dengan daftar isi pada halaman 128.
library;

const yasinTitle = 'Surat Yasin, Tahtim & Tahlil';
const yasinTotalPages = 129;

/// Perbandingan lebar : tinggi halaman aslinya (972 x 1376 piksel).
const yasinPageRatio = 972 / 1376;

String yasinPageAsset(int page) =>
    'assets/kitab/yasin/${page.toString().padLeft(3, '0')}.webp';

class KitabChapter {
  final String title;
  final int page;
  const KitabChapter(this.title, this.page);
}

const List<KitabChapter> yasinChapters = [
  KitabChapter('Sampul', 1),
  KitabChapter('Kata Pengantar Penerjemah', 4),
  KitabChapter('Transkripsi Huruf Arab - Latin', 5),
  KitabChapter('Pendahuluan', 7),
  KitabChapter('Surat Yasin', 10),
  KitabChapter('Doa Surat Yasin', 45),
  KitabChapter('Takhtim', 56),
  KitabChapter('Tahlil', 91),
  KitabChapter('Doa Setelah Takhtim / Tahlil', 99),
  KitabChapter('Shalat Jenazah', 110),
  KitabChapter('Shalat Ghaib', 120),
  KitabChapter('Doa untuk Jenazah', 122),
  KitabChapter('Doa Ziarah Kubur', 126),
  KitabChapter('Daftar Isi', 128),
];
