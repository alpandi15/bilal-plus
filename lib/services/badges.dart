import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'hutang_sholat.dart';
import 'quran_index.dart';
import 'sholat_time.dart';

/// Lencana pencapaian: penanda syukur yang dihitung dari catatan di perangkat
/// (tanpa tabel baru). Tanggal pertama diraih disimpan di pengaturan supaya
/// lencana tidak hilang bila catatannya kelak berubah. Tidak ada papan
/// peringkat atau perbandingan antar-pengguna.

/// Kunci tetap (disimpan) - jangan diganti.
enum BadgeId {
  langkahPertama,
  pekanTerjaga,
  sebulanIstiqamah,
  seratusHari,
  penjagaFajar,
  pecintaJamaah,
  jumatPenuh,
  rutinTilawah,
  khatam,
  sejuzHafalan,
  ramadanPenuh,
  pelunasHutang,
}

class BadgeDef {
  const BadgeDef(
    this.id,
    this.name,
    this.description,
    this.icon,
    this.color,
    this.target,
    this.unit,
  );

  final BadgeId id;
  final String name, description;
  final IconData icon;
  final Color color;

  /// Ambang (hari / sholat / ayat ...) dan satuannya untuk teks kemajuan.
  final int target;
  final String unit;
}

const badgeDefs = <BadgeDef>[
  BadgeDef(
    BadgeId.langkahPertama,
    'Langkah Pertama',
    'Satu hari lima waktu lengkap tercatat.',
    Icons.flag_rounded,
    Color(0xFF16A34A),
    1,
    'hari',
  ),
  BadgeDef(
    BadgeId.pekanTerjaga,
    'Pekan Terjaga',
    'Tujuh hari berturut-turut lima waktu lengkap (atau berhalangan).',
    Icons.local_fire_department_rounded,
    Color(0xFFEA580C),
    7,
    'hari',
  ),
  BadgeDef(
    BadgeId.sebulanIstiqamah,
    'Sebulan Istiqamah',
    'Tiga puluh hari berturut-turut terjaga.',
    Icons.calendar_month_rounded,
    Color(0xFFD97706),
    30,
    'hari',
  ),
  BadgeDef(
    BadgeId.seratusHari,
    'Seratus Hari',
    'Seratus hari berturut-turut terjaga.',
    Icons.workspace_premium_rounded,
    Color(0xFFB45309),
    100,
    'hari',
  ),
  BadgeDef(
    BadgeId.penjagaFajar,
    'Penjaga Fajar',
    'Subuh di awal waktu selama 30 hari (butuh pencatatan jam sholat).',
    Icons.wb_twilight_rounded,
    Color(0xFF0891B2),
    30,
    'hari',
  ),
  BadgeDef(
    BadgeId.pecintaJamaah,
    "Pecinta Jama'ah",
    "Tiga puluh sholat wajib berjama'ah.",
    Icons.groups_rounded,
    Color(0xFF0F766E),
    30,
    'sholat',
  ),
  BadgeDef(
    BadgeId.jumatPenuh,
    'Jumat Penuh',
    'Sholat Jumat di setiap Jumat dalam satu bulan.',
    Icons.mosque_rounded,
    Color(0xFF047857),
    1,
    'bulan',
  ),
  BadgeDef(
    BadgeId.rutinTilawah,
    'Rutin Tilawah',
    "Membaca Al-Qur'an di 30 hari yang berbeda.",
    Icons.menu_book_rounded,
    Color(0xFF2563EB),
    30,
    'hari',
  ),
  BadgeDef(
    BadgeId.khatam,
    'Khatam',
    "Menamatkan Al-Qur'an dari Al-Fatihah sampai An-Nas.",
    Icons.auto_stories_rounded,
    Color(0xFF7C3AED),
    1,
    'khatam',
  ),
  BadgeDef(
    BadgeId.sejuzHafalan,
    'Sejuz Hafalan',
    'Seluruh ayat dalam satu juz sudah dihafal.',
    Icons.psychology_rounded,
    Color(0xFFC026D3),
    1,
    'juz',
  ),
  BadgeDef(
    BadgeId.ramadanPenuh,
    'Ramadan Penuh',
    'Puasa penuh sebulan Ramadan.',
    Icons.nightlight_round,
    Color(0xFF4F46E5),
    1,
    'Ramadan',
  ),
  BadgeDef(
    BadgeId.pelunasHutang,
    'Pelunas Hutang',
    'Hutang sholat yang kamu catat sudah lunas.',
    Icons.verified_rounded,
    Color(0xFFDB2777),
    1,
    'lunas',
  ),
];

/// Bahan hitung - semuanya berupa tanggal/angka sederhana supaya mudah diuji.
class BadgeData {
  const BadgeData({
    required this.today,
    this.male = true,
    this.completeDates = const [],
    this.subuhOnTimeDates = const [],
    this.jamaahDates = const [],
    this.jumatDates = const {},
    this.tilawahDates = const [],
    this.khatamDates = const [],
    this.hafalanDates = const {},
    this.ramadanPenuh = const [],
    this.debtAdded = 0,
    this.debtLeft = 0,
    this.debtSettledOn,
  });

  final String today;

  /// Sholat Jumat hanya untuk laki-laki; perempuan tidak melihat lencananya.
  final bool male;

  /// Tanggal (urut) hari terjaga: lima waktu lengkap atau berhalangan.
  final List<String> completeDates;

  /// Tanggal (urut, unik) Subuh dikerjakan di awal waktu.
  final List<String> subuhOnTimeDates;

  /// Satu entri tanggal (urut) untuk tiap sholat wajib berjama'ah.
  final List<String> jamaahDates;

  /// Tanggal sholat Jumat tercatat.
  final Set<String> jumatDates;

  /// Tanggal (urut, unik) ada bacaan Al-Qur'an.
  final List<String> tilawahDates;

  /// Tanggal khatam (urut).
  final List<String> khatamDates;

  /// Nomor ayat global -> tanggal dihafal.
  final Map<int, String> hafalanDates;

  /// Tanggal terkunci Ramadan yang dipuasa penuh (urut).
  final List<String> ramadanPenuh;

  final int debtAdded, debtLeft;
  final String? debtSettledOn;
}

class BadgeStatus {
  const BadgeStatus({required this.def, required this.current, this.earnedOn});

  final BadgeDef def;

  /// Kemajuan saat ini (maksimum [BadgeDef.target]).
  final int current;
  final String? earnedOn;

  bool get earned => earnedOn != null;
  double get fraction => (current / def.target).clamp(0.0, 1.0);

  String get progressText => earned
      ? 'Diraih ${longDateId(earnedOn!)}'
      : '$current dari ${def.target} ${def.unit}';
}

const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// "1 November 2026" dari kunci tanggal.
String longDateId(String key) {
  final d = parseDateKey(key);
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

/// Panjang run hari beruntun (selisih tepat 1 hari) pada [dates] urut;
/// mengembalikan (terpanjang, tanggal saat run pertama kali mencapai tiap
/// ambang) dan panjang run yang masih berjalan sampai [today] / kemarin.
({Map<int, String> reached, int ongoing}) streakRuns(
  List<String> dates,
  List<int> thresholds,
  String today,
) {
  final reached = <int, String>{};
  var run = 0;
  String? prev;
  for (final d in dates) {
    if (prev != null &&
        parseDateKey(d).difference(parseDateKey(prev)).inDays == 1) {
      run++;
    } else if (prev == d) {
      continue;
    } else {
      run = 1;
    }
    for (final t in thresholds) {
      if (run >= t) reached.putIfAbsent(t, () => d);
    }
    prev = d;
  }
  // run berjalan: berakhir hari ini atau kemarin
  var ongoing = 0;
  if (prev != null) {
    final gap = parseDateKey(today).difference(parseDateKey(prev)).inDays;
    if (gap <= 1) ongoing = run;
  }
  return (reached: reached, ongoing: ongoing);
}

/// Tanggal ke-[n] (1-based) pada daftar urut, null bila belum sebanyak itu.
String? _nth(List<String> sorted, int n) =>
    sorted.length >= n ? sorted[n - 1] : null;

/// Semua Jumat dalam suatu bulan (<= [today]) tercatat -> tanggal Jumat
/// terakhirnya; kemajuan = Jumat tercatat dari Jumat bulan ini.
({String? earnedOn, int done, int total}) _jumatPenuh(
  Set<String> jumat,
  String today,
) {
  final t = parseDateKey(today);
  String? earned;
  // bulan-bulan yang punya catatan Jumat, ditambah bulan ini
  final months = <(int, int)>{(t.year, t.month)};
  for (final d in jumat) {
    final x = parseDateKey(d);
    months.add((x.year, x.month));
  }
  for (final (y, m) in months) {
    final fridays = <String>[];
    for (
      var d = DateTime(y, m, 1);
      d.month == m;
      d = d.add(const Duration(days: 1))
    ) {
      if (d.weekday == DateTime.friday) fridays.add(dateKey(d));
    }
    // bulan harus sudah selesai Jumatnya (semua Jumat <= hari ini)
    if (fridays.isEmpty || fridays.last.compareTo(today) > 0) continue;
    if (fridays.every(jumat.contains)) {
      final last = fridays.last;
      if (earned == null || last.compareTo(earned) < 0) earned = last;
    }
  }
  // kemajuan bulan ini
  final thisMonth = <String>[];
  for (
    var d = DateTime(t.year, t.month, 1);
    d.month == t.month;
    d = d.add(const Duration(days: 1))
  ) {
    if (d.weekday == DateTime.friday) thisMonth.add(dateKey(d));
  }
  return (
    earnedOn: earned,
    done: thisMonth.where(jumat.contains).length,
    total: thisMonth.length,
  );
}

/// Juz dengan ayat hafal terbanyak: (jumlah, ukuran juz, tanggal terakhir
/// ayatnya dihafal bila penuh).
({int best, int size, String? fullOn}) _juzHafalan(Map<int, String> hafal) {
  final counts = List<int>.filled(totalJuz + 1, 0);
  final lastOn = List<String?>.filled(totalJuz + 1, null);
  hafal.forEach((ayah, on) {
    if (ayah < 1 || ayah > totalAyahs) return;
    final j = juzOf(ayah);
    counts[j]++;
    if (lastOn[j] == null || on.compareTo(lastOn[j]!) > 0) lastOn[j] = on;
  });
  var best = 0, bestSize = 0;
  String? fullOn;
  for (var j = 1; j <= totalJuz; j++) {
    final (a, b) = juzRange(j);
    final size = b - a + 1;
    if (counts[j] == size) {
      if (fullOn == null || lastOn[j]!.compareTo(fullOn) < 0) {
        fullOn = lastOn[j];
      }
    }
    if (counts[j] * bestSize > best * size || bestSize == 0) {
      best = counts[j];
      bestSize = size;
    }
  }
  return (best: best, size: bestSize, fullOn: fullOn);
}

/// Hitung semua lencana dari [data]; [stored] = tanggal yang sudah pernah
/// tercatat diraih (menang atas hitungan baru agar lencana tidak hilang).
List<BadgeStatus> evaluateBadges(
  BadgeData data, {
  Map<String, String> stored = const {},
}) {
  final streak = streakRuns(data.completeDates, [7, 30, 100], data.today);
  final jumat = _jumatPenuh(data.jumatDates, data.today);
  final juz = _juzHafalan(data.hafalanDates);

  final raw = <BadgeId, ({int current, String? on})>{
    BadgeId.langkahPertama: (
      current: data.completeDates.isEmpty ? 0 : 1,
      on: _nth(data.completeDates, 1),
    ),
    BadgeId.pekanTerjaga: (current: streak.ongoing, on: streak.reached[7]),
    BadgeId.sebulanIstiqamah: (current: streak.ongoing, on: streak.reached[30]),
    BadgeId.seratusHari: (current: streak.ongoing, on: streak.reached[100]),
    BadgeId.penjagaFajar: (
      current: data.subuhOnTimeDates.length,
      on: _nth(data.subuhOnTimeDates, 30),
    ),
    BadgeId.pecintaJamaah: (
      current: data.jamaahDates.length,
      on: _nth(data.jamaahDates, 30),
    ),
    BadgeId.jumatPenuh: (
      current: jumat.earnedOn != null ? 1 : 0,
      on: jumat.earnedOn,
    ),
    BadgeId.rutinTilawah: (
      current: data.tilawahDates.length,
      on: _nth(data.tilawahDates, 30),
    ),
    BadgeId.khatam: (
      current: data.khatamDates.isEmpty ? 0 : 1,
      on: _nth(data.khatamDates, 1),
    ),
    BadgeId.sejuzHafalan: (current: juz.fullOn != null ? 1 : 0, on: juz.fullOn),
    BadgeId.ramadanPenuh: (
      current: data.ramadanPenuh.isEmpty ? 0 : 1,
      on: _nth(data.ramadanPenuh, 1),
    ),
    BadgeId.pelunasHutang: (
      current: data.debtAdded > 0 && data.debtLeft == 0 ? 1 : 0,
      on: data.debtAdded > 0 && data.debtLeft == 0 ? data.debtSettledOn : null,
    ),
  };

  return [
    for (final def in badgeDefs)
      if (def.id != BadgeId.jumatPenuh || data.male)
        BadgeStatus(
          def: def,
          current: raw[def.id]!.current.clamp(0, def.target),
          earnedOn: stored[def.id.name] ?? raw[def.id]!.on,
        ),
  ];
}

/// Kemajuan teks khusus (mis. "2 dari 4 Jumat bulan ini") untuk lencana
/// yang belum diraih; null = pakai [BadgeStatus.progressText].
String? badgeHint(BadgeStatus s, BadgeData data) {
  if (s.earned) return null;
  switch (s.def.id) {
    case BadgeId.jumatPenuh:
      final j = _jumatPenuh(data.jumatDates, data.today);
      return '${j.done} dari ${j.total} Jumat bulan ini';
    case BadgeId.sejuzHafalan:
      final j = _juzHafalan(data.hafalanDates);
      return '${j.best} dari ${j.size} ayat (juz terdekat)';
    case BadgeId.pelunasHutang:
      return data.debtAdded == 0
          ? 'Belum ada hutang sholat tercatat'
          : '${data.debtAdded - data.debtLeft} dari ${data.debtAdded} sholat';
    case BadgeId.pekanTerjaga:
    case BadgeId.sebulanIstiqamah:
    case BadgeId.seratusHari:
      return '${s.current} hari beruntun saat ini · target ${s.def.target}';
    default:
      return null;
  }
}

/// Lencana yang sudah diraih tersimpan: id -> tanggal.
abstract final class BadgeStore {
  static const _earnedKey = 'badges_earned';
  static const _seenKey = 'badges_seen';

  static Future<Map<String, String>> earned() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_earnedKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, String>();
    } catch (_) {
      return {};
    }
  }

  /// Simpan lencana yang baru diraih; mengembalikan yang belum pernah
  /// dilihat pengguna (untuk perayaan).
  static Future<List<BadgeId>> record(List<BadgeStatus> statuses) async {
    final p = await SharedPreferences.getInstance();
    final stored = await earned();
    var changed = false;
    for (final s in statuses) {
      if (s.earned && !stored.containsKey(s.def.id.name)) {
        stored[s.def.id.name] = s.earnedOn!;
        changed = true;
      }
    }
    if (changed) await p.setString(_earnedKey, jsonEncode(stored));
    final seen = (p.getStringList(_seenKey) ?? const <String>[]).toSet();
    return [
      for (final s in statuses)
        if (s.earned && !seen.contains(s.def.id.name)) s.def.id,
    ];
  }

  static Future<void> markSeen(Iterable<BadgeId> ids) async {
    final p = await SharedPreferences.getInstance();
    final seen = (p.getStringList(_seenKey) ?? const <String>[]).toSet()
      ..addAll(ids.map((e) => e.name));
    await p.setStringList(_seenKey, seen.toList());
  }
}

/// Kumpulkan [BadgeData] dari basis data. [male]: lencana Jumat hanya untuk
/// laki-laki. Jam sholat memakai lokasi & batas "awal waktu" pengguna.
Future<BadgeData> loadBadgeData(
  AppDatabase db, {
  required String today,
  required double latitude,
  required double longitude,
  required int onTimeMinutes,
  required bool male,
}) async {
  const from = '2000-01-01';
  final ibadah = db.ibadahDao;
  final summaries = await ibadah.summaries(from, today);
  final complete = [
    for (final e in summaries.entries)
      if (e.value.complete) e.key,
  ]..sort();

  final items = await (db.select(db.ibadahItems)).get();
  final sholatIds = {
    for (final i in items)
      if (i.groupKey == sholatWajibGroup) i.id: i.key,
  };
  final subuhId = items.where((i) => i.key == 'subuh').firstOrNull?.id;
  final dzuhurId = items.where((i) => i.key == 'dzuhur').firstOrNull?.id;

  final logs = [
    for (final l in await db.select(db.ibadahLogs).get())
      if (l.value > 0) l,
  ];
  final jamaah = <String>[];
  final subuhOnTime = <String>{};
  final jumat = <String>{};
  for (final l in logs) {
    if (!sholatIds.containsKey(l.itemId)) continue;
    if (l.jamaah == true) jamaah.add(l.date);
    if (l.itemId == dzuhurId && l.jumat == true) jumat.add(l.date);
    if (l.itemId == subuhId && l.prayedAt != null) {
      final w = sholatWindow(
        'subuh',
        parseDateKey(l.date),
        latitude: latitude,
        longitude: longitude,
      );
      if (w != null &&
          sholatStatus(
                l.prayedAt!,
                w,
                onTimeMinutes: onTimeMinutes,
                jamak: l.jamak ?? false,
                qadhaReason: l.qadhaReason,
              ) ==
              SholatStatus.onTime) {
        subuhOnTime.add(l.date);
      }
    }
  }

  final tilawah = {
    for (final r in await db.select(db.quranLogs).get()) r.date,
  }.toList()..sort();
  final khatam = [
    for (final c in await db.select(db.quranCycles).get())
      if (c.completed && c.finishedAt != null) dateKey(c.finishedAt!),
  ]..sort();
  final hafalan = {
    for (final h in await db.select(db.hafalanAyahs).get())
      h.ayah: dateKey(h.memorizedAt),
  };
  final ramadan = [
    for (final r in await db.select(db.ramadanRecaps).get())
      if (!r.manual && r.days > 0 && r.fasted >= r.days) dateKey(r.lockedAt),
  ]..sort();

  final entries = await ibadah.sholatQadhaEntriesAll();
  final debt = sholatDebt(entries, today: today);
  String? settledOn;
  if (debt.settled && entries.isNotEmpty) {
    final last = entries
        .map((e) => e.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    settledOn = dateKey(last);
  }

  return BadgeData(
    today: today,
    male: male,
    completeDates: complete,
    subuhOnTimeDates: subuhOnTime.toList()..sort(),
    jamaahDates: jamaah..sort(),
    jumatDates: jumat,
    tilawahDates: tilawah,
    khatamDates: khatam,
    hafalanDates: hafalan,
    ramadanPenuh: ramadan,
    debtAdded: debt.added,
    debtLeft: debt.left,
    debtSettledOn: settledOn,
  );
}
