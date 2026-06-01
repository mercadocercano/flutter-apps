import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/global_catalog_bloc.dart';
import 'blocs/product_form_bloc.dart';

class GlobalCatalogScreen extends StatefulWidget {
  const GlobalCatalogScreen({super.key});

  @override
  State<GlobalCatalogScreen> createState() => _GlobalCatalogScreenState();
}

class _GlobalCatalogScreenState extends State<GlobalCatalogScreen> {
  String? _filterBusinessTypeId;
  bool? _filterIsVerified;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<GlobalCatalogBloc>().add(LoadGlobalCatalogEvent());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<GlobalCatalogBloc>().add(LoadGlobalCatalogEvent(
            search: query.isEmpty ? null : query,
            businessTypeId: _filterBusinessTypeId,
            isVerified: _filterIsVerified,
          ));
    });
  }

  void _applyFilters({String? businessTypeId, bool? isVerified}) {
    setState(() {
      _filterBusinessTypeId = businessTypeId;
      _filterIsVerified = isVerified;
    });
    context.read<GlobalCatalogBloc>().add(LoadGlobalCatalogEvent(
          businessTypeId: businessTypeId,
          isVerified: isVerified,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormBloc, ProductFormState>(
      listener: _onFormStateChange,
      child: BlocBuilder<GlobalCatalogBloc, GlobalCatalogState>(
        builder: (context, state) {
          final products = state is GlobalCatalogLoaded
              ? state.products
              : <GlobalProduct>[];
          final isLoading = state is GlobalCatalogLoading;
          final error = state is GlobalCatalogError ? state.message : null;
          final currentPage =
              state is GlobalCatalogLoaded ? state.currentPage : 1;
          final pageSize =
              state is GlobalCatalogLoaded ? state.pageSize : 20;
          final totalItems =
              state is GlobalCatalogLoaded ? state.totalItems : 0;

          return Column(
            children: [
              _FilterBar(
                filterIsVerified: _filterIsVerified,
                onVerifiedChanged: (v) => _applyFilters(
                  businessTypeId: _filterBusinessTypeId,
                  isVerified: v,
                ),
                onImportTap: () => context.push('/pim/global-catalog/import'),
              ),
              Expanded(
                child: AdminDataTable<GlobalProduct>(
                  items: products,
                  isLoading: isLoading,
                  error: error,
                  onRetry: () => context
                      .read<GlobalCatalogBloc>()
                      .add(RefreshGlobalCatalogEvent()),
                  currentPage: currentPage,
                  pageSize: pageSize,
                  totalItems: totalItems,
                  onPageChanged: (page) => context
                      .read<GlobalCatalogBloc>()
                      .add(ChangeGlobalCatalogPageEvent(page)),
                  searchHint: 'Buscar por nombre, SKU o código de barras...',
                  onSearch: _onSearch,
                  createLabel: 'Nuevo producto',
                  onCreateTap: () => context.push('/pim/global-catalog/new'),
                  columns: [
                    AdminColumn(
                      label: 'Nombre',
                      builder: (item) => _NameCell(
                        name: item.name,
                        sku: item.sku,
                      ),
                    ),
                    AdminColumn(
                      label: 'SKU',
                      width: 140,
                      builder: (item) => Text(
                        item.sku,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminColumn(
                      label: 'Barcode',
                      width: 140,
                      builder: (item) => Text(
                        item.barcode ?? '—',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: item.barcode == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                    AdminColumn(
                      label: 'Categoría',
                      width: 120,
                      builder: (item) => Text(
                        item.categoryId ?? '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.categoryId == null ? Colors.grey : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AdminColumn(
                      label: 'Tipos de comercio',
                      width: 160,
                      builder: (item) => _BusinessTypeChips(
                        ids: item.businessTypeIds,
                      ),
                    ),
                    AdminColumn(
                      label: 'Verificado',
                      width: 100,
                      builder: (item) => _VerifiedBadge(
                        isVerified: item.isVerified,
                      ),
                    ),
                    AdminColumn(
                      label: 'Acciones',
                      width: 160,
                      builder: (item) => _RowActions(product: item),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onFormStateChange(BuildContext context, ProductFormState state) {
    if (state is ProductFormSuccess) {
      AdminSnackbars.showSuccess(context, 'Operación realizada correctamente');
      context.read<GlobalCatalogBloc>().add(RefreshGlobalCatalogEvent());
    } else if (state is ProductFormDeleted) {
      AdminSnackbars.showSuccess(context, 'Producto eliminado');
      context.read<GlobalCatalogBloc>().add(RefreshGlobalCatalogEvent());
    } else if (state is ProductFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

class _FilterBar extends StatelessWidget {
  final bool? filterIsVerified;
  final ValueChanged<bool?> onVerifiedChanged;
  final VoidCallback onImportTap;

  const _FilterBar({
    required this.filterIsVerified,
    required this.onVerifiedChanged,
    required this.onImportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: filterIsVerified == null,
                onSelected: (_) => onVerifiedChanged(null),
              ),
              FilterChip(
                label: const Text('Verificados'),
                selected: filterIsVerified == true,
                onSelected: (_) => onVerifiedChanged(true),
              ),
              FilterChip(
                label: const Text('Sin verificar'),
                selected: filterIsVerified == false,
                onSelected: (_) => onVerifiedChanged(false),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onImportTap,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  final String name;
  final String sku;

  const _NameCell({required this.name, required this.sku});

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
          sku,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _BusinessTypeChips extends StatelessWidget {
  final List<String> ids;

  const _BusinessTypeChips({required this.ids});

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return Text('—', style: TextStyle(color: Colors.grey[400]));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: ids
          .take(2)
          .map(
            (id) => Chip(
              label: Text(
                id.length > 8 ? '${id.substring(0, 8)}…' : id,
                style: const TextStyle(fontSize: 10),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isVerified;

  const _VerifiedBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        isVerified ? 'Verificado' : 'Sin verificar',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: (isVerified ? Colors.green : Colors.grey)
          .withAlpha(26),
      side: BorderSide(
        color: (isVerified ? Colors.green : Colors.grey).withAlpha(77),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RowActions extends StatelessWidget {
  final GlobalProduct product;

  const _RowActions({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'Ver detalle',
          onPressed: () =>
              context.push('/pim/global-catalog/${product.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () =>
              context.push('/pim/global-catalog/${product.id}/edit'),
        ),
        IconButton(
          icon: Icon(
            product.isVerified
                ? Icons.remove_moderator_outlined
                : Icons.verified_user_outlined,
            size: 18,
            color: product.isVerified ? Colors.orange : Colors.green,
          ),
          tooltip: product.isVerified ? 'Desverificar' : 'Verificar',
          onPressed: () => _toggleVerification(context),
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.red[700],
          ),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _toggleVerification(BuildContext context) async {
    if (product.isVerified) {
      context
          .read<ProductFormBloc>()
          .add(UnverifyProductEvent(product.id));
    } else {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Verificar producto',
        message: '¿Verificar "${product.name}"?',
        confirmLabel: 'Verificar',
      );
      if (confirmed == true && context.mounted) {
        context
            .read<ProductFormBloc>()
            .add(VerifyProductEvent(product.id));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar producto',
      message:
          '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<ProductFormBloc>()
          .add(DeleteProductEvent(product.id));
    }
  }
}
