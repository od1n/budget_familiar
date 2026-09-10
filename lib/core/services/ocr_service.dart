import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/settings/providers/ocr_settings_provider.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import 'ai_proxy_service.dart';

final _log = Logger();

// ── Resultado de OCR ─────────────────────────────────────────────────────────

class OcrResult {
  const OcrResult({
    this.amount,
    this.currency,
    this.date,
    this.description,
    this.categoryHint,
    this.rawText,
    this.error,
  });

  final double? amount;
  final String? currency;
  final DateTime? date;
  final String? description;
  final String? categoryHint; // 'food' | 'transport' | etc.
  final String? rawText;
  final String? error;

  bool get hasError => error != null;

  /// Intenta parsear el JSON que el modelo debería devolver.
  static OcrResult fromJson(Map<String, dynamic> json, {String? raw}) {
    DateTime? date;
    try {
      final d = json['date'] as String?;
      if (d != null && d.isNotEmpty) date = DateTime.parse(d);
    } catch (_) {}

    return OcrResult(
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      date: date,
      description: json['description'] as String?,
      categoryHint: json['category'] as String?,
      rawText: raw,
    );
  }

  /// Extrae el primer bloque JSON que encuentre en texto libre.
  static OcrResult parse(String rawText) {
    try {
      final start = rawText.indexOf('{');
      final end = rawText.lastIndexOf('}');
      if (start == -1 || end == -1) {
        return OcrResult(
          rawText: rawText,
          error: 'No se encontró JSON en la respuesta.',
        );
      }
      final jsonStr = rawText.substring(start, end + 1);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return OcrResult.fromJson(map, raw: rawText);
    } catch (e) {
      return OcrResult(rawText: rawText, error: 'Error al parsear JSON: $e');
    }
  }
}

// ── Prompt compartido ────────────────────────────────────────────────────────

const _ocrPrompt = '''
Analiza esta imagen de recibo o factura y extrae los datos en JSON.
Responde ÚNICAMENTE con el JSON sin ningún otro texto:
{
  "amount": monto total como número (null si no visible),
  "currency": "USD" o "VES" según símbolos del recibo (por defecto "USD"),
  "date": fecha en formato "YYYY-MM-DD" (null si no visible),
  "description": nombre del comercio o descripción breve (null si no visible),
  "category": una de estas opciones: food, transport, services, health, education, entertainment, clothing, home, debt, other
}
''';

// ── Interfaz abstracta ───────────────────────────────────────────────────────

abstract class OcrService {
  Future<OcrResult> extractFromImage(Uint8List imageBytes, String mimeType);
}

// ── Implementación Ollama ────────────────────────────────────────────────────

class OllamaOcrService implements OcrService {
  OllamaOcrService({required this.baseUrl, required this.model});
  final String baseUrl;
  final String model;

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  @override
  Future<OcrResult> extractFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      final b64 = base64Encode(imageBytes);
      final resp = await _dio.post(
        '$baseUrl/api/generate',
        data: {
          'model': model,
          'prompt': _ocrPrompt,
          'images': [b64],
          'stream': false,
        },
      );
      final rawText =
          (resp.data as Map<String, dynamic>)['response'] as String? ?? '';
      _log.d('OllamaOCR raw: $rawText');
      return OcrResult.parse(rawText);
    } on DioException catch (e) {
      final msg = e.response?.statusCode == null
          ? 'No se pudo conectar a Ollama en $baseUrl. ¿Está corriendo?'
          : 'Error Ollama ${e.response!.statusCode}: ${e.message}';
      return OcrResult(error: msg);
    } catch (e) {
      return OcrResult(error: 'Error inesperado: $e');
    }
  }
}

// ── Implementación Claude API ────────────────────────────────────────────────

class ClaudeOcrService implements OcrService {
  ClaudeOcrService({required this.apiKey});
  final String apiKey;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001'; // vision + económico
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  @override
  Future<OcrResult> extractFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      final b64 = base64Encode(imageBytes);
      final resp = await _dio.post(
        _endpoint,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'max_tokens': 512,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mimeType,
                    'data': b64,
                  },
                },
                {
                  'type': 'text',
                  'text': _ocrPrompt,
                },
              ],
            },
          ],
        },
      );
      final content = (resp.data as Map)['content'] as List;
      final rawText = (content.first as Map)['text'] as String? ?? '';
      _log.d('ClaudeOCR raw: $rawText');
      return OcrResult.parse(rawText);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = status == 401
          ? 'API key de Claude inválida.'
          : status == 429
              ? 'Límite de requests alcanzado. Intenta más tarde.'
              : 'Error Claude API $status: ${e.message}';
      return OcrResult(error: msg);
    } catch (e) {
      return OcrResult(error: 'Error inesperado: $e');
    }
  }
}

// ── Implementación Gemini API ─────────────────────────────────────────────────

class GeminiOcrService implements OcrService {
  GeminiOcrService({required this.apiKey});
  final String apiKey;

  static const _model = 'gemini-3.6-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  @override
  Future<OcrResult> extractFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      final b64 = base64Encode(imageBytes);
      final resp = await _dio.post(
        '$_baseUrl/$_model:generateContent?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': b64,
                  },
                },
                {'text': _ocrPrompt},
              ],
            },
          ],
          'generationConfig': {
            'maxOutputTokens': 512,
            'temperature': 0.1,
          },
        },
      );
      final candidates = (resp.data as Map)['candidates'] as List?;
      final rawText = candidates?.isNotEmpty == true
          ? ((candidates!.first as Map)['content'] as Map)['parts'] != null
              ? (((candidates.first as Map)['content'] as Map)['parts'] as List)
                  .firstWhere(
                    (p) => (p as Map).containsKey('text'),
                    orElse: () => {'text': ''},
                  )['text'] as String? ??
                  ''
              : ''
          : '';
      _log.d('GeminiOCR raw: $rawText');
      return OcrResult.parse(rawText);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = status == 400
          ? 'API key de Gemini inválida o request mal formado.'
          : status == 429
              ? 'Límite de requests Gemini alcanzado. Intenta más tarde.'
              : 'Error Gemini API $status: ${e.message}';
      return OcrResult(error: msg);
    } catch (e) {
      return OcrResult(error: 'Error inesperado Gemini: $e');
    }
  }
}

// ── Implementación via proxy del desarrollador ────────────────────────────────

/// Llama la Edge Function `ai-proxy`. Si [byokKey] es null usa la key del
/// desarrollador (consume cuota Pro). Si se provee, usa BYOK sin cuota.
class ProxyOcrService implements OcrService {
  ProxyOcrService({this.byokKey});
  final String? byokKey;

  @override
  Future<OcrResult> extractFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final aiResult = await AiProxyService.instance.ocr(
      imageBytes: imageBytes,
      mimeType: mimeType,
      byokKey: byokKey,
    );
    if (!aiResult.isSuccess) {
      return OcrResult(error: aiResult.error);
    }
    DateTime? date;
    if (aiResult.date != null) date = aiResult.date;
    return OcrResult(
      amount: double.tryParse(aiResult.amount?.replaceAll(',', '.') ?? ''),
      currency: aiResult.currency,
      date: date,
      description: aiResult.description,
      categoryHint: aiResult.categoryHint,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Ruteador de OCR:
/// - Usuario Pro sin backend configurado → ProxyOcrService (developer key, cuota Pro)
/// - Usuario Pro con Gemini configurado  → ProxyOcrService con BYOK
/// - Usuario Pro con Claude/Ollama       → backend directo (sin cuota)
/// - Usuario Free sin backend            → ProxyOcrService retornará error 403
final ocrServiceProvider = Provider<OcrService>((ref) {
  final settings = ref.watch(ocrSettingsProvider);
  final isPremium = ref.watch(isPremiumProvider);

  // Pro sin backend específico → proxy con developer key
  if (isPremium && !settings.isConfigured) {
    return ProxyOcrService();
  }

  // Pro con Gemini BYOK → proxy para centralizar las llamadas
  if (isPremium && settings.backend == OcrBackend.gemini) {
    return ProxyOcrService(byokKey: settings.geminiApiKey);
  }

  // Backends directos (Ollama, Claude, o Free+BYOK)
  return switch (settings.backend) {
    OcrBackend.ollama => OllamaOcrService(
        baseUrl: settings.ollamaUrl,
        model: settings.ollamaModel,
      ),
    OcrBackend.claude => ClaudeOcrService(
        apiKey: settings.claudeApiKey,
      ),
    OcrBackend.gemini => GeminiOcrService(
        apiKey: settings.geminiApiKey,
      ),
  };
});
