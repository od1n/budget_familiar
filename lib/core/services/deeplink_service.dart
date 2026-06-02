import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Scheme personalizado para deeplinks de la app.
const kAppScheme = 'budgetfamiliar';

/// Genera un deeplink de invitación familiar.
String buildInviteLink(String code) => '$kAppScheme://join/$code';

// ── Servicio ────────────────────────────────────────────────────────────────

class DeeplinkService {
  DeeplinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  /// Último código de invitación recibido por deeplink, pendiente de procesar.
  final pendingInviteCode = ValueNotifier<String?>(null);

  /// Inicializa el listener de deeplinks.
  /// Debe llamarse después de que el ProviderScope esté montado.
  Future<void> initialize() async {
    // Link que abrió la app (cold start).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      _log.w('DeeplinkService: error getting initial link: $e');
    }

    // Links recibidos mientras la app está abierta (warm start).
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => _log.w('DeeplinkService: stream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    _log.i('Deeplink recibido: $uri');

    // budgetfamiliar://join/AB3KP9MZ
    if (uri.scheme == kAppScheme && uri.host == 'join') {
      final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (code.isNotEmpty) {
        _log.i('Código de invitación desde deeplink: $code');
        pendingInviteCode.value = code;
      }
    }
  }

  /// Consume el código pendiente (lo lee y lo limpia).
  String? consumePendingCode() {
    final code = pendingInviteCode.value;
    pendingInviteCode.value = null;
    return code;
  }

  void dispose() {
    _sub?.cancel();
    pendingInviteCode.dispose();
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final deeplinkServiceProvider = Provider<DeeplinkService>((_) {
  final svc = DeeplinkService();
  return svc;
});

/// Emite el código de invitación pendiente cuando cambia.
/// Útil para ref.listen() en widgets.
final pendingInviteCodeProvider = StreamProvider.autoDispose<String?>((ref) {
  final svc = ref.watch(deeplinkServiceProvider);
  final controller = StreamController<String?>();

  void listener() => controller.add(svc.pendingInviteCode.value);
  svc.pendingInviteCode.addListener(listener);

  ref.onDispose(() {
    svc.pendingInviteCode.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});
