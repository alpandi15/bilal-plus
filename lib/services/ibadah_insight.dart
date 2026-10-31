import '../data/sholat_dalil.dart';
import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'hijri_calendar.dart';
import 'ibadah_day.dart';
import 'ibadah_report.dart';
import 'prayer_calculator.dart' as calc;
import 'sholat_time.dart';

/// Analisis otomatis laporan ibadah (harian & bulanan): apa yang sudah baik,
/// apa yang perlu ditingkatkan, dan rekomendasi langkah berikutnya.
///
/// Murni aturan di perangkat - bukan AI online, tidak ada data yang keluar
/// dari HP. Rujukan hadits memakai nomor kitab di aplikasi (bisa diketuk).

enum InsightKind { good, improve, tip }

/// Ikon semantik; pemetaan ke gambar ada di lapisan tampilan.
enum InsightIcon {
  sholat,
  awalWaktu,
  jamaah,
  tilawah,
  dhuha,
  malam,
  dzikir,
  sedekah,
  puasa,
  streak,
  naik,
  turun,
  alarm,
  qadha,
  masjid,
  bintang,
  kalender,
  rawatib,
  umum,
}

class Insight {
  const Insight(this.kind, this.icon, this.title, this.detail, {this.ref});

  final InsightKind kind;
  final InsightIcon icon;
  final String title, detail;

  /// "HR. Muslim no. 1181" - tautan ke hadits di aplikasi.
  final String? ref;
}

/// Predikat skor: nama + urutan (0 terbaik).
enum Grade {
  luarBiasa('Luar biasa'),
  sangatBaik('Sangat baik'),
  baik('Baik'),
  cukup('Cukup'),
  perluDitingkatkan('Perlu ditingkatkan'),
  berhalangan('Berhalangan'),
  kosong('Belum ada catatan');

  const Grade(this.label);
  final String label;
}

Grade gradeOf(double fraction, {bool excused = false, bool hasData = true}) {
  if (excused) return Grade.berhalangan;
  if (!hasData) return Grade.kosong;
  if (fraction >= 0.95) return Grade.luarBiasa;
  if (fraction >= 0.8) return Grade.sangatBaik;
  if (fraction >= 0.6) return Grade.baik;
  if (fraction >= 0.35) return Grade.cukup;
  return Grade.perluDitingkatkan;
}

/// Keadaan satu sholat wajib pada hari yang dilaporkan.
enum PrayerState {
  onTime,
  late,
  jamak,
  uzur,
  qadha,

  /// tercentang tanpa jam (pencatatan waktu mati)
  untimed,

  /// waktunya sedang berjalan & belum dikerjakan (hanya hari ini)
  ongoing,

  /// waktunya belum masuk (hanya hari ini)
  upcoming,

  /// waktunya habis & tidak dikerjakan
  missed,
  excused,
}

class PrayerRow {
  const PrayerRow({
    required this.key,
    required this.name,
    required this.state,
    this.time,
    this.until,
    this.delay = 0,
    this.jamaah,
    this.qashar = false,
    this.reason,
  });

  final String key, name;
  final PrayerState state;

  /// Jam dikerjakan ("04:58") / batas waktu bila [PrayerState.ongoing].
  final String? time, until;
  final int delay;
  final bool? jamaah;
  final bool qashar;
  final String? reason;

  bool get done => switch (state) {
    PrayerState.onTime ||
    PrayerState.late ||
    PrayerState.jamak ||
    PrayerState.uzur ||
    PrayerState.qadha ||
    PrayerState.untimed => true,
    _ => false,
  };
}

class CategoryRow {
  const CategoryRow(this.label, this.done, this.total, this.icon);
  final String label;
  final int done, total;
  final InsightIcon icon;
  double get fraction => total == 0 ? 0 : done / total;
}

class DailyReport {
  const DailyReport({
    required this.date,
    required this.isToday,
    required this.score,
    required this.grade,
    required this.prayers,
    required this.categories,
    required this.good,
    required this.improve,
    required this.tips,
    required this.streak,
    required this.previousAverage,
    required this.timed,
  });

  final String date;
  final bool isToday;
  final DayScore score;
  final Grade grade;
  final List<PrayerRow> prayers;
  final List<CategoryRow> categories;
  final List<Insight> good, improve, tips;
  final int streak;

  /// Rata-rata tuntas 7 hari sebelumnya (null bila belum ada catatan).
  final double? previousAverage;

  /// Pencatatan jam sholat aktif.
  final bool timed;

  double get fraction => score.fraction;
  int get percent => (score.fraction * 100).round();
  bool get excused => score.excused;

  /// Selisih terhadap rata-rata 7 hari sebelumnya (poin persen), null bila
  /// tidak ada pembanding.
  int? get delta => previousAverage == null || !score.hasData || excused
      ? null
      : ((score.fraction - previousAverage!) * 100).round();
}

/// Tips per ibadah lain: judul pendek + penjelasan + rujukan.
const _itemTips = <String, (String, String, String?)>{
  'dhuha': (
    'Sholat Dhuha',
    'Dua rakaat sejak ±15 menit setelah terbit sampai sebelum Dzuhur - '
        'mencukupi sedekah seluruh persendian.',
    'HR. Muslim no. 1181',
  ),
  'tahajud': (
    'Tahajud',
    'Seutama-utama sholat sesudah fardhu adalah sholat malam. Dua rakaat '
        'di sepertiga malam terakhir sudah sangat berarti.',
    'HR. Muslim no. 1982',
  ),
  'witir': (
    'Witir',
    'Tutup malam dengan witir, walau satu rakaat.',
    'HR. Muslim no. 1982',
  ),
  'dzikir_pagi': (
    'Dzikir pagi',
    'Lima menit setelah Subuh - bekal perlindungan sepanjang hari.',
    null,
  ),
  'dzikir_petang': (
    'Dzikir petang',
    'Sempatkan sebelum Maghrib - penutup hari yang menenangkan.',
    null,
  ),
  'istighfar': (
    'Istighfar',
    'Ucapkan di sela aktivitas - ringan di lisan, besar di timbangan.',
    null,
  ),
  'sedekah': (
    'Sedekah',
    'Sekecil apa pun nilainya - yang penting rutin dan ikhlas.',
    null,
  ),
  'puasa_sunnah': (
    'Puasa sunnah',
    'Senin-Kamis atau Ayyamul Bidh - mulai dari satu hari sepekan.',
    null,
  ),
};

const _monthNames = [
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
const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String monthName(int month) => _monthNames[month - 1];

String _list(List<String> names, {int max = 3}) {
  if (names.length <= max) {
    return names.length <= 1
        ? names.join()
        : '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  }
  return '${names.take(max).join(', ')} & ${names.length - max} lainnya';
}

/// Rujukan ancaman qadha tanpa uzur (HR. Muslim no. 116).
final _warningRef = peringatanUmum
    .firstWhere((d) => d.source.contains('Muslim no. 116'))
    .source;

/* -------------------------------------------------------------------------- */
/*  Harian                                                                     */
/* -------------------------------------------------------------------------- */

/// Susun laporan hari [date]. [data] harus mencakup minimal 7 hari sebelum
/// [date] sampai [date] (`IbadahDao.loadRange`).
DailyReport buildDailyReport(
  IbadahRangeData data, {
  required String date,
  required String today,
  required HijriAnchors anchors,
  required double latitude,
  required double longitude,
  required int onTimeMinutes,
  required double soloWeight,
  required bool male,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final isToday = date == today;
  final report = buildIbadahReport(
    data,
    anchors: anchors,
    today: today,
    latitude: latitude,
    longitude: longitude,
    onTimeMinutes: onTimeMinutes,
    soloWeight: soloWeight,
  );
  final score = report.days.lastWhere(
    (d) => d.date == date,
    orElse: () => DayScore(
      date: date,
      done: 0,
      total: 0,
      excused: false,
      hasData: false,
      sholat: 0,
    ),
  );

  // pembanding: rata-rata tuntas hari-hari sebelumnya di rentang
  final before = report.days
      .where(
        (d) =>
            d.date.compareTo(date) < 0 &&
            d.hasData &&
            !d.excused &&
            d.total > 0,
      )
      .toList();
  final previousAverage = before.isEmpty
      ? null
      : before.fold<double>(0, (a, d) => a + d.fraction) / before.length;

  // streak sampai hari ini yang dilaporkan
  var streak = 0;
  for (var i = report.days.length - 1; i >= 0; i--) {
    final d = report.days[i];
    if (d.date.compareTo(date) > 0) continue;
    if (d.date == date && !d.kept && isToday) continue;
    if (!d.hasData || !d.kept) break;
    streak++;
  }

  final logs = data.logs[date] ?? const <int, IbadahLog>{};
  final values = {for (final e in logs.entries) e.key: e.value.value};
  final hasTilawah = data.tilawah.contains(date);
  final tz = calc.timezoneFromLongitude(longitude);
  final day = parseDateKey(date);
  final excused = data.excused.contains(date);
  final visible = visibleItems(data.items, ibadahDay(date, anchors), values);

  // ------------------------------ sholat wajib ------------------------------
  final sholatItems = jumatAware(
    [
      for (final i in data.items)
        if (i.groupKey == sholatWajibGroup) i,
    ],
    male: male,
    date: date,
    logs: logs,
  );
  final rows = <PrayerRow>[];
  var anyTimed = false;
  for (final i in sholatItems) {
    final log = logs[i.id];
    final window = sholatWindow(
      i.key,
      day,
      latitude: latitude,
      longitude: longitude,
    );
    String hm(DateTime d) => calc.formatInZone(d.toUtc(), tz);
    if (excused) {
      rows.add(PrayerRow(key: i.key, name: i.name, state: PrayerState.excused));
      continue;
    }
    if (log != null && log.value > 0) {
      final at = log.prayedAt;
      if (at == null || window == null) {
        rows.add(
          PrayerRow(
            key: i.key,
            name: i.name,
            state: PrayerState.untimed,
            jamaah: log.jamaah,
            qashar: log.qashar ?? false,
          ),
        );
        continue;
      }
      anyTimed = true;
      final status = sholatStatus(
        at,
        window,
        onTimeMinutes: onTimeMinutes,
        jamak: log.jamak ?? false,
        qadhaReason: log.qadhaReason,
      );
      rows.add(
        PrayerRow(
          key: i.key,
          name: i.name,
          state: switch (status) {
            SholatStatus.onTime => PrayerState.onTime,
            SholatStatus.late => PrayerState.late,
            SholatStatus.jamak => PrayerState.jamak,
            SholatStatus.uzur => PrayerState.uzur,
            SholatStatus.qadha => PrayerState.qadha,
          },
          time: hm(at),
          delay: minutesAfterAdzan(at, window),
          jamaah: log.jamaah,
          qashar: log.qashar ?? false,
          reason: log.qadhaReason,
        ),
      );
      continue;
    }
    var state = PrayerState.missed;
    String? until;
    if (isToday && window != null) {
      if (clock.isBefore(window.start)) {
        state = PrayerState.upcoming;
      } else if (clock.isBefore(window.end)) {
        state = PrayerState.ongoing;
        until = hm(window.end);
      }
    }
    rows.add(PrayerRow(key: i.key, name: i.name, state: state, until: until));
  }

  // ------------------------------ kategori ------------------------------
  final rawatib = [
    for (final i in visible)
      if (i.groupKey == rawatibGroup) i,
  ];
  final tilawah = visible.where((i) => i.key == tilawahKey).toList();
  final others = [
    for (final i in visible)
      if (i.groupKey != sholatWajibGroup &&
          i.groupKey != rawatibGroup &&
          i.key != tilawahKey)
        i,
  ];
  bool done(IbadahItem i) =>
      itemDone(i, values[i.id] ?? 0, hasTilawah: hasTilawah);
  final doneRawatib = rawatib.where(done).toList();
  final undoneOthers = others.where((i) => !done(i)).toList();
  final doneOthers = others.where(done).toList();
  final tilawahDone = tilawah.isNotEmpty && done(tilawah.first);

  final categories = <CategoryRow>[
    CategoryRow(
      'Sholat wajib',
      rows.where((r) => r.done).length,
      excused ? 0 : rows.length,
      InsightIcon.sholat,
    ),
    if (rawatib.isNotEmpty)
      CategoryRow(
        'Sunnah rawatib',
        doneRawatib.length,
        rawatib.length,
        InsightIcon.rawatib,
      ),
    if (tilawah.isNotEmpty)
      CategoryRow(
        "Tilawah Al-Qur'an",
        tilawahDone ? 1 : 0,
        1,
        InsightIcon.tilawah,
      ),
    if (others.isNotEmpty)
      CategoryRow(
        'Amalan lain',
        doneOthers.length,
        others.length,
        InsightIcon.dzikir,
      ),
  ];

  final good = <Insight>[];
  final improve = <Insight>[];
  final tips = <Insight>[];
  final hasData = score.hasData;

  if (excused) {
    good.add(
      const Insight(
        InsightKind.good,
        InsightIcon.bintang,
        'Hari berhalangan',
        'Sholat & puasa tidak dihitung dan streak tetap terjaga. Dzikir, '
            'doa, dan bacaan Al-Qur\'an tetap bisa dilakukan.',
      ),
    );
  }

  if (!excused) {
    final onTime = rows.where((r) => r.state == PrayerState.onTime).toList();
    final jamak = rows.where((r) => r.state == PrayerState.jamak).toList();
    final late = rows.where((r) => r.state == PrayerState.late).toList();
    final qadha = rows.where((r) => r.state == PrayerState.qadha).toList();
    final uzur = rows.where((r) => r.state == PrayerState.uzur).toList();
    final missed = rows.where((r) => r.state == PrayerState.missed).toList();
    final ongoing = rows.where((r) => r.state == PrayerState.ongoing).toList();
    final doneRows = rows.where((r) => r.done).toList();
    final sendiri = doneRows
        .where((r) => r.jamaah == false && !r.qashar)
        .toList();
    final berjamaah = doneRows.where((r) => r.jamaah == true).toList();

    // ---- yang baik ----
    if (doneRows.length == rows.length && rows.isNotEmpty) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.sholat,
          'Lima waktu tertunaikan',
          'Alhamdulillah, semua sholat wajib hari ini terlaksana. '
              'Pertahankan - inilah amalan yang pertama kali dihisab.',
        ),
      );
    }
    final subuh = rows.where((r) => r.key == 'subuh').firstOrNull;
    if (subuh != null &&
        (subuh.state == PrayerState.onTime ||
            subuh.state == PrayerState.untimed) &&
        subuh.done) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.awalWaktu,
          subuh.state == PrayerState.onTime
              ? 'Subuh di awal waktu'
              : 'Subuh terjaga',
          'Kunci hari yang berkah - yang sholat Subuh berada dalam jaminan '
          'Allah.',
          ref: 'HR. Muslim no. 1050',
        ),
      );
    }
    final awal = [...onTime, ...jamak].where((r) => r.key != 'subuh').toList();
    if (onTime.length + jamak.length >= 2 && awal.isNotEmpty) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.awalWaktu,
          '${onTime.length + jamak.length} sholat tepat waktu',
          '${_list([
                for (final r in [...onTime, ...jamak]) r.name,
              ])} '
              'dikerjakan di awal waktunya - amal yang paling dicintai Allah.',
          ref: 'HR. Bukhari no. 496',
        ),
      );
    }
    if (berjamaah.length >= 3) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.jamaah,
          'Berjama\'ah ${berjamaah.length} dari ${doneRows.length} sholat',
          'Sholat berjama\'ah 27 derajat lebih utama daripada sendirian.',
          ref: 'HR. Bukhari no. 609',
        ),
      );
    }
    if (uzur.isNotEmpty) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.qadha,
          '${_list([for (final r in uzur) r.name])} segera ditunaikan',
          'Meski terlewat karena uzur, langsung dikerjakan begitu ingat - '
              'itulah kaffaratnya.',
          ref: 'HR. Muslim no. 1103',
        ),
      );
    }
    if (rawatib.length >= 2 && doneRawatib.length >= (rawatib.length / 2)) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.rawatib,
          'Sunnah rawatib ${doneRawatib.length}/${rawatib.length}',
          'Pelengkap sholat wajib yang menutup kekurangannya.',
        ),
      );
    }
    if (tilawahDone) {
      good.add(
        const Insight(
          InsightKind.good,
          InsightIcon.tilawah,
          "Tilawah Al-Qur'an terjaga",
          'Setiap huruf bernilai satu kebaikan, dilipatgandakan sepuluh kali.',
          ref: 'HR. Tirmidzi no. 2835',
        ),
      );
    }
    if (doneOthers.isNotEmpty) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.dzikir,
          'Amalan lain: ${_list([for (final i in doneOthers) i.name])}',
          'Amalan sunnah yang rutin - sedikit tapi terus-menerus lebih '
              'dicintai Allah.',
        ),
      );
    }
    if (streak >= 3) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.streak,
          '$streak hari berturut-turut terjaga',
          'Lima waktu lengkap tanpa putus. Istiqamah!',
        ),
      );
    }
    final delta = previousAverage == null || !hasData
        ? null
        : ((score.fraction - previousAverage) * 100).round();
    if (delta != null && delta >= 10) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.naik,
          'Naik $delta% dari rata-rata sepekan',
          'Hari ini lebih baik daripada kebiasaanmu 7 hari terakhir.',
        ),
      );
    }

    // ---- perlu ditingkatkan ----
    if (qadha.isNotEmpty) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.qadha,
          '${_list([for (final r in qadha) r.name])} diqadha tanpa uzur',
          'Menunda sholat sampai habis waktunya tanpa uzur termasuk dosa '
              'besar. Perbanyak istighfar, jangan diulangi, dan pasang alarm '
              'sebelum adzan.',
          ref: _warningRef,
        ),
      );
    }
    if (missed.isNotEmpty) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.alarm,
          '${_list([for (final r in missed) r.name])} terlewat',
          'Waktunya sudah habis tanpa dikerjakan. Segera qadha dan '
              'bertaubat - tertidur atau lupa tidak berdosa bila langsung '
              'ditunaikan begitu ingat.',
          ref: 'HR. Muslim no. 1103',
        ),
      );
    }
    if (ongoing.isNotEmpty) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.alarm,
          '${_list([for (final r in ongoing) r.name])} belum dikerjakan',
          ongoing.length == 1 && ongoing.first.until != null
              ? 'Masih ada waktu sampai ${ongoing.first.until}. Jangan '
                    'ditunda lagi.'
              : 'Waktunya masih berjalan - segera tunaikan.',
        ),
      );
    }
    if (late.isNotEmpty) {
      final worst = late.reduce((a, b) => a.delay >= b.delay ? a : b);
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.awalWaktu,
          '${_list([for (final r in late) r.name])} terlambat',
          '${worst.name} baru dikerjakan ${worst.delay} menit setelah adzan. '
              'Usahakan berhenti sejenak begitu adzan berkumandang.',
        ),
      );
    }
    if (male && sendiri.isNotEmpty) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.masjid,
          '${sendiri.length} sholat dikerjakan sendiri',
          '${_list([for (final r in sendiri) r.name])} - usahakan '
              'berjama\'ah di masjid; pahalanya 27 derajat lebih utama.',
          ref: 'HR. Bukhari no. 609',
        ),
      );
    }
    if (rawatib.length >= 2 && doneRawatib.length < rawatib.length / 2) {
      final left = [
        for (final i in rawatib)
          if (!done(i)) i.name,
      ];
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.rawatib,
          'Sunnah rawatib baru ${doneRawatib.length}/${rawatib.length}',
          'Belum: ${_list(left)}. Dua rakaat ringan sebelum/sesudah fardhu '
              'sudah cukup.',
        ),
      );
    }
    if (tilawah.isNotEmpty && !tilawahDone) {
      (isToday ? tips : improve).add(
        const Insight(
          InsightKind.improve,
          InsightIcon.tilawah,
          "Tilawah belum tercatat",
          'Mulai dari satu halaman (±5 menit) - setiap huruf bernilai '
              'sepuluh kebaikan.',
          ref: 'HR. Tirmidzi no. 2835',
        ),
      );
    }
    if (undoneOthers.isNotEmpty && hasData) {
      // hari ini: masih ada waktu - jadi rekomendasi, bukan teguran
      final target = isToday ? tips : improve;
      final names = [for (final i in undoneOthers) i.name];
      final first = undoneOthers
          .map((i) => _itemTips[i.key])
          .whereType<(String, String, String?)>()
          .firstOrNull;
      target.add(
        Insight(
          isToday ? InsightKind.tip : InsightKind.improve,
          InsightIcon.umum,
          isToday
              ? 'Masih bisa hari ini: ${_list(names)}'
              : 'Belum tercentang: ${_list(names)}',
          first == null
              ? 'Pilih satu yang paling ringan untuk dimulai.'
              : '${first.$1}: ${first.$2}',
          ref: first?.$3,
        ),
      );
    }
    if (delta != null && delta <= -15) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.turun,
          'Turun ${-delta}% dari rata-rata sepekan',
          'Lebih rendah dari kebiasaanmu 7 hari terakhir. Besok mulai lagi '
              'dari Subuh.',
        ),
      );
    }

    // ---- rekomendasi ----
    final laggards = [...late, ...qadha, ...missed];
    if (laggards.isNotEmpty) {
      final first = laggards.first;
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.alarm,
          'Pasang alarm 15 menit sebelum adzan ${first.name}',
          'Bersiap lebih dulu (wudhu, tinggalkan pekerjaan) membuat sholat '
              'di awal waktu terasa ringan.',
          ref: 'HR. Bukhari no. 496',
        ),
      );
    }
    if (laggards.any((r) => r.key == 'subuh')) {
      tips.add(
        const Insight(
          InsightKind.tip,
          InsightIcon.malam,
          'Tidur lebih awal malam ini',
          'Subuh yang berat biasanya berawal dari begadang. Tidur setelah '
              'Isya, wudhu, dan pasang dua alarm.',
          ref: 'HR. Bukhari no. 617',
        ),
      );
    }
    if (male && sendiri.isNotEmpty && tips.length < 4) {
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.masjid,
          'Coba berjama\'ah di masjid untuk ${sendiri.first.name}',
          'Berangkat 10 menit sebelum iqamah - mulai dari satu waktu yang '
              'paling mudah.',
        ),
      );
    }
    final allClean =
        laggards.isEmpty && ongoing.isEmpty && doneRows.length == rows.length;
    if (allClean && rows.isNotEmpty) {
      final next = undoneOthers
          .map((i) => _itemTips[i.key])
          .whereType<(String, String, String?)>()
          .firstOrNull;
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.bintang,
          next == null
              ? 'Pertahankan, lalu tambah satu amalan sunnah'
              : 'Tambah satu amalan: ${next.$1}',
          next?.$2 ??
              'Sholat wajib sudah rapi. Tambah satu sunnah kecil yang '
                  'konsisten - mis. Dhuha atau dzikir pagi.',
          ref: next?.$3,
        ),
      );
    }
    if (isToday && ongoing.isEmpty && missed.isEmpty) {
      final upcoming = rows
          .where((r) => r.state == PrayerState.upcoming)
          .firstOrNull;
      if (upcoming != null && tips.length < 4) {
        tips.add(
          Insight(
            InsightKind.tip,
            InsightIcon.awalWaktu,
            'Berikutnya: ${upcoming.name}',
            'Siapkan diri sebelum adzan supaya bisa di awal waktu.',
            ref: 'HR. Bukhari no. 496',
          ),
        );
      }
    }
  }

  if (!hasData && !excused) {
    tips.add(
      const Insight(
        InsightKind.tip,
        InsightIcon.kalender,
        'Mulai dengan mencatat sholat lima waktu',
        'Centang sholatmu di tab Ibadah - laporan harian akan terisi dan '
            'memberi saran yang makin tepat.',
      ),
    );
  }

  return DailyReport(
    date: date,
    isToday: isToday,
    score: score,
    grade: gradeOf(score.fraction, excused: excused, hasData: hasData),
    prayers: rows,
    categories: categories,
    good: good,
    improve: improve,
    tips: tips.take(4).toList(),
    streak: streak,
    previousAverage: previousAverage,
    timed: anyTimed,
  );
}

/* -------------------------------------------------------------------------- */
/*  Bulanan                                                                    */
/* -------------------------------------------------------------------------- */

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.report,
    required this.grade,
    required this.previousAverage,
    required this.good,
    required this.improve,
    required this.tips,
    required this.daysWithData,
    required this.totalDays,
    required this.onTime,
    required this.late,
    required this.qadha,
    required this.valid,
    required this.missed,
    required this.jamaahPercent,
    required this.tilawahDays,
    required this.bestWeekday,
    required this.worstWeekday,
  });

  /// Tanggal 1 bulan yang dilaporkan (UTC).
  final DateTime month;
  final IbadahReport report;
  final Grade grade;
  final double? previousAverage;
  final List<Insight> good, improve, tips;

  /// Hari dengan catatan / jumlah hari yang sudah berjalan di bulan itu.
  final int daysWithData, totalDays;

  /// Total sholat wajib: awal waktu, terlambat, qadha tanpa uzur, sah
  /// (jamak + qadha uzur), dan tidak dikerjakan.
  final int onTime, late, qadha, valid, missed;
  final int? jamaahPercent;
  final int tilawahDays;
  final int? bestWeekday, worstWeekday;

  double get average => report.average;
  int get percent => (average * 100).round();
  int get fullDays => report.fullDays;

  int? get delta => previousAverage == null || daysWithData == 0
      ? null
      : ((average - previousAverage!) * 100).round();

  String get title => '${monthName(month.month)} ${month.year}';
}

/// Rentang tanggal laporan bulan [month] (tanggal 1 UTC): (dari, sampai).
(String, String) monthRange(DateTime month) => (
  dateKey(DateTime.utc(month.year, month.month, 1)),
  dateKey(DateTime.utc(month.year, month.month + 1, 0)),
);

/// Susun laporan bulan [month]. [data] = `loadRange` untuk [monthRange];
/// [previous] (opsional) = rentang bulan sebelumnya, untuk pembanding.
MonthlyReport buildMonthlyReport(
  IbadahRangeData data, {
  required DateTime month,
  required String today,
  required HijriAnchors anchors,
  required double latitude,
  required double longitude,
  required int onTimeMinutes,
  required double soloWeight,
  required bool male,
  IbadahRangeData? previous,
}) {
  IbadahReport build(IbadahRangeData d) => buildIbadahReport(
    d,
    anchors: anchors,
    today: today,
    latitude: latitude,
    longitude: longitude,
    onTimeMinutes: onTimeMinutes,
    soloWeight: soloWeight,
  );
  final report = build(data);
  final prevAverage = previous == null
      ? null
      : (() {
          final r = build(previous);
          return r.counted.isEmpty ? null : r.average;
        })();

  final daysWithData = report.days.where((d) => d.hasData).length;
  int sum(int Function(SholatStat) f) =>
      report.sholat.fold(0, (a, s) => a + f(s));
  final onTime = sum((s) => s.onTime);
  final late = sum((s) => s.late);
  final qadha = sum((s) => s.qadha);
  final valid = sum((s) => s.jamak + s.uzur);
  final missed = sum((s) => s.missed);
  final timed = onTime + late + qadha + valid;
  final jamaah = sum((s) => s.jamaah);
  final withJamaah = jamaah + sum((s) => s.sendiri);
  final jamaahPercent = withJamaah == 0
      ? null
      : (jamaah * 100 / withJamaah).round();
  final tilawahDays = report.days
      .where((d) => data.tilawah.contains(d.date))
      .length;

  // hari paling rajin / paling bolong
  int? best, worst;
  final known = [
    for (var i = 0; i < 7; i++)
      if (report.weekday[i] != null) (i, report.weekday[i]!),
  ];
  if (known.length >= 2) {
    best = known.reduce((a, b) => b.$2 > a.$2 ? b : a).$1;
    worst = known.reduce((a, b) => b.$2 < a.$2 ? b : a).$1;
    if (best == worst) best = worst = null;
  }

  final good = <Insight>[];
  final improve = <Insight>[];
  final tips = <Insight>[];
  final avg = report.average;
  final pct = (avg * 100).round();
  final delta = prevAverage == null
      ? null
      : ((avg - prevAverage) * 100).round();

  if (daysWithData == 0) {
    tips.add(
      const Insight(
        InsightKind.tip,
        InsightIcon.kalender,
        'Belum ada catatan bulan ini',
        'Centang ibadahmu di tab Ibadah - laporan bulanan akan terisi.',
      ),
    );
  } else {
    // ---- baik ----
    if (avg >= 0.7) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.bintang,
          'Rata-rata tuntas $pct%',
          'Konsistensimu bulan ini sangat baik. Barakallahu fik!',
        ),
      );
    }
    if (report.fullDays > 0) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.kalender,
          '${report.fullDays} hari tuntas penuh',
          'Seluruh ibadah aktif tercentang pada hari-hari itu.',
        ),
      );
    }
    if (report.longestStreak >= 3) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.streak,
          'Streak terpanjang ${report.longestStreak} hari',
          'Lima waktu lengkap berturut-turut tanpa putus.',
        ),
      );
    }
    if (timed >= 5 && onTime * 100 / timed >= 60) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.awalWaktu,
          '${(onTime * 100 / timed).round()}% sholat di awal waktu',
          'Amal yang paling dicintai Allah adalah sholat pada waktunya.',
          ref: 'HR. Bukhari no. 496',
        ),
      );
    }
    if (jamaahPercent != null && jamaahPercent >= 70) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.jamaah,
          "$jamaahPercent% berjama'ah",
          'Sholat berjama\'ah 27 derajat lebih utama.',
          ref: 'HR. Bukhari no. 609',
        ),
      );
    }
    final strong = report.items.where((s) => s.days >= 5 && s.rate >= 0.8);
    if (strong.isNotEmpty) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.rawatib,
          'Paling konsisten: ${_list([for (final s in strong.take(3)) s.item.name])}',
          'Dikerjakan hampir setiap hari - kebiasaan yang sudah terbentuk.',
        ),
      );
    }
    if (tilawahDays >= 10) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.tilawah,
          "Tilawah $tilawahDays hari",
          'Terus dekat dengan Al-Qur\'an - setiap huruf bernilai kebaikan.',
          ref: 'HR. Tirmidzi no. 2835',
        ),
      );
    }
    if (delta != null && delta >= 5) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.naik,
          'Naik $delta% dari bulan lalu',
          'Perkembangan yang nyata - teruskan.',
        ),
      );
    }
    if (valid > 0) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.qadha,
          '$valid sholat sah karena safar/uzur',
          'Jamak saat safar dan qadha karena uzur tidak dianggap lalai.',
        ),
      );
    }

    // ---- perlu ditingkatkan ----
    if (qadha > 0) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.qadha,
          '$qadha sholat diqadha tanpa uzur',
          'Menunda sholat sampai habis waktunya tanpa uzur termasuk dosa '
              'besar. Bertaubatlah dan perbaiki kebiasaan sebelum adzan.',
          ref: _warningRef,
        ),
      );
    }
    if (missed > 0) {
      final worstPrayer = report.sholat.reduce(
        (a, b) => b.missed > a.missed ? b : a,
      );
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.alarm,
          '$missed sholat tidak tercatat',
          worstPrayer.missed > 0
              ? 'Paling sering terlewat: ${worstPrayer.item.name} '
                    '(${worstPrayer.missed}x). Bila sudah dikerjakan tapi lupa '
                    'dicentang, catat lebih rutin.'
              : 'Catat sholatmu setiap selesai agar laporan akurat.',
        ),
      );
    }
    final lateByPrayer = report.sholat.where((s) => s.timed >= 5).toList()
      ..sort(
        (a, b) => ((b.late + b.qadha) / b.timed).compareTo(
          (a.late + a.qadha) / a.timed,
        ),
      );
    if (lateByPrayer.isNotEmpty &&
        (lateByPrayer.first.late + lateByPrayer.first.qadha) /
                lateByPrayer.first.timed >=
            0.3) {
      final s = lateByPrayer.first;
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.awalWaktu,
          '${s.item.name} sering terlambat',
          '${s.late + s.qadha} dari ${s.timed} kali melewati awal waktu, '
              'rata-rata ${s.avgDelay.round()} menit setelah adzan.',
        ),
      );
    }
    if (male &&
        withJamaah >= 5 &&
        jamaahPercent != null &&
        jamaahPercent < 50) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.masjid,
          "Baru $jamaahPercent% berjama'ah",
          'Coba mulai dari satu waktu yang paling mudah ke masjid - mis. '
              'Maghrib atau Isya.',
          ref: 'HR. Bukhari no. 609',
        ),
      );
    }
    final weak =
        report.items
            .where(
              (s) =>
                  s.days >= 5 &&
                  s.rate < 0.4 &&
                  s.item.groupKey != sholatWajibGroup,
            )
            .toList()
          ..sort((a, b) => a.rate.compareTo(b.rate));
    if (weak.isNotEmpty) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.umum,
          'Perlu ditingkatkan: ${_list([for (final s in weak.take(3)) s.item.name])}',
          'Baru dikerjakan ${(weak.first.rate * 100).round()}% hari '
              '(${weak.first.item.name}). Pilih satu dan targetkan 3 hari '
              'sepekan.',
        ),
      );
    }
    if (worst != null && best != null) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.kalender,
          'Hari ${_dayNames[worst]} paling sering bolong',
          'Rata-rata tuntas hanya ${((report.weekday[worst] ?? 0) * 100).round()}% '
              'vs ${_dayNames[best]} ${((report.weekday[best] ?? 0) * 100).round()}%. '
              'Siapkan pengingat khusus hari itu.',
        ),
      );
    }
    if (delta != null && delta <= -5) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.turun,
          'Turun ${-delta}% dari bulan lalu',
          'Cari tahu apa yang berubah dan mulailah dari satu kebiasaan '
              'kecil.',
        ),
      );
    }
    if (avg < 0.35) {
      improve.add(
        const Insight(
          InsightKind.improve,
          InsightIcon.sholat,
          'Fokus ke lima waktu dulu',
          'Rawat sholat wajib sebelum menambah yang sunnah.',
        ),
      );
    }

    // ---- rekomendasi ----
    if (worst != null) {
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.alarm,
          'Buat pengingat hari ${_dayNames[worst]}',
          'Hari itu paling sering bolong - atur notifikasi khusus atau '
              'jadwalkan satu amalan tetap.',
        ),
      );
    }
    if (lateByPrayer.isNotEmpty &&
        improve.any((i) => i.icon == InsightIcon.awalWaktu)) {
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.awalWaktu,
          'Pasang alarm 15 menit sebelum ${lateByPrayer.first.item.name}',
          'Bersiap lebih awal membuat sholat tepat waktu jadi kebiasaan.',
          ref: 'HR. Bukhari no. 496',
        ),
      );
    }
    if (weak.isNotEmpty) {
      final t = _itemTips[weak.first.item.key];
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.umum,
          'Target pekan depan: ${weak.first.item.name} 3x',
          t?.$2 ??
              'Mulai kecil dan konsisten lebih baik daripada besar tapi putus.',
          ref: t?.$3,
        ),
      );
    }
    if (tips.isEmpty) {
      tips.add(
        const Insight(
          InsightKind.tip,
          InsightIcon.bintang,
          'Pertahankan dan tambah satu sunnah',
          'Bulan ini sudah rapi. Tambah satu amalan kecil yang konsisten - '
              'mis. Dhuha atau dzikir pagi.',
        ),
      );
    }
  }

  return MonthlyReport(
    month: month,
    report: report,
    grade: gradeOf(avg, hasData: daysWithData > 0),
    previousAverage: prevAverage,
    good: good,
    improve: improve,
    tips: tips.take(4).toList(),
    daysWithData: daysWithData,
    totalDays: report.days.length,
    onTime: onTime,
    late: late,
    qadha: qadha,
    valid: valid,
    missed: missed,
    jamaahPercent: jamaahPercent,
    tilawahDays: tilawahDays,
    bestWeekday: best,
    worstWeekday: worst,
  );
}

/* -------------------------------------------------------------------------- */
/*  Mingguan                                                                   */
/* -------------------------------------------------------------------------- */

/// Senin pekan yang memuat [d] (UTC).
DateTime mondayOf(DateTime d) {
  final day = DateTime.utc(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Rentang pekan Senin-Minggu yang dimulai [monday]: (dari, sampai).
(String, String) weekRange(DateTime monday) =>
    (dateKey(monday), dateKey(monday.add(const Duration(days: 6))));

/// "26 Okt - 1 Nov 2026".
String weekTitle(DateTime monday) {
  final end = monday.add(const Duration(days: 6));
  String short(DateTime d) => monthName(d.month).substring(0, 3);
  final a = '${monday.day} ${short(monday)}';
  final b = '${end.day} ${short(end)} ${end.year}';
  return monday.year == end.year ? '$a - $b' : '$a ${monday.year} - $b';
}

class WeeklyReport {
  const WeeklyReport({
    required this.monday,
    required this.report,
    required this.grade,
    required this.previousAverage,
    required this.good,
    required this.improve,
    required this.tips,
    required this.daysWithData,
    required this.onTime,
    required this.late,
    required this.qadha,
    required this.valid,
    required this.missed,
    required this.jamaahPercent,
    required this.tilawahDays,
    required this.bestDay,
    required this.worstDay,
  });

  final DateTime monday;
  final IbadahReport report;
  final Grade grade;
  final double? previousAverage;
  final List<Insight> good, improve, tips;
  final int daysWithData;
  final int onTime, late, qadha, valid, missed;
  final int? jamaahPercent;
  final int tilawahDays;

  /// Hari terbaik & terendah (tanggal), null bila belum bisa dibandingkan.
  final String? bestDay, worstDay;

  double get average => report.average;
  int get percent => (average * 100).round();
  int get fullDays => report.fullDays;
  String get title => weekTitle(monday);

  int? get delta => previousAverage == null || daysWithData == 0
      ? null
      : ((average - previousAverage!) * 100).round();
}

/// Susun laporan pekan yang dimulai [monday]. [data] = `loadRange` untuk
/// [weekRange]; [previous] = pekan sebelumnya (pembanding, opsional).
WeeklyReport buildWeeklyReport(
  IbadahRangeData data, {
  required DateTime monday,
  required String today,
  required HijriAnchors anchors,
  required double latitude,
  required double longitude,
  required int onTimeMinutes,
  required double soloWeight,
  required bool male,
  IbadahRangeData? previous,
}) {
  IbadahReport build(IbadahRangeData d) => buildIbadahReport(
    d,
    anchors: anchors,
    today: today,
    latitude: latitude,
    longitude: longitude,
    onTimeMinutes: onTimeMinutes,
    soloWeight: soloWeight,
  );
  final report = build(data);
  final prevAverage = previous == null
      ? null
      : (() {
          final r = build(previous);
          return r.counted.isEmpty ? null : r.average;
        })();

  final daysWithData = report.days.where((d) => d.hasData).length;
  int sum(int Function(SholatStat) f) =>
      report.sholat.fold(0, (a, s) => a + f(s));
  final onTime = sum((s) => s.onTime);
  final late = sum((s) => s.late);
  final qadha = sum((s) => s.qadha);
  final valid = sum((s) => s.jamak + s.uzur);
  final missed = sum((s) => s.missed);
  final timed = onTime + late + qadha + valid;
  final jamaah = sum((s) => s.jamaah);
  final withJamaah = jamaah + sum((s) => s.sendiri);
  final jamaahPercent = withJamaah == 0
      ? null
      : (jamaah * 100 / withJamaah).round();
  final tilawahDays = report.days
      .where((d) => data.tilawah.contains(d.date))
      .length;

  // hari terbaik & terendah (hanya bila ada >= 3 hari yang bisa dibandingkan)
  final counted = report.counted.toList();
  String? best, worst;
  DayScore? bestScore, worstScore;
  if (counted.length >= 3) {
    bestScore = counted.reduce((a, b) => b.fraction > a.fraction ? b : a);
    worstScore = counted.reduce((a, b) => b.fraction < a.fraction ? b : a);
    if (bestScore.fraction - worstScore.fraction < 0.1) {
      bestScore = worstScore = null;
    } else {
      best = bestScore.date;
      worst = worstScore.date;
    }
  }
  String dayOf(String key) => _dayNames[parseDateKey(key).weekday - 1];

  final good = <Insight>[];
  final improve = <Insight>[];
  final tips = <Insight>[];
  final avg = report.average;
  final pct = (avg * 100).round();
  final delta = prevAverage == null
      ? null
      : ((avg - prevAverage) * 100).round();

  if (daysWithData == 0) {
    tips.add(
      const Insight(
        InsightKind.tip,
        InsightIcon.kalender,
        'Belum ada catatan pekan ini',
        'Centang ibadahmu di tab Ibadah - laporan mingguan akan terisi.',
      ),
    );
  } else {
    // ---- baik ----
    if (avg >= 0.7) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.bintang,
          'Rata-rata tuntas $pct% pekan ini',
          'Pekan yang konsisten. Barakallahu fik!',
        ),
      );
    }
    if (report.fullDays > 0) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.kalender,
          '${report.fullDays} hari tuntas penuh',
          'Seluruh ibadah aktif tercentang pada hari-hari itu.',
        ),
      );
    }
    if (report.longestStreak >= 3) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.streak,
          '${report.longestStreak} hari berturut-turut terjaga',
          'Lima waktu lengkap tanpa putus. Istiqamah!',
        ),
      );
    }
    if (timed >= 3 && onTime * 100 / timed >= 60) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.awalWaktu,
          '${(onTime * 100 / timed).round()}% sholat di awal waktu',
          'Amal yang paling dicintai Allah adalah sholat pada waktunya.',
          ref: 'HR. Bukhari no. 496',
        ),
      );
    }
    if (jamaahPercent != null && withJamaah >= 3 && jamaahPercent >= 70) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.jamaah,
          "$jamaahPercent% berjama'ah",
          "Sholat berjama'ah 27 derajat lebih utama.",
          ref: 'HR. Bukhari no. 609',
        ),
      );
    }
    final strong = report.items
        .where((s) => s.days >= 3 && s.rate >= 0.8)
        .take(3)
        .toList();
    if (strong.isNotEmpty) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.rawatib,
          'Paling konsisten: ${_list([for (final s in strong) s.item.name])}',
          'Dikerjakan hampir setiap hari pekan ini.',
        ),
      );
    }
    if (tilawahDays >= 4) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.tilawah,
          'Tilawah $tilawahDays hari pekan ini',
          'Dekat dengan Al-Qur\'an - setiap huruf bernilai kebaikan.',
          ref: 'HR. Tirmidzi no. 2835',
        ),
      );
    }
    if (best != null && bestScore!.fraction >= 0.6) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.bintang,
          'Hari terbaik: ${dayOf(best)}',
          '${(bestScore.fraction * 100).round()}% ibadah tuntas - ulangi '
              'pola hari itu di hari lain.',
        ),
      );
    }
    if (delta != null && delta >= 5) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.naik,
          'Naik $delta% dari pekan lalu',
          'Perkembangan yang nyata - teruskan.',
        ),
      );
    }
    if (valid > 0) {
      good.add(
        Insight(
          InsightKind.good,
          InsightIcon.qadha,
          '$valid sholat sah karena safar/uzur',
          'Jamak saat safar dan qadha karena uzur tidak dianggap lalai.',
        ),
      );
    }

    // ---- perlu ditingkatkan ----
    if (qadha > 0) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.qadha,
          '$qadha sholat diqadha tanpa uzur',
          'Menunda sholat sampai habis waktunya tanpa uzur termasuk dosa '
              'besar. Bertaubatlah dan siapkan diri sebelum adzan.',
          ref: _warningRef,
        ),
      );
    }
    final worstPrayer = report.sholat.reduce(
      (a, b) => b.missed > a.missed ? b : a,
    );
    if (missed > 0) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.alarm,
          '$missed sholat tidak tercatat',
          'Paling sering terlewat: ${worstPrayer.item.name} '
              '(${worstPrayer.missed}x). Bila sudah dikerjakan tapi lupa '
              'dicentang, catat lebih rutin.',
        ),
      );
    }
    final lateByPrayer =
        report.sholat.where((s) => s.late + s.qadha >= 2).toList()
          ..sort((a, b) => (b.late + b.qadha).compareTo(a.late + a.qadha));
    if (lateByPrayer.isNotEmpty) {
      final s = lateByPrayer.first;
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.awalWaktu,
          '${s.item.name} terlambat ${s.late + s.qadha}x',
          'Rata-rata ${s.avgDelay.round()} menit setelah adzan. Siapkan diri '
              'sebelum adzan ${s.item.name}.',
        ),
      );
    }
    if (male &&
        withJamaah >= 3 &&
        jamaahPercent != null &&
        jamaahPercent < 50) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.masjid,
          "Baru $jamaahPercent% berjama'ah",
          'Coba mulai dari satu waktu yang paling mudah ke masjid.',
          ref: 'HR. Bukhari no. 609',
        ),
      );
    }
    final weak =
        report.items
            .where(
              (s) =>
                  s.days >= 3 &&
                  s.rate < 0.4 &&
                  s.item.groupKey != sholatWajibGroup,
            )
            .toList()
          ..sort((a, b) => a.rate.compareTo(b.rate));
    if (weak.isNotEmpty) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.umum,
          'Perlu ditingkatkan: ${_list([for (final s in weak.take(3)) s.item.name])}',
          'Baru ${(weak.first.rate * 100).round()}% hari untuk '
              '${weak.first.item.name}. Pilih satu dan targetkan 3 hari '
              'sepekan.',
        ),
      );
    }
    if (worst != null && worstScore!.fraction < 0.4) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.kalender,
          'Hari ${dayOf(worst)} paling rendah',
          'Hanya ${(worstScore.fraction * 100).round()}% tuntas. Cari tahu '
              'apa yang membuat hari itu berat.',
        ),
      );
    }
    if (delta != null && delta <= -5) {
      improve.add(
        Insight(
          InsightKind.improve,
          InsightIcon.turun,
          'Turun ${-delta}% dari pekan lalu',
          'Mulailah lagi dari satu kebiasaan kecil - Subuh di awal waktu.',
        ),
      );
    }
    if (avg < 0.35) {
      improve.add(
        const Insight(
          InsightKind.improve,
          InsightIcon.sholat,
          'Fokus ke lima waktu dulu',
          'Rawat sholat wajib sebelum menambah yang sunnah.',
        ),
      );
    }

    // ---- rekomendasi ----
    if (worst != null && worstScore!.fraction < 0.6) {
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.alarm,
          'Pasang pengingat hari ${dayOf(worst)}',
          'Hari terendah pekan ini - atur notifikasi khusus atau jadwalkan '
              'satu amalan tetap.',
        ),
      );
    }
    if (lateByPrayer.isNotEmpty) {
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.awalWaktu,
          'Alarm 15 menit sebelum ${lateByPrayer.first.item.name}',
          'Bersiap lebih awal membuat sholat tepat waktu jadi kebiasaan.',
          ref: 'HR. Bukhari no. 496',
        ),
      );
    }
    if (weak.isNotEmpty) {
      final t = _itemTips[weak.first.item.key];
      tips.add(
        Insight(
          InsightKind.tip,
          InsightIcon.umum,
          'Target pekan depan: ${weak.first.item.name} 3x',
          t?.$2 ??
              'Mulai kecil dan konsisten lebih baik daripada besar tapi putus.',
          ref: t?.$3,
        ),
      );
    }
    if (tips.isEmpty) {
      tips.add(
        const Insight(
          InsightKind.tip,
          InsightIcon.bintang,
          'Pertahankan dan tambah satu sunnah',
          'Pekan ini sudah rapi. Tambah satu amalan kecil yang konsisten - '
              'mis. Dhuha atau dzikir pagi.',
        ),
      );
    }
  }

  return WeeklyReport(
    monday: monday,
    report: report,
    grade: gradeOf(avg, hasData: daysWithData > 0),
    previousAverage: prevAverage,
    good: good,
    improve: improve,
    tips: tips.take(4).toList(),
    daysWithData: daysWithData,
    onTime: onTime,
    late: late,
    qadha: qadha,
    valid: valid,
    missed: missed,
    jamaahPercent: jamaahPercent,
    tilawahDays: tilawahDays,
    bestDay: best,
    worstDay: worst,
  );
}
