import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    String? groupId,
    required String name,
    required String iconCode,
    required String colorHex,
    required CategoryType type,
    @Default(false) bool isSystem,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

extension CategoryX on Category {
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get icon => _iconMap[iconCode] ?? Icons.label_outline;

  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'bolt': Icons.bolt,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'movie': Icons.movie,
    'checkroom': Icons.checkroom,
    'home': Icons.home,
    'credit_card': Icons.credit_card,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'laptop': Icons.laptop,
    'trending_up': Icons.trending_up,
    'attach_money': Icons.attach_money,
  };
}

enum CategoryType {
  income,
  expense,
  both;

  bool get canBeIncome => this == income || this == both;
  bool get canBeExpense => this == expense || this == both;

  String get label => switch (this) {
        income => 'Ingreso',
        expense => 'Gasto',
        both => 'Ambos',
      };
}
