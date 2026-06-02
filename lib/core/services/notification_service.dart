import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/app_database.dart';
import '../../features/budgets/providers/budget_alert_provider.dart';

final _log = Logger();

/// Gestiona notificaciones locales del SO.
///
/// Plataformas soportadas:
/// - Android / iOS  → flutter_local_notifications nativo
/// - Windows        → Windows Toast Notifications (flutter_local_notifications ≥17)
/// - Linux / macOS  → libnotify / UNNotification
///
/// La inicialización es no-fatal: si falla (p. ej. AUMID no registrado en
/// Windows sin instalador), `_ready` queda en `false` y todos los métodos
/// de show* retornan sin hacer nada. El SnackBar de AdaptiveScaffold actúa
/// como fallback garantizado para alertas de presupuesto.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // IDs fijos — evitan notificaciones duplicadas al reemplazar la anterior
  static const int _idRecurring = 1001;
  static const int _idWeeklySummary = 1002;

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'Abrir');

      // Windows: flutter_local_notifications v17 no incluye soporte nativo
      // de Toast en Windows Desktop. Las notificaciones en Windows se
      // manejan mediante el SnackBar en AdaptiveScaffold (fallback garantizado).
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      );
      await _plugin.initialize(settings);
      _ready = true;
      _log.i('NotificationService: inicializado');
    } catch (e) {
      _log.w('NotificationService: falló la inicialización: $e');
    }
  }

  // ── Solicitar permisos (Android 13+ / iOS) ────────────────────────────────

  Future<void> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
      }
      // Windows y Linux no requieren solicitar permisos explícitamente.
    } catch (e) {
      _log.w('NotificationService: no se pudieron solicitar permisos: $e');
    }
  }

  // ── Alerta de presupuesto ─────────────────────────────────────────────────

  /// Muestra una notificación cuando el gasto mensual supera (o se acerca a)
  /// el límite de una categoría. Funciona en todas las plataformas soportadas.
  ///
  /// El SnackBar en AdaptiveScaffold sigue siendo el fallback en-app; esta
  /// notificación del SO complementa cuando la app está en segundo plano.
  Future<void> showBudgetAlert(BudgetAlert alert) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        alert.categoryId.hashCode & 0x7FFFFFFF, // ID positivo
        alert.isOver ? 'Presupuesto superado' : 'Aviso de presupuesto',
        alert.message,
        _buildDetails(
          channelId: 'budget_alerts',
          channelName: 'Alertas de presupuesto',
          channelDescription:
              'Avisos cuando el gasto mensual supera el límite configurado.',
        ),
      );
    } catch (e) {
      _log.w('NotificationService: fallo en showBudgetAlert: $e');
    }
  }

  // ── Alerta de recurrentes generadas ──────────────────────────────────────

  /// Notifica cuántas transacciones recurrentes se generaron automáticamente.
  /// Se llama desde app.dart tras [RecurringService.processOverdue].
  Future<void> showRecurringAlert(int count) async {
    if (!_ready || count == 0) return;
    try {
      final body = count == 1
          ? 'Se generó 1 transacción recurrente automáticamente.'
          : 'Se generaron $count transacciones recurrentes automáticamente.';
      await _plugin.show(
        _idRecurring,
        'Transacciones recurrentes',
        body,
        _buildDetails(
          channelId: 'recurring_alerts',
          channelName: 'Transacciones recurrentes',
          channelDescription:
              'Aviso cuando se generan transacciones periódicas de forma automática.',
        ),
      );
    } catch (e) {
      _log.w('NotificationService: fallo en showRecurringAlert: $e');
    }
  }

  // ── Resumen mensual semanal ───────────────────────────────────────────────

  /// Muestra el resumen del mes actual con ingresos, gastos y balance.
  Future<void> showWeeklySummary({
    required double income,
    required double expense,
    required double balance,
  }) async {
    if (!_ready) return;
    try {
      final sign = balance >= 0 ? '+' : '';
      final body = 'Ingresos \$${income.toStringAsFixed(2)}'
          ' · Gastos \$${expense.toStringAsFixed(2)}'
          ' · Balance $sign${balance.toStringAsFixed(2)}';
      await _plugin.show(
        _idWeeklySummary,
        'Resumen del mes',
        body,
        _buildDetails(
          channelId: 'weekly_summary',
          channelName: 'Resumen semanal',
          channelDescription: 'Resumen mensual del presupuesto familiar.',
        ),
      );
    } catch (e) {
      _log.w('NotificationService: fallo en showWeeklySummary: $e');
    }
  }

  /// Comprueba si ya se mostró el resumen esta semana ISO. Si no, consulta
  /// la DB, calcula los totales del mes en curso y muestra la notificación.
  ///
  /// Diseño: se llama una vez al arrancar la app (tras sign-in). SharedPrefs
  /// garantiza que solo aparece una vez por semana calendario, independiente
  /// de cuántas veces se reinicie la app.
  Future<void> checkAndShowWeeklySummary({
    required String groupId,
    required AppDatabase db,
  }) async {
    if (groupId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final weekKey = _isoWeekKey(now); // p.ej. "2026-W22"
      final prefKey = 'weekly_summary_shown_${groupId}_$weekKey';

      if (prefs.getBool(prefKey) ?? false) return; // ya mostrado esta semana

      final summary = await db.transactionsDao.getMonthlySummary(
        groupId: groupId,
        year: now.year,
        month: now.month,
      );
      if (summary.count == 0) return; // sin datos: omitir para no confundir

      await showWeeklySummary(
        income: summary.totalIncome,
        expense: summary.totalExpense,
        balance: summary.balance,
      );
      await prefs.setBool(prefKey, true);
    } catch (e) {
      _log.w('NotificationService: fallo en checkAndShowWeeklySummary: $e');
    }
  }

  // ── Helpers internos ──────────────────────────────────────────────────────

  /// Construye [NotificationDetails] para todas las plataformas a partir de
  /// los parámetros del canal Android (reutilizados como etiqueta en iOS/Win).
  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
      linux: const LinuxNotificationDetails(),
    );
  }

  /// Devuelve la clave de semana ISO: `"<año>-W<nn>"`.
  ///
  /// Algoritmo estándar ISO 8601: el número de semana se calcula respecto al
  /// jueves de la semana (que siempre cae en el año correcto).
  @visibleForTesting
  static String isoWeekKey(DateTime d) => _isoWeekKey(d);

  static String _isoWeekKey(DateTime d) {
    // ISO 8601: el jueves de cada semana determina el año y número de semana.
    final thursday = d.add(Duration(days: DateTime.thursday - d.weekday));

    // Enero 4 siempre cae en la semana 1. Encontramos el jueves de esa semana
    // para usarlo como ancla del cálculo.
    final jan4 = DateTime(thursday.year, 1, 4);
    final firstThursday =
        jan4.add(Duration(days: DateTime.thursday - jan4.weekday));

    final weekNum = 1 + thursday.difference(firstThursday).inDays ~/ 7;
    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }
}
