import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

/// Formatos de fecha soportados, con etiqueta para la UI.
const kDateFormats = [
  ('dd/MM/yyyy', 'DD/MM/AAAA'),
  ('MM/dd/yyyy', 'MM/DD/AAAA'),
  ('yyyy-MM-dd', 'AAAA-MM-DD'),
  ('dd-MM-yyyy', 'DD-MM-AAAA'),
  ('d/M/yyyy',   'D/M/AAAA'),
];

/// Resultado de parsear una fila del CSV, antes de crear la transacción.
class CsvRow {
  const CsvRow({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.rawLine = '',
  });

  final DateTime date;
  final String description;
  final double amount;
  final String type; // 'income' | 'expense'
  final String rawLine;
}

/// Configuración de mapeo entre columnas del CSV y campos de la app.
class CsvColumnMapping {
  const CsvColumnMapping({
    required this.dateCol,
    required this.descriptionCol,
    this.amountCol,
    this.debitCol,
    this.creditCol,
    this.dateFormat = 'dd/MM/yyyy',
    this.skipFirstRow = true,
    this.accountId,
    this.currencyCode = 'USD',
  }) : assert(
          amountCol != null || (debitCol != null && creditCol != null),
          'Debe especificar amountCol o ambos debitCol/creditCol',
        );

  final int dateCol;
  final int descriptionCol;

  /// Columna de monto único (positivo = ingreso, negativo = gasto).
  /// Si es null, se usan [debitCol] y [creditCol].
  final int? amountCol;

  /// Columna de débitos (gasto). Valor positivo = gasto.
  final int? debitCol;

  /// Columna de créditos (ingreso). Valor positivo = ingreso.
  final int? creditCol;

  final String dateFormat;
  final bool skipFirstRow;
  final String? accountId;
  final String currencyCode;

  CsvColumnMapping copyWith({
    int? dateCol,
    int? descriptionCol,
    int? amountCol,
    int? debitCol,
    int? creditCol,
    String? dateFormat,
    bool? skipFirstRow,
    String? accountId,
    String? currencyCode,
  }) =>
      CsvColumnMapping(
        dateCol: dateCol ?? this.dateCol,
        descriptionCol: descriptionCol ?? this.descriptionCol,
        amountCol: amountCol ?? this.amountCol,
        debitCol: debitCol ?? this.debitCol,
        creditCol: creditCol ?? this.creditCol,
        dateFormat: dateFormat ?? this.dateFormat,
        skipFirstRow: skipFirstRow ?? this.skipFirstRow,
        accountId: accountId ?? this.accountId,
        currencyCode: currencyCode ?? this.currencyCode,
      );
}

/// Error de parseo con contexto de fila.
class CsvParseError {
  const CsvParseError({required this.rowIndex, required this.code, this.detail});
  final int rowIndex;
  final String code;
  final String? detail;
}

/// Resultado de una importación.
class CsvImportResult {
  const CsvImportResult({
    required this.rows,
    required this.errors,
  });

  final List<CsvRow> rows;
  final List<CsvParseError> errors;

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => rows.length;
  int get errorCount => errors.length;
}

// ── Servicio ──────────────────────────────────────────────────────────────────

class CsvImportService {
  // ── Detección automática de delimitador ─────────────────────────────────────

  /// Detecta el delimitador más probable en las primeras líneas del contenido.
  static String detectDelimiter(String content) {
    final sample = content.split('\n').take(5).join('\n');
    final commas = ','.allMatches(sample).length;
    final semis = ';'.allMatches(sample).length;
    final tabs = '\t'.allMatches(sample).length;
    if (tabs >= commas && tabs >= semis) return '\t';
    if (semis > commas) return ';';
    return ',';
  }

  // ── Parse crudo: texto → tabla de celdas ────────────────────────────────────

  static List<List<dynamic>> parseRaw(
    String content, {
    String? delimiter,
  }) {
    final delim = delimiter ?? detectDelimiter(content);
    final converter = CsvToListConverter(
      fieldDelimiter: delim,
      eol: content.contains('\r\n') ? '\r\n' : '\n',
      shouldParseNumbers: false,
    );
    return converter.convert(content);
  }

  // ── Parse con mapeo: tabla → CsvRow ─────────────────────────────────────────

  static CsvImportResult mapRows(
    List<List<dynamic>> rawRows,
    CsvColumnMapping mapping,
  ) {
    final rows = <CsvRow>[];
    final errors = <CsvParseError>[];

    final startIdx = mapping.skipFirstRow ? 1 : 0;
    final dateFmt = DateFormat(mapping.dateFormat);

    for (var i = startIdx; i < rawRows.length; i++) {
      final row = rawRows[i];

      // Saltar filas completamente vacías
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      try {
        // ── Fecha ──
        final rawDate = _cell(row, mapping.dateCol);
        if (rawDate.isEmpty) {
          errors.add(CsvParseError(rowIndex: i, code: 'emptyDate'));
          continue;
        }
        DateTime date;
        try {
          date = dateFmt.parseStrict(rawDate.trim());
        } catch (_) {
          errors.add(
            CsvParseError(rowIndex: i, code: 'invalidDate', detail: rawDate),
          );
          continue;
        }

        // ── Descripción ──
        final description = _cell(row, mapping.descriptionCol);

        // ── Monto y tipo ──
        double amount;
        String type;

        if (mapping.amountCol != null) {
          // Columna única: positivo = ingreso, negativo = gasto
          final raw = _cell(row, mapping.amountCol!);
          final parsed = _parseAmount(raw);
          if (parsed == null) {
            errors.add(
              CsvParseError(rowIndex: i, code: 'invalidAmount', detail: raw),
            );
            continue;
          }
          amount = parsed.abs();
          type = parsed >= 0 ? 'income' : 'expense';
        } else {
          // Columnas separadas débito / crédito
          final rawDebit = _cell(row, mapping.debitCol!);
          final rawCredit = _cell(row, mapping.creditCol!);
          final debit = _parseAmount(rawDebit) ?? 0.0;
          final credit = _parseAmount(rawCredit) ?? 0.0;

          if (debit > 0) {
            amount = debit;
            type = 'expense';
          } else if (credit > 0) {
            amount = credit;
            type = 'income';
          } else {
            // Ambas cero o vacías
            errors.add(
              CsvParseError(
                rowIndex: i,
                code: 'emptyDebitCredit',
              ),
            );
            continue;
          }
        }

        rows.add(
          CsvRow(
            date: date,
            description: description.isEmpty ? 'Sin descripción' : description,
            amount: amount,
            type: type,
            rawLine: row.join(', '),
          ),
        );
      } catch (e) {
        errors.add(CsvParseError(rowIndex: i, code: 'exception', detail: e.toString()));
      }
    }

    return CsvImportResult(rows: rows, errors: errors);
  }

  // ── Helpers privados ─────────────────────────────────────────────────────────

  static String _cell(List<dynamic> row, int col) {
    if (col < 0 || col >= row.length) return '';
    return row[col].toString().trim();
  }

  /// Parsea un número que puede usar coma como decimal o separador de miles.
  /// Ej.: "1.234,56" → 1234.56 | "1,234.56" → 1234.56 | "-250" → -250.0
  static double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    // Quitar símbolos de moneda, espacios, paréntesis (algunos bancos usan (250) para negativos)
    var s = raw
        .replaceAll(RegExp(r'[^\d.,\-]'), '')
        .trim();
    if (s.isEmpty) return null;

    // Paréntesis como negativo: (250) → -250
    final negative = raw.contains('(') || s.startsWith('-');

    s = s.replaceAll('-', '');

    // Detectar si la coma es decimal o separador de miles
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');

    if (lastComma > lastDot) {
      // Formato europeo: 1.234,56 → decimal = coma
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Formato anglosajón: 1,234.56 → decimal = punto
      s = s.replaceAll(',', '');
    }

    final value = double.tryParse(s);
    if (value == null) return null;
    return negative ? -value : value;
  }
}
