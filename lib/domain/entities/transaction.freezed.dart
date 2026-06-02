// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return _Transaction.fromJson(json);
}

/// @nodoc
mixin _$Transaction {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  double? get amountUsdEquivalent => throw _privateConstructorUsedError;
  String? get exchangeRateId => throw _privateConstructorUsedError;
  TransactionType get type => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get paymentMethod => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
          Transaction value, $Res Function(Transaction) then) =
      _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call(
      {String id,
      String groupId,
      String userId,
      String? categoryId,
      double amount,
      String currencyCode,
      double? amountUsdEquivalent,
      String? exchangeRateId,
      TransactionType type,
      DateTime date,
      String? description,
      String? paymentMethod,
      String? notes,
      bool isSynced,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? userId = null,
    Object? categoryId = freezed,
    Object? amount = null,
    Object? currencyCode = null,
    Object? amountUsdEquivalent = freezed,
    Object? exchangeRateId = freezed,
    Object? type = null,
    Object? date = null,
    Object? description = freezed,
    Object? paymentMethod = freezed,
    Object? notes = freezed,
    Object? isSynced = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      amountUsdEquivalent: freezed == amountUsdEquivalent
          ? _value.amountUsdEquivalent
          : amountUsdEquivalent // ignore: cast_nullable_to_non_nullable
              as double?,
      exchangeRateId: freezed == exchangeRateId
          ? _value.exchangeRateId
          : exchangeRateId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
          _$TransactionImpl value, $Res Function(_$TransactionImpl) then) =
      __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupId,
      String userId,
      String? categoryId,
      double amount,
      String currencyCode,
      double? amountUsdEquivalent,
      String? exchangeRateId,
      TransactionType type,
      DateTime date,
      String? description,
      String? paymentMethod,
      String? notes,
      bool isSynced,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
      _$TransactionImpl _value, $Res Function(_$TransactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? userId = null,
    Object? categoryId = freezed,
    Object? amount = null,
    Object? currencyCode = null,
    Object? amountUsdEquivalent = freezed,
    Object? exchangeRateId = freezed,
    Object? type = null,
    Object? date = null,
    Object? description = freezed,
    Object? paymentMethod = freezed,
    Object? notes = freezed,
    Object? isSynced = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      amountUsdEquivalent: freezed == amountUsdEquivalent
          ? _value.amountUsdEquivalent
          : amountUsdEquivalent // ignore: cast_nullable_to_non_nullable
              as double?,
      exchangeRateId: freezed == exchangeRateId
          ? _value.exchangeRateId
          : exchangeRateId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionImpl implements _Transaction {
  const _$TransactionImpl(
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
      this.isSynced = false,
      required this.createdAt,
      required this.updatedAt});

  factory _$TransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String userId;
  @override
  final String? categoryId;
  @override
  final double amount;
  @override
  final String currencyCode;
  @override
  final double? amountUsdEquivalent;
  @override
  final String? exchangeRateId;
  @override
  final TransactionType type;
  @override
  final DateTime date;
  @override
  final String? description;
  @override
  final String? paymentMethod;
  @override
  final String? notes;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Transaction(id: $id, groupId: $groupId, userId: $userId, categoryId: $categoryId, amount: $amount, currencyCode: $currencyCode, amountUsdEquivalent: $amountUsdEquivalent, exchangeRateId: $exchangeRateId, type: $type, date: $date, description: $description, paymentMethod: $paymentMethod, notes: $notes, isSynced: $isSynced, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.amountUsdEquivalent, amountUsdEquivalent) ||
                other.amountUsdEquivalent == amountUsdEquivalent) &&
            (identical(other.exchangeRateId, exchangeRateId) ||
                other.exchangeRateId == exchangeRateId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
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
      isSynced,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionImplToJson(
      this,
    );
  }
}

abstract class _Transaction implements Transaction {
  const factory _Transaction(
      {required final String id,
      required final String groupId,
      required final String userId,
      final String? categoryId,
      required final double amount,
      required final String currencyCode,
      final double? amountUsdEquivalent,
      final String? exchangeRateId,
      required final TransactionType type,
      required final DateTime date,
      final String? description,
      final String? paymentMethod,
      final String? notes,
      final bool isSynced,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$TransactionImpl;

  factory _Transaction.fromJson(Map<String, dynamic> json) =
      _$TransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get userId;
  @override
  String? get categoryId;
  @override
  double get amount;
  @override
  String get currencyCode;
  @override
  double? get amountUsdEquivalent;
  @override
  String? get exchangeRateId;
  @override
  TransactionType get type;
  @override
  DateTime get date;
  @override
  String? get description;
  @override
  String? get paymentMethod;
  @override
  String? get notes;
  @override
  bool get isSynced;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
