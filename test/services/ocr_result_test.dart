import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/ocr_service.dart';

void main() {
  // ── OcrResult.hasError ──────────────────────────────────────────────────────

  group('OcrResult.hasError', () {
    test('sin error → false', () {
      const r = OcrResult(amount: 25.0, description: 'Pago');
      expect(r.hasError, false);
    });

    test('con error → true', () {
      const r = OcrResult(error: 'No se encontró JSON');
      expect(r.hasError, true);
    });

    test('resultado vacío → false', () {
      const r = OcrResult();
      expect(r.hasError, false);
    });
  });

  // ── OcrResult.fromJson ──────────────────────────────────────────────────────

  group('OcrResult.fromJson', () {
    test('JSON completo → todos los campos mapeados', () {
      final json = {
        'amount': 45.50,
        'currency': 'USD',
        'date': '2024-06-15',
        'description': 'Supermercado Central',
        'category': 'food',
      };
      final result = OcrResult.fromJson(json);
      expect(result.amount, 45.50);
      expect(result.currency, 'USD');
      expect(result.date, DateTime(2024, 6, 15));
      expect(result.description, 'Supermercado Central');
      expect(result.categoryHint, 'food');
      expect(result.hasError, false);
    });

    test('JSON vacío → todos null, sin error', () {
      final result = OcrResult.fromJson({});
      expect(result.amount, isNull);
      expect(result.currency, isNull);
      expect(result.date, isNull);
      expect(result.description, isNull);
      expect(result.hasError, false);
    });

    test('amount como int → convertido a double', () {
      final result = OcrResult.fromJson({'amount': 100});
      expect(result.amount, 100.0);
      expect(result.amount, isA<double>());
    });

    test('date inválida → null sin crash', () {
      final result = OcrResult.fromJson({'date': 'fecha-invalida'});
      expect(result.date, isNull);
      expect(result.hasError, false);
    });

    test('date vacía → null', () {
      final result = OcrResult.fromJson({'date': ''});
      expect(result.date, isNull);
    });

    test('date null → null', () {
      final result = OcrResult.fromJson({'date': null});
      expect(result.date, isNull);
    });

    test('rawText se preserva si se pasa', () {
      final result = OcrResult.fromJson({'amount': 10.0}, raw: 'texto crudo');
      expect(result.rawText, 'texto crudo');
    });

    test('moneda VES se mapea correctamente', () {
      final result = OcrResult.fromJson({'currency': 'VES', 'amount': 730.0});
      expect(result.currency, 'VES');
      expect(result.amount, 730.0);
    });
  });

  // ── OcrResult.parse ─────────────────────────────────────────────────────────

  group('OcrResult.parse', () {
    test('JSON puro → parsea correctamente', () {
      const raw = '{"amount": 25.50, "currency": "USD", "description": "Cafe"}';
      final result = OcrResult.parse(raw);
      expect(result.hasError, false);
      expect(result.amount, 25.50);
      expect(result.currency, 'USD');
      expect(result.description, 'Cafe');
    });

    test('JSON embebido en texto libre → extrae correctamente', () {
      const raw = 'Aquí está el resultado:\n'
          '{"amount": 50.0, "currency": "USD", "description": "Farmacia"}\n'
          'Fin del análisis.';
      final result = OcrResult.parse(raw);
      expect(result.hasError, false);
      expect(result.amount, 50.0);
      expect(result.description, 'Farmacia');
    });

    test('JSON en bloque markdown → extrae correctamente', () {
      const raw = '```json\n'
          '{"amount": 12.99, "currency": "USD", "description": "Tienda"}\n'
          '```';
      final result = OcrResult.parse(raw);
      expect(result.hasError, false);
      expect(result.amount, 12.99);
    });

    test('sin JSON en el texto → error descriptivo', () {
      const raw = 'No pude identificar ningún recibo en la imagen.';
      final result = OcrResult.parse(raw);
      expect(result.hasError, true);
      expect(result.error, contains('No se encontró JSON'));
    });

    test('JSON malformado → error de parseo', () {
      const raw = '{amount: 25, description: "sin comillas en clave"}';
      final result = OcrResult.parse(raw);
      expect(result.hasError, true);
    });

    test('texto vacío → error', () {
      final result = OcrResult.parse('');
      expect(result.hasError, true);
    });

    test('rawText siempre se preserva', () {
      const raw = 'texto de prueba';
      final result = OcrResult.parse(raw);
      expect(result.rawText, raw);
    });

    test('JSON con todos los campos null → resultado sin error', () {
      const raw =
          '{"amount": null, "currency": null, "date": null, "description": null, "category": null}';
      final result = OcrResult.parse(raw);
      expect(result.hasError, false);
      expect(result.amount, isNull);
      expect(result.description, isNull);
    });

    test('JSON con fecha válida → date parseada', () {
      const raw = '{"amount": 10.0, "date": "2024-03-15", "currency": "USD"}';
      final result = OcrResult.parse(raw);
      expect(result.date, DateTime(2024, 3, 15));
    });

    test('JSON con fecha inválida → date null, sin error', () {
      const raw = '{"amount": 10.0, "date": "15/03/2024", "currency": "USD"}';
      final result = OcrResult.parse(raw);
      expect(result.hasError, false);
      expect(result.date, isNull);
    });
  });
}
