import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../services/quran_index.dart';

part 'app_database.g.dart';

/// Basis data lokal (SQLite lewat drift) untuk catatan ibadah & bacaan
/// Al-Qur'an. Semua data pengguna tinggal di perangkat; pindah perangkat
/// lewat berkas cadangan.
///
/// Aturan penting: tanggal disimpan sebagai TEXT `YYYY-MM-DD` - tanggal
/// MASEHI di zona waktu lokasi. Tanggal hijriah, "Ramadan hari ke-n", dan
/// apakah sebuah hari termasuk Ramadan SELALU diturunkan saat ditampilkan
/// dari jangkar kalender hijriah, tidak pernah disimpan - jadi bila awal
/// Ramadan bergeser (isbat, ganti metode, penyesuaian pengguna) tidak ada
/// data yang perlu dimigrasi.
///
/// Setelah mengubah tabel: `dart run build_runner build` lalu naikkan
/// [schemaVersion] beserta langkah migrasinya (setelah rilis pertama).

enum IbadahKind {
  /// sudah / belum
  check,

  /// hitungan menuju [IbadahItems.target] (rakaat, jumlah dzikir, ...)
  counter,
}

enum IbadahScope {
  /// setiap hari
  daily,

  /// siang hari Ramadan (puasa, sahur, ...)
  ramadan,

  /// malam Ramadan - malam sebelum puasa hari pertama sampai malam
  /// sebelum puasa terakhir (tarawih)
  ramadanNight,

  /// disarankan pada hari tertentu (puasa Senin-Kamis, Ayyamul Bidh, ...)
  sunnah,

  /// selama masih ada hutang puasa Ramadan (di luar Ramadan & hari yang
  /// diharamkan berpuasa)
  qadha,
}

@DataClassName('IbadahItem')
class IbadahItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Kunci stabil ('subuh', 'tarawih', 'custom_1700000000') - dipakai
  /// berkas cadangan untuk mencocokkan item antar-perangkat, bukan [id].
  TextColumn get key => text().unique()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<IbadahKind>()();
  IntColumn get target => integer().withDefault(const Constant(1))();
  TextColumn get scope => textEnum<IbadahScope>()();

  /// Item sekelompok ditampilkan dalam satu baris (mis. 'sholat_wajib'
  /// untuk lima waktu).
  TextColumn get groupKey => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  /// Bawaan aplikasi (boleh disembunyikan, tidak dihapus).
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();

  /// Hanya pada hari tertentu dalam sepekan (mis. baca Al-Kahfi tiap
  /// Jumat): bit ke-(weekday - 1), Senin = bit 0 ... Minggu = bit 6. Null =
  /// tanpa batasan hari. Berlaku BERSAMA [scope] - lihat [appliesOnWeekday].
  IntColumn get weekdays => integer().nullable()();
}

@DataClassName('IbadahLog')
class IbadahLogs extends Table {
  TextColumn get date => text()();
  IntColumn get itemId =>
      integer().references(IbadahItems, #id, onDelete: KeyAction.cascade)();

  /// check: 1 = sudah; counter: jumlahnya.
  IntColumn get value => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Sholat wajib (bila pencatatan waktu aktif): kapan dikerjakan - status
  /// awal waktu/terlambat/qadha dihitung dari jadwal, tidak disimpan.
  DateTimeColumn get prayedAt => dateTime().nullable()();

  /// Sholat wajib: 'masjid' / 'rumah' / 'lainnya'.
  TextColumn get place => text().nullable()();

  /// Sholat wajib: true = berjama'ah, false = sendiri (munfarid). null =
  /// belum dicatat (catatan dari sebelum fitur ini) - dihitung penuh.
  BoolColumn get jamaah => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {date, itemId};
}

/// Keterangan per hari, mis. sedang berhalangan (uzur) - streak tidak
/// putus dan puasa Ramadan yang terlewat terhitung hutang qadha.
@DataClassName('DayStatus')
class DayStatuses extends Table {
  TextColumn get date => text()();
  BoolColumn get excused => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

/// Rekap Ramadan yang sudah "dikunci" sesudah Idulfitri - dibekukan supaya
/// perubahan jangkar kalender di kemudian hari tidak mengubah hutang qadha
/// yang sudah dicicil. Hutang tahun itu = [days] - [fasted].
///
/// Hutang dari tahun-tahun sebelum memakai aplikasi dicatat sebagai rekap
/// manual: [days] = jumlah hutangnya, [fasted] = 0.
@DataClassName('RamadanRecap')
class RamadanRecaps extends Table {
  IntColumn get hijriYear => integer()();
  IntColumn get days => integer()();
  IntColumn get fasted => integer()();
  IntColumn get excused => integer()();
  BoolColumn get manual => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {hijriYear};
}

/// Satu putaran membaca Al-Qur'an dari awal. "Ulangi dari awal" menutup
/// putaran aktif dan membuka yang baru - riwayatnya tidak dihapus.
@DataClassName('QuranCycle')
class QuranCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();

  /// Diisi saat putaran ditutup (khatam atau diulang dari awal).
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// true = ditutup karena khatam (sampai An-Nas).
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// Batas khatam (kunci tanggal, hari terakhir yang masih termasuk),
  /// null = tanpa target.
  TextColumn get targetDate => text().nullable()();
}

/// Satu sesi baca: ayat global [fromAyah]..[toAyah] (lihat
/// `quran_index.dart`). Posisi terakhir = [toAyah] sesi terbaru.
@DataClassName('QuranLog')
class QuranLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId =>
      integer().references(QuranCycles, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()();
  IntColumn get fromAyah => integer()();
  IntColumn get toAyah => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Catatan pribadi pada rentang ayat (nomor ayat global 1..6236, inklusif).
@DataClassName('QuranNote')
class QuranNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromAyah => integer()();
  IntColumn get toAyah => integer()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Ayat yang sudah dihafal (nomor ayat global 1..6236) - mode hafalan.
@DataClassName('HafalanAyah')
class HafalanAyahs extends Table {
  IntColumn get ayah => integer()();
  DateTimeColumn get memorizedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {ayah};
}

@DriftDatabase(
  tables: [
    IbadahItems,
    IbadahLogs,
    DayStatuses,
    RamadanRecaps,
    QuranCycles,
    QuranLogs,
    QuranNotes,
    HafalanAyahs,
  ],
  daos: [QuranDao, IbadahDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'rindu_ramadan',
              // widget layar utama menulis catatan dari isolate latar
              // (callback home_widget) - satu koneksi bersama supaya tidak
              // saling mengunci & perubahan langsung terlihat di aplikasi
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ),
      );

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: waktu & tempat sholat wajib
        await m.addColumn(ibadahLogs, ibadahLogs.prayedAt);
        await m.addColumn(ibadahLogs, ibadahLogs.place);
      }
      if (from < 3) {
        // v3: "Sholat rawatib" dipecah per waktu (qabliyah/ba'diyah); item
        // lama disembunyikan, catatannya tetap tersimpan
        await customStatement(
          "UPDATE ibadah_items SET active = 0 WHERE key = 'rawatib'",
        );
      }
      if (from < 4) {
        // v4: sholat wajib berjama'ah / sendiri
        await m.addColumn(ibadahLogs, ibadahLogs.jamaah);
      }
      if (from < 5) {
        // v5: catatan pribadi per rentang ayat
        await m.createTable(quranNotes);
      }
      if (from < 6) {
        // v6: ibadah pada hari tertentu saja (dicek dulu: basis data yang
        // diturunkan versinya secara manual mungkin sudah punya kolomnya)
        final cols = await customSelect(
          "SELECT name FROM pragma_table_info('ibadah_items')",
        ).map((r) => r.read<String>('name')).get();
        if (!cols.contains('weekdays')) {
          await m.addColumn(ibadahItems, ibadahItems.weekdays);
        }
      }
      if (from < 7) {
        // v7: mode hafalan
        await m.createTable(hafalanAyahs);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // item bawaan yang belum ada ditambahkan setiap kali dibuka, jadi item
      // bawaan baru di versi berikutnya ikut muncul; yang sudah ada (mungkin
      // sudah disembunyikan/diurutkan pengguna) tidak disentuh
      await batch(
        (b) => b.insertAll(
          ibadahItems,
          defaultIbadahItems,
          mode: InsertMode.insertOrIgnore,
        ),
      );
    },
  );
}

/// Kunci kelompok sholat lima waktu.
const sholatWajibGroup = 'sholat_wajib';

/// Nama hari, indeks 0 = Senin (sama dengan `DateTime.weekday - 1`).
const weekdayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Singkatan [weekdayNames] ("Sen" ... "Min").
const weekdayShortNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Semua hari dalam sepekan sebagai bitmask [IbadahItems.weekdays].
const allWeekdays = 0x7F;

/// Item dengan hari [mask] berlaku pada [weekday] (`DateTime.weekday`).
bool appliesOnWeekday(int? mask, int weekday) =>
    mask == null || mask & allWeekdays == 0 || mask & (1 << (weekday - 1)) != 0;

/// Mask yang disimpan: null bila semua (atau tidak satu pun) hari dipilih.
int? normalizeWeekdays(int? mask) {
  final m = (mask ?? 0) & allWeekdays;
  return m == 0 || m == allWeekdays ? null : m;
}

/// "Jumat", "Senin & Kamis", "Sen, Rab, Jum" - null bila tanpa batasan.
String? weekdaysLabel(int? mask) {
  final m = normalizeWeekdays(mask);
  if (m == null) return null;
  final days = [
    for (var i = 0; i < 7; i++)
      if (m & (1 << i) != 0) i,
  ];
  if (days.length == 1) return weekdayNames[days.single];
  if (days.length == 2) {
    return '${weekdayNames[days[0]]} & ${weekdayNames[days[1]]}';
  }
  return days.map((d) => weekdayShortNames[d]).join(', ');
}

/// Kunci kelompok sholat sunnah rawatib; kuncinya `qabliyah_<sholat>` /
/// `badiyah_<sholat>` (lihat [rawatibOf]).
const rawatibGroup = 'rawatib';

/// (sholat wajib, qabliyah?) untuk kunci item rawatib, null bila bukan.
(String, bool)? rawatibOf(String key) {
  final m = RegExp(r'^(qabliyah|badiyah)_(\w+)$').firstMatch(key);
  return m == null ? null : (m.group(2)!, m.group(1) == 'qabliyah');
}

/// Kunci item puasa qadha - tiap catatannya melunasi satu hari hutang.
const qadhaKey = 'puasa_qadha';

/// Kunci item tilawah - tercentang otomatis bila ada catatan bacaan
/// Al-Qur'an pada hari itu.
const tilawahKey = 'tilawah';

IbadahItemsCompanion _item(
  String key,
  String name,
  int sort, {
  IbadahScope scope = IbadahScope.daily,
  IbadahKind kind = IbadahKind.check,
  int target = 1,
  String? group,
  bool active = true,
  int? weekdays,
}) => IbadahItemsCompanion.insert(
  key: key,
  name: name,
  kind: kind,
  scope: scope,
  target: Value(target),
  groupKey: Value(group),
  sort: Value(sort),
  active: Value(active),
  builtIn: const Value(true),
  weekdays: Value(weekdays),
);

/// Bitmask hari Jumat ([IbadahItems.weekdays]).
const fridayMask = 1 << 4;

/// Kunci item amalan Jumat (baca Al-Kahfi) - ikon kitab membuka surah 18.
const kahfiKey = 'kahfi';

final defaultIbadahItems = [
  _item('subuh', 'Subuh', 0, group: sholatWajibGroup),
  _item('dzuhur', 'Dzuhur', 1, group: sholatWajibGroup),
  _item('ashar', 'Ashar', 2, group: sholatWajibGroup),
  _item('maghrib', 'Maghrib', 3, group: sholatWajibGroup),
  _item('isya', 'Isya', 4, group: sholatWajibGroup),
  _item('puasa', 'Puasa Ramadan', 10, scope: IbadahScope.ramadan),
  _item('sahur', 'Sahur', 11, scope: IbadahScope.ramadan),
  _item('tarawih', 'Tarawih', 12, scope: IbadahScope.ramadanNight),
  _item('puasa_sunnah', 'Puasa sunnah', 20, scope: IbadahScope.sunnah),
  _item(qadhaKey, 'Puasa qadha', 21, scope: IbadahScope.qadha),
  _item(tilawahKey, "Tilawah Al-Qur'an", 30),
  _item('dhuha', 'Sholat Dhuha', 31),
  // rawatib: muakkadah aktif, ghairu muakkadah tersedia tapi disembunyikan
  _item('qabliyah_subuh', 'Qabliyah Subuh', 5, group: rawatibGroup),
  _item('qabliyah_dzuhur', 'Qabliyah Dzuhur', 6, group: rawatibGroup),
  _item('badiyah_dzuhur', "Ba'diyah Dzuhur", 7, group: rawatibGroup),
  _item(
    'qabliyah_ashar',
    'Qabliyah Ashar',
    8,
    group: rawatibGroup,
    active: false,
  ),
  _item(
    'qabliyah_maghrib',
    'Qabliyah Maghrib',
    9,
    group: rawatibGroup,
    active: false,
  ),
  _item('badiyah_maghrib', "Ba'diyah Maghrib", 10, group: rawatibGroup),
  _item(
    'qabliyah_isya',
    'Qabliyah Isya',
    11,
    group: rawatibGroup,
    active: false,
  ),
  _item('badiyah_isya', "Ba'diyah Isya", 12, group: rawatibGroup),
  _item('tahajud', 'Tahajud', 33),
  _item('witir', 'Witir', 34),
  _item('dzikir_pagi', 'Dzikir pagi', 35),
  _item('dzikir_petang', 'Dzikir petang', 36),
  _item('istighfar', 'Istighfar', 37, kind: IbadahKind.counter, target: 100),
  _item('sedekah', 'Sedekah', 38),
  // amalan Jumat - hanya tampil di hari Jumat (bisa diubah di Daftar ibadah)
  _item(kahfiKey, 'Baca Al-Kahfi', 39, weekdays: fridayMask),
  _item(
    'sholawat',
    'Sholawat',
    40,
    kind: IbadahKind.counter,
    target: 100,
    weekdays: fridayMask,
  ),
  _item('mandi_jumat', 'Mandi Jumat', 41, weekdays: fridayMask),
];

/// Data layar satu hari - lihat [IbadahDao.watchDay].
class IbadahDayData {
  const IbadahDayData({
    required this.date,
    required this.items,
    required this.values,
    required this.excused,
    required this.hasTilawah,
    required this.summaries,
    this.qadhaRemaining = 0,
    this.logs = const {},
  });

  final String date;

  /// Catatan lengkap per item (untuk waktu & tempat sholat).
  final Map<int, IbadahLog> logs;

  /// Sisa hutang puasa (rekap terkunci - puasa qadha yang tercatat).
  final int qadhaRemaining;

  /// Item aktif, terurut.
  final List<IbadahItem> items;

  /// itemId -> nilai pada [date].
  final Map<int, int> values;
  final bool excused;

  /// Ada catatan bacaan Al-Qur'an pada [date].
  final bool hasTilawah;

  /// Ringkasan per tanggal (hanya tanggal yang punya catatan).
  final Map<String, IbadahDaySummary> summaries;
}

/// Data mentah satu rentang tanggal untuk laporan - lihat
/// `ibadah_report.dart`.
class IbadahRangeData {
  const IbadahRangeData({
    required this.from,
    required this.to,
    required this.items,
    required this.logs,
    required this.excused,
    required this.tilawah,
    required this.firstDate,
  });

  final String from, to;

  /// Item aktif, terurut.
  final List<IbadahItem> items;

  /// tanggal -> itemId -> catatan.
  final Map<String, Map<int, IbadahLog>> logs;
  final Set<String> excused;
  final Set<String> tilawah;

  /// Tanggal catatan pertama yang pernah ada (semua tabel), null bila kosong.
  final String? firstDate;
}

/// Hutang puasa Ramadan.
class QadhaStatus {
  const QadhaStatus({required this.owed, required this.paid});
  final int owed;
  final int paid;
  int get remaining => (owed - paid).clamp(0, owed);
}

/// Ringkasan satu hari untuk strip tanggal & streak.
class IbadahDaySummary {
  const IbadahDaySummary({this.sholat = 0, this.excused = false});

  /// Jumlah sholat wajib yang tercentang (0..5).
  final int sholat;
  final bool excused;

  /// Hari "terjaga": lima waktu lengkap, atau sedang berhalangan.
  bool get complete => excused || sholat >= 5;
}

@DriftAccessor(
  tables: [IbadahItems, IbadahLogs, DayStatuses, QuranLogs, RamadanRecaps],
)
class IbadahDao extends DatabaseAccessor<AppDatabase> with _$IbadahDaoMixin {
  IbadahDao(super.db);

  /// Item terurut; [includeInactive] untuk layar pengaturan.
  Stream<List<IbadahItem>> watchItems({bool includeInactive = false}) {
    final q = select(ibadahItems)
      ..orderBy([
        (i) => OrderingTerm.asc(i.sort),
        (i) => OrderingTerm.asc(i.id),
      ]);
    if (!includeInactive) q.where((i) => i.active.equals(true));
    return q.watch();
  }

  /// Semua yang dibutuhkan layar satu hari, diperbarui setiap kali item,
  /// catatan, status hari, atau bacaan Al-Qur'an berubah. Ringkasan per
  /// tanggal (strip tanggal & streak) diambil untuk
  /// [summariesFrom]..[summariesTo], biasanya ~setahun terakhir s/d hari ini.
  Stream<IbadahDayData> watchDay(
    String date, {
    required String summariesFrom,
    required String summariesTo,
  }) =>
      customSelect(
        'SELECT 1',
        readsFrom: {
          ibadahItems,
          ibadahLogs,
          dayStatuses,
          quranLogs,
          ramadanRecaps,
        },
      ).watch().asyncMap(
        (_) => loadDay(
          date,
          summariesFrom: summariesFrom,
          summariesTo: summariesTo,
        ),
      );

  Future<IbadahDayData> loadDay(
    String date, {
    required String summariesFrom,
    required String summariesTo,
  }) async {
    final items =
        await (select(ibadahItems)
              ..where((i) => i.active.equals(true))
              ..orderBy([
                (i) => OrderingTerm.asc(i.sort),
                (i) => OrderingTerm.asc(i.id),
              ]))
            .get();
    final logs = await (select(
      ibadahLogs,
    )..where((l) => l.date.equals(date))).get();
    final status = await (select(
      dayStatuses,
    )..where((d) => d.date.equals(date))).getSingleOrNull();
    final tilawah =
        await (selectOnly(quranLogs)
              ..addColumns([quranLogs.id])
              ..where(quranLogs.date.equals(date))
              ..limit(1))
            .get();
    return IbadahDayData(
      date: date,
      items: items,
      values: {for (final l in logs) l.itemId: l.value},
      logs: {for (final l in logs) l.itemId: l},
      excused: status?.excused ?? false,
      hasTilawah: tilawah.isNotEmpty,
      summaries: await summaries(summariesFrom, summariesTo),
      qadhaRemaining: (await qadhaStatus()).remaining,
    );
  }

  /// Hutang puasa: total dari rekap terkunci dan yang sudah dibayar.
  Future<QadhaStatus> qadhaStatus() async {
    final recaps = await select(ramadanRecaps).get();
    final owed = recaps.fold<int>(
      0,
      (a, r) => a + (r.days - r.fasted).clamp(0, r.days),
    );
    final paid = customSelect(
      'SELECT COUNT(*) AS n FROM ibadah_logs l '
      'JOIN ibadah_items i ON i.id = l.item_id '
      'WHERE i.key = ?1 AND l.value > 0',
      variables: [Variable.withString(qadhaKey)],
    );
    return QadhaStatus(owed: owed, paid: (await paid.getSingle()).read('n'));
  }

  Stream<List<RamadanRecap>> watchRecaps() => (select(
    ramadanRecaps,
  )..orderBy([(r) => OrderingTerm.desc(r.hijriYear)])).watch();

  Stream<QadhaStatus> watchQadha() => customSelect(
    'SELECT 1',
    readsFrom: {ramadanRecaps, ibadahLogs, ibadahItems},
  ).watch().asyncMap((_) => qadhaStatus());

  Future<RamadanRecap?> recapOf(int hijriYear) => (select(
    ramadanRecaps,
  )..where((r) => r.hijriYear.equals(hijriYear))).getSingleOrNull();

  Future<void> saveRecap(RamadanRecapsCompanion recap) =>
      into(ramadanRecaps).insertOnConflictUpdate(recap);

  Future<void> deleteRecap(int hijriYear) =>
      (delete(ramadanRecaps)..where((r) => r.hijriYear.equals(hijriYear))).go();

  /// Tanggal-tanggal di [from]..[to] yang item [key]-nya tercatat.
  Future<Set<String>> datesOf(String key, String from, String to) async {
    final rows = await customSelect(
      'SELECT l.date AS date FROM ibadah_logs l '
      'JOIN ibadah_items i ON i.id = l.item_id '
      'WHERE i.key = ?1 AND l.value > 0 AND l.date BETWEEN ?2 AND ?3',
      variables: [
        Variable.withString(key),
        Variable.withString(from),
        Variable.withString(to),
      ],
    ).get();
    return {for (final r in rows) r.read<String>('date')};
  }

  /// Semua catatan di [from]..[to] untuk laporan: item aktif, catatan per
  /// tanggal, tanggal berhalangan, dan tanggal yang ada bacaan Al-Qur'an.
  Future<IbadahRangeData> loadRange(String from, String to) async {
    final items =
        await (select(ibadahItems)
              ..where((i) => i.active.equals(true))
              ..orderBy([
                (i) => OrderingTerm.asc(i.sort),
                (i) => OrderingTerm.asc(i.id),
              ]))
            .get();
    final logs = await (select(
      ibadahLogs,
    )..where((l) => l.date.isBetweenValues(from, to))).get();
    final byDate = <String, Map<int, IbadahLog>>{};
    for (final l in logs) {
      (byDate[l.date] ??= {})[l.itemId] = l;
    }
    final tilawah =
        await (selectOnly(quranLogs, distinct: true)
              ..addColumns([quranLogs.date])
              ..where(quranLogs.date.isBetweenValues(from, to)))
            .map((r) => r.read(quranLogs.date)!)
            .get();
    final first = await customSelect(
      'SELECT MIN(d) AS d FROM (SELECT MIN(date) AS d FROM ibadah_logs '
      'UNION ALL SELECT MIN(date) FROM day_statuses '
      'UNION ALL SELECT MIN(date) FROM quran_logs)',
    ).getSingle();
    return IbadahRangeData(
      from: from,
      to: to,
      items: items,
      logs: byDate,
      excused: await excusedDates(from, to),
      tilawah: tilawah.toSet(),
      firstDate: first.read<String?>('d'),
    );
  }

  /// Tanggal berhalangan di [from]..[to].
  Future<Set<String>> excusedDates(String from, String to) async {
    final rows =
        await (select(dayStatuses)..where(
              (d) => d.excused.equals(true) & d.date.isBetweenValues(from, to),
            ))
            .get();
    return {for (final r in rows) r.date};
  }

  /// Sesi baca Al-Qur'an di [from]..[to] (semua putaran).
  Future<List<QuranLog>> quranLogsBetween(String from, String to) =>
      (select(quranLogs)..where((l) => l.date.isBetweenValues(from, to))).get();

  /// Setel nilai item; 0 = hapus catatannya.
  /// [prayedAt]/[place]/[jamaah] (sholat wajib) hanya ditulis bila
  /// diberikan - tanpa itu, waktu, tempat & jama'ah yang sudah tercatat
  /// dipertahankan.
  Future<void> setValue(
    String date,
    int itemId,
    int value, {
    DateTime? prayedAt,
    String? place,
    bool? jamaah,
  }) async {
    if (value <= 0) {
      await (delete(
        ibadahLogs,
      )..where((l) => l.date.equals(date) & l.itemId.equals(itemId))).go();
      return;
    }
    await into(ibadahLogs).insertOnConflictUpdate(
      IbadahLogsCompanion.insert(
        date: date,
        itemId: itemId,
        value: value,
        updatedAt: DateTime.now(),
        prayedAt: prayedAt == null ? const Value.absent() : Value(prayedAt),
        place: place == null ? const Value.absent() : Value(place),
        jamaah: jamaah == null ? const Value.absent() : Value(jamaah),
      ),
    );
  }

  Future<void> setExcused(String date, bool excused) =>
      into(dayStatuses).insertOnConflictUpdate(
        DayStatusesCompanion.insert(
          date: date,
          excused: Value(excused),
          updatedAt: DateTime.now(),
        ),
      );

  /// Ringkasan per tanggal di rentang [from]..[to] (kunci tanggal,
  /// inklusif); tanggal tanpa catatan tidak ada di peta.
  Future<Map<String, IbadahDaySummary>> summaries(String from, String to) =>
      customSelect(
        'SELECT d.date AS date, '
        '  COALESCE(s.sholat, 0) AS sholat, '
        '  COALESCE(st.excused, 0) AS excused '
        'FROM ('
        '  SELECT date FROM ibadah_logs WHERE date BETWEEN ?1 AND ?2 '
        '  UNION SELECT date FROM day_statuses WHERE date BETWEEN ?1 AND ?2'
        ') d '
        'LEFT JOIN ('
        '  SELECT l.date, COUNT(*) AS sholat FROM ibadah_logs l '
        '  JOIN ibadah_items i ON i.id = l.item_id '
        '  WHERE i.group_key = ?3 AND l.value > 0 GROUP BY l.date'
        ') s ON s.date = d.date '
        'LEFT JOIN day_statuses st ON st.date = d.date',
        variables: [
          Variable.withString(from),
          Variable.withString(to),
          Variable.withString(sholatWajibGroup),
        ],
      ).get().then(
        (rows) => {
          for (final r in rows)
            r.read<String>('date'): IbadahDaySummary(
              sholat: r.read<int>('sholat'),
              excused: r.read<int>('excused') != 0,
            ),
        },
      );

  /// Tambah item buatan pengguna di urutan terakhir.
  Future<int> addCustomItem({
    required String name,
    IbadahKind kind = IbadahKind.check,
    int target = 1,
    int? weekdays,
  }) async {
    final maxSort = ibadahItems.sort.max();
    final last = await (selectOnly(
      ibadahItems,
    )..addColumns([maxSort])).map((r) => r.read(maxSort)).getSingle();
    return into(ibadahItems).insert(
      IbadahItemsCompanion.insert(
        key: 'custom_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        kind: kind,
        scope: IbadahScope.daily,
        target: Value(target),
        sort: Value((last ?? 0) + 1),
        weekdays: Value(normalizeWeekdays(weekdays)),
      ),
    );
  }

  /// Batasi item ke hari tertentu ([weekdays] bitmask; null = setiap hari).
  /// Sholat wajib tidak bisa dibatasi.
  Future<void> setWeekdays(int id, int? weekdays) =>
      (update(ibadahItems)..where(
            (i) => i.id.equals(id) & i.groupKey.isNotValue(sholatWajibGroup),
          ))
          .write(
            IbadahItemsCompanion(weekdays: Value(normalizeWeekdays(weekdays))),
          );

  Future<void> setActive(int id, bool active) =>
      (update(ibadahItems)..where((i) => i.id.equals(id))).write(
        IbadahItemsCompanion(active: Value(active)),
      );

  /// Simpan urutan baru: [ids] dari atas ke bawah.
  Future<void> reorder(List<int> ids) => batch((b) {
    for (var i = 0; i < ids.length; i++) {
      b.update(
        ibadahItems,
        IbadahItemsCompanion(sort: Value(i)),
        where: (t) => t.id.equals(ids[i]),
      );
    }
  });

  /// Hapus item buatan pengguna beserta catatannya. Item bawaan hanya bisa
  /// disembunyikan ([setActive]).
  Future<void> deleteCustomItem(int id) => (delete(
    ibadahItems,
  )..where((i) => i.id.equals(id) & i.builtIn.equals(false))).go();
}

/// Ringkasan putaran bacaan yang sedang berjalan.
class QuranProgress {
  const QuranProgress({
    required this.cycle,
    required this.lastAyah,
    required this.completedCycles,
  });

  final QuranCycle cycle;

  /// Ayat global terakhir yang dibaca, 0 = belum mulai.
  final int lastAyah;

  /// Jumlah putaran yang sudah khatam sebelumnya.
  final int completedCycles;

  /// Putaran ke-berapa ini (khatam ke-n bila selesai).
  int get round => completedCycles + 1;

  double get progress => progressAfter(lastAyah);

  /// Ayat berikutnya yang akan dibaca, null bila sudah sampai An-Nas.
  int? get nextAyah => lastAyah >= totalAyahs ? null : lastAyah + 1;
}

@DriftAccessor(tables: [QuranCycles, QuranLogs, QuranNotes, HafalanAyahs])
class QuranDao extends DatabaseAccessor<AppDatabase> with _$QuranDaoMixin {
  QuranDao(super.db);

  /// Semua catatan ayat, urut mushaf lalu yang terbaru.
  /// Ayat yang sudah dihafal (nomor ayat global).
  Stream<Set<int>> watchHafalan() => select(
    hafalanAyahs,
  ).watch().map((rows) => {for (final r in rows) r.ayah});

  /// Tandai/lepas tanda hafal pada ayat global [from]..[to].
  Future<void> setHafal(int from, int to, bool hafal) => transaction(() async {
    if (!hafal) {
      await (delete(
        hafalanAyahs,
      )..where((h) => h.ayah.isBetweenValues(from, to))).go();
      return;
    }
    final now = DateTime.now();
    await batch(
      (b) => b.insertAll(hafalanAyahs, [
        for (var a = from; a <= to; a++)
          HafalanAyahsCompanion.insert(ayah: Value(a), memorizedAt: now),
      ], mode: InsertMode.insertOrIgnore),
    );
  });

  Stream<List<QuranNote>> watchNotes() =>
      (select(quranNotes)..orderBy([
            (n) => OrderingTerm.asc(n.fromAyah),
            (n) => OrderingTerm.desc(n.updatedAt),
          ]))
          .watch();

  /// Catatan yang menyentuh ayat [from]..[to] (mis. satu surah).
  Stream<List<QuranNote>> watchNotesBetween(int from, int to) =>
      (select(quranNotes)
            ..where(
              (n) =>
                  n.fromAyah.isSmallerOrEqualValue(to) &
                  n.toAyah.isBiggerOrEqualValue(from),
            )
            ..orderBy([(n) => OrderingTerm.asc(n.fromAyah)]))
          .watch();

  /// Simpan catatan baru ([id] null) atau perbarui yang ada.
  Future<int> saveNote({
    int? id,
    required int fromAyah,
    required int toAyah,
    required String body,
  }) async {
    assert(fromAyah >= 1 && toAyah <= totalAyahs && fromAyah <= toAyah);
    final now = DateTime.now();
    if (id == null) {
      return into(quranNotes).insert(
        QuranNotesCompanion.insert(
          fromAyah: fromAyah,
          toAyah: toAyah,
          body: body,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await (update(quranNotes)..where((n) => n.id.equals(id))).write(
      QuranNotesCompanion(
        fromAyah: Value(fromAyah),
        toAyah: Value(toAyah),
        body: Value(body),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  Future<void> deleteNote(int id) =>
      (delete(quranNotes)..where((n) => n.id.equals(id))).go();

  Future<QuranCycle?> _openCycle() =>
      (select(quranCycles)
            ..where((c) => c.finishedAt.isNull())
            ..orderBy([(c) => OrderingTerm.desc(c.id)])
            ..limit(1))
          .getSingleOrNull();

  /// Putaran yang sedang berjalan; dibuat otomatis bila belum ada.
  Future<QuranCycle> activeCycle() => transaction(() async {
    final open = await _openCycle();
    if (open != null) return open;
    final id = await into(
      quranCycles,
    ).insert(QuranCyclesCompanion.insert(startedAt: DateTime.now()));
    return (select(quranCycles)..where((c) => c.id.equals(id))).getSingle();
  });

  Future<QuranProgress> progress() async {
    final cycle = await activeCycle();
    final last =
        await (select(quranLogs)
              ..where((l) => l.cycleId.equals(cycle.id))
              ..orderBy([
                (l) => OrderingTerm.desc(l.createdAt),
                (l) => OrderingTerm.desc(l.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    final completed = await (select(
      quranCycles,
    )..where((c) => c.completed.equals(true))).get();
    return QuranProgress(
      cycle: cycle,
      lastAyah: last?.toAyah ?? 0,
      completedCycles: completed.length,
    );
  }

  /// [progress] yang diperbarui setiap kali putaran/sesi baca berubah.
  Stream<QuranProgress> watchProgress() => customSelect(
    'SELECT 1',
    readsFrom: {quranCycles, quranLogs},
  ).watch().asyncMap((_) => progress());

  /// Catat bacaan sampai (dan termasuk) ayat global [toAyah] pada tanggal
  /// [date] (`YYYY-MM-DD`). Awal sesinya = ayat sesudah posisi terakhir;
  /// bila [toAyah] di belakang posisi itu (membaca ulang), sesi dimulai dari
  /// [toAyah] sendiri. Sampai An-Nas = putaran ditutup sebagai khatam.
  Future<QuranLog> logReading({
    required String date,
    required int toAyah,
    int? fromAyah,
  }) => transaction(() async {
    assert(toAyah >= 1 && toAyah <= totalAyahs, 'ayat $toAyah');
    final current = await progress();
    final from =
        fromAyah ?? (toAyah > current.lastAyah ? current.lastAyah + 1 : toAyah);
    final now = DateTime.now();
    final id = await into(quranLogs).insert(
      QuranLogsCompanion.insert(
        cycleId: current.cycle.id,
        date: date,
        fromAyah: from,
        toAyah: toAyah,
        createdAt: now,
      ),
    );
    if (toAyah == totalAyahs) {
      await _closeCycle(current.cycle.id, completed: true, at: now);
    }
    return (select(quranLogs)..where((l) => l.id.equals(id))).getSingle();
  });

  /// Batalkan satu sesi (mis. salah input). Bila sesi itu yang menamatkan
  /// putaran, putarannya dibuka kembali.
  Future<void> deleteLog(int id) => transaction(() async {
    final log = await (select(
      quranLogs,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
    if (log == null) return;
    await (delete(quranLogs)..where((l) => l.id.equals(id))).go();
    if (log.toAyah == totalAyahs) {
      final cycle = await (select(
        quranCycles,
      )..where((c) => c.id.equals(log.cycleId))).getSingle();
      final open = await _openCycle();
      // hanya bila belum ada putaran baru yang sudah diisi
      if (cycle.completed && (open == null || await _isEmpty(open.id))) {
        if (open != null) {
          await (delete(quranCycles)..where((c) => c.id.equals(open.id))).go();
        }
        await (update(quranCycles)..where((c) => c.id.equals(cycle.id))).write(
          const QuranCyclesCompanion(
            finishedAt: Value(null),
            completed: Value(false),
          ),
        );
      }
    }
  });

  Future<bool> _isEmpty(int cycleId) async =>
      (await (select(quranLogs)
                ..where((l) => l.cycleId.equals(cycleId))
                ..limit(1))
              .get())
          .isEmpty;

  /// Ulangi dari awal: tutup putaran aktif (bukan khatam) dan buka yang
  /// baru. Riwayat sesi putaran lama tetap tersimpan.
  Future<QuranCycle> startNewCycle({String? targetDate}) =>
      transaction(() async {
        final open = await _openCycle();
        if (open != null) {
          if (await _isEmpty(open.id)) {
            // putaran kosong cukup diganti targetnya
            await (update(quranCycles)..where((c) => c.id.equals(open.id)))
                .write(QuranCyclesCompanion(targetDate: Value(targetDate)));
            return (select(
              quranCycles,
            )..where((c) => c.id.equals(open.id))).getSingle();
          }
          await _closeCycle(open.id, completed: false, at: DateTime.now());
        }
        final id = await into(quranCycles).insert(
          QuranCyclesCompanion.insert(
            startedAt: DateTime.now(),
            targetDate: Value(targetDate),
          ),
        );
        return (select(quranCycles)..where((c) => c.id.equals(id))).getSingle();
      });

  /// Atur batas khatam putaran aktif (kunci tanggal), null = tanpa target.
  Future<void> setTargetDate(String? date) async {
    final cycle = await activeCycle();
    await (update(quranCycles)..where((c) => c.id.equals(cycle.id))).write(
      QuranCyclesCompanion(targetDate: Value(date)),
    );
  }

  Future<void> _closeCycle(
    int id, {
    required bool completed,
    required DateTime at,
  }) => (update(quranCycles)..where((c) => c.id.equals(id))).write(
    QuranCyclesCompanion(finishedAt: Value(at), completed: Value(completed)),
  );

  /// Sesi baca pada putaran [cycleId], terbaru dulu.
  Future<List<QuranLog>> logsOf(int cycleId) =>
      (select(quranLogs)
            ..where((l) => l.cycleId.equals(cycleId))
            ..orderBy([
              (l) => OrderingTerm.desc(l.createdAt),
              (l) => OrderingTerm.desc(l.id),
            ]))
          .get();

  /// Semua putaran, terbaru dulu.
  Future<List<QuranCycle>> cycles() =>
      (select(quranCycles)..orderBy([(c) => OrderingTerm.desc(c.id)])).get();
}
