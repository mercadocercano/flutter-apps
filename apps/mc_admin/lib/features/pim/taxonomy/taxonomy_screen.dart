import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/category_form_bloc.dart';
import 'blocs/taxonomy_bloc.dart';

class TaxonomyScreen extends StatefulWidget {
  const TaxonomyScreen({super.key});

  @override
  State<TaxonomyScreen> createState() => _TaxonomyScreenState();
}

class _TaxonomyScreenState extends State<TaxonomyScreen> {
  final _searchController = TextEditingController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    context.read<TaxonomyBloc>().add(LoadTaxonomyEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryFormBloc, CategoryFormState>(
      listener: _onFormStateChange,
      child: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (q) => context
                .read<TaxonomyBloc>()
                .add(SearchCategoriesEvent(q)),
          ),
          _BreadcrumbRow(
            selectedId: _selectedId,
            state: context.watch<TaxonomyBloc>().state,
          ),
          Expanded(child: _TreeBody(
            selectedId: _selectedId,
            onSelectId: (id) => setState(() => _selectedId = id),
            onDelete: _confirmDelete,
          )),
        ],
      ),
    );
  }

  void _onFormStateChange(BuildContext context, CategoryFormState state) {
    if (state is CategoryFormSuccess) {
      AdminSnackbars.showSuccess(context, 'Operación realizada correctamente');
      context.read<TaxonomyBloc>().add(RefreshTaxonomyEvent());
    } else if (state is CategoryFormDeleted) {
      AdminSnackbars.showSuccess(context, 'Categoría eliminada');
      setState(() => _selectedId = null);
      context.read<TaxonomyBloc>().add(RefreshTaxonomyEvent());
    } else if (state is CategoryFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }

  Future<void> _confirmDelete(
    BuildContext ctx,
    MarketplaceCategory cat,
  ) async {
    final confirmed = await ConfirmDialog.show(
      ctx,
      title: 'Eliminar categoría',
      message:
          '¿Eliminar "${cat.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<CategoryFormBloc>().add(DeleteCategoryEvent(cat.id));
    }
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Buscar categoría...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => context.push('/pim/taxonomy/new'),
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbRow extends StatelessWidget {
  final String? selectedId;
  final TaxonomyState state;

  const _BreadcrumbRow({required this.selectedId, required this.state});

  @override
  Widget build(BuildContext context) {
    if (selectedId == null || state is! TaxonomyLoaded) {
      return const SizedBox.shrink();
    }

    final loaded = state as TaxonomyLoaded;
    final path = loaded.tree.getPath(selectedId!);
    if (path.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          ...path.asMap().entries.map((e) {
            final isLast = e.key == path.length - 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.value.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isLast ? FontWeight.w600 : FontWeight.normal,
                    color: isLast ? null : Colors.grey,
                  ),
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('>', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TreeBody extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelectId;
  final Future<void> Function(BuildContext, MarketplaceCategory) onDelete;

  const _TreeBody({
    required this.selectedId,
    required this.onSelectId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaxonomyBloc, TaxonomyState>(
      builder: (context, state) {
        if (state is TaxonomyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TaxonomyError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<TaxonomyBloc>().add(LoadTaxonomyEvent()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is TaxonomyLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
            child: CategoryTreeView(
              categories: state.tree.roots,
              expandedIds: state.expandedIds,
              selectedId: selectedId,
              searchQuery: state.searchQuery,
              onToggleExpand: (id) => context
                  .read<TaxonomyBloc>()
                  .add(ToggleCategoryExpansionEvent(id)),
              onSelect: onSelectId,
              actionsBuilder: (cat) => _NodeActions(
                category: cat,
                onDelete: onDelete,
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _NodeActions extends StatelessWidget {
  final MarketplaceCategory category;
  final Future<void> Function(BuildContext, MarketplaceCategory) onDelete;

  const _NodeActions({required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 18),
          tooltip: 'Agregar subcategoría',
          onPressed: () =>
              context.push('/pim/taxonomy/new?parentId=${category.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () =>
              context.push('/pim/taxonomy/${category.id}/edit'),
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.red[700],
          ),
          tooltip: 'Eliminar',
          onPressed: () => onDelete(context, category),
        ),
      ],
    );
  }
}
