/// Catatan harian ibadah: kenapa hari ini naik/turun (sakit, safar, sibuk,
/// dst.) beserta keterangan bebas. Disimpan di `day_statuses` (kolom
/// `reason` & `note`), tampil di halaman Ibadah, laporan, dan dipakai widget
/// Semangat Sholat untuk memilih kata penyemangat.
library;

/// Alasan yang bisa dipilih. [key] disimpan di basis data & payload widget
/// (jangan diubah); [label] untuk tampilan.
enum DayReason {
  sakit('sakit', 'Sakit', '🤒'),
  safar('safar', 'Perjalanan', '🧳'),
  sibuk('sibuk', 'Sibuk', '💼'),
  lelah('lelah', 'Lelah', '😮‍💨'),
  futur('futur', 'Lagi futur', '🥀'),
  lainnya('lainnya', 'Lainnya', '📝');

  const DayReason(this.key, this.label, this.emoji);
  final String key;
  final String label;
  final String emoji;

  static DayReason? of(String? key) {
    for (final r in values) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// Catatan satu hari; kosong bila tanpa alasan & tanpa keterangan.
class DayNote {
  const DayNote({this.reason, this.text});

  final DayReason? reason;
  final String? text;

  bool get isEmpty => reason == null && (text == null || text!.trim().isEmpty);

  /// "🤒 Sakit · demam sejak pagi", "🤒 Sakit", atau keterangannya saja.
  String get summary {
    final t = text?.trim() ?? '';
    final r = reason;
    if (r == null) return t;
    return t.isEmpty ? '${r.emoji} ${r.label}' : '${r.emoji} ${r.label} · $t';
  }

  /// Versi singkat untuk ruang sempit (grafik): emoji + label, atau
  /// keterangan yang dipotong.
  String get short {
    final r = reason;
    if (r != null) return '${r.emoji} ${r.label}';
    final t = text?.trim() ?? '';
    return t.length > 24 ? '${t.substring(0, 23)}…' : t;
  }
}
