// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String?,
      name: json['name'] as String,
      iconCode: json['iconCode'] as String,
      colorHex: json['colorHex'] as String,
      type: $enumDecode(_$CategoryTypeEnumMap, json['type']),
      isSystem: json['isSystem'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'name': instance.name,
      'iconCode': instance.iconCode,
      'colorHex': instance.colorHex,
      'type': _$CategoryTypeEnumMap[instance.type]!,
      'isSystem': instance.isSystem,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$CategoryTypeEnumMap = {
  CategoryType.income: 'income',
  CategoryType.expense: 'expense',
  CategoryType.both: 'both',
};
