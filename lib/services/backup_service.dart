import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Versi format berkas cadangan. Naikkan bila bentuknya berubah dan
/// tambahkan pembacaan versi lama di [BackupService.import] - berkas lama
/// harus tetap bisa dipulihkan.
const backupFormatVersion = 1;
const _appId = 'rindu_ramadan';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum ImportMode {
  /// hapus semua data di perangkat, ganti dengan isi berkas
  replace,

  /// gabungkan: catatan yang sama diambil yang paling baru diperbarui
  merge,
}

class ImportResult {
  const ImportResult({
    required this.ibadahLogs,
    required this.quranLogs,
    required this.days,
  });

  /// Jumlah catatan ibadah & sesi baca yang ditambahkan/diperbarui.
  final int ibadahLogs;
  final int quranLogs;

  /// Jumlah hari berbeda yang punya catatan ibadah di berkas.
  final int days;
}

/// Ringkasan isi berkas cadangan, untuk ditampilkan sebelum memulihkan.
class BackupInfo {
  const BackupInfo({
    required this.exportedAt,
    required this.ibadahLogs,
    required this.quranLogs,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime? exportedAt;
  final int ibadahLogs;
  final int quranLogs;
  final String? firstDate;
  final String? lastDate;
}

/// Cadangan seluruh data tracker sebagai satu berkas JSON.
///
/// Item ibadah dirujuk lewat `key`-nya (bukan id) dan putaran khatam lewat
/// `ref` di dalam berkas, jadi berkas bisa dipulihkan ke perangkat lain yang
/// id-nya berbeda. Pengaturan kalender hijriah ikut disimpan di `settings`
/// (diisi & dibaca pemanggil).
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  /// Jumlah catatan ibadah & sesi baca di perangkat ini.
  Future<(int, int)> counts() async => (
    await db.ibadahLogs.count().getSingle(),
    await db.quranLogs.count().getSingle(),
  );

  Future<Map<String, Object?>> export({
    Map<String, Object?> settings = const {},
  }) async {
    final items = await db.select(db.ibadahItems).get();
    final keyOf = {for (final i in items) i.id: i.key};
    final logs = await db.select(db.ibadahLogs).get();
    final statuses = await db.select(db.dayStatuses).get();
    final recaps = await db.select(db.ramadanRecaps).get();
    final cycles = await db.select(db.quranCycles).get();
    final qlogs = await db.select(db.quranLogs).get();

    return {
      'app': _appId,
      'version': backupFormatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': settings,
      'ibadahItems': [
        for (final i in items)
          {
            'key': i.key,
            'name': i.name,
            'kind': i.kind.name,
            'target': i.target,
            'scope': i.scope.name,
            'groupKey': i.groupKey,
            'active': i.active,
            'sort': i.sort,
            'builtIn': i.builtIn,
          },
      ],
      'ibadahLogs': [
        for (final l in logs)
          {
            'date': l.date,
            'item': keyOf[l.itemId],
            'value': l.value,
            'note': l.note,
            'updatedAt': _iso(l.updatedAt),
            if (l.prayedAt != null) 'prayedAt': _iso(l.prayedAt!),
            if (l.place != null) 'place': l.place,
          },
      ],
      'dayStatuses': [
        for (final s in statuses)
          {
            'date': s.date,
            'excused': s.excused,
            'note': s.note,
            'updatedAt': _iso(s.updatedAt),
          },
      ],
      'ramadanRecaps': [
        for (final r in recaps)
          {
            'hijriYear': r.hijriYear,
            'days': r.days,
            'fasted': r.fasted,
            'excused': r.excused,
            'manual': r.manual,
            'lockedAt': _iso(r.lockedAt),
          },
      ],
      'quranCycles': [
        for (final c in cycles)
          {
            'ref': c.id,
            'startedAt': _iso(c.startedAt),
            'finishedAt': c.finishedAt == null ? null : _iso(c.finishedAt!),
            'completed': c.completed,
            'targetDate': c.targetDate,
          },
      ],
      'quranLogs': [
        for (final l in qlogs)
          {
            'cycle': l.cycleId,
            'date': l.date,
            'fromAyah': l.fromAyah,
            'toAyah': l.toAyah,
            'createdAt': _iso(l.createdAt),
          },
      ],
    };
  }

  String exportText(Map<String, Object?> data) =>
      const JsonEncoder.withIndent(' ').convert(data);

  /// Baca & periksa berkas; melempar [BackupException] bila bukan berkas
  /// cadangan aplikasi ini atau versinya lebih baru.
  static Map<String, dynamic> decode(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      throw const BackupException('Berkas bukan cadangan yang valid (JSON).');
    }
    if (raw is! Map<String, dynamic> || raw['app'] != _appId) {
      throw const BackupException('Berkas ini bukan cadangan Rindu Ramadan.');
    }
    final version = raw['version'];
    if (version is! int || version < 1) {
      throw const BackupException('Versi berkas cadangan tidak dikenal.');
    }
    if (version > backupFormatVersion) {
      throw const BackupException(
        'Berkas dibuat oleh versi aplikasi yang lebih baru - perbarui '
        'aplikasi dulu.',
      );
    }
    return raw;
  }

  static BackupInfo info(Map<String, dynamic> data) {
    final logs = _list(data, 'ibadahLogs');
    final qlogs = _list(data, 'quranLogs');
    final dates = <String>[
      for (final l in logs) l['date'] as String,
      for (final l in qlogs) l['date'] as String,
    ]..sort();
    return BackupInfo(
      exportedAt: DateTime.tryParse(data['exportedAt']?.toString() ?? ''),
      ibadahLogs: logs.length,
      quranLogs: qlogs.length,
      firstDate: dates.isEmpty ? null : dates.first,
      lastDate: dates.isEmpty ? null : dates.last,
    );
  }

  /// Pulihkan [data] (hasil [decode]). Semuanya dalam satu transaksi: bila
  /// berkasnya rusak di tengah jalan, data di perangkat tidak berubah.
  Future<ImportResult> import(
    Map<String, dynamic> data, {
    required ImportMode mode,
  }) => db.transaction(() => _import(data, mode));

  Future<ImportResult> _import(
    Map<String, dynamic> data,
    ImportMode mode,
  ) async {
    final replace = mode == ImportMode.replace;
    try {
      if (replace) {
        await db.delete(db.quranLogs).go();
        await db.delete(db.quranCycles).go();
        await db.delete(db.ibadahLogs).go();
        await db.delete(db.dayStatuses).go();
        await db.delete(db.ramadanRecaps).go();
        await db.delete(db.ibadahItems).go();
      }

      // --- item ibadah: dicocokkan lewat key ---
      for (final i in _list(data, 'ibadahItems')) {
        final companion = IbadahItemsCompanion.insert(
          key: i['key'] as String,
          name: i['name'] as String,
          kind: IbadahKind.values.byName(i['kind'] as String),
          scope: IbadahScope.values.byName(i['scope'] as String),
          target: Value(i['target'] as int),
          groupKey: Value(i['groupKey'] as String?),
          active: Value(i['active'] as bool),
          sort: Value(i['sort'] as int),
          builtIn: Value(i['builtIn'] as bool),
        );
        // gabung: pengaturan item di perangkat ini yang dipakai
        await db
            .into(db.ibadahItems)
            .insert(
              companion,
              mode: replace ? InsertMode.insert : InsertMode.insertOrIgnore,
            );
      }
      // item bawaan yang tidak ada di berkas (versi lama) tetap tersedia
      await db.batch(
        (b) => b.insertAll(
          db.ibadahItems,
          defaultIbadahItems,
          mode: InsertMode.insertOrIgnore,
        ),
      );
      final items = await db.select(db.ibadahItems).get();
      final idOf = {for (final i in items) i.key: i.id};

      // --- catatan ibadah: yang lebih baru menang ---
      var ibadahCount = 0;
      final days = <String>{};
      for (final l in _list(data, 'ibadahLogs')) {
        final itemId = idOf[l['item']];
        if (itemId == null) continue; // item tidak dikenal
        final date = l['date'] as String;
        final updatedAt = _date(l['updatedAt']);
        days.add(date);
        if (!replace) {
          final local =
              await (db.select(db.ibadahLogs)..where(
                    (x) => x.date.equals(date) & x.itemId.equals(itemId),
                  ))
                  .getSingleOrNull();
          if (local != null && !local.updatedAt.isBefore(updatedAt)) continue;
        }
        await db
            .into(db.ibadahLogs)
            .insertOnConflictUpdate(
              IbadahLogsCompanion.insert(
                date: date,
                itemId: itemId,
                value: l['value'] as int,
                note: Value(l['note'] as String?),
                updatedAt: updatedAt,
                // opsional: berkas dari versi sebelum pencatatan jam sholat
                prayedAt: Value(
                  l['prayedAt'] == null ? null : _date(l['prayedAt']),
                ),
                place: Value(l['place'] as String?),
              ),
            );
        ibadahCount++;
      }

      for (final s in _list(data, 'dayStatuses')) {
        final date = s['date'] as String;
        final updatedAt = _date(s['updatedAt']);
        if (!replace) {
          final local = await (db.select(
            db.dayStatuses,
          )..where((x) => x.date.equals(date))).getSingleOrNull();
          if (local != null && !local.updatedAt.isBefore(updatedAt)) continue;
        }
        await db
            .into(db.dayStatuses)
            .insertOnConflictUpdate(
              DayStatusesCompanion.insert(
                date: date,
                excused: Value(s['excused'] as bool),
                note: Value(s['note'] as String?),
                updatedAt: updatedAt,
              ),
            );
      }

      for (final r in _list(data, 'ramadanRecaps')) {
        final year = r['hijriYear'] as int;
        final lockedAt = _date(r['lockedAt']);
        if (!replace) {
          final local = await (db.select(
            db.ramadanRecaps,
          )..where((x) => x.hijriYear.equals(year))).getSingleOrNull();
          if (local != null && !local.lockedAt.isBefore(lockedAt)) continue;
        }
        await db
            .into(db.ramadanRecaps)
            .insertOnConflictUpdate(
              RamadanRecapsCompanion.insert(
                hijriYear: Value(year),
                days: r['days'] as int,
                fasted: r['fasted'] as int,
                excused: r['excused'] as int,
                manual: Value(r['manual'] as bool? ?? false),
                lockedAt: lockedAt,
              ),
            );
      }

      final quranCount = await _importQuran(data, replace: replace);

      return ImportResult(
        ibadahLogs: ibadahCount,
        quranLogs: quranCount,
        days: days.length,
      );
    } on BackupException {
      rethrow;
    } catch (e) {
      // tipe/bentuk tak terduga: batalkan seluruh transaksi
      throw BackupException('Isi berkas cadangan rusak ($e).');
    }
  }

  /// Putaran khatam dicocokkan lewat waktu mulainya; sesi baca lewat
  /// (putaran, waktu dicatat, ayat akhir). Sesudah digabung, hanya putaran
  /// terbaru yang dibiarkan terbuka.
  Future<int> _importQuran(
    Map<String, dynamic> data, {
    required bool replace,
  }) async {
    final cycleIdOf = <Object?, int>{};
    for (final c in _list(data, 'quranCycles')) {
      final startedAt = _date(c['startedAt']);
      final existing = replace
          ? null
          : await (db.select(
              db.quranCycles,
            )..where((x) => x.startedAt.equals(startedAt))).getSingleOrNull();
      if (existing != null) {
        cycleIdOf[c['ref']] = existing.id;
        continue;
      }
      final finishedAt = c['finishedAt'];
      cycleIdOf[c['ref']] = await db
          .into(db.quranCycles)
          .insert(
            QuranCyclesCompanion.insert(
              startedAt: startedAt,
              finishedAt: Value(finishedAt == null ? null : _date(finishedAt)),
              completed: Value(c['completed'] as bool),
              targetDate: Value(c['targetDate'] as String?),
            ),
          );
    }

    var count = 0;
    for (final l in _list(data, 'quranLogs')) {
      final cycleId = cycleIdOf[l['cycle']];
      if (cycleId == null) continue;
      final createdAt = _date(l['createdAt']);
      final toAyah = l['toAyah'] as int;
      if (!replace) {
        final dup =
            await (db.select(db.quranLogs)..where(
                  (x) =>
                      x.cycleId.equals(cycleId) &
                      x.createdAt.equals(createdAt) &
                      x.toAyah.equals(toAyah),
                ))
                .get();
        if (dup.isNotEmpty) continue;
      }
      await db
          .into(db.quranLogs)
          .insert(
            QuranLogsCompanion.insert(
              cycleId: cycleId,
              date: l['date'] as String,
              fromAyah: l['fromAyah'] as int,
              toAyah: toAyah,
              createdAt: createdAt,
            ),
          );
      count++;
    }

    // hanya satu putaran yang boleh terbuka: yang dimulai paling akhir
    final open =
        await (db.select(db.quranCycles)
              ..where((c) => c.finishedAt.isNull())
              ..orderBy([(c) => OrderingTerm.desc(c.startedAt)]))
            .get();
    for (final c in open.skip(1)) {
      await (db.update(db.quranCycles)..where((x) => x.id.equals(c.id))).write(
        QuranCyclesCompanion(finishedAt: Value(open.first.startedAt)),
      );
    }
    return count;
  }
}

String _iso(DateTime d) => d.toUtc().toIso8601String();

DateTime _date(Object? v) {
  final d = DateTime.tryParse(v?.toString() ?? '');
  if (d == null) throw BackupException('Tanggal "$v" tidak valid.');
  return d.toLocal();
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v == null) return const [];
  if (v is! List) throw BackupException('Bagian "$key" rusak.');
  return v.cast<Map<String, dynamic>>();
}
