import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Claves SharedPreferences ─────────────────────────────────────────────────

const _kBackend = 'ocr_backend'; // 'claude' | 'ollama' | 'gemini'
const _kOllamaUrl = 'ocr_ollama_url';
const _kOllamaModel = 'ocr_ollama_model';
const _kClaudeKey = 'ocr_claude_api_key';
const _kGeminiKey = 'ocr_gemini_api_key';

// ── Modelo de configuración ──────────────────────────────────────────────────

enum OcrBackend { claude, ollama, gemini }

class OcrSettings {
  const OcrSettings({
    this.backend = OcrBackend.gemini,
    this.ollamaUrl = 'http://localhost:11434',
    this.ollamaModel = 'gemma4:31b-cloud',
    this.claudeApiKey = '',
    this.geminiApiKey = '',
  });

  final OcrBackend backend;
  final String ollamaUrl;
  final String ollamaModel;
  final String claudeApiKey;
  final String geminiApiKey;

  bool get isConfigured => switch (backend) {
        OcrBackend.claude => claudeApiKey.isNotEmpty,
        OcrBackend.ollama => ollamaUrl.isNotEmpty,
        OcrBackend.gemini => geminiApiKey.isNotEmpty,
      };

  OcrSettings copyWith({
    OcrBackend? backend,
    String? ollamaUrl,
    String? ollamaModel,
    String? claudeApiKey,
    String? geminiApiKey,
  }) =>
      OcrSettings(
        backend: backend ?? this.backend,
        ollamaUrl: ollamaUrl ?? this.ollamaUrl,
        ollamaModel: ollamaModel ?? this.ollamaModel,
        claudeApiKey: claudeApiKey ?? this.claudeApiKey,
        geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class OcrSettingsNotifier extends StateNotifier<OcrSettings> {
  OcrSettingsNotifier() : super(const OcrSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final backendStr = prefs.getString(_kBackend);
    final backend = switch (backendStr) {
      'ollama' => OcrBackend.ollama,
      'claude' => OcrBackend.claude,
      'gemini' => OcrBackend.gemini,
      _ => OcrBackend.gemini, // default nuevo
    };
    state = OcrSettings(
      backend: backend,
      ollamaUrl: prefs.getString(_kOllamaUrl) ?? 'http://localhost:11434',
      ollamaModel: prefs.getString(_kOllamaModel) ?? 'gemma4:31b-cloud',
      claudeApiKey: prefs.getString(_kClaudeKey) ?? '',
      geminiApiKey: prefs.getString(_kGeminiKey) ?? '',
    );
  }

  Future<void> update(OcrSettings settings) async {
    state = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackend, switch (settings.backend) {
      OcrBackend.ollama => 'ollama',
      OcrBackend.claude => 'claude',
      OcrBackend.gemini => 'gemini',
    },);
    await prefs.setString(_kOllamaUrl, settings.ollamaUrl);
    await prefs.setString(_kOllamaModel, settings.ollamaModel);
    await prefs.setString(_kClaudeKey, settings.claudeApiKey);
    await prefs.setString(_kGeminiKey, settings.geminiApiKey);
  }
}

final ocrSettingsProvider =
    StateNotifierProvider<OcrSettingsNotifier, OcrSettings>(
  (_) => OcrSettingsNotifier(),
);
