import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

// ── Mapper de código de ícono → IconData ─────────────────────────────────────
// Usado en TransactionsPage, _CategoryLabel y CategoryCreationDialog.

IconData iconFromCode(String code) => switch (code) {
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'bolt' => Icons.bolt,
      'local_hospital' => Icons.local_hospital,
      'school' => Icons.school,
      'movie' => Icons.movie,
      'checkroom' => Icons.checkroom,
      'home' => Icons.home,
      'credit_card' => Icons.credit_card,
      'more_horiz' => Icons.more_horiz,
      'work' => Icons.work,
      'laptop' => Icons.laptop,
      'trending_up' => Icons.trending_up,
      'attach_money' => Icons.attach_money,
      'shopping_cart' => Icons.shopping_cart,
      'local_gas_station' => Icons.local_gas_station,
      'fitness_center' => Icons.fitness_center,
      'pets' => Icons.pets,
      'flight' => Icons.flight,
      'sports_soccer' => Icons.sports_soccer,
      'phone' => Icons.phone,
      'wifi' => Icons.wifi,
      'local_cafe' => Icons.local_cafe,
      'park' => Icons.park,
      'music_note' => Icons.music_note,
      'games' => Icons.games,
      'star_outline' => Icons.star_outline,
      'favorite_border' => Icons.favorite_border,
      'card_giftcard' => Icons.card_giftcard,
      'construction' => Icons.construction,
      'spa' => Icons.spa,
      'directions_bike' => Icons.directions_bike,
      'local_pharmacy' => Icons.local_pharmacy,
      'child_care' => Icons.child_care,
      _ => Icons.category,
    };

// ── Conversión de color hex → Color ──────────────────────────────────────────

Color colorFromHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

// ── Opciones de íconos disponibles para categorías personalizadas ─────────────

const kIconOptions = <(String, IconData)>[
  ('restaurant', Icons.restaurant),
  ('shopping_cart', Icons.shopping_cart),
  ('directions_car', Icons.directions_car),
  ('local_gas_station', Icons.local_gas_station),
  ('bolt', Icons.bolt),
  ('wifi', Icons.wifi),
  ('local_hospital', Icons.local_hospital),
  ('local_pharmacy', Icons.local_pharmacy),
  ('fitness_center', Icons.fitness_center),
  ('spa', Icons.spa),
  ('school', Icons.school),
  ('child_care', Icons.child_care),
  ('movie', Icons.movie),
  ('music_note', Icons.music_note),
  ('games', Icons.games),
  ('sports_soccer', Icons.sports_soccer),
  ('checkroom', Icons.checkroom),
  ('home', Icons.home),
  ('construction', Icons.construction),
  ('pets', Icons.pets),
  ('flight', Icons.flight),
  ('park', Icons.park),
  ('credit_card', Icons.credit_card),
  ('work', Icons.work),
  ('laptop', Icons.laptop),
  ('phone', Icons.phone),
  ('trending_up', Icons.trending_up),
  ('attach_money', Icons.attach_money),
  ('card_giftcard', Icons.card_giftcard),
  ('local_cafe', Icons.local_cafe),
  ('favorite_border', Icons.favorite_border),
  ('star_outline', Icons.star_outline),
  ('directions_bike', Icons.directions_bike),
  ('more_horiz', Icons.more_horiz),
];

// ── Paleta de colores predefinida para categorías personalizadas ──────────────

const kColorPalette = <String>[
  '#E74C3C',
  '#C0392B',
  '#E67E22',
  '#F39C12',
  '#F1C40F',
  '#2ECC71',
  '#27AE60',
  '#1ABC9C',
  '#16A085',
  '#3498DB',
  '#2980B9',
  '#9B59B6',
  '#8E44AD',
  '#34495E',
  '#7F8C8D',
  '#D35400',
  '#1F618D',
  '#117A65',
  '#784212',
  '#6C3483',
];


// ── Nombre localizado de una categoría ───────────────────────────────────────
// Las categorías del sistema (sys_*) se guardan en la BD con nombre en español;
// aquí se traducen al idioma actual. Las personalizadas devuelven su [fallback].
String categoryDisplayName(BuildContext context, String id, String fallback) {
  final s = S.of(context);
  return switch (id) {
    'sys_food' => s.sysCatFood,
    'sys_transport' => s.sysCatTransport,
    'sys_services' => s.sysCatServices,
    'sys_health' => s.sysCatHealth,
    'sys_education' => s.sysCatEducation,
    'sys_entertainment' => s.sysCatEntertainment,
    'sys_clothing' => s.sysCatClothing,
    'sys_home' => s.sysCatHome,
    'sys_debt' => s.sysCatDebt,
    'sys_other' => s.sysCatOther,
    'sys_income_salary' => s.sysCatSalary,
    'sys_income_freelance' => s.sysCatFreelance,
    'sys_income_investment' => s.sysCatInvestment,
    'sys_income_other' => s.sysCatOtherIncome,
    _ => fallback,
  };
}
