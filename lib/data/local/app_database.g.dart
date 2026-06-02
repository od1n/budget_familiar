// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTableTable extends AccountsTable
    with TableInfo<$AccountsTableTable, AccountsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _initialBalanceMeta =
      const VerificationMeta('initialBalance');
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
      'initial_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#607D8B'));
  static const VerificationMeta _iconCodeMeta =
      const VerificationMeta('iconCode');
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
      'icon_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('account_balance_wallet'));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        type,
        name,
        currencyCode,
        initialBalance,
        colorHex,
        iconCode,
        isArchived,
        isSynced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AccountsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
          _initialBalanceMeta,
          initialBalance.isAcceptableOrUnknown(
              data['initial_balance']!, _initialBalanceMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon_code')) {
      context.handle(_iconCodeMeta,
          iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      initialBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}initial_balance'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      iconCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_code'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTableTable createAlias(String alias) {
    return $AccountsTableTable(attachedDatabase, alias);
  }
}

class AccountsTableData extends DataClass
    implements Insertable<AccountsTableData> {
  final String id;
  final String groupId;

  /// 'cash' | 'bank' | 'digital' | 'credit' | 'investment'
  final String type;
  final String name;
  final String currencyCode;
  final double initialBalance;
  final String colorHex;
  final String iconCode;
  final bool isArchived;
  final bool isSynced;
  final DateTime createdAt;
  const AccountsTableData(
      {required this.id,
      required this.groupId,
      required this.type,
      required this.name,
      required this.currencyCode,
      required this.initialBalance,
      required this.colorHex,
      required this.iconCode,
      required this.isArchived,
      required this.isSynced,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['currency_code'] = Variable<String>(currencyCode);
    map['initial_balance'] = Variable<double>(initialBalance);
    map['color_hex'] = Variable<String>(colorHex);
    map['icon_code'] = Variable<String>(iconCode);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsTableCompanion toCompanion(bool nullToAbsent) {
    return AccountsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      type: Value(type),
      name: Value(name),
      currencyCode: Value(currencyCode),
      initialBalance: Value(initialBalance),
      colorHex: Value(colorHex),
      iconCode: Value(iconCode),
      isArchived: Value(isArchived),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory AccountsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      iconCode: serializer.fromJson<String>(json['iconCode']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'colorHex': serializer.toJson<String>(colorHex),
      'iconCode': serializer.toJson<String>(iconCode),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AccountsTableData copyWith(
          {String? id,
          String? groupId,
          String? type,
          String? name,
          String? currencyCode,
          double? initialBalance,
          String? colorHex,
          String? iconCode,
          bool? isArchived,
          bool? isSynced,
          DateTime? createdAt}) =>
      AccountsTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        type: type ?? this.type,
        name: name ?? this.name,
        currencyCode: currencyCode ?? this.currencyCode,
        initialBalance: initialBalance ?? this.initialBalance,
        colorHex: colorHex ?? this.colorHex,
        iconCode: iconCode ?? this.iconCode,
        isArchived: isArchived ?? this.isArchived,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
  AccountsTableData copyWithCompanion(AccountsTableCompanion data) {
    return AccountsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconCode: $iconCode, ')
          ..write('isArchived: $isArchived, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, type, name, currencyCode,
      initialBalance, colorHex, iconCode, isArchived, isSynced, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.type == this.type &&
          other.name == this.name &&
          other.currencyCode == this.currencyCode &&
          other.initialBalance == this.initialBalance &&
          other.colorHex == this.colorHex &&
          other.iconCode == this.iconCode &&
          other.isArchived == this.isArchived &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class AccountsTableCompanion extends UpdateCompanion<AccountsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> type;
  final Value<String> name;
  final Value<String> currencyCode;
  final Value<double> initialBalance;
  final Value<String> colorHex;
  final Value<String> iconCode;
  final Value<bool> isArchived;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsTableCompanion.insert({
    required String id,
    required String groupId,
    this.type = const Value.absent(),
    required String name,
    required String currencyCode,
    this.initialBalance = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        name = Value(name),
        currencyCode = Value(currencyCode);
  static Insertable<AccountsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? currencyCode,
    Expression<double>? initialBalance,
    Expression<String>? colorHex,
    Expression<String>? iconCode,
    Expression<bool>? isArchived,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconCode != null) 'icon_code': iconCode,
      if (isArchived != null) 'is_archived': isArchived,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? type,
      Value<String>? name,
      Value<String>? currencyCode,
      Value<double>? initialBalance,
      Value<String>? colorHex,
      Value<String>? iconCode,
      Value<bool>? isArchived,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AccountsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      initialBalance: initialBalance ?? this.initialBalance,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      isArchived: isArchived ?? this.isArchived,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconCode: $iconCode, ')
          ..write('isArchived: $isArchived, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _iconCodeMeta =
      const VerificationMeta('iconCode');
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
      'icon_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 7, maxTextLength: 7),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        name,
        iconCode,
        colorHex,
        type,
        isSystem,
        sortOrder,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(_iconCodeMeta,
          iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta));
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_code'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  final String id;
  final String? groupId;
  final String name;
  final String iconCode;
  final String colorHex;
  final String type;
  final bool isSystem;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  const CategoriesTableData(
      {required this.id,
      this.groupId,
      required this.name,
      required this.iconCode,
      required this.colorHex,
      required this.type,
      required this.isSystem,
      required this.sortOrder,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['name'] = Variable<String>(name);
    map['icon_code'] = Variable<String>(iconCode);
    map['color_hex'] = Variable<String>(colorHex);
    map['type'] = Variable<String>(type);
    map['is_system'] = Variable<bool>(isSystem);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      name: Value(name),
      iconCode: Value(iconCode),
      colorHex: Value(colorHex),
      type: Value(type),
      isSystem: Value(isSystem),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory CategoriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      iconCode: serializer.fromJson<String>(json['iconCode']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      type: serializer.fromJson<String>(json['type']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String?>(groupId),
      'name': serializer.toJson<String>(name),
      'iconCode': serializer.toJson<String>(iconCode),
      'colorHex': serializer.toJson<String>(colorHex),
      'type': serializer.toJson<String>(type),
      'isSystem': serializer.toJson<bool>(isSystem),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoriesTableData copyWith(
          {String? id,
          Value<String?> groupId = const Value.absent(),
          String? name,
          String? iconCode,
          String? colorHex,
          String? type,
          bool? isSystem,
          int? sortOrder,
          bool? isActive,
          DateTime? createdAt}) =>
      CategoriesTableData(
        id: id ?? this.id,
        groupId: groupId.present ? groupId.value : this.groupId,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
        colorHex: colorHex ?? this.colorHex,
        type: type ?? this.type,
        isSystem: isSystem ?? this.isSystem,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  CategoriesTableData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      type: data.type.present ? data.type.value : this.type,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorHex: $colorHex, ')
          ..write('type: $type, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, name, iconCode, colorHex, type,
      isSystem, sortOrder, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.iconCode == this.iconCode &&
          other.colorHex == this.colorHex &&
          other.type == this.type &&
          other.isSystem == this.isSystem &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<String> id;
  final Value<String?> groupId;
  final Value<String> name;
  final Value<String> iconCode;
  final Value<String> colorHex;
  final Value<String> type;
  final Value<bool> isSystem;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.type = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    this.groupId = const Value.absent(),
    required String name,
    required String iconCode,
    required String colorHex,
    required String type,
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        iconCode = Value(iconCode),
        colorHex = Value(colorHex),
        type = Value(type);
  static Insertable<CategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String>? iconCode,
    Expression<String>? colorHex,
    Expression<String>? type,
    Expression<bool>? isSystem,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (iconCode != null) 'icon_code': iconCode,
      if (colorHex != null) 'color_hex': colorHex,
      if (type != null) 'type': type,
      if (isSystem != null) 'is_system': isSystem,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String?>? groupId,
      Value<String>? name,
      Value<String>? iconCode,
      Value<String>? colorHex,
      Value<String>? type,
      Value<bool>? isSystem,
      Value<int>? sortOrder,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorHex: $colorHex, ')
          ..write('type: $type, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountUsdEquivalentMeta =
      const VerificationMeta('amountUsdEquivalent');
  @override
  late final GeneratedColumn<double> amountUsdEquivalent =
      GeneratedColumn<double>('amount_usd_equivalent', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _exchangeRateIdMeta =
      const VerificationMeta('exchangeRateId');
  @override
  late final GeneratedColumn<String> exchangeRateId = GeneratedColumn<String>(
      'exchange_rate_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkedTxIdMeta =
      const VerificationMeta('linkedTxId');
  @override
  late final GeneratedColumn<String> linkedTxId = GeneratedColumn<String>(
      'linked_tx_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        userId,
        categoryId,
        amount,
        currencyCode,
        amountUsdEquivalent,
        exchangeRateId,
        type,
        date,
        description,
        paymentMethod,
        notes,
        linkedTxId,
        accountId,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('amount_usd_equivalent')) {
      context.handle(
          _amountUsdEquivalentMeta,
          amountUsdEquivalent.isAcceptableOrUnknown(
              data['amount_usd_equivalent']!, _amountUsdEquivalentMeta));
    }
    if (data.containsKey('exchange_rate_id')) {
      context.handle(
          _exchangeRateIdMeta,
          exchangeRateId.isAcceptableOrUnknown(
              data['exchange_rate_id']!, _exchangeRateIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('linked_tx_id')) {
      context.handle(
          _linkedTxIdMeta,
          linkedTxId.isAcceptableOrUnknown(
              data['linked_tx_id']!, _linkedTxIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      amountUsdEquivalent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}amount_usd_equivalent']),
      exchangeRateId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exchange_rate_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      linkedTxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}linked_tx_id']),
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final String id;
  final String groupId;
  final String userId;
  final String? categoryId;
  final double amount;
  final String currencyCode;
  final double? amountUsdEquivalent;
  final String? exchangeRateId;
  final String type;
  final DateTime date;
  final String? description;
  final String? paymentMethod;
  final String? notes;
  final String? linkedTxId;
  final String? accountId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionsTableData(
      {required this.id,
      required this.groupId,
      required this.userId,
      this.categoryId,
      required this.amount,
      required this.currencyCode,
      this.amountUsdEquivalent,
      this.exchangeRateId,
      required this.type,
      required this.date,
      this.description,
      this.paymentMethod,
      this.notes,
      this.linkedTxId,
      this.accountId,
      required this.isSynced,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount'] = Variable<double>(amount);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || amountUsdEquivalent != null) {
      map['amount_usd_equivalent'] = Variable<double>(amountUsdEquivalent);
    }
    if (!nullToAbsent || exchangeRateId != null) {
      map['exchange_rate_id'] = Variable<String>(exchangeRateId);
    }
    map['type'] = Variable<String>(type);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || linkedTxId != null) {
      map['linked_tx_id'] = Variable<String>(linkedTxId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      userId: Value(userId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      amountUsdEquivalent: amountUsdEquivalent == null && nullToAbsent
          ? const Value.absent()
          : Value(amountUsdEquivalent),
      exchangeRateId: exchangeRateId == null && nullToAbsent
          ? const Value.absent()
          : Value(exchangeRateId),
      type: Value(type),
      date: Value(date),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      linkedTxId: linkedTxId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTxId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amount: serializer.fromJson<double>(json['amount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      amountUsdEquivalent:
          serializer.fromJson<double?>(json['amountUsdEquivalent']),
      exchangeRateId: serializer.fromJson<String?>(json['exchangeRateId']),
      type: serializer.fromJson<String>(json['type']),
      date: serializer.fromJson<DateTime>(json['date']),
      description: serializer.fromJson<String?>(json['description']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      notes: serializer.fromJson<String?>(json['notes']),
      linkedTxId: serializer.fromJson<String?>(json['linkedTxId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amount': serializer.toJson<double>(amount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'amountUsdEquivalent': serializer.toJson<double?>(amountUsdEquivalent),
      'exchangeRateId': serializer.toJson<String?>(exchangeRateId),
      'type': serializer.toJson<String>(type),
      'date': serializer.toJson<DateTime>(date),
      'description': serializer.toJson<String?>(description),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'notes': serializer.toJson<String?>(notes),
      'linkedTxId': serializer.toJson<String?>(linkedTxId),
      'accountId': serializer.toJson<String?>(accountId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionsTableData copyWith(
          {String? id,
          String? groupId,
          String? userId,
          Value<String?> categoryId = const Value.absent(),
          double? amount,
          String? currencyCode,
          Value<double?> amountUsdEquivalent = const Value.absent(),
          Value<String?> exchangeRateId = const Value.absent(),
          String? type,
          DateTime? date,
          Value<String?> description = const Value.absent(),
          Value<String?> paymentMethod = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> linkedTxId = const Value.absent(),
          Value<String?> accountId = const Value.absent(),
          bool? isSynced,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      TransactionsTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        currencyCode: currencyCode ?? this.currencyCode,
        amountUsdEquivalent: amountUsdEquivalent.present
            ? amountUsdEquivalent.value
            : this.amountUsdEquivalent,
        exchangeRateId:
            exchangeRateId.present ? exchangeRateId.value : this.exchangeRateId,
        type: type ?? this.type,
        date: date ?? this.date,
        description: description.present ? description.value : this.description,
        paymentMethod:
            paymentMethod.present ? paymentMethod.value : this.paymentMethod,
        notes: notes.present ? notes.value : this.notes,
        linkedTxId: linkedTxId.present ? linkedTxId.value : this.linkedTxId,
        accountId: accountId.present ? accountId.value : this.accountId,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TransactionsTableData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      amountUsdEquivalent: data.amountUsdEquivalent.present
          ? data.amountUsdEquivalent.value
          : this.amountUsdEquivalent,
      exchangeRateId: data.exchangeRateId.present
          ? data.exchangeRateId.value
          : this.exchangeRateId,
      type: data.type.present ? data.type.value : this.type,
      date: data.date.present ? data.date.value : this.date,
      description:
          data.description.present ? data.description.value : this.description,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      notes: data.notes.present ? data.notes.value : this.notes,
      linkedTxId:
          data.linkedTxId.present ? data.linkedTxId.value : this.linkedTxId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('amountUsdEquivalent: $amountUsdEquivalent, ')
          ..write('exchangeRateId: $exchangeRateId, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('notes: $notes, ')
          ..write('linkedTxId: $linkedTxId, ')
          ..write('accountId: $accountId, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      userId,
      categoryId,
      amount,
      currencyCode,
      amountUsdEquivalent,
      exchangeRateId,
      type,
      date,
      description,
      paymentMethod,
      notes,
      linkedTxId,
      accountId,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currencyCode == this.currencyCode &&
          other.amountUsdEquivalent == this.amountUsdEquivalent &&
          other.exchangeRateId == this.exchangeRateId &&
          other.type == this.type &&
          other.date == this.date &&
          other.description == this.description &&
          other.paymentMethod == this.paymentMethod &&
          other.notes == this.notes &&
          other.linkedTxId == this.linkedTxId &&
          other.accountId == this.accountId &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String?> categoryId;
  final Value<double> amount;
  final Value<String> currencyCode;
  final Value<double?> amountUsdEquivalent;
  final Value<String?> exchangeRateId;
  final Value<String> type;
  final Value<DateTime> date;
  final Value<String?> description;
  final Value<String?> paymentMethod;
  final Value<String?> notes;
  final Value<String?> linkedTxId;
  final Value<String?> accountId;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.amountUsdEquivalent = const Value.absent(),
    this.exchangeRateId = const Value.absent(),
    this.type = const Value.absent(),
    this.date = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.linkedTxId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    required String id,
    required String groupId,
    required String userId,
    this.categoryId = const Value.absent(),
    required double amount,
    required String currencyCode,
    this.amountUsdEquivalent = const Value.absent(),
    this.exchangeRateId = const Value.absent(),
    required String type,
    required DateTime date,
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.linkedTxId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        userId = Value(userId),
        amount = Value(amount),
        currencyCode = Value(currencyCode),
        type = Value(type),
        date = Value(date);
  static Insertable<TransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? categoryId,
    Expression<double>? amount,
    Expression<String>? currencyCode,
    Expression<double>? amountUsdEquivalent,
    Expression<String>? exchangeRateId,
    Expression<String>? type,
    Expression<DateTime>? date,
    Expression<String>? description,
    Expression<String>? paymentMethod,
    Expression<String>? notes,
    Expression<String>? linkedTxId,
    Expression<String>? accountId,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (amountUsdEquivalent != null)
        'amount_usd_equivalent': amountUsdEquivalent,
      if (exchangeRateId != null) 'exchange_rate_id': exchangeRateId,
      if (type != null) 'type': type,
      if (date != null) 'date': date,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      if (linkedTxId != null) 'linked_tx_id': linkedTxId,
      if (accountId != null) 'account_id': accountId,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? userId,
      Value<String?>? categoryId,
      Value<double>? amount,
      Value<String>? currencyCode,
      Value<double?>? amountUsdEquivalent,
      Value<String?>? exchangeRateId,
      Value<String>? type,
      Value<DateTime>? date,
      Value<String?>? description,
      Value<String?>? paymentMethod,
      Value<String?>? notes,
      Value<String?>? linkedTxId,
      Value<String?>? accountId,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      amountUsdEquivalent: amountUsdEquivalent ?? this.amountUsdEquivalent,
      exchangeRateId: exchangeRateId ?? this.exchangeRateId,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      linkedTxId: linkedTxId ?? this.linkedTxId,
      accountId: accountId ?? this.accountId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (amountUsdEquivalent.present) {
      map['amount_usd_equivalent'] =
          Variable<double>(amountUsdEquivalent.value);
    }
    if (exchangeRateId.present) {
      map['exchange_rate_id'] = Variable<String>(exchangeRateId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (linkedTxId.present) {
      map['linked_tx_id'] = Variable<String>(linkedTxId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('amountUsdEquivalent: $amountUsdEquivalent, ')
          ..write('exchangeRateId: $exchangeRateId, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('notes: $notes, ')
          ..write('linkedTxId: $linkedTxId, ')
          ..write('accountId: $accountId, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTableTable extends ExchangeRatesTable
    with TableInfo<$ExchangeRatesTableTable, ExchangeRatesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromCurrencyMeta =
      const VerificationMeta('fromCurrency');
  @override
  late final GeneratedColumn<String> fromCurrency = GeneratedColumn<String>(
      'from_currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _toCurrencyMeta =
      const VerificationMeta('toCurrency');
  @override
  late final GeneratedColumn<String> toCurrency = GeneratedColumn<String>(
      'to_currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rateTypeMeta =
      const VerificationMeta('rateType');
  @override
  late final GeneratedColumn<String> rateType = GeneratedColumn<String>(
      'rate_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _validAtMeta =
      const VerificationMeta('validAt');
  @override
  late final GeneratedColumn<DateTime> validAt = GeneratedColumn<DateTime>(
      'valid_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fromCurrency,
        toCurrency,
        rate,
        rateType,
        source,
        validAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
      Insertable<ExchangeRatesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_currency')) {
      context.handle(
          _fromCurrencyMeta,
          fromCurrency.isAcceptableOrUnknown(
              data['from_currency']!, _fromCurrencyMeta));
    } else if (isInserting) {
      context.missing(_fromCurrencyMeta);
    }
    if (data.containsKey('to_currency')) {
      context.handle(
          _toCurrencyMeta,
          toCurrency.isAcceptableOrUnknown(
              data['to_currency']!, _toCurrencyMeta));
    } else if (isInserting) {
      context.missing(_toCurrencyMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('rate_type')) {
      context.handle(_rateTypeMeta,
          rateType.isAcceptableOrUnknown(data['rate_type']!, _rateTypeMeta));
    } else if (isInserting) {
      context.missing(_rateTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('valid_at')) {
      context.handle(_validAtMeta,
          validAt.isAcceptableOrUnknown(data['valid_at']!, _validAtMeta));
    } else if (isInserting) {
      context.missing(_validAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRatesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRatesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fromCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_currency'])!,
      toCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_currency'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      rateType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rate_type'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
      validAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}valid_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExchangeRatesTableTable createAlias(String alias) {
    return $ExchangeRatesTableTable(attachedDatabase, alias);
  }
}

class ExchangeRatesTableData extends DataClass
    implements Insertable<ExchangeRatesTableData> {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final String rateType;
  final String? source;
  final DateTime validAt;
  final DateTime createdAt;
  const ExchangeRatesTableData(
      {required this.id,
      required this.fromCurrency,
      required this.toCurrency,
      required this.rate,
      required this.rateType,
      this.source,
      required this.validAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_currency'] = Variable<String>(fromCurrency);
    map['to_currency'] = Variable<String>(toCurrency);
    map['rate'] = Variable<double>(rate);
    map['rate_type'] = Variable<String>(rateType);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['valid_at'] = Variable<DateTime>(validAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExchangeRatesTableCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesTableCompanion(
      id: Value(id),
      fromCurrency: Value(fromCurrency),
      toCurrency: Value(toCurrency),
      rate: Value(rate),
      rateType: Value(rateType),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
      validAt: Value(validAt),
      createdAt: Value(createdAt),
    );
  }

  factory ExchangeRatesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRatesTableData(
      id: serializer.fromJson<String>(json['id']),
      fromCurrency: serializer.fromJson<String>(json['fromCurrency']),
      toCurrency: serializer.fromJson<String>(json['toCurrency']),
      rate: serializer.fromJson<double>(json['rate']),
      rateType: serializer.fromJson<String>(json['rateType']),
      source: serializer.fromJson<String?>(json['source']),
      validAt: serializer.fromJson<DateTime>(json['validAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromCurrency': serializer.toJson<String>(fromCurrency),
      'toCurrency': serializer.toJson<String>(toCurrency),
      'rate': serializer.toJson<double>(rate),
      'rateType': serializer.toJson<String>(rateType),
      'source': serializer.toJson<String?>(source),
      'validAt': serializer.toJson<DateTime>(validAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExchangeRatesTableData copyWith(
          {String? id,
          String? fromCurrency,
          String? toCurrency,
          double? rate,
          String? rateType,
          Value<String?> source = const Value.absent(),
          DateTime? validAt,
          DateTime? createdAt}) =>
      ExchangeRatesTableData(
        id: id ?? this.id,
        fromCurrency: fromCurrency ?? this.fromCurrency,
        toCurrency: toCurrency ?? this.toCurrency,
        rate: rate ?? this.rate,
        rateType: rateType ?? this.rateType,
        source: source.present ? source.value : this.source,
        validAt: validAt ?? this.validAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ExchangeRatesTableData copyWithCompanion(ExchangeRatesTableCompanion data) {
    return ExchangeRatesTableData(
      id: data.id.present ? data.id.value : this.id,
      fromCurrency: data.fromCurrency.present
          ? data.fromCurrency.value
          : this.fromCurrency,
      toCurrency:
          data.toCurrency.present ? data.toCurrency.value : this.toCurrency,
      rate: data.rate.present ? data.rate.value : this.rate,
      rateType: data.rateType.present ? data.rateType.value : this.rateType,
      source: data.source.present ? data.source.value : this.source,
      validAt: data.validAt.present ? data.validAt.value : this.validAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesTableData(')
          ..write('id: $id, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('rate: $rate, ')
          ..write('rateType: $rateType, ')
          ..write('source: $source, ')
          ..write('validAt: $validAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, fromCurrency, toCurrency, rate, rateType, source, validAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRatesTableData &&
          other.id == this.id &&
          other.fromCurrency == this.fromCurrency &&
          other.toCurrency == this.toCurrency &&
          other.rate == this.rate &&
          other.rateType == this.rateType &&
          other.source == this.source &&
          other.validAt == this.validAt &&
          other.createdAt == this.createdAt);
}

class ExchangeRatesTableCompanion
    extends UpdateCompanion<ExchangeRatesTableData> {
  final Value<String> id;
  final Value<String> fromCurrency;
  final Value<String> toCurrency;
  final Value<double> rate;
  final Value<String> rateType;
  final Value<String?> source;
  final Value<DateTime> validAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExchangeRatesTableCompanion({
    this.id = const Value.absent(),
    this.fromCurrency = const Value.absent(),
    this.toCurrency = const Value.absent(),
    this.rate = const Value.absent(),
    this.rateType = const Value.absent(),
    this.source = const Value.absent(),
    this.validAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesTableCompanion.insert({
    required String id,
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    required String rateType,
    this.source = const Value.absent(),
    required DateTime validAt,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fromCurrency = Value(fromCurrency),
        toCurrency = Value(toCurrency),
        rate = Value(rate),
        rateType = Value(rateType),
        validAt = Value(validAt);
  static Insertable<ExchangeRatesTableData> custom({
    Expression<String>? id,
    Expression<String>? fromCurrency,
    Expression<String>? toCurrency,
    Expression<double>? rate,
    Expression<String>? rateType,
    Expression<String>? source,
    Expression<DateTime>? validAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromCurrency != null) 'from_currency': fromCurrency,
      if (toCurrency != null) 'to_currency': toCurrency,
      if (rate != null) 'rate': rate,
      if (rateType != null) 'rate_type': rateType,
      if (source != null) 'source': source,
      if (validAt != null) 'valid_at': validAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? fromCurrency,
      Value<String>? toCurrency,
      Value<double>? rate,
      Value<String>? rateType,
      Value<String?>? source,
      Value<DateTime>? validAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ExchangeRatesTableCompanion(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      rateType: rateType ?? this.rateType,
      source: source ?? this.source,
      validAt: validAt ?? this.validAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromCurrency.present) {
      map['from_currency'] = Variable<String>(fromCurrency.value);
    }
    if (toCurrency.present) {
      map['to_currency'] = Variable<String>(toCurrency.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (rateType.present) {
      map['rate_type'] = Variable<String>(rateType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (validAt.present) {
      map['valid_at'] = Variable<DateTime>(validAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesTableCompanion(')
          ..write('id: $id, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('rate: $rate, ')
          ..write('rateType: $rateType, ')
          ..write('source: $source, ')
          ..write('validAt: $validAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tableName_Meta =
      const VerificationMeta('tableName_');
  @override
  late final GeneratedColumn<String> tableName_ = GeneratedColumn<String>(
      'table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tableName_,
        operation,
        recordId,
        payload,
        retryCount,
        lastError,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_name')) {
      context.handle(
          _tableName_Meta,
          tableName_.isAcceptableOrUnknown(
              data['table_name']!, _tableName_Meta));
    } else if (isInserting) {
      context.missing(_tableName_Meta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tableName_: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String tableName_;
  final String operation;
  final String recordId;
  final String payload;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  const SyncQueueTableData(
      {required this.id,
      required this.tableName_,
      required this.operation,
      required this.recordId,
      required this.payload,
      required this.retryCount,
      this.lastError,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(tableName_);
    map['operation'] = Variable<String>(operation);
    map['record_id'] = Variable<String>(recordId);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      tableName_: Value(tableName_),
      operation: Value(operation),
      recordId: Value(recordId),
      payload: Value(payload),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      tableName_: serializer.fromJson<String>(json['tableName_']),
      operation: serializer.fromJson<String>(json['operation']),
      recordId: serializer.fromJson<String>(json['recordId']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tableName_': serializer.toJson<String>(tableName_),
      'operation': serializer.toJson<String>(operation),
      'recordId': serializer.toJson<String>(recordId),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueTableData copyWith(
          {int? id,
          String? tableName_,
          String? operation,
          String? recordId,
          String? payload,
          int? retryCount,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        tableName_: tableName_ ?? this.tableName_,
        operation: operation ?? this.operation,
        recordId: recordId ?? this.recordId,
        payload: payload ?? this.payload,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      tableName_:
          data.tableName_.present ? data.tableName_.value : this.tableName_,
      operation: data.operation.present ? data.operation.value : this.operation,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('tableName_: $tableName_, ')
          ..write('operation: $operation, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tableName_, operation, recordId, payload,
      retryCount, lastError, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.tableName_ == this.tableName_ &&
          other.operation == this.operation &&
          other.recordId == this.recordId &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> tableName_;
  final Value<String> operation;
  final Value<String> recordId;
  final Value<String> payload;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.tableName_ = const Value.absent(),
    this.operation = const Value.absent(),
    this.recordId = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String tableName_,
    required String operation,
    required String recordId,
    required String payload,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : tableName_ = Value(tableName_),
        operation = Value(operation),
        recordId = Value(recordId),
        payload = Value(payload);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? tableName_,
    Expression<String>? operation,
    Expression<String>? recordId,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableName_ != null) 'table_name': tableName_,
      if (operation != null) 'operation': operation,
      if (recordId != null) 'record_id': recordId,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? tableName_,
      Value<String>? operation,
      Value<String>? recordId,
      Value<String>? payload,
      Value<int>? retryCount,
      Value<String?>? lastError,
      Value<DateTime>? createdAt}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      tableName_: tableName_ ?? this.tableName_,
      operation: operation ?? this.operation,
      recordId: recordId ?? this.recordId,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tableName_.present) {
      map['table_name'] = Variable<String>(tableName_.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('tableName_: $tableName_, ')
          ..write('operation: $operation, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTableTable extends BudgetsTable
    with TableInfo<$BudgetsTableTable, BudgetsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthlyLimitMeta =
      const VerificationMeta('monthlyLimit');
  @override
  late final GeneratedColumn<double> monthlyLimit = GeneratedColumn<double>(
      'monthly_limit', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, groupId, categoryId, monthlyLimit, currencyCode, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('monthly_limit')) {
      context.handle(
          _monthlyLimitMeta,
          monthlyLimit.isAcceptableOrUnknown(
              data['monthly_limit']!, _monthlyLimitMeta));
    } else if (isInserting) {
      context.missing(_monthlyLimitMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      monthlyLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}monthly_limit'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BudgetsTableTable createAlias(String alias) {
    return $BudgetsTableTable(attachedDatabase, alias);
  }
}

class BudgetsTableData extends DataClass
    implements Insertable<BudgetsTableData> {
  final String id;
  final String groupId;
  final String categoryId;
  final double monthlyLimit;
  final String currencyCode;
  final DateTime updatedAt;
  const BudgetsTableData(
      {required this.id,
      required this.groupId,
      required this.categoryId,
      required this.monthlyLimit,
      required this.currencyCode,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['category_id'] = Variable<String>(categoryId);
    map['monthly_limit'] = Variable<double>(monthlyLimit);
    map['currency_code'] = Variable<String>(currencyCode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetsTableCompanion toCompanion(bool nullToAbsent) {
    return BudgetsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      categoryId: Value(categoryId),
      monthlyLimit: Value(monthlyLimit),
      currencyCode: Value(currencyCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      monthlyLimit: serializer.fromJson<double>(json['monthlyLimit']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'categoryId': serializer.toJson<String>(categoryId),
      'monthlyLimit': serializer.toJson<double>(monthlyLimit),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetsTableData copyWith(
          {String? id,
          String? groupId,
          String? categoryId,
          double? monthlyLimit,
          String? currencyCode,
          DateTime? updatedAt}) =>
      BudgetsTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        categoryId: categoryId ?? this.categoryId,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
        currencyCode: currencyCode ?? this.currencyCode,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BudgetsTableData copyWithCompanion(BudgetsTableCompanion data) {
    return BudgetsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      monthlyLimit: data.monthlyLimit.present
          ? data.monthlyLimit.value
          : this.monthlyLimit,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthlyLimit: $monthlyLimit, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, groupId, categoryId, monthlyLimit, currencyCode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.categoryId == this.categoryId &&
          other.monthlyLimit == this.monthlyLimit &&
          other.currencyCode == this.currencyCode &&
          other.updatedAt == this.updatedAt);
}

class BudgetsTableCompanion extends UpdateCompanion<BudgetsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> categoryId;
  final Value<double> monthlyLimit;
  final Value<String> currencyCode;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.monthlyLimit = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsTableCompanion.insert({
    required String id,
    required String groupId,
    required String categoryId,
    required double monthlyLimit,
    this.currencyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        categoryId = Value(categoryId),
        monthlyLimit = Value(monthlyLimit);
  static Insertable<BudgetsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? categoryId,
    Expression<double>? monthlyLimit,
    Expression<String>? currencyCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (categoryId != null) 'category_id': categoryId,
      if (monthlyLimit != null) 'monthly_limit': monthlyLimit,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? categoryId,
      Value<double>? monthlyLimit,
      Value<String>? currencyCode,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BudgetsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currencyCode: currencyCode ?? this.currencyCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (monthlyLimit.present) {
      map['monthly_limit'] = Variable<double>(monthlyLimit.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
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
    return (StringBuffer('BudgetsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthlyLimit: $monthlyLimit, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTableTable extends SavingsGoalsTable
    with TableInfo<$SavingsGoalsTableTable, SavingsGoalsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentAmountMeta =
      const VerificationMeta('currentAmount');
  @override
  late final GeneratedColumn<double> currentAmount = GeneratedColumn<double>(
      'current_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
      'target_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _iconCodeMeta =
      const VerificationMeta('iconCode');
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
      'icon_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('savings'));
  static const VerificationMeta _inflationRateMonthlyMeta =
      const VerificationMeta('inflationRateMonthly');
  @override
  late final GeneratedColumn<double> inflationRateMonthly =
      GeneratedColumn<double>('inflation_rate_monthly', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        name,
        targetAmount,
        currentAmount,
        currencyCode,
        targetDate,
        iconCode,
        inflationRateMonthly,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
      Insertable<SavingsGoalsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('current_amount')) {
      context.handle(
          _currentAmountMeta,
          currentAmount.isAcceptableOrUnknown(
              data['current_amount']!, _currentAmountMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('icon_code')) {
      context.handle(_iconCodeMeta,
          iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta));
    }
    if (data.containsKey('inflation_rate_monthly')) {
      context.handle(
          _inflationRateMonthlyMeta,
          inflationRateMonthly.isAcceptableOrUnknown(
              data['inflation_rate_monthly']!, _inflationRateMonthlyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoalsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoalsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
      currentAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_amount'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_date']),
      iconCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_code'])!,
      inflationRateMonthly: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}inflation_rate_monthly']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SavingsGoalsTableTable createAlias(String alias) {
    return $SavingsGoalsTableTable(attachedDatabase, alias);
  }
}

class SavingsGoalsTableData extends DataClass
    implements Insertable<SavingsGoalsTableData> {
  final String id;
  final String groupId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String currencyCode;
  final DateTime? targetDate;
  final String iconCode;

  /// Tasa de inflación mensual en % (ej. 4.5). NULL = ajuste desactivado.
  final double? inflationRateMonthly;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavingsGoalsTableData(
      {required this.id,
      required this.groupId,
      required this.name,
      required this.targetAmount,
      required this.currentAmount,
      required this.currencyCode,
      this.targetDate,
      required this.iconCode,
      this.inflationRateMonthly,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['target_amount'] = Variable<double>(targetAmount);
    map['current_amount'] = Variable<double>(currentAmount);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    map['icon_code'] = Variable<String>(iconCode);
    if (!nullToAbsent || inflationRateMonthly != null) {
      map['inflation_rate_monthly'] = Variable<double>(inflationRateMonthly);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavingsGoalsTableCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      currencyCode: Value(currencyCode),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      iconCode: Value(iconCode),
      inflationRateMonthly: inflationRateMonthly == null && nullToAbsent
          ? const Value.absent()
          : Value(inflationRateMonthly),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavingsGoalsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoalsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      currentAmount: serializer.fromJson<double>(json['currentAmount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      iconCode: serializer.fromJson<String>(json['iconCode']),
      inflationRateMonthly:
          serializer.fromJson<double?>(json['inflationRateMonthly']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'currentAmount': serializer.toJson<double>(currentAmount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'iconCode': serializer.toJson<String>(iconCode),
      'inflationRateMonthly': serializer.toJson<double?>(inflationRateMonthly),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavingsGoalsTableData copyWith(
          {String? id,
          String? groupId,
          String? name,
          double? targetAmount,
          double? currentAmount,
          String? currencyCode,
          Value<DateTime?> targetDate = const Value.absent(),
          String? iconCode,
          Value<double?> inflationRateMonthly = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SavingsGoalsTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        currencyCode: currencyCode ?? this.currencyCode,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        iconCode: iconCode ?? this.iconCode,
        inflationRateMonthly: inflationRateMonthly.present
            ? inflationRateMonthly.value
            : this.inflationRateMonthly,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SavingsGoalsTableData copyWithCompanion(SavingsGoalsTableCompanion data) {
    return SavingsGoalsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      currentAmount: data.currentAmount.present
          ? data.currentAmount.value
          : this.currentAmount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      inflationRateMonthly: data.inflationRateMonthly.present
          ? data.inflationRateMonthly.value
          : this.inflationRateMonthly,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('targetDate: $targetDate, ')
          ..write('iconCode: $iconCode, ')
          ..write('inflationRateMonthly: $inflationRateMonthly, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      name,
      targetAmount,
      currentAmount,
      currencyCode,
      targetDate,
      iconCode,
      inflationRateMonthly,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoalsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.targetAmount == this.targetAmount &&
          other.currentAmount == this.currentAmount &&
          other.currencyCode == this.currencyCode &&
          other.targetDate == this.targetDate &&
          other.iconCode == this.iconCode &&
          other.inflationRateMonthly == this.inflationRateMonthly &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavingsGoalsTableCompanion
    extends UpdateCompanion<SavingsGoalsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<double> targetAmount;
  final Value<double> currentAmount;
  final Value<String> currencyCode;
  final Value<DateTime?> targetDate;
  final Value<String> iconCode;
  final Value<double?> inflationRateMonthly;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavingsGoalsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.currentAmount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.inflationRateMonthly = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsTableCompanion.insert({
    required String id,
    required String groupId,
    required String name,
    required double targetAmount,
    this.currentAmount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.inflationRateMonthly = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        name = Value(name),
        targetAmount = Value(targetAmount);
  static Insertable<SavingsGoalsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<double>? targetAmount,
    Expression<double>? currentAmount,
    Expression<String>? currencyCode,
    Expression<DateTime>? targetDate,
    Expression<String>? iconCode,
    Expression<double>? inflationRateMonthly,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (targetDate != null) 'target_date': targetDate,
      if (iconCode != null) 'icon_code': iconCode,
      if (inflationRateMonthly != null)
        'inflation_rate_monthly': inflationRateMonthly,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? name,
      Value<double>? targetAmount,
      Value<double>? currentAmount,
      Value<String>? currencyCode,
      Value<DateTime?>? targetDate,
      Value<String>? iconCode,
      Value<double?>? inflationRateMonthly,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SavingsGoalsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      targetDate: targetDate ?? this.targetDate,
      iconCode: iconCode ?? this.iconCode,
      inflationRateMonthly: inflationRateMonthly ?? this.inflationRateMonthly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (currentAmount.present) {
      map['current_amount'] = Variable<double>(currentAmount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (inflationRateMonthly.present) {
      map['inflation_rate_monthly'] =
          Variable<double>(inflationRateMonthly.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('SavingsGoalsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('targetDate: $targetDate, ')
          ..write('iconCode: $iconCode, ')
          ..write('inflationRateMonthly: $inflationRateMonthly, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyGroupsTableTable extends FamilyGroupsTable
    with TableInfo<$FamilyGroupsTableTable, FamilyGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inviteCodeMeta =
      const VerificationMeta('inviteCode');
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
      'invite_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, ownerId, inviteCode, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_groups';
  @override
  VerificationContext validateIntegrity(
      Insertable<FamilyGroupsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('invite_code')) {
      context.handle(
          _inviteCodeMeta,
          inviteCode.isAcceptableOrUnknown(
              data['invite_code']!, _inviteCodeMeta));
    } else if (isInserting) {
      context.missing(_inviteCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyGroupsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      inviteCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invite_code'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FamilyGroupsTableTable createAlias(String alias) {
    return $FamilyGroupsTableTable(attachedDatabase, alias);
  }
}

class FamilyGroupsTableData extends DataClass
    implements Insertable<FamilyGroupsTableData> {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final DateTime createdAt;
  const FamilyGroupsTableData(
      {required this.id,
      required this.name,
      required this.ownerId,
      required this.inviteCode,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_id'] = Variable<String>(ownerId);
    map['invite_code'] = Variable<String>(inviteCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FamilyGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return FamilyGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      ownerId: Value(ownerId),
      inviteCode: Value(inviteCode),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyGroupsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyGroupsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      inviteCode: serializer.fromJson<String>(json['inviteCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerId': serializer.toJson<String>(ownerId),
      'inviteCode': serializer.toJson<String>(inviteCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FamilyGroupsTableData copyWith(
          {String? id,
          String? name,
          String? ownerId,
          String? inviteCode,
          DateTime? createdAt}) =>
      FamilyGroupsTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
        inviteCode: inviteCode ?? this.inviteCode,
        createdAt: createdAt ?? this.createdAt,
      );
  FamilyGroupsTableData copyWithCompanion(FamilyGroupsTableCompanion data) {
    return FamilyGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      inviteCode:
          data.inviteCode.present ? data.inviteCode.value : this.inviteCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, ownerId, inviteCode, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerId == this.ownerId &&
          other.inviteCode == this.inviteCode &&
          other.createdAt == this.createdAt);
}

class FamilyGroupsTableCompanion
    extends UpdateCompanion<FamilyGroupsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerId;
  final Value<String> inviteCode;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FamilyGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyGroupsTableCompanion.insert({
    required String id,
    required String name,
    required String ownerId,
    required String inviteCode,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        ownerId = Value(ownerId),
        inviteCode = Value(inviteCode);
  static Insertable<FamilyGroupsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerId,
    Expression<String>? inviteCode,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyGroupsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? ownerId,
      Value<String>? inviteCode,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FamilyGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTableTable extends GroupMembersTable
    with TableInfo<$GroupMembersTableTable, GroupMembersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('member'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _joinedAtMeta =
      const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
      'joined_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, groupId, userId, role, displayName, email, joinedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
      Insertable<GroupMembersTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(_joinedAtMeta,
          joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupMembersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMembersTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      joinedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}joined_at'])!,
    );
  }

  @override
  $GroupMembersTableTable createAlias(String alias) {
    return $GroupMembersTableTable(attachedDatabase, alias);
  }
}

class GroupMembersTableData extends DataClass
    implements Insertable<GroupMembersTableData> {
  final String id;
  final String groupId;
  final String userId;

  /// 'owner' | 'member'
  final String role;
  final String? displayName;
  final String? email;
  final DateTime joinedAt;
  const GroupMembersTableData(
      {required this.id,
      required this.groupId,
      required this.userId,
      required this.role,
      this.displayName,
      this.email,
      required this.joinedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['joined_at'] = Variable<DateTime>(joinedAt);
    return map;
  }

  GroupMembersTableCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      userId: Value(userId),
      role: Value(role),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      joinedAt: Value(joinedAt),
    );
  }

  factory GroupMembersTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMembersTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      email: serializer.fromJson<String?>(json['email']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'displayName': serializer.toJson<String?>(displayName),
      'email': serializer.toJson<String?>(email),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
    };
  }

  GroupMembersTableData copyWith(
          {String? id,
          String? groupId,
          String? userId,
          String? role,
          Value<String?> displayName = const Value.absent(),
          Value<String?> email = const Value.absent(),
          DateTime? joinedAt}) =>
      GroupMembersTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        displayName: displayName.present ? displayName.value : this.displayName,
        email: email.present ? email.value : this.email,
        joinedAt: joinedAt ?? this.joinedAt,
      );
  GroupMembersTableData copyWithCompanion(GroupMembersTableCompanion data) {
    return GroupMembersTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, userId, role, displayName, email, joinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMembersTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.joinedAt == this.joinedAt);
}

class GroupMembersTableCompanion
    extends UpdateCompanion<GroupMembersTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String?> displayName;
  final Value<String?> email;
  final Value<DateTime> joinedAt;
  final Value<int> rowid;
  const GroupMembersTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersTableCompanion.insert({
    required String id,
    required String groupId,
    required String userId,
    this.role = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        userId = Value(userId);
  static Insertable<GroupMembersTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<DateTime>? joinedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? userId,
      Value<String>? role,
      Value<String?>? displayName,
      Value<String?>? email,
      Value<DateTime>? joinedAt,
      Value<int>? rowid}) {
    return GroupMembersTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      joinedAt: joinedAt ?? this.joinedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringTransactionsTableTable extends RecurringTransactionsTable
    with
        TableInfo<$RecurringTransactionsTableTable,
            RecurringTransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayOfMonthMeta =
      const VerificationMeta('dayOfMonth');
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
      'day_of_month', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextDueDateMeta =
      const VerificationMeta('nextDueDate');
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
      'next_due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        userId,
        categoryId,
        amount,
        currencyCode,
        type,
        description,
        frequency,
        dayOfMonth,
        nextDueDate,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecurringTransactionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
          _dayOfMonthMeta,
          dayOfMonth.isAcceptableOrUnknown(
              data['day_of_month']!, _dayOfMonthMeta));
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
          _nextDueDateMeta,
          nextDueDate.isAcceptableOrUnknown(
              data['next_due_date']!, _nextDueDateMeta));
    } else if (isInserting) {
      context.missing(_nextDueDateMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTransactionsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTransactionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      dayOfMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_month']),
      nextDueDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_due_date'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurringTransactionsTableTable createAlias(String alias) {
    return $RecurringTransactionsTableTable(attachedDatabase, alias);
  }
}

class RecurringTransactionsTableData extends DataClass
    implements Insertable<RecurringTransactionsTableData> {
  final String id;
  final String groupId;
  final String userId;
  final String? categoryId;
  final double amount;
  final String currencyCode;

  /// 'income' | 'expense'
  final String type;
  final String? description;

  /// 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly'
  final String frequency;

  /// Para frecuencia mensual: día del mes en que se genera (1–28).
  /// null = usar el día de next_due_date.
  final int? dayOfMonth;

  /// Próxima fecha en que debe generarse la transacción.
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;
  const RecurringTransactionsTableData(
      {required this.id,
      required this.groupId,
      required this.userId,
      this.categoryId,
      required this.amount,
      required this.currencyCode,
      required this.type,
      this.description,
      required this.frequency,
      this.dayOfMonth,
      required this.nextDueDate,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount'] = Variable<double>(amount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    map['next_due_date'] = Variable<DateTime>(nextDueDate);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurringTransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return RecurringTransactionsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      userId: Value(userId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      frequency: Value(frequency),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      nextDueDate: Value(nextDueDate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringTransactionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amount: serializer.fromJson<double>(json['amount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      frequency: serializer.fromJson<String>(json['frequency']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      nextDueDate: serializer.fromJson<DateTime>(json['nextDueDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amount': serializer.toJson<double>(amount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String?>(description),
      'frequency': serializer.toJson<String>(frequency),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'nextDueDate': serializer.toJson<DateTime>(nextDueDate),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringTransactionsTableData copyWith(
          {String? id,
          String? groupId,
          String? userId,
          Value<String?> categoryId = const Value.absent(),
          double? amount,
          String? currencyCode,
          String? type,
          Value<String?> description = const Value.absent(),
          String? frequency,
          Value<int?> dayOfMonth = const Value.absent(),
          DateTime? nextDueDate,
          bool? isActive,
          DateTime? createdAt}) =>
      RecurringTransactionsTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        currencyCode: currencyCode ?? this.currencyCode,
        type: type ?? this.type,
        description: description.present ? description.value : this.description,
        frequency: frequency ?? this.frequency,
        dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  RecurringTransactionsTableData copyWithCompanion(
      RecurringTransactionsTableCompanion data) {
    return RecurringTransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      type: data.type.present ? data.type.value : this.type,
      description:
          data.description.present ? data.description.value : this.description,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      dayOfMonth:
          data.dayOfMonth.present ? data.dayOfMonth.value : this.dayOfMonth,
      nextDueDate:
          data.nextDueDate.present ? data.nextDueDate.value : this.nextDueDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransactionsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      userId,
      categoryId,
      amount,
      currencyCode,
      type,
      description,
      frequency,
      dayOfMonth,
      nextDueDate,
      isActive,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTransactionsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currencyCode == this.currencyCode &&
          other.type == this.type &&
          other.description == this.description &&
          other.frequency == this.frequency &&
          other.dayOfMonth == this.dayOfMonth &&
          other.nextDueDate == this.nextDueDate &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class RecurringTransactionsTableCompanion
    extends UpdateCompanion<RecurringTransactionsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String?> categoryId;
  final Value<double> amount;
  final Value<String> currencyCode;
  final Value<String> type;
  final Value<String?> description;
  final Value<String> frequency;
  final Value<int?> dayOfMonth;
  final Value<DateTime> nextDueDate;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RecurringTransactionsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.frequency = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringTransactionsTableCompanion.insert({
    required String id,
    required String groupId,
    required String userId,
    this.categoryId = const Value.absent(),
    required double amount,
    this.currencyCode = const Value.absent(),
    required String type,
    this.description = const Value.absent(),
    required String frequency,
    this.dayOfMonth = const Value.absent(),
    required DateTime nextDueDate,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        userId = Value(userId),
        amount = Value(amount),
        type = Value(type),
        frequency = Value(frequency),
        nextDueDate = Value(nextDueDate);
  static Insertable<RecurringTransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? categoryId,
    Expression<double>? amount,
    Expression<String>? currencyCode,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? frequency,
    Expression<int>? dayOfMonth,
    Expression<DateTime>? nextDueDate,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (frequency != null) 'frequency': frequency,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringTransactionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? userId,
      Value<String?>? categoryId,
      Value<double>? amount,
      Value<String>? currencyCode,
      Value<String>? type,
      Value<String?>? description,
      Value<String>? frequency,
      Value<int?>? dayOfMonth,
      Value<DateTime>? nextDueDate,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RecurringTransactionsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      type: type ?? this.type,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentsTableTable extends InvestmentsTable
    with TableInfo<$InvestmentsTableTable, InvestmentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _initialAmountMeta =
      const VerificationMeta('initialAmount');
  @override
  late final GeneratedColumn<double> initialAmount = GeneratedColumn<double>(
      'initial_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentValueMeta =
      const VerificationMeta('currentValue');
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
      'current_value', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _maturityDateMeta =
      const VerificationMeta('maturityDate');
  @override
  late final GeneratedColumn<DateTime> maturityDate = GeneratedColumn<DateTime>(
      'maturity_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _institutionMeta =
      const VerificationMeta('institution');
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
      'institution', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        userId,
        name,
        type,
        initialAmount,
        currentValue,
        currencyCode,
        startDate,
        maturityDate,
        institution,
        notes,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investments';
  @override
  VerificationContext validateIntegrity(
      Insertable<InvestmentsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('initial_amount')) {
      context.handle(
          _initialAmountMeta,
          initialAmount.isAcceptableOrUnknown(
              data['initial_amount']!, _initialAmountMeta));
    } else if (isInserting) {
      context.missing(_initialAmountMeta);
    }
    if (data.containsKey('current_value')) {
      context.handle(
          _currentValueMeta,
          currentValue.isAcceptableOrUnknown(
              data['current_value']!, _currentValueMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('maturity_date')) {
      context.handle(
          _maturityDateMeta,
          maturityDate.isAcceptableOrUnknown(
              data['maturity_date']!, _maturityDateMeta));
    }
    if (data.containsKey('institution')) {
      context.handle(
          _institutionMeta,
          institution.isAcceptableOrUnknown(
              data['institution']!, _institutionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvestmentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      initialAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}initial_amount'])!,
      currentValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_value']),
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      maturityDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}maturity_date']),
      institution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}institution']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $InvestmentsTableTable createAlias(String alias) {
    return $InvestmentsTableTable(attachedDatabase, alias);
  }
}

class InvestmentsTableData extends DataClass
    implements Insertable<InvestmentsTableData> {
  final String id;
  final String groupId;
  final String userId;
  final String name;
  final String type;
  final double initialAmount;
  final double? currentValue;
  final String currencyCode;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final String? institution;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InvestmentsTableData(
      {required this.id,
      required this.groupId,
      required this.userId,
      required this.name,
      required this.type,
      required this.initialAmount,
      this.currentValue,
      required this.currencyCode,
      this.startDate,
      this.maturityDate,
      this.institution,
      this.notes,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['initial_amount'] = Variable<double>(initialAmount);
    if (!nullToAbsent || currentValue != null) {
      map['current_value'] = Variable<double>(currentValue);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || maturityDate != null) {
      map['maturity_date'] = Variable<DateTime>(maturityDate);
    }
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InvestmentsTableCompanion toCompanion(bool nullToAbsent) {
    return InvestmentsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      initialAmount: Value(initialAmount),
      currentValue: currentValue == null && nullToAbsent
          ? const Value.absent()
          : Value(currentValue),
      currencyCode: Value(currencyCode),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      maturityDate: maturityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maturityDate),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InvestmentsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      initialAmount: serializer.fromJson<double>(json['initialAmount']),
      currentValue: serializer.fromJson<double?>(json['currentValue']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      maturityDate: serializer.fromJson<DateTime?>(json['maturityDate']),
      institution: serializer.fromJson<String?>(json['institution']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'initialAmount': serializer.toJson<double>(initialAmount),
      'currentValue': serializer.toJson<double?>(currentValue),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'maturityDate': serializer.toJson<DateTime?>(maturityDate),
      'institution': serializer.toJson<String?>(institution),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InvestmentsTableData copyWith(
          {String? id,
          String? groupId,
          String? userId,
          String? name,
          String? type,
          double? initialAmount,
          Value<double?> currentValue = const Value.absent(),
          String? currencyCode,
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> maturityDate = const Value.absent(),
          Value<String?> institution = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      InvestmentsTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        initialAmount: initialAmount ?? this.initialAmount,
        currentValue:
            currentValue.present ? currentValue.value : this.currentValue,
        currencyCode: currencyCode ?? this.currencyCode,
        startDate: startDate.present ? startDate.value : this.startDate,
        maturityDate:
            maturityDate.present ? maturityDate.value : this.maturityDate,
        institution: institution.present ? institution.value : this.institution,
        notes: notes.present ? notes.value : this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  InvestmentsTableData copyWithCompanion(InvestmentsTableCompanion data) {
    return InvestmentsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      initialAmount: data.initialAmount.present
          ? data.initialAmount.value
          : this.initialAmount,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      maturityDate: data.maturityDate.present
          ? data.maturityDate.value
          : this.maturityDate,
      institution:
          data.institution.present ? data.institution.value : this.institution,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialAmount: $initialAmount, ')
          ..write('currentValue: $currentValue, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('institution: $institution, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      userId,
      name,
      type,
      initialAmount,
      currentValue,
      currencyCode,
      startDate,
      maturityDate,
      institution,
      notes,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.initialAmount == this.initialAmount &&
          other.currentValue == this.currentValue &&
          other.currencyCode == this.currencyCode &&
          other.startDate == this.startDate &&
          other.maturityDate == this.maturityDate &&
          other.institution == this.institution &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InvestmentsTableCompanion extends UpdateCompanion<InvestmentsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<double> initialAmount;
  final Value<double?> currentValue;
  final Value<String> currencyCode;
  final Value<DateTime?> startDate;
  final Value<DateTime?> maturityDate;
  final Value<String?> institution;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InvestmentsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.initialAmount = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.institution = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentsTableCompanion.insert({
    required String id,
    required String groupId,
    required String userId,
    required String name,
    this.type = const Value.absent(),
    required double initialAmount,
    this.currentValue = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.institution = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        userId = Value(userId),
        name = Value(name),
        initialAmount = Value(initialAmount);
  static Insertable<InvestmentsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? initialAmount,
    Expression<double>? currentValue,
    Expression<String>? currencyCode,
    Expression<DateTime>? startDate,
    Expression<DateTime>? maturityDate,
    Expression<String>? institution,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (initialAmount != null) 'initial_amount': initialAmount,
      if (currentValue != null) 'current_value': currentValue,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (startDate != null) 'start_date': startDate,
      if (maturityDate != null) 'maturity_date': maturityDate,
      if (institution != null) 'institution': institution,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? type,
      Value<double>? initialAmount,
      Value<double?>? currentValue,
      Value<String>? currencyCode,
      Value<DateTime?>? startDate,
      Value<DateTime?>? maturityDate,
      Value<String?>? institution,
      Value<String?>? notes,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return InvestmentsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialAmount: initialAmount ?? this.initialAmount,
      currentValue: currentValue ?? this.currentValue,
      currencyCode: currencyCode ?? this.currencyCode,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      institution: institution ?? this.institution,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (initialAmount.present) {
      map['initial_amount'] = Variable<double>(initialAmount.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (maturityDate.present) {
      map['maturity_date'] = Variable<DateTime>(maturityDate.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('InvestmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialAmount: $initialAmount, ')
          ..write('currentValue: $currentValue, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('institution: $institution, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VirtualEnvelopesTableTable extends VirtualEnvelopesTable
    with TableInfo<$VirtualEnvelopesTableTable, VirtualEnvelopesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VirtualEnvelopesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _allocatedAmountMeta =
      const VerificationMeta('allocatedAmount');
  @override
  late final GeneratedColumn<double> allocatedAmount = GeneratedColumn<double>(
      'allocated_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _spentAmountMeta =
      const VerificationMeta('spentAmount');
  @override
  late final GeneratedColumn<double> spentAmount = GeneratedColumn<double>(
      'spent_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('USD'));
  static const VerificationMeta _periodStartMeta =
      const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
      'period_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _periodEndMeta =
      const VerificationMeta('periodEnd');
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
      'period_end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        categoryId,
        name,
        allocatedAmount,
        spentAmount,
        currencyCode,
        periodStart,
        periodEnd,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'virtual_envelopes';
  @override
  VerificationContext validateIntegrity(
      Insertable<VirtualEnvelopesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('allocated_amount')) {
      context.handle(
          _allocatedAmountMeta,
          allocatedAmount.isAcceptableOrUnknown(
              data['allocated_amount']!, _allocatedAmountMeta));
    } else if (isInserting) {
      context.missing(_allocatedAmountMeta);
    }
    if (data.containsKey('spent_amount')) {
      context.handle(
          _spentAmountMeta,
          spentAmount.isAcceptableOrUnknown(
              data['spent_amount']!, _spentAmountMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('period_start')) {
      context.handle(
          _periodStartMeta,
          periodStart.isAcceptableOrUnknown(
              data['period_start']!, _periodStartMeta));
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(_periodEndMeta,
          periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta));
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VirtualEnvelopesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VirtualEnvelopesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      allocatedAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}allocated_amount'])!,
      spentAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}spent_amount'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      periodStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}period_start'])!,
      periodEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}period_end'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VirtualEnvelopesTableTable createAlias(String alias) {
    return $VirtualEnvelopesTableTable(attachedDatabase, alias);
  }
}

class VirtualEnvelopesTableData extends DataClass
    implements Insertable<VirtualEnvelopesTableData> {
  final String id;
  final String groupId;
  final String? categoryId;
  final String name;
  final double allocatedAmount;
  final double spentAmount;
  final String currencyCode;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VirtualEnvelopesTableData(
      {required this.id,
      required this.groupId,
      this.categoryId,
      required this.name,
      required this.allocatedAmount,
      required this.spentAmount,
      required this.currencyCode,
      required this.periodStart,
      required this.periodEnd,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['name'] = Variable<String>(name);
    map['allocated_amount'] = Variable<double>(allocatedAmount);
    map['spent_amount'] = Variable<double>(spentAmount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VirtualEnvelopesTableCompanion toCompanion(bool nullToAbsent) {
    return VirtualEnvelopesTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      allocatedAmount: Value(allocatedAmount),
      spentAmount: Value(spentAmount),
      currencyCode: Value(currencyCode),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VirtualEnvelopesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VirtualEnvelopesTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      allocatedAmount: serializer.fromJson<double>(json['allocatedAmount']),
      spentAmount: serializer.fromJson<double>(json['spentAmount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'name': serializer.toJson<String>(name),
      'allocatedAmount': serializer.toJson<double>(allocatedAmount),
      'spentAmount': serializer.toJson<double>(spentAmount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VirtualEnvelopesTableData copyWith(
          {String? id,
          String? groupId,
          Value<String?> categoryId = const Value.absent(),
          String? name,
          double? allocatedAmount,
          double? spentAmount,
          String? currencyCode,
          DateTime? periodStart,
          DateTime? periodEnd,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      VirtualEnvelopesTableData(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        name: name ?? this.name,
        allocatedAmount: allocatedAmount ?? this.allocatedAmount,
        spentAmount: spentAmount ?? this.spentAmount,
        currencyCode: currencyCode ?? this.currencyCode,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  VirtualEnvelopesTableData copyWithCompanion(
      VirtualEnvelopesTableCompanion data) {
    return VirtualEnvelopesTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      allocatedAmount: data.allocatedAmount.present
          ? data.allocatedAmount.value
          : this.allocatedAmount,
      spentAmount:
          data.spentAmount.present ? data.spentAmount.value : this.spentAmount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VirtualEnvelopesTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('allocatedAmount: $allocatedAmount, ')
          ..write('spentAmount: $spentAmount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      categoryId,
      name,
      allocatedAmount,
      spentAmount,
      currencyCode,
      periodStart,
      periodEnd,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualEnvelopesTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.allocatedAmount == this.allocatedAmount &&
          other.spentAmount == this.spentAmount &&
          other.currencyCode == this.currencyCode &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VirtualEnvelopesTableCompanion
    extends UpdateCompanion<VirtualEnvelopesTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String?> categoryId;
  final Value<String> name;
  final Value<double> allocatedAmount;
  final Value<double> spentAmount;
  final Value<String> currencyCode;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VirtualEnvelopesTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.allocatedAmount = const Value.absent(),
    this.spentAmount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VirtualEnvelopesTableCompanion.insert({
    required String id,
    required String groupId,
    this.categoryId = const Value.absent(),
    required String name,
    required double allocatedAmount,
    this.spentAmount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required DateTime periodStart,
    required DateTime periodEnd,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        name = Value(name),
        allocatedAmount = Value(allocatedAmount),
        periodStart = Value(periodStart),
        periodEnd = Value(periodEnd);
  static Insertable<VirtualEnvelopesTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<double>? allocatedAmount,
    Expression<double>? spentAmount,
    Expression<String>? currencyCode,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (allocatedAmount != null) 'allocated_amount': allocatedAmount,
      if (spentAmount != null) 'spent_amount': spentAmount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VirtualEnvelopesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String?>? categoryId,
      Value<String>? name,
      Value<double>? allocatedAmount,
      Value<double>? spentAmount,
      Value<String>? currencyCode,
      Value<DateTime>? periodStart,
      Value<DateTime>? periodEnd,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VirtualEnvelopesTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (allocatedAmount.present) {
      map['allocated_amount'] = Variable<double>(allocatedAmount.value);
    }
    if (spentAmount.present) {
      map['spent_amount'] = Variable<double>(spentAmount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('VirtualEnvelopesTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('allocatedAmount: $allocatedAmount, ')
          ..write('spentAmount: $spentAmount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTableTable accountsTable = $AccountsTableTable(this);
  late final $CategoriesTableTable categoriesTable =
      $CategoriesTableTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $ExchangeRatesTableTable exchangeRatesTable =
      $ExchangeRatesTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $BudgetsTableTable budgetsTable = $BudgetsTableTable(this);
  late final $SavingsGoalsTableTable savingsGoalsTable =
      $SavingsGoalsTableTable(this);
  late final $FamilyGroupsTableTable familyGroupsTable =
      $FamilyGroupsTableTable(this);
  late final $GroupMembersTableTable groupMembersTable =
      $GroupMembersTableTable(this);
  late final $RecurringTransactionsTableTable recurringTransactionsTable =
      $RecurringTransactionsTableTable(this);
  late final $InvestmentsTableTable investmentsTable =
      $InvestmentsTableTable(this);
  late final $VirtualEnvelopesTableTable virtualEnvelopesTable =
      $VirtualEnvelopesTableTable(this);
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final BudgetsDao budgetsDao = BudgetsDao(this as AppDatabase);
  late final SavingsGoalsDao savingsGoalsDao =
      SavingsGoalsDao(this as AppDatabase);
  late final FamilyGroupsDao familyGroupsDao =
      FamilyGroupsDao(this as AppDatabase);
  late final RecurringTransactionsDao recurringTransactionsDao =
      RecurringTransactionsDao(this as AppDatabase);
  late final InvestmentsDao investmentsDao =
      InvestmentsDao(this as AppDatabase);
  late final VirtualEnvelopesDao virtualEnvelopesDao =
      VirtualEnvelopesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accountsTable,
        categoriesTable,
        transactionsTable,
        exchangeRatesTable,
        syncQueueTable,
        budgetsTable,
        savingsGoalsTable,
        familyGroupsTable,
        groupMembersTable,
        recurringTransactionsTable,
        investmentsTable,
        virtualEnvelopesTable
      ];
}

typedef $$AccountsTableTableCreateCompanionBuilder = AccountsTableCompanion
    Function({
  required String id,
  required String groupId,
  Value<String> type,
  required String name,
  required String currencyCode,
  Value<double> initialBalance,
  Value<String> colorHex,
  Value<String> iconCode,
  Value<bool> isArchived,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AccountsTableTableUpdateCompanionBuilder = AccountsTableCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> type,
  Value<String> name,
  Value<String> currencyCode,
  Value<double> initialBalance,
  Value<String> colorHex,
  Value<String> iconCode,
  Value<bool> isArchived,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AccountsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTableTable,
    AccountsTableData,
    $$AccountsTableTableFilterComposer,
    $$AccountsTableTableOrderingComposer,
    $$AccountsTableTableAnnotationComposer,
    $$AccountsTableTableCreateCompanionBuilder,
    $$AccountsTableTableUpdateCompanionBuilder,
    (
      AccountsTableData,
      BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>
    ),
    AccountsTableData,
    PrefetchHooks Function()> {
  $$AccountsTableTableTableManager(_$AppDatabase db, $AccountsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<double> initialBalance = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> iconCode = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsTableCompanion(
            id: id,
            groupId: groupId,
            type: type,
            name: name,
            currencyCode: currencyCode,
            initialBalance: initialBalance,
            colorHex: colorHex,
            iconCode: iconCode,
            isArchived: isArchived,
            isSynced: isSynced,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            Value<String> type = const Value.absent(),
            required String name,
            required String currencyCode,
            Value<double> initialBalance = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> iconCode = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsTableCompanion.insert(
            id: id,
            groupId: groupId,
            type: type,
            name: name,
            currencyCode: currencyCode,
            initialBalance: initialBalance,
            colorHex: colorHex,
            iconCode: iconCode,
            isArchived: isArchived,
            isSynced: isSynced,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTableTable,
    AccountsTableData,
    $$AccountsTableTableFilterComposer,
    $$AccountsTableTableOrderingComposer,
    $$AccountsTableTableAnnotationComposer,
    $$AccountsTableTableCreateCompanionBuilder,
    $$AccountsTableTableUpdateCompanionBuilder,
    (
      AccountsTableData,
      BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>
    ),
    AccountsTableData,
    PrefetchHooks Function()>;
typedef $$CategoriesTableTableCreateCompanionBuilder = CategoriesTableCompanion
    Function({
  required String id,
  Value<String?> groupId,
  required String name,
  required String iconCode,
  required String colorHex,
  required String type,
  Value<bool> isSystem,
  Value<int> sortOrder,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$CategoriesTableTableUpdateCompanionBuilder = CategoriesTableCompanion
    Function({
  Value<String> id,
  Value<String?> groupId,
  Value<String> name,
  Value<String> iconCode,
  Value<String> colorHex,
  Value<String> type,
  Value<bool> isSystem,
  Value<int> sortOrder,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    CategoriesTableData,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (
      CategoriesTableData,
      BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoriesTableData>
    ),
    CategoriesTableData,
    PrefetchHooks Function()> {
  $$CategoriesTableTableTableManager(
      _$AppDatabase db, $CategoriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> iconCode = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion(
            id: id,
            groupId: groupId,
            name: name,
            iconCode: iconCode,
            colorHex: colorHex,
            type: type,
            isSystem: isSystem,
            sortOrder: sortOrder,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> groupId = const Value.absent(),
            required String name,
            required String iconCode,
            required String colorHex,
            required String type,
            Value<bool> isSystem = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion.insert(
            id: id,
            groupId: groupId,
            name: name,
            iconCode: iconCode,
            colorHex: colorHex,
            type: type,
            isSystem: isSystem,
            sortOrder: sortOrder,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    CategoriesTableData,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (
      CategoriesTableData,
      BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoriesTableData>
    ),
    CategoriesTableData,
    PrefetchHooks Function()>;
typedef $$TransactionsTableTableCreateCompanionBuilder
    = TransactionsTableCompanion Function({
  required String id,
  required String groupId,
  required String userId,
  Value<String?> categoryId,
  required double amount,
  required String currencyCode,
  Value<double?> amountUsdEquivalent,
  Value<String?> exchangeRateId,
  required String type,
  required DateTime date,
  Value<String?> description,
  Value<String?> paymentMethod,
  Value<String?> notes,
  Value<String?> linkedTxId,
  Value<String?> accountId,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$TransactionsTableTableUpdateCompanionBuilder
    = TransactionsTableCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> userId,
  Value<String?> categoryId,
  Value<double> amount,
  Value<String> currencyCode,
  Value<double?> amountUsdEquivalent,
  Value<String?> exchangeRateId,
  Value<String> type,
  Value<DateTime> date,
  Value<String?> description,
  Value<String?> paymentMethod,
  Value<String?> notes,
  Value<String?> linkedTxId,
  Value<String?> accountId,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountUsdEquivalent => $composableBuilder(
      column: $table.amountUsdEquivalent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exchangeRateId => $composableBuilder(
      column: $table.exchangeRateId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedTxId => $composableBuilder(
      column: $table.linkedTxId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountUsdEquivalent => $composableBuilder(
      column: $table.amountUsdEquivalent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exchangeRateId => $composableBuilder(
      column: $table.exchangeRateId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedTxId => $composableBuilder(
      column: $table.linkedTxId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<double> get amountUsdEquivalent => $composableBuilder(
      column: $table.amountUsdEquivalent, builder: (column) => column);

  GeneratedColumn<String> get exchangeRateId => $composableBuilder(
      column: $table.exchangeRateId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get linkedTxId => $composableBuilder(
      column: $table.linkedTxId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTableTable,
    TransactionsTableData,
    $$TransactionsTableTableFilterComposer,
    $$TransactionsTableTableOrderingComposer,
    $$TransactionsTableTableAnnotationComposer,
    $$TransactionsTableTableCreateCompanionBuilder,
    $$TransactionsTableTableUpdateCompanionBuilder,
    (
      TransactionsTableData,
      BaseReferences<_$AppDatabase, $TransactionsTableTable,
          TransactionsTableData>
    ),
    TransactionsTableData,
    PrefetchHooks Function()> {
  $$TransactionsTableTableTableManager(
      _$AppDatabase db, $TransactionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<double?> amountUsdEquivalent = const Value.absent(),
            Value<String?> exchangeRateId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> linkedTxId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsTableCompanion(
            id: id,
            groupId: groupId,
            userId: userId,
            categoryId: categoryId,
            amount: amount,
            currencyCode: currencyCode,
            amountUsdEquivalent: amountUsdEquivalent,
            exchangeRateId: exchangeRateId,
            type: type,
            date: date,
            description: description,
            paymentMethod: paymentMethod,
            notes: notes,
            linkedTxId: linkedTxId,
            accountId: accountId,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String userId,
            Value<String?> categoryId = const Value.absent(),
            required double amount,
            required String currencyCode,
            Value<double?> amountUsdEquivalent = const Value.absent(),
            Value<String?> exchangeRateId = const Value.absent(),
            required String type,
            required DateTime date,
            Value<String?> description = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> linkedTxId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsTableCompanion.insert(
            id: id,
            groupId: groupId,
            userId: userId,
            categoryId: categoryId,
            amount: amount,
            currencyCode: currencyCode,
            amountUsdEquivalent: amountUsdEquivalent,
            exchangeRateId: exchangeRateId,
            type: type,
            date: date,
            description: description,
            paymentMethod: paymentMethod,
            notes: notes,
            linkedTxId: linkedTxId,
            accountId: accountId,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTableTable,
    TransactionsTableData,
    $$TransactionsTableTableFilterComposer,
    $$TransactionsTableTableOrderingComposer,
    $$TransactionsTableTableAnnotationComposer,
    $$TransactionsTableTableCreateCompanionBuilder,
    $$TransactionsTableTableUpdateCompanionBuilder,
    (
      TransactionsTableData,
      BaseReferences<_$AppDatabase, $TransactionsTableTable,
          TransactionsTableData>
    ),
    TransactionsTableData,
    PrefetchHooks Function()>;
typedef $$ExchangeRatesTableTableCreateCompanionBuilder
    = ExchangeRatesTableCompanion Function({
  required String id,
  required String fromCurrency,
  required String toCurrency,
  required double rate,
  required String rateType,
  Value<String?> source,
  required DateTime validAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ExchangeRatesTableTableUpdateCompanionBuilder
    = ExchangeRatesTableCompanion Function({
  Value<String> id,
  Value<String> fromCurrency,
  Value<String> toCurrency,
  Value<double> rate,
  Value<String> rateType,
  Value<String?> source,
  Value<DateTime> validAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ExchangeRatesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTableTable> {
  $$ExchangeRatesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rateType => $composableBuilder(
      column: $table.rateType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get validAt => $composableBuilder(
      column: $table.validAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ExchangeRatesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTableTable> {
  $$ExchangeRatesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rateType => $composableBuilder(
      column: $table.rateType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get validAt => $composableBuilder(
      column: $table.validAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExchangeRatesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTableTable> {
  $$ExchangeRatesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromCurrency => $composableBuilder(
      column: $table.fromCurrency, builder: (column) => column);

  GeneratedColumn<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<String> get rateType =>
      $composableBuilder(column: $table.rateType, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get validAt =>
      $composableBuilder(column: $table.validAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExchangeRatesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExchangeRatesTableTable,
    ExchangeRatesTableData,
    $$ExchangeRatesTableTableFilterComposer,
    $$ExchangeRatesTableTableOrderingComposer,
    $$ExchangeRatesTableTableAnnotationComposer,
    $$ExchangeRatesTableTableCreateCompanionBuilder,
    $$ExchangeRatesTableTableUpdateCompanionBuilder,
    (
      ExchangeRatesTableData,
      BaseReferences<_$AppDatabase, $ExchangeRatesTableTable,
          ExchangeRatesTableData>
    ),
    ExchangeRatesTableData,
    PrefetchHooks Function()> {
  $$ExchangeRatesTableTableTableManager(
      _$AppDatabase db, $ExchangeRatesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fromCurrency = const Value.absent(),
            Value<String> toCurrency = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<String> rateType = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<DateTime> validAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeRatesTableCompanion(
            id: id,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            rateType: rateType,
            source: source,
            validAt: validAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fromCurrency,
            required String toCurrency,
            required double rate,
            required String rateType,
            Value<String?> source = const Value.absent(),
            required DateTime validAt,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeRatesTableCompanion.insert(
            id: id,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            rateType: rateType,
            source: source,
            validAt: validAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExchangeRatesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExchangeRatesTableTable,
    ExchangeRatesTableData,
    $$ExchangeRatesTableTableFilterComposer,
    $$ExchangeRatesTableTableOrderingComposer,
    $$ExchangeRatesTableTableAnnotationComposer,
    $$ExchangeRatesTableTableCreateCompanionBuilder,
    $$ExchangeRatesTableTableUpdateCompanionBuilder,
    (
      ExchangeRatesTableData,
      BaseReferences<_$AppDatabase, $ExchangeRatesTableTable,
          ExchangeRatesTableData>
    ),
    ExchangeRatesTableData,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String tableName_,
  required String operation,
  required String recordId,
  required String payload,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<DateTime> createdAt,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> tableName_,
  Value<String> operation,
  Value<String> recordId,
  Value<String> payload,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tableName_ => $composableBuilder(
      column: $table.tableName_, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tableName_ => $composableBuilder(
      column: $table.tableName_, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tableName_ => $composableBuilder(
      column: $table.tableName_, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$AppDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tableName_ = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            tableName_: tableName_,
            operation: operation,
            recordId: recordId,
            payload: payload,
            retryCount: retryCount,
            lastError: lastError,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tableName_,
            required String operation,
            required String recordId,
            required String payload,
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            tableName_: tableName_,
            operation: operation,
            recordId: recordId,
            payload: payload,
            retryCount: retryCount,
            lastError: lastError,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;
typedef $$BudgetsTableTableCreateCompanionBuilder = BudgetsTableCompanion
    Function({
  required String id,
  required String groupId,
  required String categoryId,
  required double monthlyLimit,
  Value<String> currencyCode,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$BudgetsTableTableUpdateCompanionBuilder = BudgetsTableCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> categoryId,
  Value<double> monthlyLimit,
  Value<String> currencyCode,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BudgetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTableTable> {
  $$BudgetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get monthlyLimit => $composableBuilder(
      column: $table.monthlyLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BudgetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTableTable> {
  $$BudgetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyLimit => $composableBuilder(
      column: $table.monthlyLimit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BudgetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTableTable> {
  $$BudgetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<double> get monthlyLimit => $composableBuilder(
      column: $table.monthlyLimit, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTableTable,
    BudgetsTableData,
    $$BudgetsTableTableFilterComposer,
    $$BudgetsTableTableOrderingComposer,
    $$BudgetsTableTableAnnotationComposer,
    $$BudgetsTableTableCreateCompanionBuilder,
    $$BudgetsTableTableUpdateCompanionBuilder,
    (
      BudgetsTableData,
      BaseReferences<_$AppDatabase, $BudgetsTableTable, BudgetsTableData>
    ),
    BudgetsTableData,
    PrefetchHooks Function()> {
  $$BudgetsTableTableTableManager(_$AppDatabase db, $BudgetsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<double> monthlyLimit = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsTableCompanion(
            id: id,
            groupId: groupId,
            categoryId: categoryId,
            monthlyLimit: monthlyLimit,
            currencyCode: currencyCode,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String categoryId,
            required double monthlyLimit,
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsTableCompanion.insert(
            id: id,
            groupId: groupId,
            categoryId: categoryId,
            monthlyLimit: monthlyLimit,
            currencyCode: currencyCode,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTableTable,
    BudgetsTableData,
    $$BudgetsTableTableFilterComposer,
    $$BudgetsTableTableOrderingComposer,
    $$BudgetsTableTableAnnotationComposer,
    $$BudgetsTableTableCreateCompanionBuilder,
    $$BudgetsTableTableUpdateCompanionBuilder,
    (
      BudgetsTableData,
      BaseReferences<_$AppDatabase, $BudgetsTableTable, BudgetsTableData>
    ),
    BudgetsTableData,
    PrefetchHooks Function()>;
typedef $$SavingsGoalsTableTableCreateCompanionBuilder
    = SavingsGoalsTableCompanion Function({
  required String id,
  required String groupId,
  required String name,
  required double targetAmount,
  Value<double> currentAmount,
  Value<String> currencyCode,
  Value<DateTime?> targetDate,
  Value<String> iconCode,
  Value<double?> inflationRateMonthly,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$SavingsGoalsTableTableUpdateCompanionBuilder
    = SavingsGoalsTableCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> name,
  Value<double> targetAmount,
  Value<double> currentAmount,
  Value<String> currencyCode,
  Value<DateTime?> targetDate,
  Value<String> iconCode,
  Value<double?> inflationRateMonthly,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SavingsGoalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTableTable> {
  $$SavingsGoalsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentAmount => $composableBuilder(
      column: $table.currentAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get inflationRateMonthly => $composableBuilder(
      column: $table.inflationRateMonthly,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SavingsGoalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTableTable> {
  $$SavingsGoalsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentAmount => $composableBuilder(
      column: $table.currentAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get inflationRateMonthly => $composableBuilder(
      column: $table.inflationRateMonthly,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavingsGoalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTableTable> {
  $$SavingsGoalsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<double> get currentAmount => $composableBuilder(
      column: $table.currentAmount, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<double> get inflationRateMonthly => $composableBuilder(
      column: $table.inflationRateMonthly, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavingsGoalsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingsGoalsTableTable,
    SavingsGoalsTableData,
    $$SavingsGoalsTableTableFilterComposer,
    $$SavingsGoalsTableTableOrderingComposer,
    $$SavingsGoalsTableTableAnnotationComposer,
    $$SavingsGoalsTableTableCreateCompanionBuilder,
    $$SavingsGoalsTableTableUpdateCompanionBuilder,
    (
      SavingsGoalsTableData,
      BaseReferences<_$AppDatabase, $SavingsGoalsTableTable,
          SavingsGoalsTableData>
    ),
    SavingsGoalsTableData,
    PrefetchHooks Function()> {
  $$SavingsGoalsTableTableTableManager(
      _$AppDatabase db, $SavingsGoalsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
            Value<double> currentAmount = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime?> targetDate = const Value.absent(),
            Value<String> iconCode = const Value.absent(),
            Value<double?> inflationRateMonthly = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingsGoalsTableCompanion(
            id: id,
            groupId: groupId,
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            currencyCode: currencyCode,
            targetDate: targetDate,
            iconCode: iconCode,
            inflationRateMonthly: inflationRateMonthly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String name,
            required double targetAmount,
            Value<double> currentAmount = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime?> targetDate = const Value.absent(),
            Value<String> iconCode = const Value.absent(),
            Value<double?> inflationRateMonthly = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingsGoalsTableCompanion.insert(
            id: id,
            groupId: groupId,
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            currencyCode: currencyCode,
            targetDate: targetDate,
            iconCode: iconCode,
            inflationRateMonthly: inflationRateMonthly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavingsGoalsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavingsGoalsTableTable,
    SavingsGoalsTableData,
    $$SavingsGoalsTableTableFilterComposer,
    $$SavingsGoalsTableTableOrderingComposer,
    $$SavingsGoalsTableTableAnnotationComposer,
    $$SavingsGoalsTableTableCreateCompanionBuilder,
    $$SavingsGoalsTableTableUpdateCompanionBuilder,
    (
      SavingsGoalsTableData,
      BaseReferences<_$AppDatabase, $SavingsGoalsTableTable,
          SavingsGoalsTableData>
    ),
    SavingsGoalsTableData,
    PrefetchHooks Function()>;
typedef $$FamilyGroupsTableTableCreateCompanionBuilder
    = FamilyGroupsTableCompanion Function({
  required String id,
  required String name,
  required String ownerId,
  required String inviteCode,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$FamilyGroupsTableTableUpdateCompanionBuilder
    = FamilyGroupsTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> ownerId,
  Value<String> inviteCode,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$FamilyGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyGroupsTableTable> {
  $$FamilyGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$FamilyGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyGroupsTableTable> {
  $$FamilyGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FamilyGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyGroupsTableTable> {
  $$FamilyGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FamilyGroupsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FamilyGroupsTableTable,
    FamilyGroupsTableData,
    $$FamilyGroupsTableTableFilterComposer,
    $$FamilyGroupsTableTableOrderingComposer,
    $$FamilyGroupsTableTableAnnotationComposer,
    $$FamilyGroupsTableTableCreateCompanionBuilder,
    $$FamilyGroupsTableTableUpdateCompanionBuilder,
    (
      FamilyGroupsTableData,
      BaseReferences<_$AppDatabase, $FamilyGroupsTableTable,
          FamilyGroupsTableData>
    ),
    FamilyGroupsTableData,
    PrefetchHooks Function()> {
  $$FamilyGroupsTableTableTableManager(
      _$AppDatabase db, $FamilyGroupsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyGroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyGroupsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> inviteCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FamilyGroupsTableCompanion(
            id: id,
            name: name,
            ownerId: ownerId,
            inviteCode: inviteCode,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String ownerId,
            required String inviteCode,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FamilyGroupsTableCompanion.insert(
            id: id,
            name: name,
            ownerId: ownerId,
            inviteCode: inviteCode,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FamilyGroupsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FamilyGroupsTableTable,
    FamilyGroupsTableData,
    $$FamilyGroupsTableTableFilterComposer,
    $$FamilyGroupsTableTableOrderingComposer,
    $$FamilyGroupsTableTableAnnotationComposer,
    $$FamilyGroupsTableTableCreateCompanionBuilder,
    $$FamilyGroupsTableTableUpdateCompanionBuilder,
    (
      FamilyGroupsTableData,
      BaseReferences<_$AppDatabase, $FamilyGroupsTableTable,
          FamilyGroupsTableData>
    ),
    FamilyGroupsTableData,
    PrefetchHooks Function()>;
typedef $$GroupMembersTableTableCreateCompanionBuilder
    = GroupMembersTableCompanion Function({
  required String id,
  required String groupId,
  required String userId,
  Value<String> role,
  Value<String?> displayName,
  Value<String?> email,
  Value<DateTime> joinedAt,
  Value<int> rowid,
});
typedef $$GroupMembersTableTableUpdateCompanionBuilder
    = GroupMembersTableCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> userId,
  Value<String> role,
  Value<String?> displayName,
  Value<String?> email,
  Value<DateTime> joinedAt,
  Value<int> rowid,
});

class $$GroupMembersTableTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTableTable> {
  $$GroupMembersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnFilters(column));
}

class $$GroupMembersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTableTable> {
  $$GroupMembersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnOrderings(column));
}

class $$GroupMembersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTableTable> {
  $$GroupMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);
}

class $$GroupMembersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupMembersTableTable,
    GroupMembersTableData,
    $$GroupMembersTableTableFilterComposer,
    $$GroupMembersTableTableOrderingComposer,
    $$GroupMembersTableTableAnnotationComposer,
    $$GroupMembersTableTableCreateCompanionBuilder,
    $$GroupMembersTableTableUpdateCompanionBuilder,
    (
      GroupMembersTableData,
      BaseReferences<_$AppDatabase, $GroupMembersTableTable,
          GroupMembersTableData>
    ),
    GroupMembersTableData,
    PrefetchHooks Function()> {
  $$GroupMembersTableTableTableManager(
      _$AppDatabase db, $GroupMembersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<DateTime> joinedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersTableCompanion(
            id: id,
            groupId: groupId,
            userId: userId,
            role: role,
            displayName: displayName,
            email: email,
            joinedAt: joinedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String userId,
            Value<String> role = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<DateTime> joinedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersTableCompanion.insert(
            id: id,
            groupId: groupId,
            userId: userId,
            role: role,
            displayName: displayName,
            email: email,
            joinedAt: joinedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupMembersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupMembersTableTable,
    GroupMembersTableData,
    $$GroupMembersTableTableFilterComposer,
    $$GroupMembersTableTableOrderingComposer,
    $$GroupMembersTableTableAnnotationComposer,
    $$GroupMembersTableTableCreateCompanionBuilder,
    $$GroupMembersTableTableUpdateCompanionBuilder,
    (
      GroupMembersTableData,
      BaseReferences<_$AppDatabase, $GroupMembersTableTable,
          GroupMembersTableData>
    ),
    GroupMembersTableData,
    PrefetchHooks Function()>;
typedef $$RecurringTransactionsTableTableCreateCompanionBuilder
    = RecurringTransactionsTableCompanion Function({
  required String id,
  required String groupId,
  required String userId,
  Value<String?> categoryId,
  required double amount,
  Value<String> currencyCode,
  required String type,
  Value<String?> description,
  required String frequency,
  Value<int?> dayOfMonth,
  required DateTime nextDueDate,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$RecurringTransactionsTableTableUpdateCompanionBuilder
    = RecurringTransactionsTableCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> userId,
  Value<String?> categoryId,
  Value<double> amount,
  Value<String> currencyCode,
  Value<String> type,
  Value<String?> description,
  Value<String> frequency,
  Value<int?> dayOfMonth,
  Value<DateTime> nextDueDate,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$RecurringTransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTableTable> {
  $$RecurringTransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RecurringTransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTableTable> {
  $$RecurringTransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RecurringTransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTableTable> {
  $$RecurringTransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecurringTransactionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringTransactionsTableTable,
    RecurringTransactionsTableData,
    $$RecurringTransactionsTableTableFilterComposer,
    $$RecurringTransactionsTableTableOrderingComposer,
    $$RecurringTransactionsTableTableAnnotationComposer,
    $$RecurringTransactionsTableTableCreateCompanionBuilder,
    $$RecurringTransactionsTableTableUpdateCompanionBuilder,
    (
      RecurringTransactionsTableData,
      BaseReferences<_$AppDatabase, $RecurringTransactionsTableTable,
          RecurringTransactionsTableData>
    ),
    RecurringTransactionsTableData,
    PrefetchHooks Function()> {
  $$RecurringTransactionsTableTableTableManager(
      _$AppDatabase db, $RecurringTransactionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTransactionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTransactionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTransactionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int?> dayOfMonth = const Value.absent(),
            Value<DateTime> nextDueDate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringTransactionsTableCompanion(
            id: id,
            groupId: groupId,
            userId: userId,
            categoryId: categoryId,
            amount: amount,
            currencyCode: currencyCode,
            type: type,
            description: description,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            nextDueDate: nextDueDate,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String userId,
            Value<String?> categoryId = const Value.absent(),
            required double amount,
            Value<String> currencyCode = const Value.absent(),
            required String type,
            Value<String?> description = const Value.absent(),
            required String frequency,
            Value<int?> dayOfMonth = const Value.absent(),
            required DateTime nextDueDate,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringTransactionsTableCompanion.insert(
            id: id,
            groupId: groupId,
            userId: userId,
            categoryId: categoryId,
            amount: amount,
            currencyCode: currencyCode,
            type: type,
            description: description,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            nextDueDate: nextDueDate,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurringTransactionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecurringTransactionsTableTable,
        RecurringTransactionsTableData,
        $$RecurringTransactionsTableTableFilterComposer,
        $$RecurringTransactionsTableTableOrderingComposer,
        $$RecurringTransactionsTableTableAnnotationComposer,
        $$RecurringTransactionsTableTableCreateCompanionBuilder,
        $$RecurringTransactionsTableTableUpdateCompanionBuilder,
        (
          RecurringTransactionsTableData,
          BaseReferences<_$AppDatabase, $RecurringTransactionsTableTable,
              RecurringTransactionsTableData>
        ),
        RecurringTransactionsTableData,
        PrefetchHooks Function()>;
typedef $$InvestmentsTableTableCreateCompanionBuilder
    = InvestmentsTableCompanion Function({
  required String id,
  required String groupId,
  required String userId,
  required String name,
  Value<String> type,
  required double initialAmount,
  Value<double?> currentValue,
  Value<String> currencyCode,
  Value<DateTime?> startDate,
  Value<DateTime?> maturityDate,
  Value<String?> institution,
  Value<String?> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$InvestmentsTableTableUpdateCompanionBuilder
    = InvestmentsTableCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> userId,
  Value<String> name,
  Value<String> type,
  Value<double> initialAmount,
  Value<double?> currentValue,
  Value<String> currencyCode,
  Value<DateTime?> startDate,
  Value<DateTime?> maturityDate,
  Value<String?> institution,
  Value<String?> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$InvestmentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentsTableTable> {
  $$InvestmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get initialAmount => $composableBuilder(
      column: $table.initialAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get maturityDate => $composableBuilder(
      column: $table.maturityDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get institution => $composableBuilder(
      column: $table.institution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$InvestmentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentsTableTable> {
  $$InvestmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get initialAmount => $composableBuilder(
      column: $table.initialAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentValue => $composableBuilder(
      column: $table.currentValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get maturityDate => $composableBuilder(
      column: $table.maturityDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institution => $composableBuilder(
      column: $table.institution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InvestmentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentsTableTable> {
  $$InvestmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get initialAmount => $composableBuilder(
      column: $table.initialAmount, builder: (column) => column);

  GeneratedColumn<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get maturityDate => $composableBuilder(
      column: $table.maturityDate, builder: (column) => column);

  GeneratedColumn<String> get institution => $composableBuilder(
      column: $table.institution, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InvestmentsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvestmentsTableTable,
    InvestmentsTableData,
    $$InvestmentsTableTableFilterComposer,
    $$InvestmentsTableTableOrderingComposer,
    $$InvestmentsTableTableAnnotationComposer,
    $$InvestmentsTableTableCreateCompanionBuilder,
    $$InvestmentsTableTableUpdateCompanionBuilder,
    (
      InvestmentsTableData,
      BaseReferences<_$AppDatabase, $InvestmentsTableTable,
          InvestmentsTableData>
    ),
    InvestmentsTableData,
    PrefetchHooks Function()> {
  $$InvestmentsTableTableTableManager(
      _$AppDatabase db, $InvestmentsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> initialAmount = const Value.absent(),
            Value<double?> currentValue = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> maturityDate = const Value.absent(),
            Value<String?> institution = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvestmentsTableCompanion(
            id: id,
            groupId: groupId,
            userId: userId,
            name: name,
            type: type,
            initialAmount: initialAmount,
            currentValue: currentValue,
            currencyCode: currencyCode,
            startDate: startDate,
            maturityDate: maturityDate,
            institution: institution,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String userId,
            required String name,
            Value<String> type = const Value.absent(),
            required double initialAmount,
            Value<double?> currentValue = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> maturityDate = const Value.absent(),
            Value<String?> institution = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvestmentsTableCompanion.insert(
            id: id,
            groupId: groupId,
            userId: userId,
            name: name,
            type: type,
            initialAmount: initialAmount,
            currentValue: currentValue,
            currencyCode: currencyCode,
            startDate: startDate,
            maturityDate: maturityDate,
            institution: institution,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InvestmentsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvestmentsTableTable,
    InvestmentsTableData,
    $$InvestmentsTableTableFilterComposer,
    $$InvestmentsTableTableOrderingComposer,
    $$InvestmentsTableTableAnnotationComposer,
    $$InvestmentsTableTableCreateCompanionBuilder,
    $$InvestmentsTableTableUpdateCompanionBuilder,
    (
      InvestmentsTableData,
      BaseReferences<_$AppDatabase, $InvestmentsTableTable,
          InvestmentsTableData>
    ),
    InvestmentsTableData,
    PrefetchHooks Function()>;
typedef $$VirtualEnvelopesTableTableCreateCompanionBuilder
    = VirtualEnvelopesTableCompanion Function({
  required String id,
  required String groupId,
  Value<String?> categoryId,
  required String name,
  required double allocatedAmount,
  Value<double> spentAmount,
  Value<String> currencyCode,
  required DateTime periodStart,
  required DateTime periodEnd,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$VirtualEnvelopesTableTableUpdateCompanionBuilder
    = VirtualEnvelopesTableCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String?> categoryId,
  Value<String> name,
  Value<double> allocatedAmount,
  Value<double> spentAmount,
  Value<String> currencyCode,
  Value<DateTime> periodStart,
  Value<DateTime> periodEnd,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$VirtualEnvelopesTableTableFilterComposer
    extends Composer<_$AppDatabase, $VirtualEnvelopesTableTable> {
  $$VirtualEnvelopesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get allocatedAmount => $composableBuilder(
      column: $table.allocatedAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get spentAmount => $composableBuilder(
      column: $table.spentAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$VirtualEnvelopesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VirtualEnvelopesTableTable> {
  $$VirtualEnvelopesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get allocatedAmount => $composableBuilder(
      column: $table.allocatedAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get spentAmount => $composableBuilder(
      column: $table.spentAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VirtualEnvelopesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VirtualEnvelopesTableTable> {
  $$VirtualEnvelopesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get allocatedAmount => $composableBuilder(
      column: $table.allocatedAmount, builder: (column) => column);

  GeneratedColumn<double> get spentAmount => $composableBuilder(
      column: $table.spentAmount, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VirtualEnvelopesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VirtualEnvelopesTableTable,
    VirtualEnvelopesTableData,
    $$VirtualEnvelopesTableTableFilterComposer,
    $$VirtualEnvelopesTableTableOrderingComposer,
    $$VirtualEnvelopesTableTableAnnotationComposer,
    $$VirtualEnvelopesTableTableCreateCompanionBuilder,
    $$VirtualEnvelopesTableTableUpdateCompanionBuilder,
    (
      VirtualEnvelopesTableData,
      BaseReferences<_$AppDatabase, $VirtualEnvelopesTableTable,
          VirtualEnvelopesTableData>
    ),
    VirtualEnvelopesTableData,
    PrefetchHooks Function()> {
  $$VirtualEnvelopesTableTableTableManager(
      _$AppDatabase db, $VirtualEnvelopesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VirtualEnvelopesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$VirtualEnvelopesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VirtualEnvelopesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> allocatedAmount = const Value.absent(),
            Value<double> spentAmount = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<DateTime> periodStart = const Value.absent(),
            Value<DateTime> periodEnd = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VirtualEnvelopesTableCompanion(
            id: id,
            groupId: groupId,
            categoryId: categoryId,
            name: name,
            allocatedAmount: allocatedAmount,
            spentAmount: spentAmount,
            currencyCode: currencyCode,
            periodStart: periodStart,
            periodEnd: periodEnd,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            Value<String?> categoryId = const Value.absent(),
            required String name,
            required double allocatedAmount,
            Value<double> spentAmount = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            required DateTime periodStart,
            required DateTime periodEnd,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VirtualEnvelopesTableCompanion.insert(
            id: id,
            groupId: groupId,
            categoryId: categoryId,
            name: name,
            allocatedAmount: allocatedAmount,
            spentAmount: spentAmount,
            currencyCode: currencyCode,
            periodStart: periodStart,
            periodEnd: periodEnd,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VirtualEnvelopesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $VirtualEnvelopesTableTable,
        VirtualEnvelopesTableData,
        $$VirtualEnvelopesTableTableFilterComposer,
        $$VirtualEnvelopesTableTableOrderingComposer,
        $$VirtualEnvelopesTableTableAnnotationComposer,
        $$VirtualEnvelopesTableTableCreateCompanionBuilder,
        $$VirtualEnvelopesTableTableUpdateCompanionBuilder,
        (
          VirtualEnvelopesTableData,
          BaseReferences<_$AppDatabase, $VirtualEnvelopesTableTable,
              VirtualEnvelopesTableData>
        ),
        VirtualEnvelopesTableData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableTableManager get accountsTable =>
      $$AccountsTableTableTableManager(_db, _db.accountsTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$ExchangeRatesTableTableTableManager get exchangeRatesTable =>
      $$ExchangeRatesTableTableTableManager(_db, _db.exchangeRatesTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$BudgetsTableTableTableManager get budgetsTable =>
      $$BudgetsTableTableTableManager(_db, _db.budgetsTable);
  $$SavingsGoalsTableTableTableManager get savingsGoalsTable =>
      $$SavingsGoalsTableTableTableManager(_db, _db.savingsGoalsTable);
  $$FamilyGroupsTableTableTableManager get familyGroupsTable =>
      $$FamilyGroupsTableTableTableManager(_db, _db.familyGroupsTable);
  $$GroupMembersTableTableTableManager get groupMembersTable =>
      $$GroupMembersTableTableTableManager(_db, _db.groupMembersTable);
  $$RecurringTransactionsTableTableTableManager
      get recurringTransactionsTable =>
          $$RecurringTransactionsTableTableTableManager(
              _db, _db.recurringTransactionsTable);
  $$InvestmentsTableTableTableManager get investmentsTable =>
      $$InvestmentsTableTableTableManager(_db, _db.investmentsTable);
  $$VirtualEnvelopesTableTableTableManager get virtualEnvelopesTable =>
      $$VirtualEnvelopesTableTableTableManager(_db, _db.virtualEnvelopesTable);
}
