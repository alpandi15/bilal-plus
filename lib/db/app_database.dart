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

  /// hanya selama Ramadan (tarawih, sahur, ...)
  ramadan,

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
  daos: [QuranDao],
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
    },
  );
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
