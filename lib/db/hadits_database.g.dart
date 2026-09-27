// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hadits_database.dart';

// ignore_for_file: type=lint
class $HaditsBooksTable extends HaditsBooks
    with TableInfo<$HaditsBooksTable, HaditsBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HaditsBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, name, total, sort, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadits_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<HaditsBook> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    } else if (isInserting) {
      context.missing(_sortMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  HaditsBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HaditsBook(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $HaditsBooksTable createAlias(String alias) {
    return $HaditsBooksTable(attachedDatabase, alias);
  }
}

class HaditsBook extends DataClass implements Insertable<HaditsBook> {
  final String key;
  final String name;
  final int total;
  final int sort;

  /// Selesai diunduh (null = belum / belum lengkap).
  final DateTime? completedAt;
  const HaditsBook({
    required this.key,
    required this.name,
    required this.total,
    required this.sort,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    map['total'] = Variable<int>(total);
    map['sort'] = Variable<int>(sort);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  HaditsBooksCompanion toCompanion(bool nullToAbsent) {
    return HaditsBooksCompanion(
      key: Value(key),
      name: Value(name),
      total: Value(total),
      sort: Value(sort),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory HaditsBook.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HaditsBook(
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      total: serializer.fromJson<int>(json['total']),
      sort: serializer.fromJson<int>(json['sort']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'total': serializer.toJson<int>(total),
      'sort': serializer.toJson<int>(sort),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  HaditsBook copyWith({
    String? key,
    String? name,
    int? total,
    int? sort,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => HaditsBook(
    key: key ?? this.key,
    name: name ?? this.name,
    total: total ?? this.total,
    sort: sort ?? this.sort,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  HaditsBook copyWithCompanion(HaditsBooksCompanion data) {
    return HaditsBook(
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      total: data.total.present ? data.total.value : this.total,
      sort: data.sort.present ? data.sort.value : this.sort,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HaditsBook(')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('total: $total, ')
          ..write('sort: $sort, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, name, total, sort, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HaditsBook &&
          other.key == this.key &&
          other.name == this.name &&
          other.total == this.total &&
          other.sort == this.sort &&
          other.completedAt == this.completedAt);
}

class HaditsBooksCompanion extends UpdateCompanion<HaditsBook> {
  final Value<String> key;
  final Value<String> name;
  final Value<int> total;
  final Value<int> sort;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const HaditsBooksCompanion({
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.total = const Value.absent(),
    this.sort = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HaditsBooksCompanion.insert({
    required String key,
    required String name,
    required int total,
    required int sort,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       name = Value(name),
       total = Value(total),
       sort = Value(sort);
  static Insertable<HaditsBook> custom({
    Expression<String>? key,
    Expression<String>? name,
    Expression<int>? total,
    Expression<int>? sort,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (total != null) 'total': total,
      if (sort != null) 'sort': sort,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HaditsBooksCompanion copyWith({
    Value<String>? key,
    Value<String>? name,
    Value<int>? total,
    Value<int>? sort,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return HaditsBooksCompanion(
      key: key ?? this.key,
      name: name ?? this.name,
      total: total ?? this.total,
      sort: sort ?? this.sort,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HaditsBooksCompanion(')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('total: $total, ')
          ..write('sort: $sort, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HadithsTable extends Hadiths with TableInfo<$HadithsTable, Hadith> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabMeta = const VerificationMeta('arab');
  @override
  late final GeneratedColumn<String> arab = GeneratedColumn<String>(
    'arab',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [book, number, arab, translation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadiths';
  @override
  VerificationContext validateIntegrity(
    Insertable<Hadith> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('arab')) {
      context.handle(
        _arabMeta,
        arab.isAcceptableOrUnknown(data['arab']!, _arabMeta),
      );
    } else if (isInserting) {
      context.missing(_arabMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {book, number};
  @override
  Hadith map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hadith(
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      arab: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arab'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
    );
  }

  @override
  $HadithsTable createAlias(String alias) {
    return $HadithsTable(attachedDatabase, alias);
  }
}

class Hadith extends DataClass implements Insertable<Hadith> {
  final String book;
  final int number;
  final String arab;
  final String translation;
  const Hadith({
    required this.book,
    required this.number,
    required this.arab,
    required this.translation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book'] = Variable<String>(book);
    map['number'] = Variable<int>(number);
    map['arab'] = Variable<String>(arab);
    map['translation'] = Variable<String>(translation);
    return map;
  }

  HadithsCompanion toCompanion(bool nullToAbsent) {
    return HadithsCompanion(
      book: Value(book),
      number: Value(number),
      arab: Value(arab),
      translation: Value(translation),
    );
  }

  factory Hadith.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Hadith(
      book: serializer.fromJson<String>(json['book']),
      number: serializer.fromJson<int>(json['number']),
      arab: serializer.fromJson<String>(json['arab']),
      translation: serializer.fromJson<String>(json['translation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'book': serializer.toJson<String>(book),
      'number': serializer.toJson<int>(number),
      'arab': serializer.toJson<String>(arab),
      'translation': serializer.toJson<String>(translation),
    };
  }

  Hadith copyWith({
    String? book,
    int? number,
    String? arab,
    String? translation,
  }) => Hadith(
    book: book ?? this.book,
    number: number ?? this.number,
    arab: arab ?? this.arab,
    translation: translation ?? this.translation,
  );
  Hadith copyWithCompanion(HadithsCompanion data) {
    return Hadith(
      book: data.book.present ? data.book.value : this.book,
      number: data.number.present ? data.number.value : this.number,
      arab: data.arab.present ? data.arab.value : this.arab,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Hadith(')
          ..write('book: $book, ')
          ..write('number: $number, ')
          ..write('arab: $arab, ')
          ..write('translation: $translation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(book, number, arab, translation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Hadith &&
          other.book == this.book &&
          other.number == this.number &&
          other.arab == this.arab &&
          other.translation == this.translation);
}

class HadithsCompanion extends UpdateCompanion<Hadith> {
  final Value<String> book;
  final Value<int> number;
  final Value<String> arab;
  final Value<String> translation;
  final Value<int> rowid;
  const HadithsCompanion({
    this.book = const Value.absent(),
    this.number = const Value.absent(),
    this.arab = const Value.absent(),
    this.translation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HadithsCompanion.insert({
    required String book,
    required int number,
    required String arab,
    required String translation,
    this.rowid = const Value.absent(),
  }) : book = Value(book),
       number = Value(number),
       arab = Value(arab),
       translation = Value(translation);
  static Insertable<Hadith> custom({
    Expression<String>? book,
    Expression<int>? number,
    Expression<String>? arab,
    Expression<String>? translation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (book != null) 'book': book,
      if (number != null) 'number': number,
      if (arab != null) 'arab': arab,
      if (translation != null) 'translation': translation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HadithsCompanion copyWith({
    Value<String>? book,
    Value<int>? number,
    Value<String>? arab,
    Value<String>? translation,
    Value<int>? rowid,
  }) {
    return HadithsCompanion(
      book: book ?? this.book,
      number: number ?? this.number,
      arab: arab ?? this.arab,
      translation: translation ?? this.translation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (arab.present) {
      map['arab'] = Variable<String>(arab.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HadithsCompanion(')
          ..write('book: $book, ')
          ..write('number: $number, ')
          ..write('arab: $arab, ')
          ..write('translation: $translation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HaditsDatabase extends GeneratedDatabase {
  _$HaditsDatabase(QueryExecutor e) : super(e);
  $HaditsDatabaseManager get managers => $HaditsDatabaseManager(this);
  late final $HaditsBooksTable haditsBooks = $HaditsBooksTable(this);
  late final $HadithsTable hadiths = $HadithsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [haditsBooks, hadiths];
}

typedef $$HaditsBooksTableCreateCompanionBuilder =
    HaditsBooksCompanion Function({
      required String key,
      required String name,
      required int total,
      required int sort,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$HaditsBooksTableUpdateCompanionBuilder =
    HaditsBooksCompanion Function({
      Value<String> key,
      Value<String> name,
      Value<int> total,
      Value<int> sort,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$HaditsBooksTableFilterComposer
    extends Composer<_$HaditsDatabase, $HaditsBooksTable> {
  $$HaditsBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HaditsBooksTableOrderingComposer
    extends Composer<_$HaditsDatabase, $HaditsBooksTable> {
  $$HaditsBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HaditsBooksTableAnnotationComposer
    extends Composer<_$HaditsDatabase, $HaditsBooksTable> {
  $$HaditsBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$HaditsBooksTableTableManager
    extends
        RootTableManager<
          _$HaditsDatabase,
          $HaditsBooksTable,
          HaditsBook,
          $$HaditsBooksTableFilterComposer,
          $$HaditsBooksTableOrderingComposer,
          $$HaditsBooksTableAnnotationComposer,
          $$HaditsBooksTableCreateCompanionBuilder,
          $$HaditsBooksTableUpdateCompanionBuilder,
          (
            HaditsBook,
            BaseReferences<_$HaditsDatabase, $HaditsBooksTable, HaditsBook>,
          ),
          HaditsBook,
          PrefetchHooks Function()
        > {
  $$HaditsBooksTableTableManager(_$HaditsDatabase db, $HaditsBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HaditsBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HaditsBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HaditsBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HaditsBooksCompanion(
                key: key,
                name: name,
                total: total,
                sort: sort,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String name,
                required int total,
                required int sort,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HaditsBooksCompanion.insert(
                key: key,
                name: name,
                total: total,
                sort: sort,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HaditsBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$HaditsDatabase,
      $HaditsBooksTable,
      HaditsBook,
      $$HaditsBooksTableFilterComposer,
      $$HaditsBooksTableOrderingComposer,
      $$HaditsBooksTableAnnotationComposer,
      $$HaditsBooksTableCreateCompanionBuilder,
      $$HaditsBooksTableUpdateCompanionBuilder,
      (
        HaditsBook,
        BaseReferences<_$HaditsDatabase, $HaditsBooksTable, HaditsBook>,
      ),
      HaditsBook,
      PrefetchHooks Function()
    >;
typedef $$HadithsTableCreateCompanionBuilder =
    HadithsCompanion Function({
      required String book,
      required int number,
      required String arab,
      required String translation,
      Value<int> rowid,
    });
typedef $$HadithsTableUpdateCompanionBuilder =
    HadithsCompanion Function({
      Value<String> book,
      Value<int> number,
      Value<String> arab,
      Value<String> translation,
      Value<int> rowid,
    });

class $$HadithsTableFilterComposer
    extends Composer<_$HaditsDatabase, $HadithsTable> {
  $$HadithsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arab => $composableBuilder(
    column: $table.arab,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HadithsTableOrderingComposer
    extends Composer<_$HaditsDatabase, $HadithsTable> {
  $$HadithsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arab => $composableBuilder(
    column: $table.arab,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HadithsTableAnnotationComposer
    extends Composer<_$HaditsDatabase, $HadithsTable> {
  $$HadithsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get arab =>
      $composableBuilder(column: $table.arab, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );
}

class $$HadithsTableTableManager
    extends
        RootTableManager<
          _$HaditsDatabase,
          $HadithsTable,
          Hadith,
          $$HadithsTableFilterComposer,
          $$HadithsTableOrderingComposer,
          $$HadithsTableAnnotationComposer,
          $$HadithsTableCreateCompanionBuilder,
          $$HadithsTableUpdateCompanionBuilder,
          (Hadith, BaseReferences<_$HaditsDatabase, $HadithsTable, Hadith>),
          Hadith,
          PrefetchHooks Function()
        > {
  $$HadithsTableTableManager(_$HaditsDatabase db, $HadithsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HadithsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HadithsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HadithsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> book = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> arab = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HadithsCompanion(
                book: book,
                number: number,
                arab: arab,
                translation: translation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String book,
                required int number,
                required String arab,
                required String translation,
                Value<int> rowid = const Value.absent(),
              }) => HadithsCompanion.insert(
                book: book,
                number: number,
                arab: arab,
                translation: translation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HadithsTableProcessedTableManager =
    ProcessedTableManager<
      _$HaditsDatabase,
      $HadithsTable,
      Hadith,
      $$HadithsTableFilterComposer,
      $$HadithsTableOrderingComposer,
      $$HadithsTableAnnotationComposer,
      $$HadithsTableCreateCompanionBuilder,
      $$HadithsTableUpdateCompanionBuilder,
      (Hadith, BaseReferences<_$HaditsDatabase, $HadithsTable, Hadith>),
      Hadith,
      PrefetchHooks Function()
    >;

class $HaditsDatabaseManager {
  final _$HaditsDatabase _db;
  $HaditsDatabaseManager(this._db);
  $$HaditsBooksTableTableManager get haditsBooks =>
      $$HaditsBooksTableTableManager(_db, _db.haditsBooks);
  $$HadithsTableTableManager get hadiths =>
      $$HadithsTableTableManager(_db, _db.hadiths);
}
