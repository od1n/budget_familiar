import 'dart:typed_data';

import 'ocr_service.dart';

/// Estado de un ticket dentro de un lote.
enum BatchStatus { pending, processing, ready, failed, saved }

/// Un ticket del lote: imagen + campos editables rellenados por OCR.
/// Mutable a propósito: la pantalla de revisión edita estos campos.
class BatchItem {
  BatchItem({
    required this.id,
    required this.name,
    required this.bytes,
    required this.mime,
    this.sourcePath,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final String mime;

  /// Ruta en disco (solo flujo de carpeta en escritorio), para archivar luego.
  final String? sourcePath;

  /// Marcado si parece duplicado de una transacción ya existente o del lote.
  bool duplicate = false;

  BatchStatus status = BatchStatus.pending;
  String? error;

  /// Si se incluye al guardar. Los que fallan o no traen monto arrancan en false.
  bool include = true;

  // ── Campos editables (rellenados por OCR, corregibles por el usuario) ──
  String type = 'expense'; // 'expense' | 'income'
  double? amount;
  String currencyCode = 'USD';
  DateTime date = DateTime.now();
  String? description;
  String? categoryId;
  String? categoryHint; // pista cruda del OCR ('food', 'transport', ...)
}

/// Procesa un lote de tickets por OCR con concurrencia acotada (throttle),
/// para no chocar con el rate limit del proveedor. No depende de Riverpod:
/// recibe el [OcrService] ya resuelto (proxy Pro / BYOK / etc.).
class ReceiptBatchService {
  ReceiptBatchService(this._ocr);

  final OcrService _ocr;

  /// Procesa [items] en sitio (muta su status y campos). Llama [onProgress]
  /// cada vez que un item cambia de estado, para refrescar la UI.
  Future<void> processAll(
    List<BatchItem> items, {
    int concurrency = 2,
    void Function()? onProgress,
  }) async {
    if (items.isEmpty) return;

    final queue = List<BatchItem>.from(items);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final item = queue.removeAt(0);
        item.status = BatchStatus.processing;
        onProgress?.call();
        try {
          final r = await _ocr.extractFromImage(item.bytes, item.mime);
          if (r.hasError) {
            item.status = BatchStatus.failed;
            item.error = r.error;
            item.include = false;
          } else {
            item.amount = r.amount;
            if (r.currency != null && r.currency!.isNotEmpty) {
              item.currencyCode = r.currency!;
            }
            if (r.date != null) item.date = r.date!;
            item.description = r.description;
            item.categoryHint = r.categoryHint;
            item.status = BatchStatus.ready;
            // Sin monto legible → no incluir por defecto (el usuario decide).
            if (item.amount == null) item.include = false;
          }
        } catch (e) {
          item.status = BatchStatus.failed;
          item.error = e.toString();
          item.include = false;
        }
        onProgress?.call();
      }
    }

    final n = concurrency.clamp(1, items.length);
    await Future.wait(List.generate(n, (_) => worker()));
  }
}
