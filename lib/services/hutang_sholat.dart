import '../db/app_database.dart';
import '../utils/date_key.dart';

/// Waktu sholat wajib yang bisa dihutang, urut seperti di checklist.
const hutangPrayers = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

const hutangPrayerNames = {
  'subuh': 'Subuh',
  'dzuhur': 'Dzuhur',
  'ashar': 'Ashar',
  'maghrib': 'Maghrib',
  'isya': 'Isya',
};

/// Ringkasan hutang sholat dari buku besar.
class SholatDebt {
  const SholatDebt({
    required this.remaining,
    required this.added,
    required this.paid,
    required this.paidPerDay,
  });

  /// Sisa per waktu sholat (kunci di [hutangPrayers]).
  final Map<String, int> remaining;

  /// Total yang pernah ditambahkan / dibayar.
  final int added, paid;

  /// Rata-rata dibayar per hari dalam [paceDays] hari terakhir.
  final double paidPerDay;

  int get left => remaining.values.fold(0, (a, b) => a + b);
  bool get isEmpty => added == 0;
  bool get settled => added > 0 && left == 0;
  double get fraction => added == 0 ? 0 : (added - left) / added;

  /// Perkiraan hari sampai lunas pada kecepatan sekarang; null bila tidak
  /// ada hutang atau pembayaran terakhir terlalu sedikit ([minPaidForEta])
  /// untuk dijadikan patokan.
  int? get daysToSettle => left == 0 || paidPerDay * paceDays < minPaidForEta
      ? null
      : (left / paidPerDay).ceil();
}

/// Jendela penghitung kecepatan bayar.
const paceDays = 14;

/// Pembayaran minimal dalam [paceDays] hari agar perkiraan lunas ditampilkan.
const minPaidForEta = 3;

SholatDebt sholatDebt(List<SholatQadhaEntry> entries, {required String today}) {
  final left = {for (final p in hutangPrayers) p: 0};
  var added = 0, paid = 0, recentPaid = 0;
  final since = dateKey(
    parseDateKey(today).subtract(const Duration(days: paceDays - 1)),
  );
  for (final e in entries) {
    left[e.prayer] = (left[e.prayer] ?? 0) + e.count;
    if (e.count > 0) {
      added += e.count;
    } else {
      paid += -e.count;
      if ((e.date ?? '').compareTo(since) >= 0) recentPaid += -e.count;
    }
  }
  return SholatDebt(
    remaining: {for (final e in left.entries) e.key: e.value < 0 ? 0 : e.value},
    added: added,
    paid: paid,
    paidPerDay: recentPaid / paceDays,
  );
}

/// Satu sholat yang belum tercatat pada [date].
class MissedPrayer {
  const MissedPrayer(this.date, this.prayer);
  final String date;
  final String prayer;
}

/// Sholat wajib yang BELUM tercatat sama sekali pada hari-hari lampau
/// ([from]..kemarin, sesudah catatan pertama pengguna) - untuk ditawarkan,
/// bukan ditambahkan otomatis: tidak tercatat belum tentu terlewat. Hari
/// berhalangan dilewati; yang sudah pernah dipilih ([already]) tidak
/// ditawarkan lagi.
List<MissedPrayer> missedFromRecords(
  IbadahRangeData data, {
  required String today,
  Set<String> already = const {},
}) {
  final first = data.firstDate;
  if (first == null) return const [];
  final ids = {
    for (final i in data.items)
      if (i.groupKey == sholatWajibGroup) i.key: i.id,
  };
  final start = first.compareTo(data.from) > 0 ? first : data.from;
  final out = <MissedPrayer>[];
  for (
    var d = parseDateKey(start);
    dateKey(d).compareTo(today) < 0 && dateKey(d).compareTo(data.to) <= 0;
    d = d.add(const Duration(days: 1))
  ) {
    final key = dateKey(d);
    if (data.excused.contains(key)) continue;
    final logs = data.logs[key] ?? const {};
    for (final p in hutangPrayers) {
      final id = ids[p];
      if (id == null || (logs[id]?.value ?? 0) > 0) continue;
      if (already.contains('$key|$p')) continue;
      out.add(MissedPrayer(key, p));
    }
  }
  return out;
}
