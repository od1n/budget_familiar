import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/csv_import_service.dart';

void main() {
  // ── detectDelimiter ─────────────────────────────────────────────────────────

  group('detectDelimiter', () {
    test('detecta coma', () {
      const csv = 'fecha,monto,descripcion\n01/01/2024,100,pago';
      expect(CsvImportService.detectDelimiter(csv), ',');
    });

    test('detecta punto y coma', () {
      const csv = 'fecha;monto;descripcion\n01/01/2024;100;pago';
      expect(CsvImportService.detectDelimiter(csv), ';');
    });

    test('detecta tabulación', () {
      const csv = 'fecha\tmonto\tdescripcion\n01/01/2024\t100\tpago';
      expect(CsvImportService.detectDelimiter(csv), '\t');
    });

    test('prefiere tabulación sobre coma si hay más tabs', () {
      const csv = 'a\tb\tc,d\ne\tf\tg,h';
      expect(CsvImportService.detectDelimiter(csv), '\t');
    });
  });

  // ── parseRaw ────────────────────────────────────────────────────────────────

  group('parseRaw', () {
    test('parsea CSV con coma', () {
      const csv = 'a,b,c\n1,2,3';
      final rows = CsvImportService.parseRaw(csv);
      expect(rows.length, 2);
      expect(rows[0], ['a', 'b', 'c']);
      expect(rows[1], ['1', '2', '3']);
    });

    test('parsea CSV con punto y coma explícito', () {
      const csv = 'a;b;c\n1;2;3';
      final rows = CsvImportService.parseRaw(csv, delimiter: ';');
      expect(rows.length, 2);
      expect(rows[1][1], '2');
    });

    test('respeta comillas en campos', () {
      const csv = '"apellido, nombre",100\n"otro campo",200';
      final rows = CsvImportService.parseRaw(csv);
      expect(rows[0][0], 'apellido, nombre');
    });
  });

  // ── mapRows — columna de monto única ───────────────────────────────────────

  group('mapRows — amountCol único', () {
    const mapping = CsvColumnMapping(
      dateCol: 0,
      descriptionCol: 1,
      amountCol: 2,
      dateFormat: 'dd/MM/yyyy',
      skipFirstRow: true,
    );

    List<List<dynamic>> _rows(List<List<dynamic>> data) =>
        [['Fecha', 'Desc', 'Monto'], ...data];

    test('ingreso (monto positivo)', () {
      final rows = _rows([
        ['15/03/2024', 'Salario', '1500.00'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.length, 1);
      expect(result.rows.first.type, 'income');
      expect(result.rows.first.amount, 1500.0);
      expect(result.rows.first.description, 'Salario');
      expect(result.rows.first.date, DateTime(2024, 3, 15));
    });

    test('gasto (monto negativo)', () {
      final rows = _rows([
        ['01/06/2024', 'Supermercado', '-85.50'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.first.type, 'expense');
      expect(result.rows.first.amount, 85.50);
    });

    test('formato europeo: 1.234,56', () {
      final rows = _rows([
        ['01/01/2024', 'Pago', '1.234,56'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.first.amount, closeTo(1234.56, 0.001));
    });

    test('formato con paréntesis: (250) → gasto', () {
      final rows = _rows([
        ['01/01/2024', 'Débito', '(250)'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.first.type, 'expense');
      expect(result.rows.first.amount, 250.0);
    });

    test('error en fecha inválida', () {
      final rows = _rows([
        ['99/99/2024', 'X', '100'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows, isEmpty);
      expect(result.errors.length, 1);
      expect(result.errors.first.message, contains('Fecha inválida'));
    });

    test('error en monto inválido', () {
      final rows = _rows([
        ['01/01/2024', 'X', 'N/A'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows, isEmpty);
      expect(result.errors.first.message, contains('Monto inválido'));
    });

    test('fecha vacía reporta error', () {
      final rows = _rows([
        ['', 'X', '100'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.errors.first.message, contains('Fecha vacía'));
    });

    test('filas completamente vacías se ignoran sin error', () {
      final rows = _rows([
        ['01/01/2024', 'Normal', '50'],
        ['', '', ''],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.length, 1);
      expect(result.errors, isEmpty);
    });

    test('descripción vacía se reemplaza por "Sin descripción"', () {
      final rows = _rows([
        ['01/01/2024', '', '50'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.first.description, 'Sin descripción');
    });

    test('múltiples filas válidas e inválidas mezcladas', () {
      final rows = _rows([
        ['01/01/2024', 'OK', '100'],
        ['99/99/2024', 'MAL', '100'],
        ['15/06/2024', 'OK2', '200'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.successCount, 2);
      expect(result.errorCount, 1);
    });

    test('skipFirstRow = false incluye la primera fila', () {
      const noSkip = CsvColumnMapping(
        dateCol: 0,
        descriptionCol: 1,
        amountCol: 2,
        dateFormat: 'dd/MM/yyyy',
        skipFirstRow: false,
      );
      final rows = [
        ['01/01/2024', 'Primera', '50'],
        ['02/01/2024', 'Segunda', '75'],
      ];
      final result = CsvImportService.mapRows(rows, noSkip);
      expect(result.rows.length, 2);
    });
  });

  // ── mapRows — columnas débito/crédito separadas ─────────────────────────────

  group('mapRows — debitCol + creditCol', () {
    const mapping = CsvColumnMapping(
      dateCol: 0,
      descriptionCol: 1,
      debitCol: 2,
      creditCol: 3,
      dateFormat: 'yyyy-MM-dd',
      skipFirstRow: true,
    );

    List<List<dynamic>> _rows(List<List<dynamic>> data) =>
        [['Fecha', 'Desc', 'Débito', 'Crédito'], ...data];

    test('débito > 0 → gasto', () {
      final rows = _rows([
        ['2024-03-10', 'Alquiler', '800', ''],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.first.type, 'expense');
      expect(result.rows.first.amount, 800.0);
    });

    test('crédito > 0 → ingreso', () {
      final rows = _rows([
        ['2024-03-10', 'Cobro', '', '1200'],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.rows.first.type, 'income');
      expect(result.rows.first.amount, 1200.0);
    });

    test('ambos vacíos → error', () {
      final rows = _rows([
        ['2024-03-10', 'X', '', ''],
      ]);
      final result = CsvImportService.mapRows(rows, mapping);
      expect(result.errors.first.message, contains('Débito y crédito vacíos'));
    });
  });

  // ── Formatos de fecha ───────────────────────────────────────────────────────

  group('mapRows — formatos de fecha', () {
    CsvImportResult _parse(String dateStr, String fmt) {
      final mapping = CsvColumnMapping(
        dateCol: 0,
        descriptionCol: 1,
        amountCol: 2,
        dateFormat: fmt,
        skipFirstRow: false,
      );
      return CsvImportService.mapRows([
        [dateStr, 'X', '10'],
      ], mapping);
    }

    test('dd/MM/yyyy', () {
      final r = _parse('25/12/2023', 'dd/MM/yyyy');
      expect(r.rows.first.date, DateTime(2023, 12, 25));
    });

    test('MM/dd/yyyy', () {
      final r = _parse('12/25/2023', 'MM/dd/yyyy');
      expect(r.rows.first.date, DateTime(2023, 12, 25));
    });

    test('yyyy-MM-dd', () {
      final r = _parse('2023-12-25', 'yyyy-MM-dd');
      expect(r.rows.first.date, DateTime(2023, 12, 25));
    });

    test('dd-MM-yyyy', () {
      final r = _parse('25-12-2023', 'dd-MM-yyyy');
      expect(r.rows.first.date, DateTime(2023, 12, 25));
    });
  });

  // ── CsvImportResult ─────────────────────────────────────────────────────────

  group('CsvImportResult', () {
    test('hasErrors es false cuando no hay errores', () {
      final result = const CsvImportResult(rows: [], errors: []);
      expect(result.hasErrors, false);
    });

    test('successCount y errorCount son correctos', () {
      final result = CsvImportResult(
        rows: [
          CsvRow(
            date: DateTime(2024),
            description: 'x',
            amount: 1,
            type: 'income',
          ),
        ],
        errors: [
          const CsvParseError(rowIndex: 0, message: 'error'),
        ],
      );
      expect(result.successCount, 1);
      expect(result.errorCount, 1);
      expect(result.hasErrors, true);
    });
  });
}
