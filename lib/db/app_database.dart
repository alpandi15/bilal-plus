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
/// yang sudah dicicil.
@DataClassName('RamadanRecap')
class RamadanRecaps extends Table {
  IntColumn get hijriYear => integer()();
  IntColumn get days => integer()();
  IntColumn get fasted => integer()();
  IntColumn get excused => integer()();
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

@DriftDatabase(
  tables: [
    IbadahItems,
    IbadahLogs,
    DayStatuses,
    RamadanRecaps,
    QuranCycles,
    QuranLogs,
  ],
  daos: [QuranDao, IbadahDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'rindu_ramadan'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
}) => IbadahItemsCompanion.insert(
  key: key,
  name: name,
  kind: kind,
  scope: scope,
  target: Value(target),
  groupKey: Value(group),
  sort: Value(sort),
  builtIn: const Value(true),
);

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
  _item(tilawahKey, "Tilawah Al-Qur'an", 30),
  _item('dhuha', 'Sholat Dhuha', 31),
  _item('rawatib', 'Sholat rawatib', 32),
  _item('tahajud', 'Tahajud', 33),
  _item('witir', 'Witir', 34),
  _item('dzikir_pagi', 'Dzikir pagi', 35),
  _item('dzikir_petang', 'Dzikir petang', 36),
  _item('istighfar', 'Istighfar', 37, kind: IbadahKind.counter, target: 100),
  _item('sedekah', 'Sedekah', 38),
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
  });

  final String date;

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

/// Ringkasan satu hari untuk strip tanggal & streak.
class IbadahDaySummary {
  const IbadahDaySummary({this.sholat = 0, this.excused = false});

  /// Jumlah sholat wajib yang tercentang (0..5).
  final int sholat;
  final bool excused;

  /// Hari "terjaga": lima waktu lengkap, atau sedang berhalangan.
  bool get complete => excused || sholat >= 5;
}

@DriftAccessor(tables: [IbadahItems, IbadahLogs, DayStatuses, QuranLogs])
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
        readsFrom: {ibadahItems, ibadahLogs, dayStatuses, quranLogs},
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
      excused: status?.excused ?? false,
      hasTilawah: tilawah.isNotEmpty,
      summaries: await summaries(summariesFrom, summariesTo),
    );
  }

  /// Setel nilai item; 0 = hapus catatannya.
  Future<void> setValue(String date, int itemId, int value) async {
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
      ),
    );
  }

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

@DriftAccessor(tables: [QuranCycles, QuranLogs])
class QuranDao extends DatabaseAccessor<AppDatabase> with _$QuranDaoMixin {
  QuranDao(super.db);

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
