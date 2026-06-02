import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/utils/category_utils.dart';

void main() {
  // ── colorFromHex ────────────────────────────────────────────────────────────

  group('colorFromHex', () {
    test('convierte hex con # correctamente', () {
      expect(colorFromHex('#E74C3C'), const Color(0xFFE74C3C));
    });

    test('convierte hex sin # correctamente', () {
      expect(colorFromHex('E74C3C'), const Color(0xFFE74C3C));
    });

    test('blanco', () {
      expect(colorFromHex('#FFFFFF'), const Color(0xFFFFFFFF));
    });

    test('negro', () {
      expect(colorFromHex('#000000'), const Color(0xFF000000));
    });

    test('azul primario de la app', () {
      expect(colorFromHex('#1A56DB'), const Color(0xFF1A56DB));
    });

    test('siempre agrega canal alpha FF', () {
      final color = colorFromHex('#123456');
      // El valor alpha debe ser 0xFF (255)
      expect(color.alpha, 0xFF);
    });

    test('todos los colores de la paleta son válidos', () {
      for (final hex in kColorPalette) {
        expect(() => colorFromHex(hex), returnsNormally,
            reason: 'Falló con $hex');
      }
    });
  });

  // ── iconFromCode ────────────────────────────────────────────────────────────

  group('iconFromCode', () {
    test('restaurant → Icons.restaurant', () {
      expect(iconFromCode('restaurant'), Icons.restaurant);
    });

    test('directions_car → Icons.directions_car', () {
      expect(iconFromCode('directions_car'), Icons.directions_car);
    });

    test('school → Icons.school', () {
      expect(iconFromCode('school'), Icons.school);
    });

    test('código desconocido → Icons.category (fallback)', () {
      expect(iconFromCode('codigo_inexistente'), Icons.category);
      expect(iconFromCode(''), Icons.category);
      expect(iconFromCode('RESTAURANT'), Icons.category); // case-sensitive
    });

    test('todos los códigos de kIconOptions tienen mapeo válido', () {
      for (final (code, expectedIcon) in kIconOptions) {
        expect(
          iconFromCode(code),
          expectedIcon,
          reason: 'Falló con código "$code"',
        );
      }
    });

    test('ningún código de kIconOptions devuelve el fallback', () {
      for (final (code, _) in kIconOptions) {
        expect(
          iconFromCode(code),
          isNot(Icons.category),
          reason: 'Código "$code" devolvió el fallback inesperadamente',
        );
      }
    });
  });
}
