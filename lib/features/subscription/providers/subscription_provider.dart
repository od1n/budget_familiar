import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/subscription_service.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(SubscriptionState.free) {
    _init();
  }

  final _service = SubscriptionService.instance;

  Future<void> _init() async {
    final cached = await _service.loadFromCache();
    if (mounted) state = cached;
  }

  /// Refresca desde Supabase. Llamar al hacer sign-in y en el botón "Restaurar".
  Future<void> refresh() async {
    final fresh = await _service.refresh();
    if (mounted) state = fresh;
  }

  /// Limpia el estado al cerrar sesión.
  Future<void> clear() async {
    await _service.clearCache();
    if (mounted) state = SubscriptionState.free;
  }
}

// ── Provider principal ────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);

// ── Selectores ────────────────────────────────────────────────────────────────

/// `true` si el usuario tiene suscripción activa y no expirada.
/// Equivale a "al menos plan Familiar activo".
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isActive;
});

/// `true` si el usuario tiene acceso a features de grupo
/// (plan Familiar, Premium o Beta, activos).
final hasGroupAccessProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.isActive && sub.hasGroupAccess;
});

/// `true` si el usuario tiene acceso a features de IA
/// (plan Premium o Beta, activos).
final hasAiAccessProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.isActive && sub.canUseAi;
});

/// Nombre del plan activo del usuario ('free', 'family', 'premium', 'beta').
final planNameProvider = Provider<String>((ref) {
  return ref.watch(subscriptionProvider).planName;
});

/// Máximo de miembros permitidos según el plan del usuario.
final maxMembersProvider = Provider<int>((ref) {
  return ref.watch(subscriptionProvider).maxMembers;
});
