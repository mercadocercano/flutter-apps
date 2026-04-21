import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

/// Búsqueda de productos — por nombre, código o scanner.
/// Muestra variantes como items vendibles (Coca-Cola — 500ml — $2.000).
class ProductSearch extends StatefulWidget {
  final void Function(ProductVariant variant, String productName)
      onVariantSelected;

  const ProductSearch({super.key, required this.onVariantSelected});

  @override
  State<ProductSearch> createState() => _ProductSearchState();
}

class _ProductSearchState extends State<ProductSearch> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      final catalog = context.read<CatalogPort>();
      final products =
          await catalog.listProducts(status: ProductStatus.active);
      if (mounted) setState(() => _products = products);
    } catch (_) {
      // Silencioso en carga inicial
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = query.isNotEmpty;
    });
    try {
      final catalog = context.read<CatalogPort>();
      final products = await catalog.listProducts(
        search: query.isEmpty ? null : query,
        status: ProductStatus.active,
      );
      if (mounted) setState(() => _products = products);
    } catch (_) {
      // Mantener resultados anteriores
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Expande los productos a una lista plana de variantes vendibles.
  List<_SellableItem> get _sellableItems {
    final items = <_SellableItem>[];
    for (final product in _products) {
      final activeVariants =
          product.variants.where((v) => v.isActive).toList();
      if (activeVariants.isEmpty) continue;

      for (final variant in activeVariants) {
        items.add(_SellableItem(product: product, variant: variant));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _sellableItems;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(McSpacing.md),
          child: McTextField(
            hint: 'Buscar producto o escanear código...',
            controller: _searchController,
            onChanged: _onSearchChanged,
            prefixIcon: Icons.search,
            suffix: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                // TODO: abrir scanner de cámara
              },
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(McSpacing.lg),
            child: CircularProgressIndicator(),
          )
        else if (items.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _hasSearched
                    ? 'No se encontraron productos'
                    : 'Cargando catálogo...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: McColors.textSecondaryLight,
                    ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return McCard(
                  onTap: () => widget.onVariantSelected(
                    item.variant,
                    item.product.name,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: McSpacing.base,
                    vertical: McSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              item.variant.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: McColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.variant.price.formatted,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : McColors.primary,
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SellableItem {
  final Product product;
  final ProductVariant variant;
  const _SellableItem({required this.product, required this.variant});
}
