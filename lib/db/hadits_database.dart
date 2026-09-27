import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'hadits_database.g.dart';

/// Kitab hadits: jumlah hadits & yang sudah tersimpan di HP.
@DataClassName('HaditsBook')
class HaditsBooks extends Table {
  TextColumn get key => text()();
  TextColumn get name => text()();
  IntColumn get total => integer()();
  IntColumn get sort => integer()();

  /// Selesai diunduh (null = belum / belum lengkap).
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('Hadith')
class Hadiths extends Table {
  TextColumn get book => text()();
  IntColumn get number => integer()();
  TextColumn get arab => text()();
  TextColumn get translation => text()();

  @override
  Set<Column> get primaryKey => {book, number};
}

/// Sembilan kitab di web Bilal Tarawih (sumber teks & terjemahan).
const haditsCatalog = <(String, String, int)>[
  ('bukhari', 'Shahih Bukhari', 6638),
  ('muslim', 'Shahih Muslim', 4930),
  ('abu-daud', 'Sunan Abu Daud', 4419),
  ('tirmidzi', 'Sunan Tirmidzi', 3625),
  ('nasai', "Sunan Nasa'i", 5364),
  ('ibnu-majah', 'Sunan Ibnu Majah', 4285),
  ('ahmad', 'Musnad Ahmad', 4305),
  ('malik', "Muwaththa' Malik", 1587),
  ('darimi', 'Sunan Darimi', 2949),
];

/// Teks hadits yang diunduh per kitab - basis data TERPISAH dari catatan
/// ibadah (besar & bisa diunduh ulang kapan saja, jadi tidak ikut cadangan).
@DriftDatabase(tables: [HaditsBooks, Hadiths])
class HaditsDatabase extends _$HaditsDatabase {
  HaditsDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'hadits'));

  static HaditsDatabase? _instance;

  /// Satu koneksi bersama, dibuka saat halaman hadits pertama dipakai.
  static HaditsDatabase get instance => _instance ??= HaditsDatabase();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await batch(
        (b) => b.insertAll(haditsBooks, [
          for (final (i, (key, name, total)) in haditsCatalog.indexed)
            HaditsBooksCompanion.insert(
              key: key,
              name: name,
              total: total,
              sort: i,
            ),
        ], mode: InsertMode.insertOrIgnore),
      );
    },
  );

  /// Kitab beserta jumlah hadits yang sudah tersimpan.
  Stream<List<(HaditsBook, int)>> watchBooks() {
    final count = hadiths.number.count();
    final q =
        select(haditsBooks).join([
            leftOuterJoin(hadiths, hadiths.book.equalsExp(haditsBooks.key)),
          ])
          ..addColumns([count])
          ..groupBy([haditsBooks.key])
          ..orderBy([OrderingTerm.asc(haditsBooks.sort)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows) (r.readTable(haditsBooks), r.read(count) ?? 0),
      ],
    );
  }

  Future<int> storedCount(String book) async {
    final count = hadiths.number.count();
    final row =
        await (selectOnly(hadiths)
              ..addColumns([count])
              ..where(hadiths.book.equals(book)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Expression<bool> _match(Hadiths h, String book, String query) {
    Expression<bool> e = h.book.equals(book);
    final q = query.trim();
    if (q.isEmpty) return e;
    final n = int.tryParse(q);
    if (n != null) return e & h.number.equals(n);
    for (final w in q.split(RegExp(r'\s+'))) {
      e = e & h.translation.like('%$w%');
    }
    return e;
  }

  /// Jumlah hadits di [book] yang cocok dengan [query] (kata di terjemahan,
  /// atau nomor hadits).
  Future<int> countMatching(String book, String query) async {
    final count = hadiths.number.count();
    final row =
        await (selectOnly(hadiths)
              ..addColumns([count])
              ..where(_match(hadiths, book, query)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<Hadith>> page(
    String book,
    String query, {
    required int offset,
    required int limit,
  }) =>
      (select(hadiths)
            ..where((h) => _match(h, book, query))
            ..orderBy([(h) => OrderingTerm.asc(h.number)])
            ..limit(limit, offset: offset))
          .get();

  Future<void> insertPage(String book, List<Hadith> rows) => batch(
    (b) => b.insertAll(hadiths, rows, mode: InsertMode.insertOrReplace),
  );

  Future<void> markComplete(String book, bool complete) =>
      (update(haditsBooks)..where((b) => b.key.equals(book))).write(
        HaditsBooksCompanion(
          completedAt: Value(complete ? DateTime.now() : null),
        ),
      );

  /// Hapus teks satu kitab (bisa diunduh lagi).
  Future<void> deleteBook(String book) => transaction(() async {
    await (delete(hadiths)..where((h) => h.book.equals(book))).go();
    await markComplete(book, false);
  });
}
