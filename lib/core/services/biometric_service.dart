import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger();

const _kBiometricEnabled = 'biometric_enabled';

// ── Servicio ────────────────────────────────────────────────────────────────

class BiometricService {
  final _auth = LocalAuthentication();

  /// Verifica si el dispositivo soporta biometría o PIN.
  Future<bool> get isAvailable async {
    // local_auth no tiene soporte real en Windows — solo Android/iOS/macOS.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      return false;
    }
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Lee si el usuario activó la protección biométrica.
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Activa o desactiva la protección biométrica.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }

  /// Solicita autenticación biométrica o PIN del dispositivo.
  /// Retorna `true` si el usuario se autenticó correctamente.
  /// Si la biometría no está habilitada o no está disponible, retorna `true`
  /// (sin bloquear el flujo).
  Future<bool> authenticate({
    String reason = 'Confirma tu identidad para continuar',
  }) async {
    final enabled = await isEnabled;
    if (!enabled) return true;

    final available = await isAvailable;
    if (!available) return true;

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // permite PIN/patrón como fallback
        ),
      );
    } on PlatformException catch (e) {
      _log.w('Biometric auth failed: ${e.message}');
      return false;
    }
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);

/// Si el dispositivo soporta biometría.
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.read(biometricServiceProvider).isAvailable;
});

/// Si el usuario activó la protección biométrica.
final biometricEnabledProvider =
    StateNotifierProvider<_BiometricEnabledNotifier, AsyncValue<bool>>(
  (ref) => _BiometricEnabledNotifier(ref.read(biometricServiceProvider)),
);

class _BiometricEnabledNotifier extends StateNotifier<AsyncValue<bool>> {
  _BiometricEnabledNotifier(this._svc) : super(const AsyncValue.loading()) {
    _load();
  }

  final BiometricService _svc;

  Future<void> _load() async {
    state = AsyncValue.data(await _svc.isEnabled);
  }

  Future<void> toggle(bool value) async {
    await _svc.setEnabled(value);
    state = AsyncValue.data(value);
  }
}
