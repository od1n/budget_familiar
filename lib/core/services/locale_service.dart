import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma elegido por el usuario para la interfaz.
///
/// `null` = automático: la aplicación sigue el idioma configurado en el
/// teléfono o la computadora. Un código de idioma (por ejemplo 'es' o 'en')
/// fuerza ese idioma sin importar el del sistema.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  static const _kKey = 'app_locale';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_kKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  /// Fija el idioma. `null` o cadena vacía = automático (idioma del sistema).
  Future<void> setLocale(String? code) async {
    state = (code == null || code.isEmpty) ? null : Locale(code);
    final p = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await p.remove(_kKey);
    } else {
      await p.setString(_kKey, code);
    }
  }
}

/// Idioma actual de la interfaz. Se observa en la raíz (BudgetApp) para que el
/// cambio se aplique al instante en toda la aplicación.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) => LocaleNotifier());
