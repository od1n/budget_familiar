// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      amountUsdEquivalent: (json['amountUsdEquivalent'] as num?)?.toDouble(),
      exchangeRateId: json['exchangeRateId'] as String?,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'userId': instance.userId,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'currencyCode': instance.currencyCode,
      'amountUsdEquivalent': instance.amountUsdEquivalent,
      'exchangeRateId': instance.exchangeRateId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'date': instance.date.toIso8601String(),
      'description': instance.description,
      'paymentMethod': instance.paymentMethod,
      'notes': instance.notes,
      'isSynced': instance.isSynced,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
};
