import 'adzan_messages.dart' show AdzanMessage;

/// Ringkasan ibadah satu hari untuk teks notifikasi muhasabah - diambil dari
/// data widget (`ibadah_json`) yang selalu diperbarui setiap catatan berubah.
class DaySummary {
  const DaySummary({
    required this.date,
    required this.done,
    required this.total,
    required this.score,
    required this.excused,
    required this.sholatDone,
    required this.sholatTotal,
  });

  final String date;
  final int done, total;

  /// Nilai tertimbang (sholat wajib sendiri bernilai lebih kecil).
  final double score;
  final bool excused;
  final int sholatDone, sholatTotal;

  double get fraction => total == 0 ? 0 : (score / total).clamp(0.0, 1.0);
  int get percent => (fraction * 100).round();
  int get remaining => (total - done).clamp(0, total);
  bool get complete => total > 0 && done >= total;

  /// Dari satu hari di `ibadah_json` (`days[i]`); null bila bukan [date].
  static DaySummary? fromPayload(Map<String, Object?> payload, String date) {
    final days = payload['days'];
    if (days is! List) return null;
    for (final d in days) {
      if (d is! Map || d['date'] != date) continue;
      final sholat = (d['sholat'] as List?) ?? const [];
      return DaySummary(
        date: date,
        done: (d['done'] as num?)?.toInt() ?? 0,
        total: (d['total'] as num?)?.toInt() ?? 0,
        score: (d['score'] as num?)?.toDouble() ?? 0,
        excused: d['excused'] == true,
        sholatDone: sholat.where((e) => e is Map && e['done'] == true).length,
        sholatTotal: sholat.length,
      );
    }
    return null;
  }
}

/// Teks notifikasi muhasabah malam. [summary] null = tidak ada data terbaru
/// (aplikasi belum dibuka / hari lain): teks generik yang selalu benar.
AdzanMessage muhasabahMessage(DaySummary? summary) {
  const title = 'Muhasabah malam';
  final s = summary;
  if (s == null || s.total == 0 && !s.excused) {
    return const AdzanMessage(
      title,
      'Luangkan satu menit melihat laporan ibadah hari ini: apa yang sudah '
      'baik, apa yang perlu ditingkatkan, dan saran untuk besok.',
    );
  }
  if (s.excused) {
    return const AdzanMessage(
      title,
      'Semoga harimu ringan. Lihat laporan hari ini bila sempat - dzikir '
      'dan doa tetap bisa dilakukan.',
    );
  }
  if (s.complete) {
    return AdzanMessage(
      title,
      'Masyaa Allah, ${s.done} dari ${s.total} ibadah hari ini tuntas. '
      'Lihat laporannya, lalu syukuri dan jaga istiqamahnya.',
    );
  }
  if (s.fraction >= 0.7) {
    return AdzanMessage(
      title,
      'Hari ini ${s.percent}% tuntas - sedikit lagi. ${s.remaining} ibadah '
      'belum tercatat; lihat apa yang masih bisa dikejar malam ini.',
    );
  }
  if (s.sholatTotal > 0 && s.sholatDone < s.sholatTotal) {
    final left = s.sholatTotal - s.sholatDone;
    return AdzanMessage(
      title,
      'Hari ini ${s.percent}% tuntas. $left sholat wajib belum tercatat - '
      'kerjakan atau catat dulu, lalu lihat laporannya.',
    );
  }
  return AdzanMessage(
    title,
    'Hari ini ${s.percent}% tuntas (${s.done} dari ${s.total}). Lihat '
    'laporan dan rencanakan langkah kecil untuk besok.',
  );
}

/// Teks notifikasi laporan mingguan (Minggu malam).
const weeklyReportMessage = AdzanMessage(
  'Laporan mingguan siap',
  'Lihat rangkuman ibadahmu pekan ini: yang sudah baik, yang perlu '
      'ditingkatkan, dan rekomendasi untuk pekan depan.',
);
