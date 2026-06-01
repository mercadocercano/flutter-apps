import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import 'blocs/bulk_import_bloc.dart';

class BulkImportScreen extends StatelessWidget {
  const BulkImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar productos'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Descargar template'),
            onPressed: () => _showTemplateDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<BulkImportBloc, BulkImportState>(
        listener: _onStateChange,
        builder: (context, state) {
          if (state is BulkImportInitial) {
            return _InitialView();
          }
          if (state is BulkImportParsing || state is BulkImportUploading) {
            return const _LoadingView();
          }
          if (state is BulkImportPreview) {
            return _PreviewView(state: state);
          }
          if (state is BulkImportSuccess) {
            return _SuccessView(result: state);
          }
          if (state is BulkImportFailed) {
            return _FailedView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onStateChange(BuildContext context, BulkImportState state) {
    if (state is BulkImportFailed) {
      AdminSnackbars.showError(context, state.message);
    }
  }

  void _showTemplateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _TemplateDialog(),
    );
  }
}

// --- Vista inicial: pegar contenido ---

class _InitialView extends StatefulWidget {
  @override
  State<_InitialView> createState() => _InitialViewState();
}

class _InitialViewState extends State<_InitialView> {
  final _contentController = TextEditingController();
  String _format = 'csv';

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _parseContent(BuildContext context) {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      AdminSnackbars.showError(context, 'Pegá el contenido del archivo primero');
      return;
    }
    final bytes = utf8.encode(content);
    final fileName = _format == 'json' ? 'import.json' : 'import.csv';
    context.read<BulkImportBloc>().add(
          ParseBulkImportFileEvent(bytes: bytes, fileName: fileName),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Importar productos desde CSV o JSON',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pegá el contenido del archivo en el campo de abajo. '
                'Campos obligatorios: name, sku.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _FormatSelector(
                selected: _format,
                onChanged: (v) => setState(() => _format = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 16,
                decoration: InputDecoration(
                  labelText: _format == 'json'
                      ? 'Contenido JSON'
                      : 'Contenido CSV',
                  border: const OutlineInputBorder(),
                  hintText: _format == 'json'
                      ? '[{"name":"Tornillo M6","sku":"TORN-M6"}]'
                      : 'name,sku,barcode\nTornillo M6,TORN-M6,7701234',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _parseContent(context),
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Previsualizar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Selector de formato ---

class _FormatSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FormatSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Formato:'),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('CSV'),
          selected: selected == 'csv',
          onSelected: (_) => onChanged('csv'),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('JSON'),
          selected: selected == 'json',
          onSelected: (_) => onChanged('json'),
        ),
      ],
    );
  }
}

// --- Vista de carga ---

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Procesando...'),
        ],
      ),
    );
  }
}

// --- Vista de preview ---

class _PreviewView extends StatelessWidget {
  final BulkImportPreview state;

  const _PreviewView({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasValidRows = state.validRowCount > 0;

    return Column(
      children: [
        _PreviewSummaryBar(
          validCount: state.validRowCount,
          errorCount: state.errorRowCount,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            child: _PreviewTable(state: state),
          ),
        ),
        _PreviewActions(
          canConfirm: hasValidRows,
          onConfirm: () => context.read<BulkImportBloc>().add(
                ConfirmBulkImportEvent(
                  state.rows
                      .asMap()
                      .entries
                      .where((e) => state.rowErrors[e.key] == null)
                      .map((e) => e.value)
                      .toList(),
                ),
              ),
          onCancel: () =>
              context.read<BulkImportBloc>().add(ResetBulkImportEvent()),
        ),
      ],
    );
  }
}

class _PreviewSummaryBar extends StatelessWidget {
  final int validCount;
  final int errorCount;

  const _PreviewSummaryBar({
    required this.validCount,
    required this.errorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _SummaryChip(
            icon: Icons.check_circle_outline,
            label: '$validCount válidos',
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          _SummaryChip(
            icon: Icons.error_outline,
            label: '$errorCount con errores',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _PreviewTable extends StatelessWidget {
  final BulkImportPreview state;

  const _PreviewTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = state.rows;
    if (rows.isEmpty) {
      return const Center(child: Text('No hay filas para previsualizar'));
    }

    final headers = rows.first.keys.toList();

    return DataTable(
      columns: [
        const DataColumn(label: Text('#')),
        ...headers.map((h) => DataColumn(label: Text(h))),
        const DataColumn(label: Text('Estado')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final error = state.rowErrors[index];
        final hasError = error != null;

        return DataRow(
          color: hasError
              ? WidgetStateProperty.all(Colors.red[50])
              : null,
          cells: [
            DataCell(Text('${index + 1}')),
            ...headers.map(
              (h) => DataCell(
                Text(
                  row[h]?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
              hasError
                  ? Tooltip(
                      message: error,
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 18,
                    ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PreviewActions extends StatelessWidget {
  final bool canConfirm;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PreviewActions({
    required this.canConfirm,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Volver'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: canConfirm ? onConfirm : null,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Confirmar importación'),
          ),
        ],
      ),
    );
  }
}

// --- Vista de éxito ---

class _SuccessView extends StatelessWidget {
  final BulkImportSuccess result;

  const _SuccessView({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result.result;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Importación completada',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ResultRow(
                        icon: Icons.add_circle_outline,
                        label: 'Productos importados',
                        value: '${r.importedCount}',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _ResultRow(
                        icon: Icons.error_outline,
                        label: 'Errores',
                        value: '${r.failedCount}',
                        color: r.hasErrors ? Colors.red : Colors.grey,
                      ),
                      if (r.hasErrors) ...[
                        const Divider(height: 20),
                        ...r.errors.take(5).map(
                              (e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '• Fila ${e.rowNumber}: ${e.reason}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                        if (r.errors.length > 5)
                          Text(
                            '... y ${r.errors.length - 5} errores más',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => context
                        .read<BulkImportBloc>()
                        .add(ResetBulkImportEvent()),
                    child: const Text('Nueva importación'),
                  ),
                  FilledButton(
                    onPressed: () => context.go('/pim/global-catalog'),
                    child: const Text('Ir al catálogo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// --- Vista de error general ---

class _FailedView extends StatelessWidget {
  final String message;

  const _FailedView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context
                  .read<BulkImportBloc>()
                  .add(ResetBulkImportEvent()),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Dialog de template descargable ---

class _TemplateDialog extends StatelessWidget {
  const _TemplateDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Template de importación'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Formato CSV:',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const SelectableText(
                'name,sku,barcode,description,image_url,category_id,business_type_ids\n'
                'Tornillo M6x20,TORN-M6-20,7701234567890,Tornillo de acero,,cat-123,bt-ferreteria',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Formato JSON:',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const SelectableText(
                '[\n'
                '  {\n'
                '    "name": "Tornillo M6x20",\n'
                '    "sku": "TORN-M6-20",\n'
                '    "barcode": "7701234567890",\n'
                '    "description": "Tornillo de acero",\n'
                '    "category_id": "cat-123"\n'
                '  }\n'
                ']',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '* Campos obligatorios: name, sku',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
