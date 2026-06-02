import 'package:logger/logger.dart';

import 'supabase_service.dart';

final _log = Logger();

// ── Modelos ───────────────────────────────────────────────────────────────────

class AiInsightRecommendation {
  const AiInsightRecommendation({
    required this.type,
    required this.priority,
    required this.category,
    required this.title,
    required this.message,
    this.action,
  });

  final String type;     // 'spending_alert' | 'savings_tip' | 'investment_advice' | 'macro_context'
  final String priority; // 'high' | 'medium' | 'low'
  final String category;
  final String title;
  final String message;
  final String? action;

  factory AiInsightRecommendation.fromJson(Map<String, dynamic> j) =>
      AiInsightRecommendation(
        type:     j['type']     as String? ?? 'macro_context',
        priority: j['priority'] as String? ?? 'medium',
        category: j['category'] as String? ?? '',
        title:    j['title']    as String? ?? '',
        message:  j['message']  as String? ?? '',
        action:   j['action']   as String?,
      );
}

class AiInsight {
  const AiInsight({
    required this.id,
    required this.groupId,
    required this.generatedAt,
    required this.expiresAt,
    required this.recommendations,
    this.macroContext,
    this.healthScore,
    required this.modelUsed,
    required this.fromCache,
  });

  final String? id;
  final String groupId;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final List<AiInsightRecommendation> recommendations;
  final String? macroContext;
  final int? healthScore;
  final String modelUsed;
  final bool fromCache;

  factory AiInsight.fromJson(Map<String, dynamic> j, {bool fromCache = false}) {
    final rawRecs = j['recommendations'] as List<dynamic>? ?? [];
    return AiInsight(
      id:              j['id'] as String?,
      groupId:         j['group_id'] as String? ?? '',
      generatedAt:     DateTime.tryParse(j['generated_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt:       DateTime.tryParse(j['expires_at'] as String? ?? '') ?? DateTime.now(),
      recommendations: rawRecs
          .whereType<Map<String, dynamic>>()
          .map(AiInsightRecommendation.fromJson)
          .toList(),
      macroContext:    j['macro_context'] as String?,
      healthScore:     j['overall_health_score'] as int?,
      modelUsed:       j['model_used'] as String? ?? '',
      fromCache:       fromCache,
    );
  }
}

// ── InsightsService ───────────────────────────────────────────────────────────

/// Servicio para generar y recuperar AI Insights persistentes.
///
/// Diferencias con el `quick-api` (recomendaciones rápidas):
/// - Usa historial de 3 meses para contexto comparativo.
/// - Incluye contexto macroeconómico (tasas BCV/paralela, noticias).
/// - Los resultados se guardan en `ai_insights` con TTL de 7 días.
/// - Requiere plan Premium o Beta.
class InsightsService {
  InsightsService._();
  static final InsightsService instance = InsightsService._();

  static const _functionName = 'generate-ai-insights';

  /// Genera (o recupera del caché) un insight para el grupo indicado.
  Future<({AiInsight? insight, String? error})> generateInsight({
    required String groupId,
  }) async {
    if (groupId.isEmpty) {
      return (insight: null, error: 'Sin grupo activo.');
    }

    try {
      final response = await supabase.functions.invoke(
        _functionName,
        body: {'group_id': groupId},
      );

      if (response.status == 403) {
        final code = (response.data as Map?)?['error'] as String?;
        return (
          insight: null,
          error: code == 'premium_required'
              ? 'premium_required'
              : 'Sin acceso.',
        );
      }

      if (response.status != 200) {
        final msg = (response.data as Map?)?['error'] as String?;
        return (insight: null, error: msg ?? 'Error del servidor.');
      }

      final data = response.data as Map<String, dynamic>;
      final insightJson = data['insight'] as Map<String, dynamic>?;
      final fromCache = (data['cached'] as bool?) ?? false;

      if (insightJson == null) {
        return (insight: null, error: 'Respuesta vacía del servidor.');
      }

      final insight = AiInsight.fromJson(insightJson, fromCache: fromCache);
      _log.i(
        'InsightsService: insight ${fromCache ? "(caché)" : "(nuevo)"} '
        'para group=$groupId, score=${insight.healthScore}',
      );
      return (insight: insight, error: null);
    } catch (e) {
      _log.w('InsightsService.generateInsight error: $e');
      return (insight: null, error: 'Error de conexión: $e');
    }
  }
}
