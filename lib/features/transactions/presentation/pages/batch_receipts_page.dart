import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/receipt_batch_service.dart';
import '../../../../data/local/app_database.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../family/providers/family_provider.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../../../core/services/ai_proxy_service.dart';
import '../../../settings/providers/ocr_settings_provider.dart';

/// Punto de entrada del lote: en móvil ofrece galería (varios) o cámara
/// (tomar varios); en escritorio va directo a selección de archivos.
Future<void> launchBatchReceipts(BuildContext context, WidgetRef ref) async {
  if (!ref.read(isPremiumProvider)) {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
    return;
  }

  final isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (!isMobile) {
    await _desktopFolderEntry(context);
    return;
  }

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(S.of(context).batchGalleryMultiple),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(S.of(context).batchTakePhotos),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  if (choice == 'gallery') {
    await _pickGalleryAndReview(context);
  } else {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ReceiptCaptureQueuePage()),
    );
  }
}

Future<void> _pickGalleryAndReview(BuildContext context) async {
  final picker = ImagePicker();
  final files = await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
  if (files.isEmpty || !context.mounted) return;
  await _reviewImages(context, files);
}

/// Construye los BatchItem desde una lista de XFile y abre la revisión.
Future<void> _reviewImages(BuildContext context, List<XFile> files) async {
  final items = <BatchItem>[];
  for (var i = 0; i < files.length; i++) {
    final f = files[i];
    final bytes = await f.readAsBytes();
    final lower = f.name.toLowerCase();
    final mime = f.mimeType ??
        (lower.endsWith('.png') ? 'image/png' : 'image/jpeg');
    items.add(BatchItem(id: '${i}_${f.name}', name: f.name, bytes: bytes, mime: mime));
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => BatchReceiptsPage(items: items)),
  );
}

const _kReceiptFolderKey = 'receipt_inbox_folder';

/// Escritorio: elegir/escanear una carpeta designada de tickets.
Future<void> _desktopFolderEntry(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kReceiptFolderKey);
  if (!context.mounted) return;

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saved != null)
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: Text(S.of(context).batchScanFolder),
              subtitle:
                  Text(saved, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, 'scan'),
            ),
          ListTile(
            leading: const Icon(Icons.drive_folder_upload_outlined),
            title: Text(
                saved == null ? S.of(context).batchChooseFolder : S.of(context).batchChangeFolder),
            onTap: () => Navigator.pop(context, 'choose'),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: Text(S.of(context).batchChooseFiles),
            onTap: () => Navigator.pop(context, 'files'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  if (choice == 'files') {
    await _pickGalleryAndReview(context);
    return;
  }

  var folder = saved;
  if (choice == 'choose' || folder == null) {
    final picked = await getDirectoryPath();
    if (picked == null || !context.mounted) return;
    folder = picked;
    await prefs.setString(_kReceiptFolderKey, folder);
  }
  if (!context.mounted) return;
  await _scanFolderAndReview(context, folder);
}

Future<void> _scanFolderAndReview(BuildContext context, String folder) async {
  final dir = Directory(folder);
  if (!dir.existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).batchFolderGone)));
    }
    return;
  }
  const exts = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => exts.any((e) => f.path.toLowerCase().endsWith(e)))
      .toList();
  if (files.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).batchNoNew)));
    }
    return;
  }
  final items = <BatchItem>[];
  for (var i = 0; i < files.length; i++) {
    final f = files[i];
    final bytes = await f.readAsBytes();
    final name = f.path.split(Platform.pathSeparator).last;
    final lower = name.toLowerCase();
    final mime = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    items.add(BatchItem(
        id: 'folder_${i}_$name',
        name: name,
        bytes: bytes,
        mime: mime,
        sourcePath: f.path));
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
        builder: (_) => BatchReceiptsPage(items: items, inboxFolder: folder)),
  );
}

class BatchReceiptsPage extends ConsumerStatefulWidget {
  const BatchReceiptsPage({super.key, required this.items, this.inboxFolder});
  final List<BatchItem> items;
  final String? inboxFolder;

  @override
  ConsumerState<BatchReceiptsPage> createState() => _BatchReceiptsPageState();
}

class _BatchReceiptsPageState extends ConsumerState<BatchReceiptsPage> {
  bool _processing = true;
  bool _saving = false;
  List<CategoriesTableData> _cats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    // Cargar categorías del grupo para los dropdowns.
    final db = ref.read(appDatabaseProvider);
    final groupId = ref.read(activeGroupIdProvider);
    _cats = await db.categoriesDao.getCategoriesForGroup(groupId);

    // Confirmación de cuota (solo si usa la key del desarrollador, no BYOK).
    final settings = ref.read(ocrSettingsProvider);
    if (!settings.isConfigured) {
      final used = await AiProxyService.instance.getUsageThisMonth('ocr');
      const limit = 150;
      final remaining = (limit - used).clamp(0, limit);
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(S.of(context).batchConfirmTitle),
          content: Text(
            S.of(context).batchQuotaBody(
                    widget.items.length, used, limit, remaining) +
                (widget.items.length > remaining
                    ? S.of(context).batchQuotaWarning
                    : ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(S.of(context).cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(S.of(context).batchContinue),
            ),
          ],
        ),
      );
      if (go != true) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }

    // Procesar el lote por OCR con throttle.
    final ocr = ref.read(ocrServiceProvider);
    final svc = ReceiptBatchService(ocr);
    await svc.processAll(
      widget.items,
      concurrency: 2,
      onProgress: () {
        if (mounted) setState(() {});
      },
    );

    // Pre-seleccionar categoría por la pista del OCR (best-effort por nombre).
    for (final it in widget.items) {
      if (it.categoryId == null && it.categoryHint != null) {
        final hint = it.categoryHint!.toLowerCase();
        for (final c in _cats) {
          if (c.name.toLowerCase().contains(hint)) {
            it.categoryId = c.id;
            break;
          }
        }
      }
    }

    // Detección de posibles duplicados (dentro del lote y contra la BD).
    final seen = <String>{};
    for (final it in widget.items) {
      if (it.status != BatchStatus.ready || it.amount == null) continue;
      final key = '${it.type}|${it.amount!.toStringAsFixed(2)}|'
          '${it.date.year}-${it.date.month}-${it.date.day}';
      final inBatchDup = !seen.add(key);
      final dbDup = await db.transactionsDao.existsSimilar(
        groupId: groupId,
        amount: it.amount!,
        day: it.date,
        type: it.type,
      );
      if (inBatchDup || dbDup) {
        it.duplicate = true;
        it.include = false; // por seguridad, desmarcar duplicados
      }
    }

    // Archivar fallidos a Errores/ (solo flujo de carpeta escritorio).
    if (widget.inboxFolder != null) {
      for (final it in widget.items) {
        if (it.status == BatchStatus.failed && it.sourcePath != null) {
          await _archive(it.sourcePath!, 'Errores');
        }
      }
    }

    if (mounted) setState(() => _processing = false);
  }

  Future<void> _archive(String srcPath, String sub) async {
    final base = widget.inboxFolder;
    if (base == null) return;
    try {
      final destDir = Directory('$base${Platform.pathSeparator}$sub');
      if (!destDir.existsSync()) destDir.createSync(recursive: true);
      final name = srcPath.split(Platform.pathSeparator).last;
      var dest = '${destDir.path}${Platform.pathSeparator}$name';
      if (File(dest).existsSync()) {
        dest = '${destDir.path}${Platform.pathSeparator}'
            '${DateTime.now().millisecondsSinceEpoch}_$name';
      }
      try {
        await File(srcPath).rename(dest);
      } catch (_) {
        await File(srcPath).copy(dest);
        await File(srcPath).delete();
      }
    } catch (_) {/* no bloquear el flujo por un archivo */}
  }

  int get _doneCount =>
      widget.items.where((i) => i.status != BatchStatus.pending &&
          i.status != BatchStatus.processing).length;

  int get _selectedCount => widget.items.where((i) => i.include).length;

  Future<void> _saveSelected() async {
    final toSave =
        widget.items.where((i) => i.include && i.amount != null).toList();
    if (toSave.isEmpty) return;

    setState(() => _saving = true);
    final notifier = ref.read(transactionNotifierProvider.notifier);
    var saved = 0;

    for (final it in toSave) {
      double? usd;
      if (it.currencyCode == 'VES') {
        final rates = ref.read(vesRatesProvider).valueOrNull;
        if (rates != null && rates.bcv > 0) usd = it.amount! / rates.bcv;
      } else {
        usd = it.amount;
      }
      final ok = await notifier.save(
        type: it.type,
        amount: it.amount!,
        currencyCode: it.currencyCode,
        date: it.date,
        categoryId: it.categoryId,
        description: (it.description?.trim().isEmpty ?? true)
            ? null
            : it.description!.trim(),
        amountUsdEquivalent: usd,
        accountId: null,
      );
      if (ok) {
        it.status = BatchStatus.saved;
        saved++;
        if (widget.inboxFolder != null && it.sourcePath != null) {
          await _archive(it.sourcePath!, 'Procesados');
        }
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).batchSavedCount(saved))),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final failed = widget.items.where((i) => i.status == BatchStatus.failed).length;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).batchReviewTitle)),
      body: _processing
          ? _ProgressView(done: _doneCount, total: total)
          : Column(
              children: [
                if (failed > 0)
                  Container(
                    width: double.infinity,
                    color: AppColors.warningLight,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      S.of(context).batchFailedWarn(failed),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _ItemCard(
                      item: widget.items[i],
                      cats: _cats,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _processing
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  onPressed:
                      (_saving || _selectedCount == 0) ? null : _saveSelected,
                  child: Text(_saving
                      ? S.of(context).batchSaving
                      : S.of(context).batchSaveSelected(_selectedCount)),
                ),
              ),
            ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(S.of(context).batchProcessing(done, total)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.cats,
    required this.onChanged,
  });

  final BatchItem item;
  final List<CategoriesTableData> cats;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final failed = item.status == BatchStatus.failed;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.include,
                  onChanged: failed
                      ? null
                      : (v) {
                          item.include = v ?? false;
                          onChanged();
                        },
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(item.bytes,
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (item.duplicate)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  S.of(context).batchDuplicate,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.expense),
                ),
              ),
            if (failed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.error ?? S.of(context).batchCouldntRead,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.expense),
                ),
              )
            else ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.amount?.toStringAsFixed(2) ?? '',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: S.of(context).amountLabel,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        item.amount = double.tryParse(v.replaceAll(',', '.'));
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CurrencyToggle(item: item, onChanged: onChanged),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _TypeToggle(item: item, onChanged: onChanged),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(DateFormat('d MMM yyyy', 'es').format(item.date)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: item.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        item.date = picked;
                        onChanged();
                      }
                    },
                  ),
                ],
              ),
              DropdownButtonFormField<String?>(
                initialValue: item.categoryId,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: S.of(context).categoryLabel, isDense: true),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(S.of(context).batchNoCategory),
                  ),
                  ...cats.map((c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (v) {
                  item.categoryId = v;
                  onChanged();
                },
              ),
              TextFormField(
                initialValue: item.description ?? '',
                decoration: InputDecoration(
                    labelText: S.of(context).descriptionOptional, isDense: true),
                onChanged: (v) => item.description = v,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.item, required this.onChanged});
  final BatchItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'USD', label: Text('USD')),
        ButtonSegment(value: 'VES', label: Text('VES')),
      ],
      selected: {item.currencyCode == 'VES' ? 'VES' : 'USD'},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        item.currencyCode = s.first;
        onChanged();
      },
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.item, required this.onChanged});
  final BatchItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: 'expense', label: Text(S.of(context).expenseTypeButton)),
        ButtonSegment(
            value: 'income', label: Text(S.of(context).incomeTypeButton)),
      ],
      selected: {item.type == 'income' ? 'income' : 'expense'},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        item.type = s.first;
        onChanged();
      },
    );
  }
}


/// Cola de captura con cámara: toma varias fotos seguidas y luego procesa
/// todo el lote. Usa image_picker (sin dependencia extra de cámara).
class ReceiptCaptureQueuePage extends StatefulWidget {
  const ReceiptCaptureQueuePage({super.key});

  @override
  State<ReceiptCaptureQueuePage> createState() =>
      _ReceiptCaptureQueuePageState();
}

class _ReceiptCaptureQueuePageState extends State<ReceiptCaptureQueuePage> {
  final _picker = ImagePicker();
  final List<XFile> _shots = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Abrir la cámara para la primera foto al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeOne());
  }

  Future<void> _takeOne() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final shot = await _picker.pickImage(
          source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
      if (shot != null && mounted) setState(() => _shots.add(shot));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _process() async {
    if (_shots.isEmpty) return;
    final nav = Navigator.of(context); // capturar antes del await
    final files = List<XFile>.of(_shots);
    final items = <BatchItem>[];
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      final bytes = await f.readAsBytes();
      final lower = f.name.toLowerCase();
      final mime = f.mimeType ??
          (lower.endsWith('.png') ? 'image/png' : 'image/jpeg');
      items.add(BatchItem(
          id: 'cam_${i}_${f.name}', name: f.name, bytes: bytes, mime: mime));
    }
    // Reemplaza la cola por la revisión (no deja la cámara en el back stack).
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => BatchReceiptsPage(items: items)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).batchTakeTickets(_shots.length))),
      body: _shots.isEmpty
          ? Center(child: Text(S.of(context).batchNoPhotos))
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _shots.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_shots[i].path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _shots.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _takeOne,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(S.of(context).batchTakeAnother),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _shots.isEmpty ? null : _process,
                  child: Text(S.of(context).batchProcessN(_shots.length)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
