import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

part 'auth_provider.g.dart';

const _kOAuthPort = 7777;
const _kOAuthRedirect = 'http://localhost:$_kOAuthPort';

const _kSuccessHtml = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Budget Familiar</title>
  <style>
    body { font-family: sans-serif; text-align: center; padding: 60px; color: #111827; }
    .icon { font-size: 56px; }
    h2 { color: #1A56DB; margin: 16px 0 8px; }
    p { color: #6B7280; }
  </style>
</head>
<body>
  <div class="icon">✓</div>
  <h2>Autenticación completada</h2>
  <p>Puedes cerrar esta ventana y volver a Budget Familiar.</p>
</body>
</html>''';

@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  return supabase.auth.onAuthStateChange;
}

@riverpod
Session? currentSession(CurrentSessionRef ref) {
  return supabase.auth.currentSession;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() => AsyncValue.data(supabase.auth.currentUser);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user;
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': displayName},
      );
      return res.user;
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    state = await AsyncValue.guard(
      isDesktop ? _signInWithGoogleDesktop : _signInWithGoogleMobile,
    );
  }

  /// Flujo desktop: abre el navegador del sistema y captura el callback
  /// en un servidor HTTP local en localhost:7777.
  Future<User?> _signInWithGoogleDesktop() async {
    HttpServer? server;
    try {
      // Iniciar servidor antes de abrir el navegador para evitar race condition.
      try {
        server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          _kOAuthPort,
        );
      } on SocketException {
        throw Exception(
          'El puerto $_kOAuthPort está en uso por otra aplicación. '
          'Cierra otros programas y vuelve a intentarlo.',
        );
      }

      // Abrir flujo OAuth en el navegador del sistema.
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _kOAuthRedirect,
      );

      // Esperar el redirect (máx. 5 minutos).
      final request = await server.first.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException(
          'Tiempo de espera agotado. Intenta iniciar sesión de nuevo.',
        ),
      );

      final callbackUri = request.requestedUri;

      // Responder al navegador con una página de confirmación.
      request.response
        ..statusCode = 200
        ..headers.set('Content-Type', 'text/html; charset=utf-8')
        ..write(_kSuccessHtml);
      await request.response.close();

      // Intercambiar el código de autorización por una sesión.
      await supabase.auth.getSessionFromUrl(callbackUri);
      return supabase.auth.currentUser;
    } finally {
      await server?.close(force: true);
    }
  }

  /// Flujo móvil: deep link nativo (Android / iOS).
  Future<User?> _signInWithGoogleMobile() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.budgetfamiliar://login-callback/',
    );
    return supabase.auth.currentUser;
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.budgetfamiliar://login-callback/',
      );
      return supabase.auth.currentUser;
    });
  }

  Future<void> updateDisplayName(String displayName) async {
    state = await AsyncValue.guard(() async {
      final res = await supabase.auth.updateUser(
        UserAttributes(data: {'full_name': displayName}),
      );
      return res.user;
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Elimina permanentemente la cuenta del usuario.
  ///
  /// Llama a la Edge Function `delete-account`, que verifica que el usuario
  /// no sea owner de un grupo con otros miembros y luego borra el registro
  /// en auth.users (cascadea a profiles, transacciones, membresías, etc.).
  ///
  /// Lanza [AccountDeletionException] con código específico para errores
  /// manejables (ej. `owner_with_members`).
  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response =
          await supabase.functions.invoke('delete-account');

      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        final errorCode = data?['error'] as String?;
        final message = data?['message'] as String?;
        throw AccountDeletionException(
          code: errorCode ?? 'unknown',
          message: message ??
              'No se pudo eliminar la cuenta. Intenta de nuevo.',
        );
      }

      // Cerrar sesión local (el token ya es inválido)
      await supabase.auth.signOut();
      return null;
    });
  }
}

/// Excepción tipada para errores de eliminación de cuenta.
class AccountDeletionException implements Exception {
  const AccountDeletionException({required this.code, required this.message});

  /// Código de error de la Edge Function.
  /// Valores conocidos: `owner_with_members`, `invalid_session`, `server_error`.
  final String code;
  final String message;

  @override
  String toString() => 'AccountDeletionException($code): $message';
}
