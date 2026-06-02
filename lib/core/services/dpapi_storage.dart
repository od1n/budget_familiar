import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estructura DATA_BLOB usada por Windows DPAPI.
final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

// ── Typedefs Win32 ────────────────────────────────────────────────────────────

typedef _CryptProtectNative = Int32 Function(
  Pointer<_DataBlob> pDataIn,
  Pointer<Void> szDataDescr,
  Pointer<_DataBlob> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  Uint32 dwFlags,
  Pointer<_DataBlob> pDataOut,
);
typedef _CryptProtectDart = int Function(
  Pointer<_DataBlob>,
  Pointer<Void>,
  Pointer<_DataBlob>,
  Pointer<Void>,
  Pointer<Void>,
  int,
  Pointer<_DataBlob>,
);

typedef _CryptUnprotectNative = Int32 Function(
  Pointer<_DataBlob> pDataIn,
  Pointer<Pointer<Void>> ppszDataDescr,
  Pointer<_DataBlob> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  Uint32 dwFlags,
  Pointer<_DataBlob> pDataOut,
);
typedef _CryptUnprotectDart = int Function(
  Pointer<_DataBlob>,
  Pointer<Pointer<Void>>,
  Pointer<_DataBlob>,
  Pointer<Void>,
  Pointer<Void>,
  int,
  Pointer<_DataBlob>,
);

typedef _LocalFreeNative = Pointer<Void> Function(Pointer<Void> hMem);
typedef _LocalFreeDart = Pointer<Void> Function(Pointer<Void> hMem);

// ── DpapiStorage ──────────────────────────────────────────────────────────────

/// [LocalStorage] para Windows que cifra la sesión con DPAPI
/// (CryptProtectData / CryptUnprotectData de crypt32.dll).
///
/// Ventajas sobre SharedPreferences en texto plano:
/// - Los datos cifrados solo pueden ser descifrados por el mismo usuario
///   de Windows en el mismo equipo.
/// - No requiere contraseña ni certificado externo.
/// - No compila C++ ni necesita ATL — usa crypt32.dll vía dart:ffi en runtime.
class DpapiStorage extends LocalStorage {
  static const _sessionKey = 'supabase.session.dpapi';

  late final _CryptProtectDart _cryptProtect;
  late final _CryptUnprotectDart _cryptUnprotect;
  late final _LocalFreeDart _localFree;
  bool _loaded = false;

  void _loadLibraries() {
    if (_loaded) return;
    final crypt32 = DynamicLibrary.open('crypt32.dll');
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    _cryptProtect = crypt32.lookupFunction<_CryptProtectNative, _CryptProtectDart>(
      'CryptProtectData',
    );
    _cryptUnprotect = crypt32.lookupFunction<_CryptUnprotectNative, _CryptUnprotectDart>(
      'CryptUnprotectData',
    );
    _localFree = kernel32.lookupFunction<_LocalFreeNative, _LocalFreeDart>(
      'LocalFree',
    );
    _loaded = true;
  }

  @override
  Future<void> initialize() async {
    _loadLibraries();
  }

  @override
  Future<bool> hasAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_sessionKey);
  }

  @override
  Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_sessionKey);
    if (encoded == null) return null;
    try {
      return _decrypt(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final encrypted = _encrypt(utf8.encode(persistSessionString));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, base64Encode(encrypted));
  }

  // ── Cifrado DPAPI ───────────────────────────────────────────────────────────

  Uint8List _encrypt(List<int> plaintext) {
    return using((arena) {
      final inData = arena<Uint8>(plaintext.length);
      for (var i = 0; i < plaintext.length; i++) {
        inData[i] = plaintext[i];
      }
      final inBlob = arena<_DataBlob>()
        ..ref.cbData = plaintext.length
        ..ref.pbData = inData;
      final outBlob = arena<_DataBlob>();

      final ok = _cryptProtect(
        inBlob, nullptr, nullptr, nullptr, nullptr, 0, outBlob,
      );
      if (ok == 0) throw Exception('DPAPI: CryptProtectData falló');

      final result = Uint8List.fromList(
        List.generate(outBlob.ref.cbData, (i) => outBlob.ref.pbData[i]),
      );
      _localFree(outBlob.ref.pbData.cast());
      return result;
    });
  }

  String _decrypt(Uint8List ciphertext) {
    return using((arena) {
      final inData = arena<Uint8>(ciphertext.length);
      for (var i = 0; i < ciphertext.length; i++) {
        inData[i] = ciphertext[i];
      }
      final inBlob = arena<_DataBlob>()
        ..ref.cbData = ciphertext.length
        ..ref.pbData = inData;
      final outBlob = arena<_DataBlob>();
      final descPtr = arena<Pointer<Void>>();

      final ok = _cryptUnprotect(
        inBlob, descPtr, nullptr, nullptr, nullptr, 0, outBlob,
      );
      if (ok == 0) throw Exception('DPAPI: CryptUnprotectData falló');

      final result = utf8.decode(
        List.generate(outBlob.ref.cbData, (i) => outBlob.ref.pbData[i]),
      );
      _localFree(outBlob.ref.pbData.cast());
      return result;
    });
  }
}
