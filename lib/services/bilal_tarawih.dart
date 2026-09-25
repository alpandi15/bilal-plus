/// Jenis bacaan bilal - menentukan tampilan kartu.
enum BilalKind {
  /// Seruan bilal yang dijawab jamaah.
  seruan,
  doa,
  niat,
  dzikir,
}

class BilalItem {
  const BilalItem({
    required this.kind,
    required this.arabic,
    required this.latin,
    required this.arti,
  });

  final BilalKind kind;
  final String arabic, latin, arti;
}

/// Satu bagian: dibaca bilal sebelum dua rakaat berikutnya (atau sesudah
/// witir untuk dzikir & doa penutup).
class BilalSection {
  const BilalSection({required this.title, required this.items});
  final String title;
  final List<BilalItem> items;
}
