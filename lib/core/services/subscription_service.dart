import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

final _log = Logger();

// ── Niveles de plan ───────────────────────────────────────────────────────────

/// Orden de planes de menor a mayor. Útil para comparaciones.
enum PlanTier {
  free,    // $0
  family,  // $2.99/mes
  premium, // $9.99/mes
  beta,    // Acceso completo para beta testers
}

extension PlanTierX on PlanTier {
  /// `true` si este tier es mayor o igual al tier requerido.
  bool includes(PlanTier required) {
    // beta tiene acceso a todo
    if (this == PlanTier.beta) return true;
    return index >= required.index;
  }
}

// ── Estado de suscripción ─────────────────────────────────────────────────────

/// Modelo inmutable del estado de suscripción del usuario.
class SubscriptionState {
  const SubscriptionState({
    this.planName = 'free',
    this.billingCycle,
    this.expiresAt,
  });

  /// Nombre del plan: 'beta' | 'free' | 'family' | 'premium'
  final String planName;

  /// Ciclo de facturación: 'monthly' | 'annual' | null (beta/free)
  final String? billingCycle;

  /// Fecha de expiración. null = beta (sin vencimiento) o free.
  final DateTime? expiresAt;

  // ── Tier ─────────────────────────────────────────────────────────────────

  PlanTier get tier => switch (planName) {
        'premium' => PlanTier.premium,
        'family'  => PlanTier.family,
        'beta'    => PlanTier.beta,
        _         => PlanTier.free,
      };

  // ── Estado de vigencia ───────────────────────────────────────────────────

  /// `true` si el plan es de pago y no ha vencido.
  bool get isActive {
    if (tier == PlanTier.free) return false;
    if (expiresAt == null) return true; // beta o lifetime
    return DateTime.now().isBefore(expiresAt!);
  }

  // ── Capacidades del plan ─────────────────────────────────────────────────

  /// Puede exportar PDF/CSV.
  bool get canExportPdf => tier.includes(PlanTier.family);

  /// Puede usar IA (insights, recomendaciones avanzadas).
  bool get canUseAi => tier.includes(PlanTier.premium);

  /// Puede usar la app en escritorio con todas las funciones.
  bool get canUseDesktop => tier.includes(PlanTier.family);

  /// Puede unirse / crear grupos con más de 1 miembro extra.
  bool get hasGroupAccess => tier.includes(PlanTier.family);

  /// Número máximo de miembros en el grupo familiar.
  int get maxMembers => switch (tier) {
        PlanTier.premium || PlanTier.beta => 10,
        PlanTier.family                    => 5,
        PlanTier.free                      => 2,
      };

  /// Número máximo de categorías personalizadas.
  int get maxCustomCategories => switch (tier) {
        PlanTier.premium || PlanTier.beta => 50,
        PlanTier.family                    => 30,
        PlanTier.free                      => 10,
      };

  // ── Compatibilidad con código antiguo ────────────────────────────────────

  /// `true` si el usuario tiene cualquier plan de pago activo.
  /// Alias de [isActive] para compatibilidad con código existente.
  bool get isPremium => isActive;

  // ── Labels ───────────────────────────────────────────────────────────────

  String get planLabel => switch (planName) {
        'premium' => billingCycle == 'annual' ? 'Premium Anual' : 'Premium',
        'family'  => billingCycle == 'annual' ? 'Familiar Anual' : 'Familiar',
        'beta'    => 'Beta Tester',
        _         => 'Gratuito',
      };

  // ── Constructores de conveniencia ────────────────────────────────────────

  static const free = SubscriptionState();

  SubscriptionState copyWith({
    String? planName,
    String? billingCycle,
    DateTime? expiresAt,
  }) =>
      SubscriptionState(
        planName: planName ?? this.planName,
        billingCycle: billingCycle ?? this.billingCycle,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}

// ── SubscriptionService ───────────────────────────────────────────────────────

/// Gestiona el estado de suscripción.
///
/// Arquitectura:
/// - **Supabase** es la fuente de verdad: columna `plan_name` en `profiles`.
/// - **SharedPreferences** actúa como caché local para respuesta inmediata.
/// - El webhook de LemonSqueezy llama a `set_user_plan` con service_role.
///
/// Flujo:
/// 1. Al iniciar → leer caché local (respuesta inmediata).
/// 2. Al hacer login → `refresh()` desde Supabase, sobreescribe caché.
/// 3. Botón "Restaurar" → `refresh()` manual.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  // ── Claves SharedPreferences ─────────────────────────────────────────────

  static const _kPlanName    = 'sub_plan_name';
  static const _kBilling     = 'sub_billing_cycle';
  static const _kExpiresKey  = 'sub_expires_at';

  // Claves antiguas (para migración de caché)
  static const _kOldPremium  = 'sub_is_premium';
  static const _kOldPlan     = 'sub_plan';

  // ── Estado en memoria ────────────────────────────────────────────────────

  SubscriptionState _state = SubscriptionState.free;
  SubscriptionState get state => _state;

  // ── Inicialización desde caché ───────────────────────────────────────────

  /// Lee el estado guardado localmente. Llamar antes del primer frame.
  Future<SubscriptionState> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planName = prefs.getString(_kPlanName);

      if (planName != null) {
        // Caché nueva con plan_name
        final billing    = prefs.getString(_kBilling);
        final expiresRaw = prefs.getString(_kExpiresKey);
        final expiresAt  = expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
        _state = SubscriptionState(
          planName: planName,
          billingCycle: billing,
          expiresAt: expiresAt,
        );
      } else {
        // Migración: caché antigua con is_premium boolean
        final wasPremium = prefs.getBool(_kOldPremium) ?? false;
        if (wasPremium) {
          final oldPlan    = prefs.getString(_kOldPlan);
          final expiresRaw = prefs.getString(_kExpiresKey);
          final expiresAt  = expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
          _state = SubscriptionState(
            planName: 'premium',
            billingCycle: oldPlan,
            expiresAt: expiresAt,
          );
          // Guardar en el nuevo formato
          await _saveToCache(_state);
        }
      }
    } catch (e) {
      _log.w('SubscriptionService: error al leer caché: $e');
    }
    return _state;
  }

  // ── Refresh desde Supabase ───────────────────────────────────────────────

  /// Consulta `profiles` en Supabase y actualiza la caché local.
  Future<SubscriptionState> refresh() async {
    final user = supabase.auth.currentUser;
    if (user == null) return SubscriptionState.free;

    try {
      final row = await supabase
          .from('profiles')
          .select('plan_name, premium_plan, premium_expires_at')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) return _state;

      final planName   = (row['plan_name'] as String?) ?? 'free';
      final billing    = row['premium_plan'] as String?;
      final expiresRaw = row['premium_expires_at'] as String?;
      final expiresAt  = expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;

      _state = SubscriptionState(
        planName: planName,
        billingCycle: billing,
        expiresAt: expiresAt,
      );

      await _saveToCache(_state);
      _log.i('SubscriptionService: plan actualizado → ${_state.planLabel}');
    } catch (e) {
      _log.w('SubscriptionService: error al consultar Supabase: $e');
    }

    return _state;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _saveToCache(SubscriptionState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPlanName, s.planName);
      if (s.billingCycle != null) {
        await prefs.setString(_kBilling, s.billingCycle!);
      } else {
        await prefs.remove(_kBilling);
      }
      if (s.expiresAt != null) {
        await prefs.setString(_kExpiresKey, s.expiresAt!.toIso8601String());
      } else {
        await prefs.remove(_kExpiresKey);
      }
    } catch (e) {
      _log.w('SubscriptionService: error al guardar caché: $e');
    }
  }

  /// Limpia toda la caché al cerrar sesión o eliminar la cuenta.
  Future<void> clearCache() async {
    _state = SubscriptionState.free;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPlanName);
      await prefs.remove(_kBilling);
      await prefs.remove(_kExpiresKey);
      await prefs.remove(_kOldPremium);
      await prefs.remove(_kOldPlan);
    } catch (_) {}
  }
}
