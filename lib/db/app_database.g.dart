// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $IbadahItemsTable extends IbadahItems
    with TableInfo<$IbadahItemsTable, IbadahItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IbadahItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  @override
  late final GeneratedColumnWithTypeConverter<IbadahKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<IbadahKind>($IbadahItemsTable.$converterkind);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<IbadahScope, String> scope =
      GeneratedColumn<String>(
        'scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<IbadahScope>($IbadahItemsTable.$converterscope);
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<int> weekdays = GeneratedColumn<int>(
    'weekdays',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    name,
    kind,
    target,
    scope,
    groupKey,
    active,
    sort,
    builtIn,
    weekdays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ibadah_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<IbadahItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IbadahItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IbadahItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $IbadahItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      )!,
      scope: $IbadahItemsTable.$converterscope.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scope'],
        )!,
      ),
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekdays'],
      ),
    );
  }

  @override
  $IbadahItemsTable createAlias(String alias) {
    return $IbadahItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IbadahKind, String, String> $converterkind =
      const EnumNameConverter<IbadahKind>(IbadahKind.values);
  static JsonTypeConverter2<IbadahScope, String, String> $converterscope =
      const EnumNameConverter<IbadahScope>(IbadahScope.values);
}

class IbadahItem extends DataClass implements Insertable<IbadahItem> {
  final int id;

  /// Kunci stabil ('subuh', 'tarawih', 'custom_1700000000') - dipakai
  /// berkas cadangan untuk mencocokkan item antar-perangkat, bukan [id].
  final String key;
  final String name;
  final IbadahKind kind;
  final int target;
  final IbadahScope scope;

  /// Item sekelompok ditampilkan dalam satu baris (mis. 'sholat_wajib'
  /// untuk lima waktu).
  final String? groupKey;
  final bool active;
  final int sort;

  /// Bawaan aplikasi (boleh disembunyikan, tidak dihapus).
  final bool builtIn;

  /// Hanya pada hari tertentu dalam sepekan (mis. baca Al-Kahfi tiap
  /// Jumat): bit ke-(weekday - 1), Senin = bit 0 ... Ahad = bit 6. Null =
  /// tanpa batasan hari. Berlaku BERSAMA [scope] - lihat [appliesOnWeekday].
  final int? weekdays;
  const IbadahItem({
    required this.id,
    required this.key,
    required this.name,
    required this.kind,
    required this.target,
    required this.scope,
    this.groupKey,
    required this.active,
    required this.sort,
    required this.builtIn,
    this.weekdays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $IbadahItemsTable.$converterkind.toSql(kind),
      );
    }
    map['target'] = Variable<int>(target);
    {
      map['scope'] = Variable<String>(
        $IbadahItemsTable.$converterscope.toSql(scope),
      );
    }
    if (!nullToAbsent || groupKey != null) {
      map['group_key'] = Variable<String>(groupKey);
    }
    map['active'] = Variable<bool>(active);
    map['sort'] = Variable<int>(sort);
    map['built_in'] = Variable<bool>(builtIn);
    if (!nullToAbsent || weekdays != null) {
      map['weekdays'] = Variable<int>(weekdays);
    }
    return map;
  }

  IbadahItemsCompanion toCompanion(bool nullToAbsent) {
    return IbadahItemsCompanion(
      id: Value(id),
      key: Value(key),
      name: Value(name),
      kind: Value(kind),
      target: Value(target),
      scope: Value(scope),
      groupKey: groupKey == null && nullToAbsent
          ? const Value.absent()
          : Value(groupKey),
      active: Value(active),
      sort: Value(sort),
      builtIn: Value(builtIn),
      weekdays: weekdays == null && nullToAbsent
          ? const Value.absent()
          : Value(weekdays),
    );
  }

  factory IbadahItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IbadahItem(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      kind: $IbadahItemsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      target: serializer.fromJson<int>(json['target']),
      scope: $IbadahItemsTable.$converterscope.fromJson(
        serializer.fromJson<String>(json['scope']),
      ),
      groupKey: serializer.fromJson<String?>(json['groupKey']),
      active: serializer.fromJson<bool>(json['active']),
      sort: serializer.fromJson<int>(json['sort']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      weekdays: serializer.fromJson<int?>(json['weekdays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $IbadahItemsTable.$converterkind.toJson(kind),
      ),
      'target': serializer.toJson<int>(target),
      'scope': serializer.toJson<String>(
        $IbadahItemsTable.$converterscope.toJson(scope),
      ),
      'groupKey': serializer.toJson<String?>(groupKey),
      'active': serializer.toJson<bool>(active),
      'sort': serializer.toJson<int>(sort),
      'builtIn': serializer.toJson<bool>(builtIn),
      'weekdays': serializer.toJson<int?>(weekdays),
    };
  }

  IbadahItem copyWith({
    int? id,
    String? key,
    String? name,
    IbadahKind? kind,
    int? target,
    IbadahScope? scope,
    Value<String?> groupKey = const Value.absent(),
    bool? active,
    int? sort,
    bool? builtIn,
    Value<int?> weekdays = const Value.absent(),
  }) => IbadahItem(
    id: id ?? this.id,
    key: key ?? this.key,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    target: target ?? this.target,
    scope: scope ?? this.scope,
    groupKey: groupKey.present ? groupKey.value : this.groupKey,
    active: active ?? this.active,
    sort: sort ?? this.sort,
    builtIn: builtIn ?? this.builtIn,
    weekdays: weekdays.present ? weekdays.value : this.weekdays,
  );
  IbadahItem copyWithCompanion(IbadahItemsCompanion data) {
    return IbadahItem(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      target: data.target.present ? data.target.value : this.target,
      scope: data.scope.present ? data.scope.value : this.scope,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      active: data.active.present ? data.active.value : this.active,
      sort: data.sort.present ? data.sort.value : this.sort,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IbadahItem(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('target: $target, ')
          ..write('scope: $scope, ')
          ..write('groupKey: $groupKey, ')
          ..write('active: $active, ')
          ..write('sort: $sort, ')
          ..write('builtIn: $builtIn, ')
          ..write('weekdays: $weekdays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    key,
    name,
    kind,
    target,
    scope,
    groupKey,
    active,
    sort,
    builtIn,
    weekdays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IbadahItem &&
          other.id == this.id &&
          other.key == this.key &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.target == this.target &&
          other.scope == this.scope &&
          other.groupKey == this.groupKey &&
          other.active == this.active &&
          other.sort == this.sort &&
          other.builtIn == this.builtIn &&
          other.weekdays == this.weekdays);
}

class IbadahItemsCompanion extends UpdateCompanion<IbadahItem> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> name;
  final Value<IbadahKind> kind;
  final Value<int> target;
  final Value<IbadahScope> scope;
  final Value<String?> groupKey;
  final Value<bool> active;
  final Value<int> sort;
  final Value<bool> builtIn;
  final Value<int?> weekdays;
  const IbadahItemsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.target = const Value.absent(),
    this.scope = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.active = const Value.absent(),
    this.sort = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.weekdays = const Value.absent(),
  });
  IbadahItemsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String name,
    required IbadahKind kind,
    this.target = const Value.absent(),
    required IbadahScope scope,
    this.groupKey = const Value.absent(),
    this.active = const Value.absent(),
    this.sort = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.weekdays = const Value.absent(),
  }) : key = Value(key),
       name = Value(name),
       kind = Value(kind),
       scope = Value(scope);
  static Insertable<IbadahItem> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? target,
    Expression<String>? scope,
    Expression<String>? groupKey,
    Expression<bool>? active,
    Expression<int>? sort,
    Expression<bool>? builtIn,
    Expression<int>? weekdays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (target != null) 'target': target,
      if (scope != null) 'scope': scope,
      if (groupKey != null) 'group_key': groupKey,
      if (active != null) 'active': active,
      if (sort != null) 'sort': sort,
      if (builtIn != null) 'built_in': builtIn,
      if (weekdays != null) 'weekdays': weekdays,
    });
  }

  IbadahItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? name,
    Value<IbadahKind>? kind,
    Value<int>? target,
    Value<IbadahScope>? scope,
    Value<String?>? groupKey,
    Value<bool>? active,
    Value<int>? sort,
    Value<bool>? builtIn,
    Value<int?>? weekdays,
  }) {
    return IbadahItemsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      scope: scope ?? this.scope,
      groupKey: groupKey ?? this.groupKey,
      active: active ?? this.active,
      sort: sort ?? this.sort,
      builtIn: builtIn ?? this.builtIn,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $IbadahItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(
        $IbadahItemsTable.$converterscope.toSql(scope.value),
      );
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<int>(weekdays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IbadahItemsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('target: $target, ')
          ..write('scope: $scope, ')
          ..write('groupKey: $groupKey, ')
          ..write('active: $active, ')
          ..write('sort: $sort, ')
          ..write('builtIn: $builtIn, ')
          ..write('weekdays: $weekdays')
          ..write(')'))
        .toString();
  }
}

class $IbadahLogsTable extends IbadahLogs
    with TableInfo<$IbadahLogsTable, IbadahLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IbadahLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ibadah_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prayedAtMeta = const VerificationMeta(
    'prayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> prayedAt = GeneratedColumn<DateTime>(
    'prayed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jamaahMeta = const VerificationMeta('jamaah');
  @override
  late final GeneratedColumn<bool> jamaah = GeneratedColumn<bool>(
    'jamaah',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("jamaah" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    itemId,
    value,
    note,
    updatedAt,
    prayedAt,
    place,
    jamaah,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ibadah_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<IbadahLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('prayed_at')) {
      context.handle(
        _prayedAtMeta,
        prayedAt.isAcceptableOrUnknown(data['prayed_at']!, _prayedAtMeta),
      );
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    }
    if (data.containsKey('jamaah')) {
      context.handle(
        _jamaahMeta,
        jamaah.isAcceptableOrUnknown(data['jamaah']!, _jamaahMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, itemId};
  @override
  IbadahLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IbadahLog(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      prayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}prayed_at'],
      ),
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      ),
      jamaah: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}jamaah'],
      ),
    );
  }

  @override
  $IbadahLogsTable createAlias(String alias) {
    return $IbadahLogsTable(attachedDatabase, alias);
  }
}

class IbadahLog extends DataClass implements Insertable<IbadahLog> {
  final String date;
  final int itemId;

  /// check: 1 = sudah; counter: jumlahnya.
  final int value;
  final String? note;
  final DateTime updatedAt;

  /// Sholat wajib (bila pencatatan waktu aktif): kapan dikerjakan - status
  /// awal waktu/terlambat/qadha dihitung dari jadwal, tidak disimpan.
  final DateTime? prayedAt;

  /// Sholat wajib: 'masjid' / 'rumah' / 'lainnya'.
  final String? place;

  /// Sholat wajib: true = berjama'ah, false = sendiri (munfarid). null =
  /// belum dicatat (catatan dari sebelum fitur ini) - dihitung penuh.
  final bool? jamaah;
  const IbadahLog({
    required this.date,
    required this.itemId,
    required this.value,
    this.note,
    required this.updatedAt,
    this.prayedAt,
    this.place,
    this.jamaah,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['item_id'] = Variable<int>(itemId);
    map['value'] = Variable<int>(value);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || prayedAt != null) {
      map['prayed_at'] = Variable<DateTime>(prayedAt);
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    if (!nullToAbsent || jamaah != null) {
      map['jamaah'] = Variable<bool>(jamaah);
    }
    return map;
  }

  IbadahLogsCompanion toCompanion(bool nullToAbsent) {
    return IbadahLogsCompanion(
      date: Value(date),
      itemId: Value(itemId),
      value: Value(value),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
      prayedAt: prayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(prayedAt),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      jamaah: jamaah == null && nullToAbsent
          ? const Value.absent()
          : Value(jamaah),
    );
  }

  factory IbadahLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IbadahLog(
      date: serializer.fromJson<String>(json['date']),
      itemId: serializer.fromJson<int>(json['itemId']),
      value: serializer.fromJson<int>(json['value']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      prayedAt: serializer.fromJson<DateTime?>(json['prayedAt']),
      place: serializer.fromJson<String?>(json['place']),
      jamaah: serializer.fromJson<bool?>(json['jamaah']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'itemId': serializer.toJson<int>(itemId),
      'value': serializer.toJson<int>(value),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'prayedAt': serializer.toJson<DateTime?>(prayedAt),
      'place': serializer.toJson<String?>(place),
      'jamaah': serializer.toJson<bool?>(jamaah),
    };
  }

  IbadahLog copyWith({
    String? date,
    int? itemId,
    int? value,
    Value<String?> note = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> prayedAt = const Value.absent(),
    Value<String?> place = const Value.absent(),
    Value<bool?> jamaah = const Value.absent(),
  }) => IbadahLog(
    date: date ?? this.date,
    itemId: itemId ?? this.itemId,
    value: value ?? this.value,
    note: note.present ? note.value : this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    prayedAt: prayedAt.present ? prayedAt.value : this.prayedAt,
    place: place.present ? place.value : this.place,
    jamaah: jamaah.present ? jamaah.value : this.jamaah,
  );
  IbadahLog copyWithCompanion(IbadahLogsCompanion data) {
    return IbadahLog(
      date: data.date.present ? data.date.value : this.date,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      prayedAt: data.prayedAt.present ? data.prayedAt.value : this.prayedAt,
      place: data.place.present ? data.place.value : this.place,
      jamaah: data.jamaah.present ? data.jamaah.value : this.jamaah,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IbadahLog(')
          ..write('date: $date, ')
          ..write('itemId: $itemId, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('prayedAt: $prayedAt, ')
          ..write('place: $place, ')
          ..write('jamaah: $jamaah')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    itemId,
    value,
    note,
    updatedAt,
    prayedAt,
    place,
    jamaah,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IbadahLog &&
          other.date == this.date &&
          other.itemId == this.itemId &&
          other.value == this.value &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.prayedAt == this.prayedAt &&
          other.place == this.place &&
          other.jamaah == this.jamaah);
}

class IbadahLogsCompanion extends UpdateCompanion<IbadahLog> {
  final Value<String> date;
  final Value<int> itemId;
  final Value<int> value;
  final Value<String?> note;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> prayedAt;
  final Value<String?> place;
  final Value<bool?> jamaah;
  final Value<int> rowid;
  const IbadahLogsCompanion({
    this.date = const Value.absent(),
    this.itemId = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.prayedAt = const Value.absent(),
    this.place = const Value.absent(),
    this.jamaah = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IbadahLogsCompanion.insert({
    required String date,
    required int itemId,
    required int value,
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.prayedAt = const Value.absent(),
    this.place = const Value.absent(),
    this.jamaah = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       itemId = Value(itemId),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<IbadahLog> custom({
    Expression<String>? date,
    Expression<int>? itemId,
    Expression<int>? value,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? prayedAt,
    Expression<String>? place,
    Expression<bool>? jamaah,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (itemId != null) 'item_id': itemId,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (prayedAt != null) 'prayed_at': prayedAt,
      if (place != null) 'place': place,
      if (jamaah != null) 'jamaah': jamaah,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IbadahLogsCompanion copyWith({
    Value<String>? date,
    Value<int>? itemId,
    Value<int>? value,
    Value<String?>? note,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? prayedAt,
    Value<String?>? place,
    Value<bool?>? jamaah,
    Value<int>? rowid,
  }) {
    return IbadahLogsCompanion(
      date: date ?? this.date,
      itemId: itemId ?? this.itemId,
      value: value ?? this.value,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      prayedAt: prayedAt ?? this.prayedAt,
      place: place ?? this.place,
      jamaah: jamaah ?? this.jamaah,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (prayedAt.present) {
      map['prayed_at'] = Variable<DateTime>(prayedAt.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (jamaah.present) {
      map['jamaah'] = Variable<bool>(jamaah.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IbadahLogsCompanion(')
          ..write('date: $date, ')
          ..write('itemId: $itemId, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('prayedAt: $prayedAt, ')
          ..write('place: $place, ')
          ..write('jamaah: $jamaah, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayStatusesTable extends DayStatuses
    with TableInfo<$DayStatusesTable, DayStatus> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayStatusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excusedMeta = const VerificationMeta(
    'excused',
  );
  @override
  late final GeneratedColumn<bool> excused = GeneratedColumn<bool>(
    'excused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("excused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, excused, note, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_statuses';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayStatus> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('excused')) {
      context.handle(
        _excusedMeta,
        excused.isAcceptableOrUnknown(data['excused']!, _excusedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayStatus map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayStatus(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      excused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excused'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DayStatusesTable createAlias(String alias) {
    return $DayStatusesTable(attachedDatabase, alias);
  }
}

class DayStatus extends DataClass implements Insertable<DayStatus> {
  final String date;
  final bool excused;
  final String? note;
  final DateTime updatedAt;
  const DayStatus({
    required this.date,
    required this.excused,
    this.note,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['excused'] = Variable<bool>(excused);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DayStatusesCompanion toCompanion(bool nullToAbsent) {
    return DayStatusesCompanion(
      date: Value(date),
      excused: Value(excused),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayStatus.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayStatus(
      date: serializer.fromJson<String>(json['date']),
      excused: serializer.fromJson<bool>(json['excused']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'excused': serializer.toJson<bool>(excused),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DayStatus copyWith({
    String? date,
    bool? excused,
    Value<String?> note = const Value.absent(),
    DateTime? updatedAt,
  }) => DayStatus(
    date: date ?? this.date,
    excused: excused ?? this.excused,
    note: note.present ? note.value : this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DayStatus copyWithCompanion(DayStatusesCompanion data) {
    return DayStatus(
      date: data.date.present ? data.date.value : this.date,
      excused: data.excused.present ? data.excused.value : this.excused,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayStatus(')
          ..write('date: $date, ')
          ..write('excused: $excused, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, excused, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayStatus &&
          other.date == this.date &&
          other.excused == this.excused &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class DayStatusesCompanion extends UpdateCompanion<DayStatus> {
  final Value<String> date;
  final Value<bool> excused;
  final Value<String?> note;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DayStatusesCompanion({
    this.date = const Value.absent(),
    this.excused = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayStatusesCompanion.insert({
    required String date,
    this.excused = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       updatedAt = Value(updatedAt);
  static Insertable<DayStatus> custom({
    Expression<String>? date,
    Expression<bool>? excused,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (excused != null) 'excused': excused,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayStatusesCompanion copyWith({
    Value<String>? date,
    Value<bool>? excused,
    Value<String?>? note,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DayStatusesCompanion(
      date: date ?? this.date,
      excused: excused ?? this.excused,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (excused.present) {
      map['excused'] = Variable<bool>(excused.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayStatusesCompanion(')
          ..write('date: $date, ')
          ..write('excused: $excused, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RamadanRecapsTable extends RamadanRecaps
    with TableInfo<$RamadanRecapsTable, RamadanRecap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RamadanRecapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hijriYearMeta = const VerificationMeta(
    'hijriYear',
  );
  @override
  late final GeneratedColumn<int> hijriYear = GeneratedColumn<int>(
    'hijri_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fastedMeta = const VerificationMeta('fasted');
  @override
  late final GeneratedColumn<int> fasted = GeneratedColumn<int>(
    'fasted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excusedMeta = const VerificationMeta(
    'excused',
  );
  @override
  late final GeneratedColumn<int> excused = GeneratedColumn<int>(
    'excused',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manualMeta = const VerificationMeta('manual');
  @override
  late final GeneratedColumn<bool> manual = GeneratedColumn<bool>(
    'manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'locked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    hijriYear,
    days,
    fasted,
    excused,
    manual,
    lockedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ramadan_recaps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RamadanRecap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hijri_year')) {
      context.handle(
        _hijriYearMeta,
        hijriYear.isAcceptableOrUnknown(data['hijri_year']!, _hijriYearMeta),
      );
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    } else if (isInserting) {
      context.missing(_daysMeta);
    }
    if (data.containsKey('fasted')) {
      context.handle(
        _fastedMeta,
        fasted.isAcceptableOrUnknown(data['fasted']!, _fastedMeta),
      );
    } else if (isInserting) {
      context.missing(_fastedMeta);
    }
    if (data.containsKey('excused')) {
      context.handle(
        _excusedMeta,
        excused.isAcceptableOrUnknown(data['excused']!, _excusedMeta),
      );
    } else if (isInserting) {
      context.missing(_excusedMeta);
    }
    if (data.containsKey('manual')) {
      context.handle(
        _manualMeta,
        manual.isAcceptableOrUnknown(data['manual']!, _manualMeta),
      );
    }
    if (data.containsKey('locked_at')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['locked_at']!, _lockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hijriYear};
  @override
  RamadanRecap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RamadanRecap(
      hijriYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hijri_year'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      )!,
      fasted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fasted'],
      )!,
      excused: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excused'],
      )!,
      manual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual'],
      )!,
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_at'],
      )!,
    );
  }

  @override
  $RamadanRecapsTable createAlias(String alias) {
    return $RamadanRecapsTable(attachedDatabase, alias);
  }
}

class RamadanRecap extends DataClass implements Insertable<RamadanRecap> {
  final int hijriYear;
  final int days;
  final int fasted;
  final int excused;
  final bool manual;
  final DateTime lockedAt;
  const RamadanRecap({
    required this.hijriYear,
    required this.days,
    required this.fasted,
    required this.excused,
    required this.manual,
    required this.lockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hijri_year'] = Variable<int>(hijriYear);
    map['days'] = Variable<int>(days);
    map['fasted'] = Variable<int>(fasted);
    map['excused'] = Variable<int>(excused);
    map['manual'] = Variable<bool>(manual);
    map['locked_at'] = Variable<DateTime>(lockedAt);
    return map;
  }

  RamadanRecapsCompanion toCompanion(bool nullToAbsent) {
    return RamadanRecapsCompanion(
      hijriYear: Value(hijriYear),
      days: Value(days),
      fasted: Value(fasted),
      excused: Value(excused),
      manual: Value(manual),
      lockedAt: Value(lockedAt),
    );
  }

  factory RamadanRecap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RamadanRecap(
      hijriYear: serializer.fromJson<int>(json['hijriYear']),
      days: serializer.fromJson<int>(json['days']),
      fasted: serializer.fromJson<int>(json['fasted']),
      excused: serializer.fromJson<int>(json['excused']),
      manual: serializer.fromJson<bool>(json['manual']),
      lockedAt: serializer.fromJson<DateTime>(json['lockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hijriYear': serializer.toJson<int>(hijriYear),
      'days': serializer.toJson<int>(days),
      'fasted': serializer.toJson<int>(fasted),
      'excused': serializer.toJson<int>(excused),
      'manual': serializer.toJson<bool>(manual),
      'lockedAt': serializer.toJson<DateTime>(lockedAt),
    };
  }

  RamadanRecap copyWith({
    int? hijriYear,
    int? days,
    int? fasted,
    int? excused,
    bool? manual,
    DateTime? lockedAt,
  }) => RamadanRecap(
    hijriYear: hijriYear ?? this.hijriYear,
    days: days ?? this.days,
    fasted: fasted ?? this.fasted,
    excused: excused ?? this.excused,
    manual: manual ?? this.manual,
    lockedAt: lockedAt ?? this.lockedAt,
  );
  RamadanRecap copyWithCompanion(RamadanRecapsCompanion data) {
    return RamadanRecap(
      hijriYear: data.hijriYear.present ? data.hijriYear.value : this.hijriYear,
      days: data.days.present ? data.days.value : this.days,
      fasted: data.fasted.present ? data.fasted.value : this.fasted,
      excused: data.excused.present ? data.excused.value : this.excused,
      manual: data.manual.present ? data.manual.value : this.manual,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RamadanRecap(')
          ..write('hijriYear: $hijriYear, ')
          ..write('days: $days, ')
          ..write('fasted: $fasted, ')
          ..write('excused: $excused, ')
          ..write('manual: $manual, ')
          ..write('lockedAt: $lockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(hijriYear, days, fasted, excused, manual, lockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RamadanRecap &&
          other.hijriYear == this.hijriYear &&
          other.days == this.days &&
          other.fasted == this.fasted &&
          other.excused == this.excused &&
          other.manual == this.manual &&
          other.lockedAt == this.lockedAt);
}

class RamadanRecapsCompanion extends UpdateCompanion<RamadanRecap> {
  final Value<int> hijriYear;
  final Value<int> days;
  final Value<int> fasted;
  final Value<int> excused;
  final Value<bool> manual;
  final Value<DateTime> lockedAt;
  const RamadanRecapsCompanion({
    this.hijriYear = const Value.absent(),
    this.days = const Value.absent(),
    this.fasted = const Value.absent(),
    this.excused = const Value.absent(),
    this.manual = const Value.absent(),
    this.lockedAt = const Value.absent(),
  });
  RamadanRecapsCompanion.insert({
    this.hijriYear = const Value.absent(),
    required int days,
    required int fasted,
    required int excused,
    this.manual = const Value.absent(),
    required DateTime lockedAt,
  }) : days = Value(days),
       fasted = Value(fasted),
       excused = Value(excused),
       lockedAt = Value(lockedAt);
  static Insertable<RamadanRecap> custom({
    Expression<int>? hijriYear,
    Expression<int>? days,
    Expression<int>? fasted,
    Expression<int>? excused,
    Expression<bool>? manual,
    Expression<DateTime>? lockedAt,
  }) {
    return RawValuesInsertable({
      if (hijriYear != null) 'hijri_year': hijriYear,
      if (days != null) 'days': days,
      if (fasted != null) 'fasted': fasted,
      if (excused != null) 'excused': excused,
      if (manual != null) 'manual': manual,
      if (lockedAt != null) 'locked_at': lockedAt,
    });
  }

  RamadanRecapsCompanion copyWith({
    Value<int>? hijriYear,
    Value<int>? days,
    Value<int>? fasted,
    Value<int>? excused,
    Value<bool>? manual,
    Value<DateTime>? lockedAt,
  }) {
    return RamadanRecapsCompanion(
      hijriYear: hijriYear ?? this.hijriYear,
      days: days ?? this.days,
      fasted: fasted ?? this.fasted,
      excused: excused ?? this.excused,
      manual: manual ?? this.manual,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hijriYear.present) {
      map['hijri_year'] = Variable<int>(hijriYear.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (fasted.present) {
      map['fasted'] = Variable<int>(fasted.value);
    }
    if (excused.present) {
      map['excused'] = Variable<int>(excused.value);
    }
    if (manual.present) {
      map['manual'] = Variable<bool>(manual.value);
    }
    if (lockedAt.present) {
      map['locked_at'] = Variable<DateTime>(lockedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RamadanRecapsCompanion(')
          ..write('hijriYear: $hijriYear, ')
          ..write('days: $days, ')
          ..write('fasted: $fasted, ')
          ..write('excused: $excused, ')
          ..write('manual: $manual, ')
          ..write('lockedAt: $lockedAt')
          ..write(')'))
        .toString();
  }
}

class $QuranCyclesTable extends QuranCycles
    with TableInfo<$QuranCyclesTable, QuranCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    finishedAt,
    completed,
    targetDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuranCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      ),
    );
  }

  @override
  $QuranCyclesTable createAlias(String alias) {
    return $QuranCyclesTable(attachedDatabase, alias);
  }
}

class QuranCycle extends DataClass implements Insertable<QuranCycle> {
  final int id;
  final DateTime startedAt;

  /// Diisi saat putaran ditutup (khatam atau diulang dari awal).
  final DateTime? finishedAt;

  /// true = ditutup karena khatam (sampai An-Nas).
  final bool completed;

  /// Batas khatam (kunci tanggal, hari terakhir yang masih termasuk),
  /// null = tanpa target.
  final String? targetDate;
  const QuranCycle({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.completed,
    this.targetDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    return map;
  }

  QuranCyclesCompanion toCompanion(bool nullToAbsent) {
    return QuranCyclesCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      completed: Value(completed),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
    );
  }

  factory QuranCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranCycle(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'completed': serializer.toJson<bool>(completed),
      'targetDate': serializer.toJson<String?>(targetDate),
    };
  }

  QuranCycle copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    bool? completed,
    Value<String?> targetDate = const Value.absent(),
  }) => QuranCycle(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    completed: completed ?? this.completed,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
  );
  QuranCycle copyWithCompanion(QuranCyclesCompanion data) {
    return QuranCycle(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranCycle(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('completed: $completed, ')
          ..write('targetDate: $targetDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startedAt, finishedAt, completed, targetDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranCycle &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.completed == this.completed &&
          other.targetDate == this.targetDate);
}

class QuranCyclesCompanion extends UpdateCompanion<QuranCycle> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<bool> completed;
  final Value<String?> targetDate;
  const QuranCyclesCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.targetDate = const Value.absent(),
  });
  QuranCyclesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.targetDate = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<QuranCycle> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<bool>? completed,
    Expression<String>? targetDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (completed != null) 'completed': completed,
      if (targetDate != null) 'target_date': targetDate,
    });
  }

  QuranCyclesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<bool>? completed,
    Value<String?>? targetDate,
  }) {
    return QuranCyclesCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      completed: completed ?? this.completed,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranCyclesCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('completed: $completed, ')
          ..write('targetDate: $targetDate')
          ..write(')'))
        .toString();
  }
}

class $QuranLogsTable extends QuranLogs
    with TableInfo<$QuranLogsTable, QuranLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quran_cycles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAyahMeta = const VerificationMeta(
    'fromAyah',
  );
  @override
  late final GeneratedColumn<int> fromAyah = GeneratedColumn<int>(
    'from_ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAyahMeta = const VerificationMeta('toAyah');
  @override
  late final GeneratedColumn<int> toAyah = GeneratedColumn<int>(
    'to_ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    date,
    fromAyah,
    toAyah,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('from_ayah')) {
      context.handle(
        _fromAyahMeta,
        fromAyah.isAcceptableOrUnknown(data['from_ayah']!, _fromAyahMeta),
      );
    } else if (isInserting) {
      context.missing(_fromAyahMeta);
    }
    if (data.containsKey('to_ayah')) {
      context.handle(
        _toAyahMeta,
        toAyah.isAcceptableOrUnknown(data['to_ayah']!, _toAyahMeta),
      );
    } else if (isInserting) {
      context.missing(_toAyahMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuranLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      fromAyah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_ayah'],
      )!,
      toAyah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_ayah'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuranLogsTable createAlias(String alias) {
    return $QuranLogsTable(attachedDatabase, alias);
  }
}

class QuranLog extends DataClass implements Insertable<QuranLog> {
  final int id;
  final int cycleId;
  final String date;
  final int fromAyah;
  final int toAyah;
  final DateTime createdAt;
  const QuranLog({
    required this.id,
    required this.cycleId,
    required this.date,
    required this.fromAyah,
    required this.toAyah,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['date'] = Variable<String>(date);
    map['from_ayah'] = Variable<int>(fromAyah);
    map['to_ayah'] = Variable<int>(toAyah);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuranLogsCompanion toCompanion(bool nullToAbsent) {
    return QuranLogsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      date: Value(date),
      fromAyah: Value(fromAyah),
      toAyah: Value(toAyah),
      createdAt: Value(createdAt),
    );
  }

  factory QuranLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranLog(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      date: serializer.fromJson<String>(json['date']),
      fromAyah: serializer.fromJson<int>(json['fromAyah']),
      toAyah: serializer.fromJson<int>(json['toAyah']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'date': serializer.toJson<String>(date),
      'fromAyah': serializer.toJson<int>(fromAyah),
      'toAyah': serializer.toJson<int>(toAyah),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuranLog copyWith({
    int? id,
    int? cycleId,
    String? date,
    int? fromAyah,
    int? toAyah,
    DateTime? createdAt,
  }) => QuranLog(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    date: date ?? this.date,
    fromAyah: fromAyah ?? this.fromAyah,
    toAyah: toAyah ?? this.toAyah,
    createdAt: createdAt ?? this.createdAt,
  );
  QuranLog copyWithCompanion(QuranLogsCompanion data) {
    return QuranLog(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      date: data.date.present ? data.date.value : this.date,
      fromAyah: data.fromAyah.present ? data.fromAyah.value : this.fromAyah,
      toAyah: data.toAyah.present ? data.toAyah.value : this.toAyah,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranLog(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('date: $date, ')
          ..write('fromAyah: $fromAyah, ')
          ..write('toAyah: $toAyah, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleId, date, fromAyah, toAyah, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranLog &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.date == this.date &&
          other.fromAyah == this.fromAyah &&
          other.toAyah == this.toAyah &&
          other.createdAt == this.createdAt);
}

class QuranLogsCompanion extends UpdateCompanion<QuranLog> {
  final Value<int> id;
  final Value<int> cycleId;
  final Value<String> date;
  final Value<int> fromAyah;
  final Value<int> toAyah;
  final Value<DateTime> createdAt;
  const QuranLogsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.date = const Value.absent(),
    this.fromAyah = const Value.absent(),
    this.toAyah = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuranLogsCompanion.insert({
    this.id = const Value.absent(),
    required int cycleId,
    required String date,
    required int fromAyah,
    required int toAyah,
    required DateTime createdAt,
  }) : cycleId = Value(cycleId),
       date = Value(date),
       fromAyah = Value(fromAyah),
       toAyah = Value(toAyah),
       createdAt = Value(createdAt);
  static Insertable<QuranLog> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<String>? date,
    Expression<int>? fromAyah,
    Expression<int>? toAyah,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (date != null) 'date': date,
      if (fromAyah != null) 'from_ayah': fromAyah,
      if (toAyah != null) 'to_ayah': toAyah,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuranLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? cycleId,
    Value<String>? date,
    Value<int>? fromAyah,
    Value<int>? toAyah,
    Value<DateTime>? createdAt,
  }) {
    return QuranLogsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      fromAyah: fromAyah ?? this.fromAyah,
      toAyah: toAyah ?? this.toAyah,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (fromAyah.present) {
      map['from_ayah'] = Variable<int>(fromAyah.value);
    }
    if (toAyah.present) {
      map['to_ayah'] = Variable<int>(toAyah.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranLogsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('date: $date, ')
          ..write('fromAyah: $fromAyah, ')
          ..write('toAyah: $toAyah, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuranNotesTable extends QuranNotes
    with TableInfo<$QuranNotesTable, QuranNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fromAyahMeta = const VerificationMeta(
    'fromAyah',
  );
  @override
  late final GeneratedColumn<int> fromAyah = GeneratedColumn<int>(
    'from_ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAyahMeta = const VerificationMeta('toAyah');
  @override
  late final GeneratedColumn<int> toAyah = GeneratedColumn<int>(
    'to_ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromAyah,
    toAyah,
    body,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_ayah')) {
      context.handle(
        _fromAyahMeta,
        fromAyah.isAcceptableOrUnknown(data['from_ayah']!, _fromAyahMeta),
      );
    } else if (isInserting) {
      context.missing(_fromAyahMeta);
    }
    if (data.containsKey('to_ayah')) {
      context.handle(
        _toAyahMeta,
        toAyah.isAcceptableOrUnknown(data['to_ayah']!, _toAyahMeta),
      );
    } else if (isInserting) {
      context.missing(_toAyahMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuranNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromAyah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_ayah'],
      )!,
      toAyah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_ayah'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuranNotesTable createAlias(String alias) {
    return $QuranNotesTable(attachedDatabase, alias);
  }
}

class QuranNote extends DataClass implements Insertable<QuranNote> {
  final int id;
  final int fromAyah;
  final int toAyah;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QuranNote({
    required this.id,
    required this.fromAyah,
    required this.toAyah,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_ayah'] = Variable<int>(fromAyah);
    map['to_ayah'] = Variable<int>(toAyah);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuranNotesCompanion toCompanion(bool nullToAbsent) {
    return QuranNotesCompanion(
      id: Value(id),
      fromAyah: Value(fromAyah),
      toAyah: Value(toAyah),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuranNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranNote(
      id: serializer.fromJson<int>(json['id']),
      fromAyah: serializer.fromJson<int>(json['fromAyah']),
      toAyah: serializer.fromJson<int>(json['toAyah']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromAyah': serializer.toJson<int>(fromAyah),
      'toAyah': serializer.toJson<int>(toAyah),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuranNote copyWith({
    int? id,
    int? fromAyah,
    int? toAyah,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuranNote(
    id: id ?? this.id,
    fromAyah: fromAyah ?? this.fromAyah,
    toAyah: toAyah ?? this.toAyah,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuranNote copyWithCompanion(QuranNotesCompanion data) {
    return QuranNote(
      id: data.id.present ? data.id.value : this.id,
      fromAyah: data.fromAyah.present ? data.fromAyah.value : this.fromAyah,
      toAyah: data.toAyah.present ? data.toAyah.value : this.toAyah,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranNote(')
          ..write('id: $id, ')
          ..write('fromAyah: $fromAyah, ')
          ..write('toAyah: $toAyah, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fromAyah, toAyah, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranNote &&
          other.id == this.id &&
          other.fromAyah == this.fromAyah &&
          other.toAyah == this.toAyah &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuranNotesCompanion extends UpdateCompanion<QuranNote> {
  final Value<int> id;
  final Value<int> fromAyah;
  final Value<int> toAyah;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const QuranNotesCompanion({
    this.id = const Value.absent(),
    this.fromAyah = const Value.absent(),
    this.toAyah = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QuranNotesCompanion.insert({
    this.id = const Value.absent(),
    required int fromAyah,
    required int toAyah,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : fromAyah = Value(fromAyah),
       toAyah = Value(toAyah),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuranNote> custom({
    Expression<int>? id,
    Expression<int>? fromAyah,
    Expression<int>? toAyah,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromAyah != null) 'from_ayah': fromAyah,
      if (toAyah != null) 'to_ayah': toAyah,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QuranNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? fromAyah,
    Value<int>? toAyah,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return QuranNotesCompanion(
      id: id ?? this.id,
      fromAyah: fromAyah ?? this.fromAyah,
      toAyah: toAyah ?? this.toAyah,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromAyah.present) {
      map['from_ayah'] = Variable<int>(fromAyah.value);
    }
    if (toAyah.present) {
      map['to_ayah'] = Variable<int>(toAyah.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranNotesCompanion(')
          ..write('id: $id, ')
          ..write('fromAyah: $fromAyah, ')
          ..write('toAyah: $toAyah, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IbadahItemsTable ibadahItems = $IbadahItemsTable(this);
  late final $IbadahLogsTable ibadahLogs = $IbadahLogsTable(this);
  late final $DayStatusesTable dayStatuses = $DayStatusesTable(this);
  late final $RamadanRecapsTable ramadanRecaps = $RamadanRecapsTable(this);
  late final $QuranCyclesTable quranCycles = $QuranCyclesTable(this);
  late final $QuranLogsTable quranLogs = $QuranLogsTable(this);
  late final $QuranNotesTable quranNotes = $QuranNotesTable(this);
  late final QuranDao quranDao = QuranDao(this as AppDatabase);
  late final IbadahDao ibadahDao = IbadahDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ibadahItems,
    ibadahLogs,
    dayStatuses,
    ramadanRecaps,
    quranCycles,
    quranLogs,
    quranNotes,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ibadah_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ibadah_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'quran_cycles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('quran_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$IbadahItemsTableCreateCompanionBuilder =
    IbadahItemsCompanion Function({
      Value<int> id,
      required String key,
      required String name,
      required IbadahKind kind,
      Value<int> target,
      required IbadahScope scope,
      Value<String?> groupKey,
      Value<bool> active,
      Value<int> sort,
      Value<bool> builtIn,
      Value<int?> weekdays,
    });
typedef $$IbadahItemsTableUpdateCompanionBuilder =
    IbadahItemsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> name,
      Value<IbadahKind> kind,
      Value<int> target,
      Value<IbadahScope> scope,
      Value<String?> groupKey,
      Value<bool> active,
      Value<int> sort,
      Value<bool> builtIn,
      Value<int?> weekdays,
    });

final class $$IbadahItemsTableReferences
    extends BaseReferences<_$AppDatabase, $IbadahItemsTable, IbadahItem> {
  $$IbadahItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IbadahLogsTable, List<IbadahLog>>
  _ibadahLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ibadahLogs,
    aliasName: $_aliasNameGenerator(db.ibadahItems.id, db.ibadahLogs.itemId),
  );

  $$IbadahLogsTableProcessedTableManager get ibadahLogsRefs {
    final manager = $$IbadahLogsTableTableManager(
      $_db,
      $_db.ibadahLogs,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ibadahLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IbadahItemsTableFilterComposer
    extends Composer<_$AppDatabase, $IbadahItemsTable> {
  $$IbadahItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IbadahKind, IbadahKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IbadahScope, IbadahScope, String> get scope =>
      $composableBuilder(
        column: $table.scope,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ibadahLogsRefs(
    Expression<bool> Function($$IbadahLogsTableFilterComposer f) f,
  ) {
    final $$IbadahLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ibadahLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IbadahLogsTableFilterComposer(
            $db: $db,
            $table: $db.ibadahLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IbadahItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $IbadahItemsTable> {
  $$IbadahItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IbadahItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IbadahItemsTable> {
  $$IbadahItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<IbadahKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumnWithTypeConverter<IbadahScope, String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<int> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  Expression<T> ibadahLogsRefs<T extends Object>(
    Expression<T> Function($$IbadahLogsTableAnnotationComposer a) f,
  ) {
    final $$IbadahLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ibadahLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IbadahLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.ibadahLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IbadahItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IbadahItemsTable,
          IbadahItem,
          $$IbadahItemsTableFilterComposer,
          $$IbadahItemsTableOrderingComposer,
          $$IbadahItemsTableAnnotationComposer,
          $$IbadahItemsTableCreateCompanionBuilder,
          $$IbadahItemsTableUpdateCompanionBuilder,
          (IbadahItem, $$IbadahItemsTableReferences),
          IbadahItem,
          PrefetchHooks Function({bool ibadahLogsRefs})
        > {
  $$IbadahItemsTableTableManager(_$AppDatabase db, $IbadahItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IbadahItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IbadahItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IbadahItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<IbadahKind> kind = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<IbadahScope> scope = const Value.absent(),
                Value<String?> groupKey = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int?> weekdays = const Value.absent(),
              }) => IbadahItemsCompanion(
                id: id,
                key: key,
                name: name,
                kind: kind,
                target: target,
                scope: scope,
                groupKey: groupKey,
                active: active,
                sort: sort,
                builtIn: builtIn,
                weekdays: weekdays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String name,
                required IbadahKind kind,
                Value<int> target = const Value.absent(),
                required IbadahScope scope,
                Value<String?> groupKey = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int?> weekdays = const Value.absent(),
              }) => IbadahItemsCompanion.insert(
                id: id,
                key: key,
                name: name,
                kind: kind,
                target: target,
                scope: scope,
                groupKey: groupKey,
                active: active,
                sort: sort,
                builtIn: builtIn,
                weekdays: weekdays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IbadahItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ibadahLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ibadahLogsRefs) db.ibadahLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ibadahLogsRefs)
                    await $_getPrefetchedData<
                      IbadahItem,
                      $IbadahItemsTable,
                      IbadahLog
                    >(
                      currentTable: table,
                      referencedTable: $$IbadahItemsTableReferences
                          ._ibadahLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$IbadahItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).ibadahLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$IbadahItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IbadahItemsTable,
      IbadahItem,
      $$IbadahItemsTableFilterComposer,
      $$IbadahItemsTableOrderingComposer,
      $$IbadahItemsTableAnnotationComposer,
      $$IbadahItemsTableCreateCompanionBuilder,
      $$IbadahItemsTableUpdateCompanionBuilder,
      (IbadahItem, $$IbadahItemsTableReferences),
      IbadahItem,
      PrefetchHooks Function({bool ibadahLogsRefs})
    >;
typedef $$IbadahLogsTableCreateCompanionBuilder =
    IbadahLogsCompanion Function({
      required String date,
      required int itemId,
      required int value,
      Value<String?> note,
      required DateTime updatedAt,
      Value<DateTime?> prayedAt,
      Value<String?> place,
      Value<bool?> jamaah,
      Value<int> rowid,
    });
typedef $$IbadahLogsTableUpdateCompanionBuilder =
    IbadahLogsCompanion Function({
      Value<String> date,
      Value<int> itemId,
      Value<int> value,
      Value<String?> note,
      Value<DateTime> updatedAt,
      Value<DateTime?> prayedAt,
      Value<String?> place,
      Value<bool?> jamaah,
      Value<int> rowid,
    });

final class $$IbadahLogsTableReferences
    extends BaseReferences<_$AppDatabase, $IbadahLogsTable, IbadahLog> {
  $$IbadahLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IbadahItemsTable _itemIdTable(_$AppDatabase db) =>
      db.ibadahItems.createAlias(
        $_aliasNameGenerator(db.ibadahLogs.itemId, db.ibadahItems.id),
      );

  $$IbadahItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$IbadahItemsTableTableManager(
      $_db,
      $_db.ibadahItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IbadahLogsTableFilterComposer
    extends Composer<_$AppDatabase, $IbadahLogsTable> {
  $$IbadahLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get prayedAt => $composableBuilder(
    column: $table.prayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get jamaah => $composableBuilder(
    column: $table.jamaah,
    builder: (column) => ColumnFilters(column),
  );

  $$IbadahItemsTableFilterComposer get itemId {
    final $$IbadahItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.ibadahItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IbadahItemsTableFilterComposer(
            $db: $db,
            $table: $db.ibadahItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IbadahLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $IbadahLogsTable> {
  $$IbadahLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get prayedAt => $composableBuilder(
    column: $table.prayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get jamaah => $composableBuilder(
    column: $table.jamaah,
    builder: (column) => ColumnOrderings(column),
  );

  $$IbadahItemsTableOrderingComposer get itemId {
    final $$IbadahItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.ibadahItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IbadahItemsTableOrderingComposer(
            $db: $db,
            $table: $db.ibadahItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IbadahLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IbadahLogsTable> {
  $$IbadahLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get prayedAt =>
      $composableBuilder(column: $table.prayedAt, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<bool> get jamaah =>
      $composableBuilder(column: $table.jamaah, builder: (column) => column);

  $$IbadahItemsTableAnnotationComposer get itemId {
    final $$IbadahItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.ibadahItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IbadahItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.ibadahItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IbadahLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IbadahLogsTable,
          IbadahLog,
          $$IbadahLogsTableFilterComposer,
          $$IbadahLogsTableOrderingComposer,
          $$IbadahLogsTableAnnotationComposer,
          $$IbadahLogsTableCreateCompanionBuilder,
          $$IbadahLogsTableUpdateCompanionBuilder,
          (IbadahLog, $$IbadahLogsTableReferences),
          IbadahLog,
          PrefetchHooks Function({bool itemId})
        > {
  $$IbadahLogsTableTableManager(_$AppDatabase db, $IbadahLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IbadahLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IbadahLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IbadahLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> prayedAt = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<bool?> jamaah = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IbadahLogsCompanion(
                date: date,
                itemId: itemId,
                value: value,
                note: note,
                updatedAt: updatedAt,
                prayedAt: prayedAt,
                place: place,
                jamaah: jamaah,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int itemId,
                required int value,
                Value<String?> note = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> prayedAt = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<bool?> jamaah = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IbadahLogsCompanion.insert(
                date: date,
                itemId: itemId,
                value: value,
                note: note,
                updatedAt: updatedAt,
                prayedAt: prayedAt,
                place: place,
                jamaah: jamaah,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IbadahLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$IbadahLogsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$IbadahLogsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IbadahLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IbadahLogsTable,
      IbadahLog,
      $$IbadahLogsTableFilterComposer,
      $$IbadahLogsTableOrderingComposer,
      $$IbadahLogsTableAnnotationComposer,
      $$IbadahLogsTableCreateCompanionBuilder,
      $$IbadahLogsTableUpdateCompanionBuilder,
      (IbadahLog, $$IbadahLogsTableReferences),
      IbadahLog,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$DayStatusesTableCreateCompanionBuilder =
    DayStatusesCompanion Function({
      required String date,
      Value<bool> excused,
      Value<String?> note,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DayStatusesTableUpdateCompanionBuilder =
    DayStatusesCompanion Function({
      Value<String> date,
      Value<bool> excused,
      Value<String?> note,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DayStatusesTableFilterComposer
    extends Composer<_$AppDatabase, $DayStatusesTable> {
  $$DayStatusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excused => $composableBuilder(
    column: $table.excused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayStatusesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayStatusesTable> {
  $$DayStatusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excused => $composableBuilder(
    column: $table.excused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayStatusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayStatusesTable> {
  $$DayStatusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get excused =>
      $composableBuilder(column: $table.excused, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DayStatusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayStatusesTable,
          DayStatus,
          $$DayStatusesTableFilterComposer,
          $$DayStatusesTableOrderingComposer,
          $$DayStatusesTableAnnotationComposer,
          $$DayStatusesTableCreateCompanionBuilder,
          $$DayStatusesTableUpdateCompanionBuilder,
          (
            DayStatus,
            BaseReferences<_$AppDatabase, $DayStatusesTable, DayStatus>,
          ),
          DayStatus,
          PrefetchHooks Function()
        > {
  $$DayStatusesTableTableManager(_$AppDatabase db, $DayStatusesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayStatusesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayStatusesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayStatusesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<bool> excused = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayStatusesCompanion(
                date: date,
                excused: excused,
                note: note,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<bool> excused = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DayStatusesCompanion.insert(
                date: date,
                excused: excused,
                note: note,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayStatusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayStatusesTable,
      DayStatus,
      $$DayStatusesTableFilterComposer,
      $$DayStatusesTableOrderingComposer,
      $$DayStatusesTableAnnotationComposer,
      $$DayStatusesTableCreateCompanionBuilder,
      $$DayStatusesTableUpdateCompanionBuilder,
      (DayStatus, BaseReferences<_$AppDatabase, $DayStatusesTable, DayStatus>),
      DayStatus,
      PrefetchHooks Function()
    >;
typedef $$RamadanRecapsTableCreateCompanionBuilder =
    RamadanRecapsCompanion Function({
      Value<int> hijriYear,
      required int days,
      required int fasted,
      required int excused,
      Value<bool> manual,
      required DateTime lockedAt,
    });
typedef $$RamadanRecapsTableUpdateCompanionBuilder =
    RamadanRecapsCompanion Function({
      Value<int> hijriYear,
      Value<int> days,
      Value<int> fasted,
      Value<int> excused,
      Value<bool> manual,
      Value<DateTime> lockedAt,
    });

class $$RamadanRecapsTableFilterComposer
    extends Composer<_$AppDatabase, $RamadanRecapsTable> {
  $$RamadanRecapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get hijriYear => $composableBuilder(
    column: $table.hijriYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fasted => $composableBuilder(
    column: $table.fasted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excused => $composableBuilder(
    column: $table.excused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RamadanRecapsTableOrderingComposer
    extends Composer<_$AppDatabase, $RamadanRecapsTable> {
  $$RamadanRecapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get hijriYear => $composableBuilder(
    column: $table.hijriYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fasted => $composableBuilder(
    column: $table.fasted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excused => $composableBuilder(
    column: $table.excused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RamadanRecapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RamadanRecapsTable> {
  $$RamadanRecapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get hijriYear =>
      $composableBuilder(column: $table.hijriYear, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<int> get fasted =>
      $composableBuilder(column: $table.fasted, builder: (column) => column);

  GeneratedColumn<int> get excused =>
      $composableBuilder(column: $table.excused, builder: (column) => column);

  GeneratedColumn<bool> get manual =>
      $composableBuilder(column: $table.manual, builder: (column) => column);

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);
}

class $$RamadanRecapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RamadanRecapsTable,
          RamadanRecap,
          $$RamadanRecapsTableFilterComposer,
          $$RamadanRecapsTableOrderingComposer,
          $$RamadanRecapsTableAnnotationComposer,
          $$RamadanRecapsTableCreateCompanionBuilder,
          $$RamadanRecapsTableUpdateCompanionBuilder,
          (
            RamadanRecap,
            BaseReferences<_$AppDatabase, $RamadanRecapsTable, RamadanRecap>,
          ),
          RamadanRecap,
          PrefetchHooks Function()
        > {
  $$RamadanRecapsTableTableManager(_$AppDatabase db, $RamadanRecapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RamadanRecapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RamadanRecapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RamadanRecapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> hijriYear = const Value.absent(),
                Value<int> days = const Value.absent(),
                Value<int> fasted = const Value.absent(),
                Value<int> excused = const Value.absent(),
                Value<bool> manual = const Value.absent(),
                Value<DateTime> lockedAt = const Value.absent(),
              }) => RamadanRecapsCompanion(
                hijriYear: hijriYear,
                days: days,
                fasted: fasted,
                excused: excused,
                manual: manual,
                lockedAt: lockedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> hijriYear = const Value.absent(),
                required int days,
                required int fasted,
                required int excused,
                Value<bool> manual = const Value.absent(),
                required DateTime lockedAt,
              }) => RamadanRecapsCompanion.insert(
                hijriYear: hijriYear,
                days: days,
                fasted: fasted,
                excused: excused,
                manual: manual,
                lockedAt: lockedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RamadanRecapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RamadanRecapsTable,
      RamadanRecap,
      $$RamadanRecapsTableFilterComposer,
      $$RamadanRecapsTableOrderingComposer,
      $$RamadanRecapsTableAnnotationComposer,
      $$RamadanRecapsTableCreateCompanionBuilder,
      $$RamadanRecapsTableUpdateCompanionBuilder,
      (
        RamadanRecap,
        BaseReferences<_$AppDatabase, $RamadanRecapsTable, RamadanRecap>,
      ),
      RamadanRecap,
      PrefetchHooks Function()
    >;
typedef $$QuranCyclesTableCreateCompanionBuilder =
    QuranCyclesCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<bool> completed,
      Value<String?> targetDate,
    });
typedef $$QuranCyclesTableUpdateCompanionBuilder =
    QuranCyclesCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<bool> completed,
      Value<String?> targetDate,
    });

final class $$QuranCyclesTableReferences
    extends BaseReferences<_$AppDatabase, $QuranCyclesTable, QuranCycle> {
  $$QuranCyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuranLogsTable, List<QuranLog>>
  _quranLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.quranLogs,
    aliasName: $_aliasNameGenerator(db.quranCycles.id, db.quranLogs.cycleId),
  );

  $$QuranLogsTableProcessedTableManager get quranLogsRefs {
    final manager = $$QuranLogsTableTableManager(
      $_db,
      $_db.quranLogs,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quranLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuranCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $QuranCyclesTable> {
  $$QuranCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> quranLogsRefs(
    Expression<bool> Function($$QuranLogsTableFilterComposer f) f,
  ) {
    final $$QuranLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quranLogs,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranLogsTableFilterComposer(
            $db: $db,
            $table: $db.quranLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuranCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranCyclesTable> {
  $$QuranCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuranCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranCyclesTable> {
  $$QuranCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  Expression<T> quranLogsRefs<T extends Object>(
    Expression<T> Function($$QuranLogsTableAnnotationComposer a) f,
  ) {
    final $$QuranLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quranLogs,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.quranLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuranCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranCyclesTable,
          QuranCycle,
          $$QuranCyclesTableFilterComposer,
          $$QuranCyclesTableOrderingComposer,
          $$QuranCyclesTableAnnotationComposer,
          $$QuranCyclesTableCreateCompanionBuilder,
          $$QuranCyclesTableUpdateCompanionBuilder,
          (QuranCycle, $$QuranCyclesTableReferences),
          QuranCycle,
          PrefetchHooks Function({bool quranLogsRefs})
        > {
  $$QuranCyclesTableTableManager(_$AppDatabase db, $QuranCyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
              }) => QuranCyclesCompanion(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                completed: completed,
                targetDate: targetDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
              }) => QuranCyclesCompanion.insert(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                completed: completed,
                targetDate: targetDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuranCyclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({quranLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (quranLogsRefs) db.quranLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quranLogsRefs)
                    await $_getPrefetchedData<
                      QuranCycle,
                      $QuranCyclesTable,
                      QuranLog
                    >(
                      currentTable: table,
                      referencedTable: $$QuranCyclesTableReferences
                          ._quranLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$QuranCyclesTableReferences(
                            db,
                            table,
                            p0,
                          ).quranLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cycleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$QuranCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranCyclesTable,
      QuranCycle,
      $$QuranCyclesTableFilterComposer,
      $$QuranCyclesTableOrderingComposer,
      $$QuranCyclesTableAnnotationComposer,
      $$QuranCyclesTableCreateCompanionBuilder,
      $$QuranCyclesTableUpdateCompanionBuilder,
      (QuranCycle, $$QuranCyclesTableReferences),
      QuranCycle,
      PrefetchHooks Function({bool quranLogsRefs})
    >;
typedef $$QuranLogsTableCreateCompanionBuilder =
    QuranLogsCompanion Function({
      Value<int> id,
      required int cycleId,
      required String date,
      required int fromAyah,
      required int toAyah,
      required DateTime createdAt,
    });
typedef $$QuranLogsTableUpdateCompanionBuilder =
    QuranLogsCompanion Function({
      Value<int> id,
      Value<int> cycleId,
      Value<String> date,
      Value<int> fromAyah,
      Value<int> toAyah,
      Value<DateTime> createdAt,
    });

final class $$QuranLogsTableReferences
    extends BaseReferences<_$AppDatabase, $QuranLogsTable, QuranLog> {
  $$QuranLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuranCyclesTable _cycleIdTable(_$AppDatabase db) =>
      db.quranCycles.createAlias(
        $_aliasNameGenerator(db.quranLogs.cycleId, db.quranCycles.id),
      );

  $$QuranCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$QuranCyclesTableTableManager(
      $_db,
      $_db.quranCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuranLogsTableFilterComposer
    extends Composer<_$AppDatabase, $QuranLogsTable> {
  $$QuranLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromAyah => $composableBuilder(
    column: $table.fromAyah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAyah => $composableBuilder(
    column: $table.toAyah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuranCyclesTableFilterComposer get cycleId {
    final $$QuranCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.quranCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranCyclesTableFilterComposer(
            $db: $db,
            $table: $db.quranCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuranLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranLogsTable> {
  $$QuranLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromAyah => $composableBuilder(
    column: $table.fromAyah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAyah => $composableBuilder(
    column: $table.toAyah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuranCyclesTableOrderingComposer get cycleId {
    final $$QuranCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.quranCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.quranCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuranLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranLogsTable> {
  $$QuranLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get fromAyah =>
      $composableBuilder(column: $table.fromAyah, builder: (column) => column);

  GeneratedColumn<int> get toAyah =>
      $composableBuilder(column: $table.toAyah, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$QuranCyclesTableAnnotationComposer get cycleId {
    final $$QuranCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.quranCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.quranCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuranLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranLogsTable,
          QuranLog,
          $$QuranLogsTableFilterComposer,
          $$QuranLogsTableOrderingComposer,
          $$QuranLogsTableAnnotationComposer,
          $$QuranLogsTableCreateCompanionBuilder,
          $$QuranLogsTableUpdateCompanionBuilder,
          (QuranLog, $$QuranLogsTableReferences),
          QuranLog,
          PrefetchHooks Function({bool cycleId})
        > {
  $$QuranLogsTableTableManager(_$AppDatabase db, $QuranLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> fromAyah = const Value.absent(),
                Value<int> toAyah = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuranLogsCompanion(
                id: id,
                cycleId: cycleId,
                date: date,
                fromAyah: fromAyah,
                toAyah: toAyah,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cycleId,
                required String date,
                required int fromAyah,
                required int toAyah,
                required DateTime createdAt,
              }) => QuranLogsCompanion.insert(
                id: id,
                cycleId: cycleId,
                date: date,
                fromAyah: fromAyah,
                toAyah: toAyah,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuranLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable: $$QuranLogsTableReferences
                                    ._cycleIdTable(db),
                                referencedColumn: $$QuranLogsTableReferences
                                    ._cycleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuranLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranLogsTable,
      QuranLog,
      $$QuranLogsTableFilterComposer,
      $$QuranLogsTableOrderingComposer,
      $$QuranLogsTableAnnotationComposer,
      $$QuranLogsTableCreateCompanionBuilder,
      $$QuranLogsTableUpdateCompanionBuilder,
      (QuranLog, $$QuranLogsTableReferences),
      QuranLog,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$QuranNotesTableCreateCompanionBuilder =
    QuranNotesCompanion Function({
      Value<int> id,
      required int fromAyah,
      required int toAyah,
      required String body,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$QuranNotesTableUpdateCompanionBuilder =
    QuranNotesCompanion Function({
      Value<int> id,
      Value<int> fromAyah,
      Value<int> toAyah,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$QuranNotesTableFilterComposer
    extends Composer<_$AppDatabase, $QuranNotesTable> {
  $$QuranNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromAyah => $composableBuilder(
    column: $table.fromAyah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAyah => $composableBuilder(
    column: $table.toAyah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuranNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranNotesTable> {
  $$QuranNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromAyah => $composableBuilder(
    column: $table.fromAyah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAyah => $composableBuilder(
    column: $table.toAyah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuranNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranNotesTable> {
  $$QuranNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fromAyah =>
      $composableBuilder(column: $table.fromAyah, builder: (column) => column);

  GeneratedColumn<int> get toAyah =>
      $composableBuilder(column: $table.toAyah, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuranNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranNotesTable,
          QuranNote,
          $$QuranNotesTableFilterComposer,
          $$QuranNotesTableOrderingComposer,
          $$QuranNotesTableAnnotationComposer,
          $$QuranNotesTableCreateCompanionBuilder,
          $$QuranNotesTableUpdateCompanionBuilder,
          (
            QuranNote,
            BaseReferences<_$AppDatabase, $QuranNotesTable, QuranNote>,
          ),
          QuranNote,
          PrefetchHooks Function()
        > {
  $$QuranNotesTableTableManager(_$AppDatabase db, $QuranNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fromAyah = const Value.absent(),
                Value<int> toAyah = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => QuranNotesCompanion(
                id: id,
                fromAyah: fromAyah,
                toAyah: toAyah,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fromAyah,
                required int toAyah,
                required String body,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => QuranNotesCompanion.insert(
                id: id,
                fromAyah: fromAyah,
                toAyah: toAyah,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuranNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranNotesTable,
      QuranNote,
      $$QuranNotesTableFilterComposer,
      $$QuranNotesTableOrderingComposer,
      $$QuranNotesTableAnnotationComposer,
      $$QuranNotesTableCreateCompanionBuilder,
      $$QuranNotesTableUpdateCompanionBuilder,
      (QuranNote, BaseReferences<_$AppDatabase, $QuranNotesTable, QuranNote>),
      QuranNote,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IbadahItemsTableTableManager get ibadahItems =>
      $$IbadahItemsTableTableManager(_db, _db.ibadahItems);
  $$IbadahLogsTableTableManager get ibadahLogs =>
      $$IbadahLogsTableTableManager(_db, _db.ibadahLogs);
  $$DayStatusesTableTableManager get dayStatuses =>
      $$DayStatusesTableTableManager(_db, _db.dayStatuses);
  $$RamadanRecapsTableTableManager get ramadanRecaps =>
      $$RamadanRecapsTableTableManager(_db, _db.ramadanRecaps);
  $$QuranCyclesTableTableManager get quranCycles =>
      $$QuranCyclesTableTableManager(_db, _db.quranCycles);
  $$QuranLogsTableTableManager get quranLogs =>
      $$QuranLogsTableTableManager(_db, _db.quranLogs);
  $$QuranNotesTableTableManager get quranNotes =>
      $$QuranNotesTableTableManager(_db, _db.quranNotes);
}

mixin _$QuranDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuranCyclesTable get quranCycles => attachedDatabase.quranCycles;
  $QuranLogsTable get quranLogs => attachedDatabase.quranLogs;
  $QuranNotesTable get quranNotes => attachedDatabase.quranNotes;
  QuranDaoManager get managers => QuranDaoManager(this);
}

class QuranDaoManager {
  final _$QuranDaoMixin _db;
  QuranDaoManager(this._db);
  $$QuranCyclesTableTableManager get quranCycles =>
      $$QuranCyclesTableTableManager(_db.attachedDatabase, _db.quranCycles);
  $$QuranLogsTableTableManager get quranLogs =>
      $$QuranLogsTableTableManager(_db.attachedDatabase, _db.quranLogs);
  $$QuranNotesTableTableManager get quranNotes =>
      $$QuranNotesTableTableManager(_db.attachedDatabase, _db.quranNotes);
}

mixin _$IbadahDaoMixin on DatabaseAccessor<AppDatabase> {
  $IbadahItemsTable get ibadahItems => attachedDatabase.ibadahItems;
  $IbadahLogsTable get ibadahLogs => attachedDatabase.ibadahLogs;
  $DayStatusesTable get dayStatuses => attachedDatabase.dayStatuses;
  $QuranCyclesTable get quranCycles => attachedDatabase.quranCycles;
  $QuranLogsTable get quranLogs => attachedDatabase.quranLogs;
  $RamadanRecapsTable get ramadanRecaps => attachedDatabase.ramadanRecaps;
  IbadahDaoManager get managers => IbadahDaoManager(this);
}

class IbadahDaoManager {
  final _$IbadahDaoMixin _db;
  IbadahDaoManager(this._db);
  $$IbadahItemsTableTableManager get ibadahItems =>
      $$IbadahItemsTableTableManager(_db.attachedDatabase, _db.ibadahItems);
  $$IbadahLogsTableTableManager get ibadahLogs =>
      $$IbadahLogsTableTableManager(_db.attachedDatabase, _db.ibadahLogs);
  $$DayStatusesTableTableManager get dayStatuses =>
      $$DayStatusesTableTableManager(_db.attachedDatabase, _db.dayStatuses);
  $$QuranCyclesTableTableManager get quranCycles =>
      $$QuranCyclesTableTableManager(_db.attachedDatabase, _db.quranCycles);
  $$QuranLogsTableTableManager get quranLogs =>
      $$QuranLogsTableTableManager(_db.attachedDatabase, _db.quranLogs);
  $$RamadanRecapsTableTableManager get ramadanRecaps =>
      $$RamadanRecapsTableTableManager(_db.attachedDatabase, _db.ramadanRecaps);
}
