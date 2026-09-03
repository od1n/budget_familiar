import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de visualización de totales:
/// - primaryCurrency: moneda principal del usuario ('USD' | 'EUR'), su
///   moneda por defecto para ver y registrar. Es por-usuario (este dispositivo).
/// - currency: en qué moneda se muestran los totales ahora ('USD' | 'VES' | 'EUR')
/// - rate: qué tasa se usa para convertir a VES ('parallel' | 'bcv')
class DisplayPrefs {
  const DisplayPrefs({
    this.primaryCurrency = 'USD',
    this.currency = 'USD',
    this.rate = 'parallel',
  });
  final String primaryCurrency;
  final String currency;
  final String rate;
  DisplayPrefs copyWith({String? primaryCurrency, String? currency, String? rate}) =>
      DisplayPrefs(
        primaryCurrency: primaryCurrency ?? this.primaryCurrency,
        currency: currency ?? this.currency,
        rate: rate ?? this.rate,
      );
}

class DisplayPrefsNotifier extends StateNotifier<DisplayPrefs> {
  DisplayPrefsNotifier() : super(const DisplayPrefs()) {
    _load();
  }
  static const _kPrimary = 'disp_primary';
  static const _kCur = 'disp_currency';
  static const _kRate = 'disp_rate';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final primary = p.getString(_kPrimary) ?? 'USD';
    state = DisplayPrefs(
      primaryCurrency: primary,
      // La primera vez, la moneda mostrada sigue a la principal.
      currency: p.getString(_kCur) ?? primary,
      rate: p.getString(_kRate) ?? 'parallel',
    );
  }

  /// Cambia la moneda principal del usuario y ajusta la vista a esa moneda.
  Future<void> setPrimaryCurrency(String c) async {
    state = state.copyWith(primaryCurrency: c, currency: c);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrimary, c);
    await p.setString(_kCur, c);
  }

  Future<void> setCurrency(String c) async {
    state = state.copyWith(currency: c);
    (await SharedPreferences.getInstance()).setString(_kCur, c);
  }

  Future<void> setRate(String r) async {
    state = state.copyWith(rate: r);
    (await SharedPreferences.getInstance()).setString(_kRate, r);
  }
}

final displayPrefsProvider =
    StateNotifierProvider<DisplayPrefsNotifier, DisplayPrefs>(
        (ref) => DisplayPrefsNotifier());
