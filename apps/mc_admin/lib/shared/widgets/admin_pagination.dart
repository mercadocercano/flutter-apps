import 'package:flutter/material.dart';

/// Controles de paginación: anterior/siguiente + selector de page_size.
class AdminPagination extends StatelessWidget {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final void Function(int page) onPageChanged;
  final void Function(int size)? onPageSizeChanged;

  static const _pageSizes = [10, 20, 50, 100];

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    this.onPageSizeChanged,
  });

  int get _totalPages => (totalItems / pageSize).ceil().clamp(1, 99999);
  int get _startItem => ((currentPage - 1) * pageSize) + 1;
  int get _endItem => (currentPage * pageSize).clamp(1, totalItems);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$_startItem–$_endItem de $totalItems',
            style: theme.textTheme.bodySmall,
          ),
          if (onPageSizeChanged != null) ...[
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: _pageSizes.contains(pageSize) ? pageSize : _pageSizes.first,
              isDense: true,
              underline: const SizedBox(),
              items: _pageSizes
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('$s / página',
                            style: theme.textTheme.bodySmall),
                      ))
                  .toList(),
              onChanged: (s) => s != null ? onPageSizeChanged!(s) : null,
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            tooltip: 'Página anterior',
          ),
          Text(
            '$currentPage / $_totalPages',
            style: theme.textTheme.bodySmall,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            onPressed: currentPage < _totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
            tooltip: 'Página siguiente',
          ),
        ],
      ),
    );
  }
}
