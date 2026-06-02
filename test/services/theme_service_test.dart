import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_familiar/core/services/theme_service.dart';

void main() {
  group('ThemeModeNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('estado inicial es ThemeMode.system', () {
      final notifier = ThemeModeNotifier();
      // Antes de cargar desde prefs, el default es system.
      expect(notifier.state, ThemeMode.system);
    });

    test('set(light) persiste y actualiza estado', () async {
      final notifier = ThemeModeNotifier();
      await notifier.set(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('set(dark) persiste y actualiza estado', () async {
      final notifier = ThemeModeNotifier();
      await notifier.set(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('set(system) persiste y actualiza estado', () async {
      final notifier = ThemeModeNotifier();
      await notifier.set(ThemeMode.dark);
      await notifier.set(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'system');
    });

    test('carga valor persistido al inicializar', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeModeNotifier();
      // Esperar a que _load() termine.
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, ThemeMode.dark);
    });

    test('valor desconocido carga como system', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
      final notifier = ThemeModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, ThemeMode.system);
    });
  });
}
