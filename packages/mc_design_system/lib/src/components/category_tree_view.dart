import 'package:flutter/material.dart';
import 'package:mc_domain/mc_domain.dart';

/// Widget reutilizable para visualizar el árbol de categorías del marketplace.
///
/// Soporta n niveles, expand/collapse, selección, highlight de búsqueda
/// y un slot de acciones contextuales por nodo.
class CategoryTreeView extends StatelessWidget {
  /// Nodos raíz del árbol. Cada uno puede tener [children] anidados.
  final List<MarketplaceCategory> categories;

  /// Ids de nodos actualmente expandidos.
  final Set<String> expandedIds;

  /// Id del nodo seleccionado (se resalta visualmente).
  final String? selectedId;

  /// Texto de búsqueda actual — los nodos coincidentes se resaltan.
  final String? searchQuery;

  /// Callback al hacer tap en el chevron de expand/collapse.
  final void Function(String id)? onToggleExpand;

  /// Callback al seleccionar un nodo (tap en el título).
  final void Function(String id)? onSelect;

  /// Slot para renderizar acciones contextuales a la derecha del nodo.
  final Widget Function(MarketplaceCategory category)? actionsBuilder;

  const CategoryTreeView({
    super.key,
    required this.categories,
    this.expandedIds = const {},
    this.selectedId,
    this.searchQuery,
    this.onToggleExpand,
    this.onSelect,
    this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No hay categorías',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) => _CategoryNodeTile(
        category: categories[index],
        expandedIds: expandedIds,
        selectedId: selectedId,
        searchQuery: searchQuery,
        onToggleExpand: onToggleExpand,
        onSelect: onSelect,
        actionsBuilder: actionsBuilder,
      ),
    );
  }
}

class _CategoryNodeTile extends StatelessWidget {
  final MarketplaceCategory category;
  final Set<String> expandedIds;
  final String? selectedId;
  final String? searchQuery;
  final void Function(String id)? onToggleExpand;
  final void Function(String id)? onSelect;
  final Widget Function(MarketplaceCategory)? actionsBuilder;

  const _CategoryNodeTile({
    required this.category,
    required this.expandedIds,
    this.selectedId,
    this.searchQuery,
    this.onToggleExpand,
    this.onSelect,
    this.actionsBuilder,
  });

  bool get _isExpanded => expandedIds.contains(category.id);
  bool get _isSelected => selectedId == category.id;
  bool get _hasChildren => category.hasChildren;

  bool get _matchesSearch {
    final q = searchQuery;
    if (q == null || q.isEmpty) return false;
    return category.name.toLowerCase().contains(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final indent = _levelIndent(category.level);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTile(context, theme, indent),
        if (_isExpanded && _hasChildren) _buildChildren(),
      ],
    );
  }

  Widget _buildTile(BuildContext context, ThemeData theme, double indent) {
    return Material(
      color: _isSelected
          ? theme.colorScheme.primaryContainer.withAlpha(77)
          : Colors.transparent,
      child: InkWell(
        onTap: onSelect != null ? () => onSelect!(category.id) : null,
        child: Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            children: [
              _buildExpandIcon(),
              _buildLeadingIcon(),
              const SizedBox(width: 4),
              Expanded(child: _buildTitle(theme)),
              if (_hasChildren && !_isExpanded) _buildChildrenBadge(theme),
              if (actionsBuilder != null) actionsBuilder!(category),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandIcon() {
    if (!_hasChildren) return const SizedBox(width: 32);

    return IconButton(
      key: Key('expand_${category.id}'),
      icon: AnimatedRotation(
        turns: _isExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.chevron_right, size: 20),
      ),
      onPressed: onToggleExpand != null
          ? () => onToggleExpand!(category.id)
          : null,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildLeadingIcon() {
    return Icon(
      _hasChildren ? Icons.folder_outlined : Icons.label_outline,
      size: 18,
      color: category.isActive ? null : Colors.grey,
    );
  }

  Widget _buildTitle(ThemeData theme) {
    final q = searchQuery;
    final isMatch = _matchesSearch;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: isMatch && q != null
          ? _HighlightedText(text: category.name, query: q)
          : Text(
              category.name,
              style: TextStyle(
                fontWeight: _isSelected ? FontWeight.w600 : FontWeight.normal,
                color: category.isActive ? null : Colors.grey,
              ),
            ),
    );
  }

  Widget _buildChildrenBadge(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        key: Key('badge_${category.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${category.children.length}',
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }

  Widget _buildChildren() {
    return Column(
      children: category.children
          .map(
            (child) => _CategoryNodeTile(
              category: child,
              expandedIds: expandedIds,
              selectedId: selectedId,
              searchQuery: searchQuery,
              onToggleExpand: onToggleExpand,
              onSelect: onSelect,
              actionsBuilder: actionsBuilder,
            ),
          )
          .toList(),
    );
  }

  double _levelIndent(int level) => (level * 20.0).clamp(0.0, 120.0);
}

/// Texto con highlight de la coincidencia de búsqueda.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) return Text(text);

    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
