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
    this.manualVesRate = 0,
  });
  final String primaryCurrency;
  final String currency;
  final String rate;

  /// Tasa manual del bolívar (Bs. por 1 USD). 0 = usar la tasa automática.
  final double manualVesRate;

  DisplayPrefs copyWith({
    String? primaryCurrency,
    String? currency,
    String? rate,
    double? manualVesRate,
  }) =>
      DisplayPrefs(
        primaryCurrency: primaryCurrency ?? this.primaryCurrency,
        currency: currency ?? this.currency,
        rate: rate ?? this.rate,
        manualVesRate: manualVesRate ?? this.manualVesRate,
      );
}

class DisplayPrefsNotifier extends StateNotifier<DisplayPrefs> {
  DisplayPrefsNotifier() : super(const DisplayPrefs()) {
    _load();
  }
  static const _kPrimary = 'disp_primary';
  static const _kCur = 'disp_currency';
  static const _kRate = 'disp_rate';
  static const _kManualVes = 'disp_manual_ves';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final primary = p.getString(_kPrimary) ?? 'USD';
    state = DisplayPrefs(
      primaryCurrency: primary,
      // La primera vez, la moneda mostrada sigue a la principal.
      currency: p.getString(_kCur) ?? primary,
      rate: p.getString(_kRate) ?? 'parallel',
      manualVesRate: p.getDouble(_kManualVes) ?? 0,
    );
  }

  /// Fija la tasa manual del bolívar (Bs. por 1 USD). 0 vuelve a la automática.
  Future<void> setManualVesRate(double v) async {
    final val = v > 0 ? v : 0.0;
    state = state.copyWith(manualVesRate: val);
    (await SharedPreferences.getInstance()).setDouble(_kManualVes, val);
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
