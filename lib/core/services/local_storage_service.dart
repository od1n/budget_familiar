import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación de [LocalStorage] usando SharedPreferences.
///
/// Reemplaza a FlutterSecureStorage (que requiere ATL en Windows).
/// SharedPreferences es suficiente para desarrollo en desktop.
/// En producción móvil (Fase 2) se puede volver a FlutterSecureStorage.
class SharedPrefsStorage extends LocalStorage {
  static const _sessionKey = 'supabase.session';

  late SharedPreferences _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<bool> hasAccessToken() async => _prefs.containsKey(_sessionKey);

  @override
  Future<String?> accessToken() async => _prefs.getString(_sessionKey);

  @override
  Future<void> removePersistedSession() async {
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _prefs.setString(_sessionKey, persistSessionString);
  }
}
