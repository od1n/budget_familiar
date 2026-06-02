import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

final _log = Logger();
final _fmt = NumberFormat('#,##0.00');

/// Actualiza el widget de pantalla de inicio con los datos financieros actuales.
/// Solo funciona en Android. En otras plataformas es un no-op.
class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static bool get _supported =>
      !kIsWeb && Platform.isAndroid;

  static const _appGroupId = 'com.budgetfamiliar.app';
  static const _widgetName = 'BalanceWidget';

  /// Escribe los datos del widget y solicita actualización.
  Future<void> updateBalance({
    required double balance,
    required double income,
    required double expense,
    String currency = 'USD',
  }) async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final now = DateTime.now();
      final monthLabel =
          'Balance de ${DateFormat('MMMM yyyy', 'es').format(now)}';
      final sign = balance >= 0 ? '' : '-';
      final absBalance = balance.abs();

      await Future.wait([
        HomeWidget.saveWidgetData<String>(
            'widget_balance', '$currency $sign${_fmt.format(absBalance)}'),
        HomeWidget.saveWidgetData<String>(
            'widget_income', '$currency ${_fmt.format(income)}'),
        HomeWidget.saveWidgetData<String>(
            'widget_expense', '$currency ${_fmt.format(expense)}'),
        HomeWidget.saveWidgetData<String>('widget_label', monthLabel),
      ]);

      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );

      _log.d(
        'WidgetService: actualizado — balance=$currency ${_fmt.format(balance)}',
      );
    } catch (e) {
      _log.w('WidgetService: error al actualizar widget: $e');
    }
  }
}
