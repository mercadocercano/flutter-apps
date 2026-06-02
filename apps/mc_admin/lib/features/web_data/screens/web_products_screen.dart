import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../blocs/web_products_bloc.dart';

class WebProductsScreen extends StatefulWidget {
  const WebProductsScreen({super.key});

  @override
  State<WebProductsScreen> createState() => _WebProductsScreenState();
}

class _WebProductsScreenState extends State<WebProductsScreen> {
  String? _sourceFilter;
  String? _businessTypeFilter;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebProductsBloc, WebProductsState>(
      listener: _onStateChange,
      builder: (context, state) {
        final products =
            state is WebProductsLoaded ? state.products : <WebProduct>[];
        final isLoading = state is WebProductsLoading;
        final error = state is WebProductsError ? state.message : null;
        final loaded = state is WebProductsLoaded ? state : null;

        return Stack(
          children: [
            Column(
              children: [
                _FilterBar(
                  sourceFilter: _sourceFilter,
                  businessTypeFilter: _businessTypeFilter,
                  onSourceChanged: _applySourceFilter,
                  onBusinessTypeChanged: _applyBusinessTypeFilter,
                ),
                Expanded(
                  child: AdminDataTable<WebProduct>(
                    items: products,
                    isLoading: isLoading,
                    error: error,
                    onRetry: () => context
                        .read<WebProductsBloc>()
                        .add(LoadWebProductsEvent()),
                    currentPage: 1,
                    pageSize: products.isNotEmpty ? products.length : 20,
                    totalItems: products.length,
                    onPageChanged: (_) {},
                    searchHint: 'Buscar productos...',
                    columns: _buildColumns(context, loaded),
                  ),
                ),
              ],
            ),
            if (loaded != null && loaded.hasSelection)
              _BulkActionBar(
                selectedCount: loaded.selectedIds.length,
                selectedIds: loaded.selectedIds,
                products: loaded.products,
              ),
          ],
        );
      },
    );
  }

  List<AdminColumn<WebProduct>> _buildColumns(
    BuildContext context,
    WebProductsLoaded? loaded,
  ) {
    return [
      AdminColumn(
        label: '',
        width: 48,
        builder: (product) => Checkbox(
          value: loaded?.selectedIds.contains(product.id) ?? false,
          onChanged: (selected) => _toggleSelection(context, product.id, selected),
        ),
      ),
      AdminColumn(
        label: 'Nombre',
        builder: (product) => _NameCell(name: product.name, price: product.price),
      ),
      AdminColumn(
        label: 'Fuente',
        width: 120,
        builder: (product) => Text(
          product.sourceId,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      AdminColumn(
        label: 'Tipo',
        width: 130,
        builder: (product) => product.hasBusinessType
            ? StatusBadge.fromString('active',
                customLabel: product.businessTypeId!)
            : const StatusBadge(
                status: AdminStatus.pending,
                customLabel: 'Sin asignar',
              ),
      ),
      AdminColumn(
        label: 'Scrapeado',
        width: 120,
        builder: (product) => _ScrapedAtCell(date: product.scrapedAt),
      ),
      AdminColumn(
        label: 'Acciones',
        width: 130,
        builder: (product) => _RowActions(product: product),
      ),
    ];
  }

  void _toggleSelection(BuildContext context, String id, bool? selected) {
    if (selected == true) {
      context.read<WebProductsBloc>().add(SelectProductEvent(id));
    } else {
      context.read<WebProductsBloc>().add(DeselectProductEvent(id));
    }
  }

  void _applySourceFilter(String? source) {
    setState(() => _sourceFilter = source);
    context.read<WebProductsBloc>().add(
          LoadWebProductsEvent(
            sourceId: source,
            businessTypeId: _businessTypeFilter,
          ),
        );
  }

  void _applyBusinessTypeFilter(String? businessType) {
    setState(() => _businessTypeFilter = businessType);
    context.read<WebProductsBloc>().add(
          LoadWebProductsEvent(
            sourceId: _sourceFilter,
            businessTypeId: businessType,
          ),
        );
  }

  void _onStateChange(BuildContext context, WebProductsState state) {
    if (state is WebProductsError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final String? sourceFilter;
  final String? businessTypeFilter;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onBusinessTypeChanged;

  const _FilterBar({
    required this.sourceFilter,
    required this.businessTypeFilter,
    required this.onSourceChanged,
    required this.onBusinessTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Fuente:'),
            const SizedBox(width: 8),
            DropdownButton<String?>(
              value: sourceFilter,
              hint: const Text('Todas'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas')),
              ],
              onChanged: onSourceChanged,
            ),
            const SizedBox(width: 16),
            const Text('Tipo:'),
            const SizedBox(width: 8),
            DropdownButton<String?>(
              value: businessTypeFilter,
              hint: const Text('Todos'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
              ],
              onChanged: onBusinessTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Celdas de tabla
// ---------------------------------------------------------------------------

class _NameCell extends StatelessWidget {
  final String name;
  final double price;

  const _NameCell({required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ScrapedAtCell extends StatelessWidget {
  final DateTime date;

  const _ScrapedAtCell({required this.date});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Text(formatted, style: const TextStyle(fontSize: 12));
  }
}

// ---------------------------------------------------------------------------
// Acciones de fila
// ---------------------------------------------------------------------------

class _RowActions extends StatelessWidget {
  final WebProduct product;

  const _RowActions({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'Ver detalle',
          onPressed: () => context.push('/web-data/products/${product.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.label_outline, size: 18),
          tooltip: 'Asignar tipo',
          onPressed: () => _showAssignDialog(context, product.id),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _showAssignDialog(BuildContext context, String productId) async {
    final businessTypeId = await showDialog<String>(
      context: context,
      builder: (_) => const _BusinessTypeDialog(),
    );
    if (businessTypeId != null && context.mounted) {
      context.read<WebProductsBloc>().add(
            AssignBusinessTypeEvent(
              id: productId,
              businessTypeId: businessTypeId,
            ),
          );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar producto',
      message: '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<WebProductsBloc>().add(DeleteWebProductEvent(product.id));
    }
  }
}

// ---------------------------------------------------------------------------
// Barra de acciones bulk
// ---------------------------------------------------------------------------

class _BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final Set<String> selectedIds;
  final List<WebProduct> products;

  const _BulkActionBar({
    required this.selectedCount,
    required this.selectedIds,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  '$selectedCount seleccionados',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text('Eliminar ($selectedCount)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmBulkDelete(context),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.label_outline, size: 16),
                label: Text('Asignar tipo ($selectedCount)'),
                onPressed: () => _showBulkAssignDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBulkAssignDialog(BuildContext context) async {
    final businessTypeId = await showDialog<String>(
      context: context,
      builder: (_) => const _BusinessTypeDialog(),
    );
    if (businessTypeId != null && context.mounted) {
      context
          .read<WebProductsBloc>()
          .add(BulkAssignBusinessTypeEvent(businessTypeId));
    }
  }

  Future<void> _confirmBulkDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar productos',
      message:
          '¿Eliminar $selectedCount productos? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<WebProductsBloc>().add(BulkDeleteWebProductsEvent());
    }
  }
}

// ---------------------------------------------------------------------------
// Diálogo selector de business type
// ---------------------------------------------------------------------------

class _BusinessTypeDialog extends StatefulWidget {
  const _BusinessTypeDialog();

  @override
  State<_BusinessTypeDialog> createState() => _BusinessTypeDialogState();
}

class _BusinessTypeDialogState extends State<_BusinessTypeDialog> {
  String? _selectedId;

  // Lista estática de ejemplo — en producción se cargaría desde repositorio.
  // El BLoC de business types se integraría aquí cuando se disponga del
  // QuickstartRepository en el contexto.
  static const _options = [
    ('ferreteria', 'Ferretería'),
    ('supermercado', 'Supermercado'),
    ('panaderia', 'Panadería'),
    ('farmacia', 'Farmacia'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar tipo de comercio'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _options
              .map(
                (option) => RadioListTile<String>(
                  title: Text(option.$2),
                  value: option.$1,
                  groupValue: _selectedId,
                  onChanged: (v) => setState(() => _selectedId = v),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _selectedId != null ? () => Navigator.of(context).pop(_selectedId) : null,
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}
