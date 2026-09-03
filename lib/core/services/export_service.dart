import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../utils/category_utils.dart';

import '../../data/local/app_database.dart';

// ── Servicio de exportación de reportes ──────────────────────────────────────
//
// Genera reportes mensuales en formato PDF (legible, imprimible) o CSV
// (para análisis en Excel/Sheets).
//
// Desktop  → diálogo de guardar archivo (file_selector.getSaveLocation).
// Móvil    → hoja de compartir del sistema operativo (share_plus).

class ExportService {
  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  // ── Punto de entrada público ──────────────────────────────────────────────

  /// [format] debe ser 'pdf' o 'csv'.
  static Future<void> exportMonthlyReport({
    required BuildContext context,
    required String format,
    required int year,
    required int month,
    required List<TransactionsTableData> transactions,
    required List<CategoriesTableData> categories,
  }) async {
    final monthName = _monthNames[month - 1];
    final fileName = 'budget_${monthName}_$year.$format';

    final s = S.of(context);
    final localeName = Localizations.localeOf(context).languageCode;
    final displayMonth = toBeginningOfSentenceCase(
          DateFormat.MMMM(localeName).format(DateTime(year, month)),
        ) ??
        monthName;
    final catNames = {
      for (final c in categories) c.id: categoryDisplayName(context, c.id, c.name),
    };

    final Uint8List bytes;
    final String mimeType;

    if (format == 'csv') {
      final csv = _buildCsv(transactions, catNames, s);
      // BOM UTF-8 para que Excel abra correctamente en Windows
      bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
      mimeType = 'text/csv';
    } else {
      bytes = await _buildPdf(
        year: year,
        month: month,
        displayMonth: displayMonth,
        transactions: transactions,
        categories: categories,
        catNames: catNames,
        s: s,
      );
      mimeType = 'application/pdf';
    }

    if (!context.mounted) return;
    await _saveOrShare(context, fileName, bytes, mimeType);
  }

  // ── CSV ───────────────────────────────────────────────────────────────────

  static String _buildCsv(
    List<TransactionsTableData> transactions,
    Map<String, String> catMap,
    S s,
  ) {
    final buf = StringBuffer();
    buf.writeln(s.csvExportHeader);
    // Ordenar por fecha descendente (igual que en la UI)
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    for (final tx in sorted) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final String type;
      final String peer;
      if (tx.type == 'transfer') {
        final meta = _parseTransferNotes(tx.notes);
        type = meta != null && meta['direction'] == 'out'
            ? s.transferSent
            : s.transferReceived;
        peer = meta?['peer_name'] as String? ?? '';
      } else {
        type = tx.type == 'income' ? s.incomeTypeButton : s.expenseTypeButton;
        peer = '';
      }
      final cat = catMap[tx.categoryId ?? ''] ?? '';
      final desc = (tx.description ?? '').replaceAll('"', "'");
      final usd = tx.amountUsdEquivalent?.toStringAsFixed(2) ?? '';
      buf.writeln(
        '$date,$type,${tx.amount.toStringAsFixed(2)},${tx.currencyCode},$usd,"$cat","$desc","$peer"',
      );
    }
    return buf.toString();
  }

  static Map<String, dynamic>? _parseTransferNotes(String? notes) {
    if (notes == null) return null;
    try {
      return jsonDecode(notes) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── PDF ───────────────────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdf({
    required int year,
    required int month,
    required String displayMonth,
    required List<TransactionsTableData> transactions,
    required List<CategoriesTableData> categories,
    required Map<String, String> catNames,
    required S s,
  }) async {
    final doc = pw.Document();
    final fmt = NumberFormat('#,##0.00', 'es');
    final dateFmt = DateFormat('dd/MM');
    final catMap = catNames;
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // ── Calcular totales ────────────────────────────────────────────────────
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> byCategory = {};

    for (final tx in transactions) {
      if (tx.type == 'transfer') continue; // Neutrales: no afectan totales
      final val = tx.amountUsdEquivalent ?? (tx.currencyCode == 'USD' ? tx.amount : 0.0);
      if (tx.type == 'income') {
        totalIncome += val;
      } else {
        totalExpense += val;
        final catId = tx.categoryId ?? '';
        byCategory[catId] = (byCategory[catId] ?? 0) + val;
      }
    }
    final balance = totalIncome - totalExpense;

    // Categorías ordenadas por gasto descendente
    final sortedCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Transacciones ordenadas por fecha descendente
    final sortedTxs = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    // ── Colores PDF ─────────────────────────────────────────────────────────
    final cPrimary = _pdfColor('#2C3E50');
    final cIncome = _pdfColor('#27AE60');
    final cExpense = _pdfColor('#E74C3C');
    final cBalance = balance >= 0 ? _pdfColor('#2980B9') : _pdfColor('#E67E22');
    final cHeaderBg = _pdfColor('#F0F3F4');
    final cRowSep = _pdfColor('#E8EAEC');
    final cTextSecondary = _pdfColor('#7F8C8D');

    // ── Estilos ─────────────────────────────────────────────────────────────
    const baseSize = 8.5;
    const sNormal = pw.TextStyle(fontSize: baseSize);
    // ignore: prefer_const_declarations
    final sBold = pw.TextStyle(
      fontSize: baseSize,
      fontWeight: pw.FontWeight.bold,
    );
    final sSmall = pw.TextStyle(fontSize: 7.0, color: cTextSecondary);
    final sHeader = pw.TextStyle(
      fontSize: 10.5,
      fontWeight: pw.FontWeight.bold,
      color: cPrimary,
    );

    // ── Helper: celda de tabla ───────────────────────────────────────────────
    pw.Widget cell(
      String text,
      pw.TextStyle style, {
      double pad = 5,
      pw.TextAlign align = pw.TextAlign.left,
      int maxLines = 2,
    }) =>
        pw.Padding(
          padding: pw.EdgeInsets.all(pad),
          child: pw.Text(
            text,
            style: style,
            textAlign: align,
            maxLines: maxLines,
            overflow: pw.TextOverflow.clip,
          ),
        );

    // ── Helper: caja de resumen ──────────────────────────────────────────────
    pw.Widget summaryBox(
      String label,
      String value,
      PdfColor color,
    ) =>
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 6),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: color, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label, style: sSmall),
                pw.SizedBox(height: 3),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );

    // ── Encabezado de página (se repite en cada página) ─────────────────────
    pw.Widget pageHeader(pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Budget Familiar',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: cPrimary,
                  ),
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      s.reportTitle(displayMonth, year),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(s.generatedOn(now), style: sSmall),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.5, color: cPrimary),
          ],
        );

    // ── Pie de página ───────────────────────────────────────────────────────
    pw.Widget pageFooter(pw.Context ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            s.pageOf(ctx.pageNumber, ctx.pagesCount),
            style: sSmall,
          ),
        );

    // ── Tabla de categorías ─────────────────────────────────────────────────
    pw.Widget categoryTable() => pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FixedColumnWidth(78),
            2: pw.FixedColumnWidth(38),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: cHeaderBg),
              children: [
                cell(s.categoryLabel, sBold),
                cell(s.pdfColAmountUsd, sBold, align: pw.TextAlign.right),
                cell('%', sBold, align: pw.TextAlign.right),
              ],
            ),
            ...sortedCats.map((e) {
              final name = e.key.isEmpty
                  ? s.noCategoryLabel
                  : (catMap[e.key] ?? e.key);
              final pct = totalExpense > 0
                  ? (e.value / totalExpense * 100)
                  : 0.0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: cRowSep, width: 0.5),
                  ),
                ),
                children: [
                  cell(name, sNormal),
                  cell(
                    '\$ ${fmt.format(e.value)}',
                    sNormal,
                    align: pw.TextAlign.right,
                  ),
                  cell(
                    '${pct.toStringAsFixed(1)}%',
                    sNormal,
                    align: pw.TextAlign.right,
                  ),
                ],
              );
            }),
          ],
        );

    // ── Tabla de movimientos ─────────────────────────────────────────────────
    pw.Widget transactionTable() => sortedTxs.isEmpty
        ? pw.Text(s.noMovements, style: sNormal)
        : pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(42), // Fecha
              1: pw.FixedColumnWidth(40), // Tipo
              2: pw.FlexColumnWidth(), // Descripción
              3: pw.FixedColumnWidth(68), // Categoría
              4: pw.FixedColumnWidth(72), // Monto
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: cHeaderBg),
                children: [
                  cell(s.fieldDate, sBold),
                  cell(s.fieldType, sBold),
                  cell(s.fieldDescription, sBold),
                  cell(s.categoryLabel, sBold),
                  cell(s.amountLabel, sBold, align: pw.TextAlign.right),
                ],
              ),
              ...sortedTxs.map((tx) {
                final PdfColor color;
                final String sign;
                final String typeLabel;
                final String descText;

                if (tx.type == 'transfer') {
                  final meta = _parseTransferNotes(tx.notes);
                  final isOut = meta?['direction'] == 'out';
                  color = cTextSecondary;
                  sign = isOut ? '→' : '←';
                  typeLabel = isOut ? s.transferSentShort : s.transferReceivedShort;
                  final peer = meta?['peer_name'] as String? ?? '';
                  descText = peer.isNotEmpty
                      ? '${tx.description ?? ''} ($peer)'.trim()
                      : (tx.description ?? '-');
                } else {
                  final isIncome = tx.type == 'income';
                  color = isIncome ? cIncome : cExpense;
                  sign = isIncome ? '+' : '-';
                  typeLabel = isIncome ? s.incomeTypeButton : s.expenseTypeButton;
                  descText = tx.description ?? '-';
                }

                final catName = catMap[tx.categoryId ?? ''] ?? '';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: cRowSep, width: 0.5),
                    ),
                  ),
                  children: [
                    cell(dateFmt.format(tx.date), sNormal),
                    cell(
                      typeLabel,
                      pw.TextStyle(fontSize: baseSize, color: color),
                    ),
                    cell(descText, sNormal),
                    cell(catName, sNormal),
                    cell(
                      '$sign ${tx.currencyCode} ${fmt.format(tx.amount)}',
                      pw.TextStyle(fontSize: baseSize, color: color),
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
            ],
          );

    // ── Página ───────────────────────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        header: pageHeader,
        footer: pageFooter,
        build: (ctx) => [
          pw.SizedBox(height: 14),

          // Resumen numérico
          pw.Row(
            children: [
              summaryBox(
                s.summaryIncomeUsd,
                '+\$ ${fmt.format(totalIncome)}',
                cIncome,
              ),
              summaryBox(
                s.summaryExpenseUsd,
                '-\$ ${fmt.format(totalExpense)}',
                cExpense,
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: cBalance, width: 1.5),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(s.summaryBalanceUsd, style: sSmall),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${balance >= 0 ? '+' : ''}\$ ${fmt.format(balance)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: cBalance,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Gastos por categoría
          if (sortedCats.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            pw.Text(s.pdfExpensesByCategory, style: sHeader),
            pw.SizedBox(height: 8),
            categoryTable(),
          ],

          // Movimientos del mes
          pw.SizedBox(height: 22),
          pw.Text(
            s.pdfMonthMovements(transactions.length),
            style: sHeader,
          ),
          pw.SizedBox(height: 8),
          transactionTable(),
        ],
      ),
    );

    return doc.save();
  }

  // ── Guardar o compartir ───────────────────────────────────────────────────

  static Future<void> _saveOrShare(
    BuildContext context,
    String fileName,
    Uint8List bytes,
    String mimeType,
  ) async {
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktop) {
      final ext = fileName.split('.').last;
      final typeGroup = XTypeGroup(
        label: ext.toUpperCase(),
        extensions: [ext],
        mimeTypes: [mimeType],
      );
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [typeGroup],
      );
      if (location == null) return; // Usuario canceló
      await File(location.path).writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).savedTo(location.path)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      // Móvil: guardar en directorio temporal y compartir
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
    }
  }

  // ── Utilidades privadas ───────────────────────────────────────────────────

  /// Convierte un hex como '#27AE60' a PdfColor.
  static PdfColor _pdfColor(String hex) {
    final c = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return PdfColor(
      ((c >> 16) & 0xFF) / 255.0,
      ((c >> 8) & 0xFF) / 255.0,
      (c & 0xFF) / 255.0,
    );
  }
}
