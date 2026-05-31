import 'marketplace_category.dart';

/// Value object que representa el árbol completo de categorías.
/// Permite navegar la jerarquía, encontrar nodos y construir breadcrumbs.
class CategoryTree {
  final List<MarketplaceCategory> roots;

  const CategoryTree({required this.roots});

  /// Construye el árbol desde una lista plana de categorías.
  /// Los nodos raíz (parentId == null) se colocan en [roots].
  factory CategoryTree.fromFlat(List<MarketplaceCategory> flat) {
    if (flat.isEmpty) return const CategoryTree(roots: []);

    final childrenMap = <String, List<MarketplaceCategory>>{};

    for (final cat in flat) {
      if (cat.parentId != null) {
        childrenMap.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    MarketplaceCategory attachChildren(
      MarketplaceCategory node,
      List<String> parentPath,
    ) {
      final nodePath = [...parentPath, node.name];
      final kids = (childrenMap[node.id] ?? [])
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final attachedKids = kids
          .map((k) => attachChildren(k, nodePath))
          .toList();
      return node.copyWith(children: attachedKids, path: nodePath);
    }

    final roots = flat
        .where((c) => c.parentId == null)
        .map((r) => attachChildren(r, []))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return CategoryTree(roots: roots);
  }

  /// Busca una categoría por id en toda la jerarquía.
  MarketplaceCategory? findById(String id) => _findInList(roots, id);

  /// Retorna la lista de categorías desde la raíz hasta el nodo con [id].
  /// Retorna lista vacía si el id no existe.
  List<MarketplaceCategory> getPath(String id) {
    final result = <MarketplaceCategory>[];
    if (_collectPath(roots, id, result)) return result;
    return const [];
  }

  bool get isEmpty => roots.isEmpty;

  // --- private helpers ---

  MarketplaceCategory? _findInList(
    List<MarketplaceCategory> list,
    String id,
  ) {
    for (final cat in list) {
      if (cat.id == id) return cat;
      final found = _findInList(cat.children, id);
      if (found != null) return found;
    }
    return null;
  }

  bool _collectPath(
    List<MarketplaceCategory> list,
    String id,
    List<MarketplaceCategory> acc,
  ) {
    for (final cat in list) {
      acc.add(cat);
      if (cat.id == id) return true;
      if (_collectPath(cat.children, id, acc)) return true;
      acc.removeLast();
    }
    return false;
  }
}
