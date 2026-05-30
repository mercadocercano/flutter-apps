import 'package:flutter/material.dart';

import 'admin_pagination.dart';
import 'admin_search_bar.dart';
import 'loading.dart';
import 'empty_state.dart';
import 'error.dart' as admin_error;

/// Definición de columna para AdminDataTable.
class AdminColumn<T> {
  final String label;
  final double? width;
  final bool sortable;
  final Widget Function(T item) builder;

  const AdminColumn({
    required this.label,
    required this.builder,
    this.width,
    this.sortable = false,
  });
}

/// Tabla de datos reutilizable con paginación, búsqueda, sort y selección múltiple.
class AdminDataTable<T> extends StatelessWidget {
  final List<T> items;
  final List<AdminColumn<T>> columns;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  // Paginación
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final void Function(int page) onPageChanged;
  final void Function(int size)? onPageSizeChanged;

  // Búsqueda
  final String? searchQuery;
  final String searchHint;
  final void Function(String query)? onSearch;

  // Selección múltiple
  final Set<T>? selectedItems;
  final void Function(T item, bool selected)? onItemSelected;
  final void Function(bool? selectAll)? onSelectAll;

  // Sort
  final void Function(int columnIndex, bool ascending)? onSort;
  final int? sortColumnIndex;
  final bool sortAscending;

  // Slot para acciones bulk (aparece cuando hay selección)
  final Widget? bulkActions;

  // Acción de creación
  final String? createLabel;
  final VoidCallback? onCreateTap;

  // Key para extraer fila (para selección)
  final Object Function(T item)? itemKey;

  const AdminDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onPageSizeChanged,
    this.searchQuery,
    this.searchHint = 'Buscar...',
    this.onSearch,
    this.selectedItems,
    this.onItemSelected,
    this.onSelectAll,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.bulkActions,
    this.createLabel,
    this.onCreateTap,
    this.itemKey,
  });

  bool get _hasSelection => selectedItems != null && selectedItems!.isNotEmpty;
  bool get _multiSelect => selectedItems != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar: búsqueda + acciones
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (onSearch != null)
                Expanded(
                  child: AdminSearchBar(
                    hint: searchHint,
                    initialValue: searchQuery ?? '',
                    onSearch: onSearch!,
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              if (_hasSelection && bulkActions != null) ...[
                bulkActions!,
                const SizedBox(width: 8),
              ],
              if (createLabel != null && onCreateTap != null)
                FilledButton.icon(
                  onPressed: onCreateTap,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(createLabel!),
                ),
            ],
          ),
        ),
        // Estado de selección
        if (_hasSelection)
          Container(
            color: c.primaryContainer.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${selectedItems!.length} elemento(s) seleccionado(s)',
              style: theme.textTheme.bodySmall?.copyWith(color: c.primary),
            ),
          ),
        // Tabla
        Expanded(
          child: _buildBody(context),
        ),
        // Paginación
        if (!isLoading && error == null && items.isNotEmpty)
          AdminPagination(
            currentPage: currentPage,
            pageSize: pageSize,
            totalItems: totalItems,
            onPageChanged: onPageChanged,
            onPageSizeChanged: onPageSizeChanged,
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) return const LoadingWidget();
    if (error != null) {
      return admin_error.ErrorWidget(message: error!, onRetry: onRetry);
    }
    if (items.isEmpty) {
      return const EmptyStateWidget(message: 'No hay resultados');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 256,
        ),
        child: DataTable(
          showCheckboxColumn: _multiSelect,
          onSelectAll: _multiSelect ? onSelectAll : null,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: columns
              .asMap()
              .entries
              .map(
                (entry) => DataColumn(
                  label: Text(
                    entry.value.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  numeric: false,
                  onSort: entry.value.sortable && onSort != null
                      ? (_, ascending) => onSort!(entry.key, ascending)
                      : null,
                ),
              )
              .toList(),
          rows: items.map((item) {
            final isSelected = selectedItems?.contains(item) ?? false;
            return DataRow(
              selected: isSelected,
              onSelectChanged: _multiSelect
                  ? (selected) => onItemSelected?.call(item, selected ?? false)
                  : null,
              cells: columns
                  .map((col) => DataCell(col.builder(item)))
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
