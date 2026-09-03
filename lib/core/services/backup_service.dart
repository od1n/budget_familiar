import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/app_database.dart';
import '../../l10n/app_localizations.dart';

final _log = Logger();

/// Versión del formato de backup. Incrementar al cambiar la estructura.
const _kBackupVersion = 1;

// ── Servicio ────────────────────────────────────────────────────────────────

class BackupService {
  // ── Exportar ─────────────────────────────────────────────────────────────

  /// Exporta todos los datos del grupo activo como JSON.
  /// Desktop: diálogo de guardar archivo.
  /// Móvil: hoja de compartir.
  static Future<void> exportBackup({
    required BuildContext context,
    required AppDatabase db,
    required String groupId,
  }) async {
    try {
      final data = await _gatherData(db, groupId);
      final backup = {
        'version': _kBackupVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'groupId': groupId,
        'data': data,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final bytes = utf8.encode(jsonStr);
      final fileName =
          'budget_familiar_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      if (_isDesktop) {
        // Guardar en Documentos directamente — el diálogo nativo de
        // file_selector puede quedar detrás de la ventana Flutter en Windows.
        final docsDir = await getApplicationDocumentsDirectory();
        final outFile = File('${docsDir.path}${Platform.pathSeparator}$fileName');
        await outFile.writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).backupSaved(outFile.path)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/json')],
        );
      }
    } catch (e) {
      _log.e('Error exportando backup', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).exportError(e.toString()))),
        );
      }
    }
  }

  // ── Importar ─────────────────────────────────────────────────────────────

  /// Importa datos desde un archivo JSON de backup.
  /// Retorna la cantidad de registros restaurados.
  static Future<void> importBackup({
    required BuildContext context,
    required AppDatabase db,
    required String groupId,
  }) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (file == null) return;

      final jsonStr = await file.readAsString();
      final backup = jsonDecode(jsonStr) as Map<String, dynamic>;

      final version = backup['version'] as int? ?? 0;
      if (version > _kBackupVersion) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).backupNewerVersion,
              ),
            ),
          );
        }
        return;
      }

      final data = backup['data'] as Map<String, dynamic>? ?? {};

      // Confirmar antes de importar.
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(S.of(context).restoreBackupTitle),
          content: Text(
            S.of(context).restoreBackupWarning(_summarize(context, data)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.of(context).cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.of(context).restoreButton),
            ),
          ],
        ),
      );
      if (ok != true) return;

      final count = await _restoreData(db, groupId, data);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).recordsRestored(count))),
        );
      }
    } catch (e) {
      _log.e('Error importando backup', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).importError(e.toString()))),
        );
      }
    }
  }

  // ── Recolección de datos ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _gatherData(
    AppDatabase db,
    String groupId,
  ) async {
    // Transacciones
    final txRows = await (db.select(db.transactionsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    // Categorías (personalizadas del grupo + del sistema)
    final catRows = await (db.select(db.categoriesTable)
          ..where(
            (t) => t.groupId.equals(groupId) | t.groupId.isNull(),
          ))
        .get();

    // Presupuestos
    final budgetRows = await (db.select(db.budgetsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    // Metas de ahorro
    final goalRows = await (db.select(db.savingsGoalsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    // Inversiones
    final invRows = await (db.select(db.investmentsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    // Sobres virtuales
    final envRows = await (db.select(db.virtualEnvelopesTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    // Cuentas
    final accRows = await (db.select(db.accountsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    // Transacciones recurrentes
    final recRows = await (db.select(db.recurringTransactionsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    return {
      'transactions': txRows.map(_txToMap).toList(),
      'categories': catRows.where((c) => !c.isSystem).map(_catToMap).toList(),
      'budgets': budgetRows.map(_budgetToMap).toList(),
      'savingsGoals': goalRows.map(_goalToMap).toList(),
      'investments': invRows.map(_invToMap).toList(),
      'virtualEnvelopes': envRows.map(_envToMap).toList(),
      'accounts': accRows.map(_accToMap).toList(),
      'recurringTransactions': recRows.map(_recToMap).toList(),
    };
  }

  // ── Restauración de datos ────────────────────────────────────────────────

  static Future<int> _restoreData(
    AppDatabase db,
    String groupId,
    Map<String, dynamic> data,
  ) async {
    var count = 0;

    await db.transaction(() async {
      // Categorías
      for (final m in _list(data['categories'])) {
        await db.into(db.categoriesTable).insertOnConflictUpdate(
              CategoriesTableCompanion.insert(
                id: m['id'] as String,
                groupId: Value(groupId),
                name: m['name'] as String,
                iconCode: m['iconCode'] as String,
                colorHex: m['colorHex'] as String,
                type: m['type'] as String,
                isSystem: const Value(false),
                sortOrder: Value(m['sortOrder'] as int? ?? 0),
                isActive: Value(m['isActive'] as bool? ?? true),
              ),
            );
        count++;
      }

      // Cuentas
      for (final m in _list(data['accounts'])) {
        await db.into(db.accountsTable).insertOnConflictUpdate(
              AccountsTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                name: m['name'] as String,
                currencyCode: m['currencyCode'] as String,
                type: Value(m['type'] as String? ?? 'cash'),
                initialBalance:
                    Value((m['initialBalance'] as num?)?.toDouble() ?? 0),
                colorHex: Value(m['colorHex'] as String? ?? '#607D8B'),
                iconCode: Value(
                  m['iconCode'] as String? ?? 'account_balance_wallet',
                ),
                isArchived: Value(m['isArchived'] as bool? ?? false),
              ),
            );
        count++;
      }

      // Transacciones
      for (final m in _list(data['transactions'])) {
        await db.into(db.transactionsTable).insertOnConflictUpdate(
              TransactionsTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                userId: m['userId'] as String,
                categoryId: Value(m['categoryId'] as String?),
                amount: (m['amount'] as num).toDouble(),
                currencyCode: m['currencyCode'] as String,
                amountUsdEquivalent: Value(
                  (m['amountUsdEquivalent'] as num?)?.toDouble(),
                ),
                type: m['type'] as String,
                date: DateTime.parse(m['date'] as String),
                description: Value(m['description'] as String?),
                paymentMethod: Value(m['paymentMethod'] as String?),
                notes: Value(m['notes'] as String?),
                linkedTxId: Value(m['linkedTxId'] as String?),
                accountId: Value(m['accountId'] as String?),
                isSynced: const Value(false),
              ),
            );
        count++;
      }

      // Presupuestos
      for (final m in _list(data['budgets'])) {
        await db.into(db.budgetsTable).insertOnConflictUpdate(
              BudgetsTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                categoryId: m['categoryId'] as String,
                monthlyLimit: (m['monthlyLimit'] as num).toDouble(),
                currencyCode: Value(m['currencyCode'] as String? ?? 'USD'),
              ),
            );
        count++;
      }

      // Metas de ahorro
      for (final m in _list(data['savingsGoals'])) {
        await db.into(db.savingsGoalsTable).insertOnConflictUpdate(
              SavingsGoalsTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                name: m['name'] as String,
                targetAmount: (m['targetAmount'] as num).toDouble(),
                currentAmount:
                    Value((m['currentAmount'] as num?)?.toDouble() ?? 0),
                currencyCode: Value(m['currencyCode'] as String? ?? 'USD'),
                targetDate: Value(
                  m['targetDate'] != null
                      ? DateTime.parse(m['targetDate'] as String)
                      : null,
                ),
                iconCode: Value(m['iconCode'] as String? ?? 'savings'),
                inflationRateMonthly: Value(
                  (m['inflationRateMonthly'] as num?)?.toDouble(),
                ),
              ),
            );
        count++;
      }

      // Inversiones
      for (final m in _list(data['investments'])) {
        await db.into(db.investmentsTable).insertOnConflictUpdate(
              InvestmentsTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                userId: m['userId'] as String,
                name: m['name'] as String,
                type: Value(m['type'] as String? ?? 'other'),
                initialAmount: (m['initialAmount'] as num).toDouble(),
                currentValue:
                    Value((m['currentValue'] as num?)?.toDouble()),
                currencyCode: Value(m['currencyCode'] as String? ?? 'USD'),
                startDate: Value(
                  m['startDate'] != null
                      ? DateTime.parse(m['startDate'] as String)
                      : null,
                ),
                maturityDate: Value(
                  m['maturityDate'] != null
                      ? DateTime.parse(m['maturityDate'] as String)
                      : null,
                ),
                institution: Value(m['institution'] as String?),
                notes: Value(m['notes'] as String?),
                isActive: Value(m['isActive'] as bool? ?? true),
              ),
            );
        count++;
      }

      // Sobres virtuales
      for (final m in _list(data['virtualEnvelopes'])) {
        await db.into(db.virtualEnvelopesTable).insertOnConflictUpdate(
              VirtualEnvelopesTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                categoryId: Value(m['categoryId'] as String?),
                name: m['name'] as String,
                allocatedAmount:
                    (m['allocatedAmount'] as num).toDouble(),
                spentAmount:
                    Value((m['spentAmount'] as num?)?.toDouble() ?? 0),
                currencyCode: Value(m['currencyCode'] as String? ?? 'USD'),
                periodStart:
                    DateTime.parse(m['periodStart'] as String),
                periodEnd: DateTime.parse(m['periodEnd'] as String),
                isActive: Value(m['isActive'] as bool? ?? true),
              ),
            );
        count++;
      }

      // Transacciones recurrentes
      for (final m in _list(data['recurringTransactions'])) {
        await db.into(db.recurringTransactionsTable).insertOnConflictUpdate(
              RecurringTransactionsTableCompanion.insert(
                id: m['id'] as String,
                groupId: groupId,
                userId: m['userId'] as String,
                categoryId: Value(m['categoryId'] as String?),
                amount: (m['amount'] as num).toDouble(),
                currencyCode: Value(m['currencyCode'] as String? ?? 'USD'),
                type: m['type'] as String,
                description: Value(m['description'] as String?),
                frequency: m['frequency'] as String,
                dayOfMonth: Value(m['dayOfMonth'] as int?),
                nextDueDate:
                    DateTime.parse(m['nextDueDate'] as String),
                isActive: Value(m['isActive'] as bool? ?? true),
              ),
            );
        count++;
      }
    });

    return count;
  }

  // ── Serialización ────────────────────────────────────────────────────────

  static Map<String, dynamic> _txToMap(TransactionsTableData t) => {
        'id': t.id,
        'userId': t.userId,
        'categoryId': t.categoryId,
        'amount': t.amount,
        'currencyCode': t.currencyCode,
        'amountUsdEquivalent': t.amountUsdEquivalent,
        'type': t.type,
        'date': t.date.toIso8601String(),
        'description': t.description,
        'paymentMethod': t.paymentMethod,
        'notes': t.notes,
        'linkedTxId': t.linkedTxId,
        'accountId': t.accountId,
      };

  static Map<String, dynamic> _catToMap(CategoriesTableData c) => {
        'id': c.id,
        'name': c.name,
        'iconCode': c.iconCode,
        'colorHex': c.colorHex,
        'type': c.type,
        'sortOrder': c.sortOrder,
        'isActive': c.isActive,
      };

  static Map<String, dynamic> _budgetToMap(BudgetsTableData b) => {
        'id': b.id,
        'categoryId': b.categoryId,
        'monthlyLimit': b.monthlyLimit,
        'currencyCode': b.currencyCode,
      };

  static Map<String, dynamic> _goalToMap(SavingsGoalsTableData g) => {
        'id': g.id,
        'name': g.name,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
        'currencyCode': g.currencyCode,
        'targetDate': g.targetDate?.toIso8601String(),
        'iconCode': g.iconCode,
        'inflationRateMonthly': g.inflationRateMonthly,
      };

  static Map<String, dynamic> _invToMap(InvestmentsTableData i) => {
        'id': i.id,
        'userId': i.userId,
        'name': i.name,
        'type': i.type,
        'initialAmount': i.initialAmount,
        'currentValue': i.currentValue,
        'currencyCode': i.currencyCode,
        'startDate': i.startDate?.toIso8601String(),
        'maturityDate': i.maturityDate?.toIso8601String(),
        'institution': i.institution,
        'notes': i.notes,
        'isActive': i.isActive,
      };

  static Map<String, dynamic> _envToMap(VirtualEnvelopesTableData e) => {
        'id': e.id,
        'categoryId': e.categoryId,
        'name': e.name,
        'allocatedAmount': e.allocatedAmount,
        'spentAmount': e.spentAmount,
        'currencyCode': e.currencyCode,
        'periodStart': e.periodStart.toIso8601String(),
        'periodEnd': e.periodEnd.toIso8601String(),
        'isActive': e.isActive,
      };

  static Map<String, dynamic> _accToMap(AccountsTableData a) => {
        'id': a.id,
        'name': a.name,
        'type': a.type,
        'currencyCode': a.currencyCode,
        'initialBalance': a.initialBalance,
        'colorHex': a.colorHex,
        'iconCode': a.iconCode,
        'isArchived': a.isArchived,
      };

  static Map<String, dynamic> _recToMap(RecurringTransactionsTableData r) => {
        'id': r.id,
        'userId': r.userId,
        'categoryId': r.categoryId,
        'amount': r.amount,
        'currencyCode': r.currencyCode,
        'type': r.type,
        'description': r.description,
        'frequency': r.frequency,
        'dayOfMonth': r.dayOfMonth,
        'nextDueDate': r.nextDueDate.toIso8601String(),
        'isActive': r.isActive,
      };

  // ── Utilidades ───────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

  static String _summarize(BuildContext context, Map<String, dynamic> data) {
    final s = S.of(context);
    final parts = <String>[];
    void add(String key, String label) {
      final list = data[key] as List?;
      if (list != null && list.isNotEmpty) parts.add('${list.length} $label');
    }

    add('transactions', s.sumTransactions);
    add('categories', s.sumCategories);
    add('budgets', s.sumBudgets);
    add('savingsGoals', s.sumGoals);
    add('investments', s.sumInvestments);
    add('virtualEnvelopes', s.sumEnvelopes);
    add('accounts', s.sumAccounts);
    add('recurringTransactions', s.sumRecurring);
    return parts.isEmpty ? s.sumEmpty : parts.join(', ');
  }

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
