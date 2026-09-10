import 'dart:convert';
import 'dart:typed_data';

import 'package:logger/logger.dart';

import 'supabase_service.dart';

final _log = Logger();

/// Resultado de un llamado OCR vía proxy.
class AiOcrResult {
  const AiOcrResult({
    this.amount,
    this.description,
    this.date,
    this.categoryHint,
    this.currency,
    this.type,
    this.error,
  });

  final String? amount;
  final String? description;
  final DateTime? date;
  final String? categoryHint;
  final String? currency;
  final String? type; // 'expense' | 'income' (solo en interpretación por texto/voz)
  final String? error;

  bool get isSuccess => error == null;
}

/// Una recomendación de inversión/finanzas.
class AiRecommendation {
  const AiRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
  });

  final String title;
  final String description;
  final String priority; // 'high' | 'medium' | 'low'
  final String category; // 'ahorro' | 'gasto' | 'inversión' | 'deuda' | 'divisa'

  factory AiRecommendation.fromJson(Map<String, dynamic> j) =>
      AiRecommendation(
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        priority: j['priority'] as String? ?? 'medium',
        category: j['category'] as String? ?? 'ahorro',
      );
}

/// Contexto financiero mensual para las recomendaciones.
class InvestmentContext {
  const InvestmentContext({
    required this.income,
    required this.expense,
    required this.balance,
    required this.month,
    required this.currency,
    required this.topCategories,
    required this.savingsGoals,
  });

  final double income;
  final double expense;
  final double balance;
  final String month; // 'Mayo 2026'
  final String currency;
  final List<({String name, double amount})> topCategories;
  final List<({String name, double current, double target})> savingsGoals;

  Map<String, dynamic> toJson() => {
        'income': income,
        'expense': expense,
        'balance': balance,
        'month': month,
        'currency': currency,
        'top_categories': topCategories
            .map((c) => {'name': c.name, 'amount': c.amount})
            .toList(),
        'savings_goals': savingsGoals
            .map((g) => {
                  'name': g.name,
                  'current': g.current,
                  'target': g.target,
                },)
            .toList(),
      };
}

/// Servicio que llama la Edge Function `ai-proxy` de Supabase.
///
/// Flujo:
/// - Si [byokKey] es provisto → se usa esa key, sin consumir cuota del plan Pro.
/// - Si [byokKey] es null → se usa la key del desarrollador, verificando cuota.
/// - Si el usuario es Free y no provee [byokKey] → la Edge Function retorna 403.
class AiProxyService {
  AiProxyService._();
  static final AiProxyService instance = AiProxyService._();

  static const _functionName = 'quick-api';

  // ── OCR ──────────────────────────────────────────────────────────────────────

  /// Envía una imagen al proxy y retorna los datos del recibo extraídos.
  /// [imageBytes] son los bytes crudos de la imagen (JPEG o PNG).
  /// [mimeType] debe ser 'image/jpeg' o 'image/png'.
  /// [byokKey] es la Gemini API key del usuario (opcional).
  Future<AiOcrResult> ocr({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? byokKey,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final body = <String, dynamic>{
        'feature': 'ocr',
        'image_base64': base64Image,
        'mime_type': mimeType,
        if (byokKey != null) 'byok_key': byokKey,
      };

      final response = await supabase.functions.invoke(
        _functionName,
        body: body,
      );

      if (response.status == 403) {
        return const AiOcrResult(error: 'pro_required');
      }
      if (response.status == 429) {
        final msg = (response.data as Map?)?['message'] as String? ??
            'Límite mensual alcanzado.';
        return AiOcrResult(error: msg);
      }
      if (response.status != 200) {
        return AiOcrResult(
          error: (response.data as Map?)?['message'] as String? ??
              'Error del servidor.',
        );
      }

      final result = (response.data as Map)['result'] as Map<String, dynamic>;
      return _parseOcrResult(result);
    } catch (e) {
      _log.w('AiProxyService.ocr error: $e');
      return AiOcrResult(error: 'Error de conexión: $e');
    }
  }

  AiOcrResult _parseOcrResult(Map<String, dynamic> r) {
    DateTime? date;
    final rawDate = r['date'] as String?;
    if (rawDate != null) {
      date = DateTime.tryParse(rawDate);
    }
    return AiOcrResult(
      amount: r['amount']?.toString(),
      description: r['description'] as String?,
      date: date,
      categoryHint: r['category_hint'] as String?,
      currency: r['currency'] as String?,
      type: r['type'] as String?,
    );
  }

  // ── Interpretación de texto/voz ────────────────────────────────────────────

  /// Envía una frase en lenguaje natural (escrita o dictada) al proxy y retorna
  /// los datos del movimiento interpretados. Usa la misma cuota que el OCR.
  Future<AiOcrResult> parseText({
    required String text,
    String? byokKey,
  }) async {
    try {
      final body = <String, dynamic>{
        'feature': 'voice_parse',
        'text': text,
        if (byokKey != null) 'byok_key': byokKey,
      };

      final response = await supabase.functions.invoke(
        _functionName,
        body: body,
      );

      if (response.status == 403) {
        return const AiOcrResult(error: 'pro_required');
      }
      if (response.status == 429) {
        final msg = (response.data as Map?)?['message'] as String? ??
            'Límite mensual alcanzado.';
        return AiOcrResult(error: msg);
      }
      if (response.status != 200) {
        return AiOcrResult(
          error: (response.data as Map?)?['message'] as String? ??
              'Error del servidor.',
        );
      }

      final result = (response.data as Map)['result'] as Map<String, dynamic>;
      return _parseOcrResult(result);
    } catch (e) {
      _log.w('AiProxyService.parseText error: $e');
      return AiOcrResult(error: 'Error de conexión: $e');
    }
  }

  // ── Recomendaciones de inversión ──────────────────────────────────────────

  /// Solicita recomendaciones financieras personalizadas.
  /// Retorna una lista de [AiRecommendation] o lanza excepción.
  Future<({List<AiRecommendation> items, String? error})>
      getInvestmentRecommendations({
    required InvestmentContext context,
    String? byokKey,
  }) async {
    try {
      final body = <String, dynamic>{
        'feature': 'investment_recommendation',
        'context': context.toJson(),
        if (byokKey != null) 'byok_key': byokKey,
      };

      final response = await supabase.functions.invoke(
        _functionName,
        body: body,
      );

      if (response.status == 403) {
        return (items: <AiRecommendation>[], error: 'pro_required');
      }
      if (response.status == 429) {
        final msg = (response.data as Map?)?['message'] as String? ??
            'Límite mensual alcanzado.';
        return (items: <AiRecommendation>[], error: msg);
      }
      if (response.status != 200) {
        return (
          items: <AiRecommendation>[],
          error: (response.data as Map?)?['message'] as String? ??
              'Error del servidor.',
        );
      }

      final result = (response.data as Map)['result'] as Map<String, dynamic>;
      final rawList = result['recommendations'] as List<dynamic>? ?? [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(AiRecommendation.fromJson)
          .toList();

      return (items: items, error: null);
    } catch (e) {
      _log.w('AiProxyService.getInvestmentRecommendations error: $e');
      return (items: <AiRecommendation>[], error: 'Error de conexión: $e');
    }
  }

  // ── Cuota ─────────────────────────────────────────────────────────────────

  /// Retorna cuántas llamadas de [feature] ha hecho el usuario este mes.
  Future<int> getUsageThisMonth(String feature) async {
    try {
      final result = await supabase
          .rpc('get_ai_usage_this_month', params: {'p_feature': feature});
      return (result as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Límite mensual para [feature] en el plan Pro.
  static int limitFor(String feature) {
    switch (feature) {
      case 'ocr':
        return 150;
      case 'investment_recommendation':
        return 50;
      default:
        return 0;
    }
  }
}
