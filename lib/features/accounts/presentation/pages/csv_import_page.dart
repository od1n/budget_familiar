import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/csv_import_service.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../transactions/providers/transactions_provider.dart';
import '../../providers/accounts_provider.dart';

// ── Constantes ────────────────────────────────────────────────────────────────

const _kDelimiters = [
  (',', 'Coma  ,'),
  (';', 'Punto y coma  ;'),
  ('\t', 'Tabulador  ⇥'),
];

const _kCurrencies = ['USD', 'VES', 'EUR', 'COP'];

// ── Página principal ──────────────────────────────────────────────────────────

class CsvImportPage extends ConsumerStatefulWidget {
  const CsvImportPage({super.key, this.preselectedAccountId});

  final String? preselectedAccountId;

  @override
  ConsumerState<CsvImportPage> createState() => _CsvImportPageState();
}

class _CsvImportPageState extends ConsumerState<CsvImportPage> {
  int _step = 0;

  // ── Paso 1: archivo ─────────────────────────────────────────────────────────
  String? _filePath;
  String? _fileContent;
  String _delimiter = ',';
  String? _selectedAccountId;
  String _currency = 'USD';

  // Tabla cruda parseada (incluyendo encabezado)
  List<List<dynamic>> _rawRows = [];

  // ── Paso 2: mapeo de columnas ───────────────────────────────────────────────
  int _dateCol = 0;
  int _descCol = 1;
  bool _useSeparateCols = false; // false = columna única de monto
  int _amountCol = 2;
  int _debitCol = 2;
  int _creditCol = 3;
  String _dateFormat = 'dd/MM/yyyy';
  bool _skipFirstRow = true;

  // ── Paso 3: resultado ───────────────────────────────────────────────────────
  CsvImportResult? _importResult;
  bool _importing = false;
  int _importedCount = 0;

  // ── Step 1 helpers ──────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'CSV',
      extensions: ['csv', 'txt'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final content = await file.readAsString();
    final detectedDelim = CsvImportService.detectDelimiter(content);
    final raw = CsvImportService.parseRaw(content, delimiter: detectedDelim);
    setState(() {
      _filePath = file.name;
      _fileContent = content;
      _delimiter = detectedDelim;
      _rawRows = raw;
      // Auto-sugerir columnas si hay al menos 3
      if (raw.isNotEmpty && raw[0].length >= 3) {
        _dateCol = 0;
        _descCol = 1;
        _amountCol = 2;
      }
    });
  }

  void _onDelimiterChanged(String delim) {
    if (_fileContent == null) return;
    final raw = CsvImportService.parseRaw(_fileContent!, delimiter: delim);
    setState(() {
      _delimiter = delim;
      _rawRows = raw;
    });
  }

  bool get _step1Valid =>
      _fileContent != null &&
      _rawRows.isNotEmpty &&
      _selectedAccountId != null;

  // ── Step 2 helpers ──────────────────────────────────────────────────────────

  List<dynamic> get _headerRow =>
      _rawRows.isNotEmpty ? _rawRows[0] : const [];

  List<DropdownMenuItem<int>> _colItems() {
    return List.generate(_headerRow.length, (i) {
      final label = _skipFirstRow
          ? '${i + 1}: ${_headerRow[i]}'
          : 'Columna ${i + 1}';
      return DropdownMenuItem(value: i, child: Text(label));
    });
  }

  bool get _step2Valid {
    if (_useSeparateCols) {
      return _debitCol != _creditCol;
    }
    return true;
  }

  void _buildPreview() {
    final mapping = _buildMapping();
    final result = CsvImportService.mapRows(_rawRows, mapping);
    setState(() => _importResult = result);
  }

  CsvColumnMapping _buildMapping() => CsvColumnMapping(
        dateCol: _dateCol,
        descriptionCol: _descCol,
        amountCol: _useSeparateCols ? null : _amountCol,
        debitCol: _useSeparateCols ? _debitCol : null,
        creditCol: _useSeparateCols ? _creditCol : null,
        dateFormat: _dateFormat,
        skipFirstRow: _skipFirstRow,
        accountId: _selectedAccountId,
        currencyCode: _currency,
      );

  // ── Step 3: importar ────────────────────────────────────────────────────────

  Future<void> _doImport() async {
    final result = _importResult;
    if (result == null) return;

    setState(() {
      _importing = true;
      _importedCount = 0;
    });

    final notifier = ref.read(transactionNotifierProvider.notifier);
    int count = 0;

    for (final row in result.rows) {
      final ok = await notifier.save(
        type: row.type,
        amount: row.amount,
        currencyCode: _currency,
        date: row.date,
        description: row.description,
        accountId: _selectedAccountId,
      );
      if (ok) count++;
    }

    if (mounted) {
      setState(() {
        _importing = false;
        _importedCount = count;
        _step = 3; // paso final (resumen)
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar CSV bancario'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _step == 3 ? _buildDone() : _buildStepper(),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Stepper(
      currentStep: _step,
      onStepTapped: (i) {
        if (i < _step) setState(() => _step = i);
      },
      controlsBuilder: (context, details) => _StepControls(
        step: details.currentStep,
        totalSteps: 3,
        canContinue: details.currentStep == 0
            ? _step1Valid
            : details.currentStep == 1
                ? _step2Valid
                : !_importing,
        onContinue: details.currentStep == 2
            ? _doImport
            : () {
                if (details.currentStep == 1) _buildPreview();
                setState(() => _step = details.currentStep + 1);
              },
        onCancel: details.currentStep > 0
            ? () => setState(() => _step = details.currentStep - 1)
            : null,
        continueLabel: details.currentStep == 2 ? 'Importar' : 'Siguiente',
        cancelLabel: 'Atrás',
        importing: _importing,
      ),
      steps: [
        Step(
          title: const Text('Archivo y cuenta'),
          isActive: _step >= 0,
          state: _step > 0 ? StepState.complete : StepState.indexed,
          content: _buildStep1(),
        ),
        Step(
          title: const Text('Mapeo de columnas'),
          isActive: _step >= 1,
          state: _step > 1 ? StepState.complete : StepState.indexed,
          content: _buildStep2(),
        ),
        Step(
          title: const Text('Vista previa'),
          isActive: _step >= 2,
          state: StepState.indexed,
          content: _buildStep3(),
        ),
      ],
    );
  }

  // ── Paso 1 ───────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de archivo
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            _filePath ?? 'Seleccionar archivo CSV…',
          ),
        ),
        if (_filePath != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_rawRows.length} filas detectadas',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // Delimitador
        DropdownButtonFormField<String>(
          initialValue: _delimiter,
          decoration: const InputDecoration(
            labelText: 'Delimitador',
            isDense: true,
          ),
          items: _kDelimiters
              .map(
                (d) => DropdownMenuItem(
                  value: d.$1,
                  child: Text(d.$2),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) _onDelimiterChanged(v);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Cuenta destino
        accountsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) =>
              const Text('Error cargando cuentas'),
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Text(
                'Crea una cuenta primero para asociar las transacciones.',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            // Pre-seleccionar si viene del AccountsPage
            _selectedAccountId ??= widget.preselectedAccountId;
            return DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Cuenta destino',
                isDense: true,
              ),
              items: accounts
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(
                            iconFromCode(a.iconCode),
                            size: 16,
                            color: colorFromHex(a.colorHex),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(a.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedAccountId = v),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Moneda
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(
            labelText: 'Moneda del CSV',
            isDense: true,
          ),
          items: _kCurrencies
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _currency = v);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Vista previa de las primeras filas
        if (_rawRows.isNotEmpty) _RawPreview(rows: _rawRows),
      ],
    );
  }

  // ── Paso 2 ───────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    if (_rawRows.isEmpty) {
      return const Text('Carga un archivo primero.');
    }
    final items = _colItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        SwitchListTile(
          value: _skipFirstRow,
          onChanged: (v) => setState(() => _skipFirstRow = v),
          title: const Text('Primera fila es encabezado'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Fecha
        DropdownButtonFormField<int>(
          initialValue: _dateCol,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Columna de fecha',
            isDense: true,
          ),
          items: items,
          onChanged: (v) {
            if (v != null) setState(() => _dateCol = v);
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Formato de fecha
        DropdownButtonFormField<String>(
          initialValue: _dateFormat,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Formato de fecha',
            isDense: true,
          ),
          items: kDateFormats
              .map(
                (f) => DropdownMenuItem(
                  value: f.$1,
                  child: Text('${f.$2}  (${f.$1})'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _dateFormat = v);
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Descripción
        DropdownButtonFormField<int>(
          initialValue: _descCol,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Columna de descripción',
            isDense: true,
          ),
          items: items,
          onChanged: (v) {
            if (v != null) setState(() => _descCol = v);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Modo de monto
        const Text(
          'Columnas de monto',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Monto único'),
              icon: Icon(Icons.attach_money, size: 16),
            ),
            ButtonSegment(
              value: true,
              label: Text('Débito / Crédito'),
              icon: Icon(Icons.compare_arrows, size: 16),
            ),
          ],
          selected: {_useSeparateCols},
          onSelectionChanged: (s) =>
              setState(() => _useSeparateCols = s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (!_useSeparateCols)
          DropdownButtonFormField<int>(
            initialValue: _amountCol,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Columna de monto (+ ingreso / − gasto)',
              isDense: true,
            ),
            items: items,
            onChanged: (v) {
              if (v != null) setState(() => _amountCol = v);
            },
          )
        else ...[
          DropdownButtonFormField<int>(
            initialValue: _debitCol,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Columna débito (gasto)',
              isDense: true,
            ),
            items: items,
            onChanged: (v) {
              if (v != null) setState(() => _debitCol = v);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int>(
            initialValue: _creditCol,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Columna crédito (ingreso)',
              isDense: true,
            ),
            items: items,
            onChanged: (v) {
              if (v != null) setState(() => _creditCol = v);
            },
          ),
        ],
      ],
    );
  }

  // ── Paso 3: previsualización ──────────────────────────────────────────────────

  Widget _buildStep3() {
    final result = _importResult;
    if (result == null) {
      return const Text('Vuelve al paso anterior y pulsa Siguiente.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen
        Row(
          children: [
            _SummaryChip(
              label: '${result.successCount} válidas',
              color: AppColors.income,
            ),
            const SizedBox(width: AppSpacing.sm),
            if (result.hasErrors)
              _SummaryChip(
                label: '${result.errorCount} errores',
                color: AppColors.expense,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Tabla de previsualización (primeras 15 filas)
        _PreviewTable(rows: result.rows.take(15).toList()),

        // Errores (primeros 5)
        if (result.hasErrors) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Filas con error (no se importarán):',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.expense,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...result.errors.take(5).map(
                (e) => Text(
                  e.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          if (result.errorCount > 5)
            Text(
              '… y ${result.errorCount - 5} errores más.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDisabled,
              ),
            ),
        ],

        if (_importing) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Importando…',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildDone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 72,
            color: AppColors.income,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$_importedCount transacciones importadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x2l),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check),
            label: const Text('Listo'),
          ),
        ],
      ),
    );
  }
}

// ── Controles del Stepper ─────────────────────────────────────────────────────

class _StepControls extends StatelessWidget {
  const _StepControls({
    required this.step,
    required this.totalSteps,
    required this.canContinue,
    required this.onContinue,
    required this.onCancel,
    this.continueLabel = 'Siguiente',
    this.cancelLabel = 'Atrás',
    this.importing = false,
  });

  final int step;
  final int totalSteps;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback? onCancel;
  final String continueLabel;
  final String cancelLabel;
  final bool importing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            FilledButton(
              onPressed: canContinue && !importing ? onContinue : null,
              child: importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(continueLabel),
            ),
            if (onCancel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onCancel,
                child: Text(cancelLabel),
              ),
            ],
          ],
        ),
      );
}

// ── Vista previa de filas crudas ──────────────────────────────────────────────

class _RawPreview extends StatelessWidget {
  const _RawPreview({required this.rows});
  final List<List<dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final preview = rows.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista previa (primeras 4 filas):',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: AppColors.border, width: 0.5),
            defaultColumnWidth: const FixedColumnWidth(110),
            children: preview
                .map(
                  (row) => TableRow(
                    children: row
                        .take(6)
                        .map(
                          (cell) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              cell.toString(),
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Tabla de previsualización de filas mapeadas ───────────────────────────────

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.rows});
  final List<CsvRow> rows;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0.00', 'es');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 36,
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Fecha', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Descripción', style: TextStyle(fontSize: 12))),
          DataColumn(
            label: Text('Tipo', style: TextStyle(fontSize: 12)),
            numeric: false,
          ),
          DataColumn(
            label: Text('Monto', style: TextStyle(fontSize: 12)),
            numeric: true,
          ),
        ],
        rows: rows
            .map(
              (r) => DataRow(
                cells: [
                  DataCell(Text(fmt.format(r.date), style: const TextStyle(fontSize: 12))),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        r.description,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.type == 'income' ? 'Ingreso' : 'Gasto',
                      style: TextStyle(
                        fontSize: 12,
                        color: r.type == 'income'
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      moneyFmt.format(r.amount),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Chip de resumen ───────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}
