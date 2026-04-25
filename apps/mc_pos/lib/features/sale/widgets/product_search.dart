import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../quickstart/brand_badge.dart';

/// Búsqueda de productos para el POS — misma UI que CatalogScreen.
/// Grid con buscador y chips de categoría. Tap → agrega variante al carrito.
class ProductSearch extends StatefulWidget {
  final void Function(ProductVariant variant, String productName)
      onVariantSelected;

  /// Items actuales del carrito — para mostrar badge de cantidad en las cards.
  final List<PosSaleItem> cartItems;

  const ProductSearch({
    super.key,
    required this.onVariantSelected,
    this.cartItems = const [],
  });

  @override
  State<ProductSearch> createState() => _ProductSearchState();
}

class _ProductSearchState extends State<ProductSearch> {
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<Product> _products = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _selectedCategory;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadPage(1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _query.isNotEmpty) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadPage(int page) async {
    if (page == 1) setState(() { _isLoading = true; _error = null; _products = []; });
    try {
      final result = await context.read<CatalogPort>().listProducts(
            page: page,
            pageSize: _pageSize,
            search: _query.isEmpty ? null : _query,
          );
      if (!mounted) return;
      setState(() {
        _products = page == 1 ? result.items : [..._products, ...result.items];
        _currentPage = page;
        _totalCount = result.totalCount;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el catálogo';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_currentPage + 1);
  }

  bool get _hasMore => _currentPage * _pageSize < _totalCount;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _query = value;
    _debounce = Timer(const Duration(milliseconds: 300), () => _loadPage(1));
  }

  List<String> get _categories {
    final cats = <String>{};
    for (final p in _products) {
      if (p.categoryName != null) cats.add(p.categoryName!);
    }
    return cats.toList()..sort();
  }

  List<Product> get _filtered {
    if (_selectedCategory == null) return _products;
    return _products.where((p) => p.categoryName == _selectedCategory).toList();
  }

  void _onProductTap(Product product) {
    final actives = product.variants.where((v) => v.isActive).toList();
    if (actives.isEmpty) return;
    if (actives.length == 1) {
      widget.onVariantSelected(actives.first, product.name);
      return;
    }
    _showVariantPicker(product, actives);
  }

  void _showVariantPicker(Product product, List<ProductVariant> variants) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(McSpacing.md),
              child: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ...variants.map((v) => ListTile(
                  title: Text(v.name),
                  subtitle: v.sku != null ? Text(v.sku!.value) : null,
                  trailing: Text(v.price.formatted,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: McColors.primary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onVariantSelected(v, product.name);
                  },
                )),
            const SizedBox(height: McSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // ─── Buscador ───
        Padding(
          padding: const EdgeInsets.all(McSpacing.md),
          child: McTextField(
            hint: 'Buscar producto o escanear código...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: _onSearchChanged,
            suffix: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                // TODO: abrir scanner de cámara
              },
            ),
          ),
        ),

        // ─── Chips de categoría ───
        if (_categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
              children: [
                _CategoryChip(
                  label: 'Todos',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ..._categories.map((cat) => _CategoryChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    )),
              ],
            ),
          ),

        if (!_isLoading) ...[
          const SizedBox(height: McSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} producto${filtered.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: McColors.textSecondaryLight,
                    ),
              ),
            ),
          ),
          const SizedBox(height: McSpacing.xs),
        ],

        // ─── Contenido ───
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: McColors.error)),
                  const SizedBox(height: McSpacing.md),
                  McButton(label: 'Reintentar', onPressed: () => _loadPage(1)),
                ],
              ),
            ),
          )
        else if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _query.isNotEmpty ? 'Sin resultados' : 'Sin productos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: McColors.textSecondaryLight,
                    ),
              ),
            ),
          )
        else
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final product = filtered[i];
                        final cartQty = widget.cartItems
                            .where((item) => item.productName.startsWith(product.name))
                            .fold(0, (sum, item) => sum + item.quantity);
                        return _ProductCard(
                          product: product,
                          cartQty: cartQty,
                          onTap: () => _onProductTap(product),
                        );
                      },
                      childCount: filtered.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 180,
                      crossAxisSpacing: McSpacing.sm,
                      mainAxisSpacing: McSpacing.sm,
                    ),
                  ),
                ),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(McSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (_hasMore && !_isLoadingMore && _query.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(McSpacing.md),
                      child: FilledButton.tonal(
                        onPressed: _loadMore,
                        child: const Text('Cargar más'),
                      ),
                    ),
                  ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 80), // espacio para MobileCartBar
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Card de producto (igual a CatalogScreen pero con onTap) ───

class _ProductCard extends StatelessWidget {
  final Product product;
  final int cartQty;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.cartQty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeVariants = product.variants.where((v) => v.isActive).toList();
    final defaultVariant =
        activeVariants.where((v) => v.isDefault).firstOrNull ??
            activeVariants.firstOrNull;
    final inCart = cartQty > 0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(McSpacing.radiusMd),
              border: Border.all(
                color: inCart ? McColors.primary : const Color(0xFFE2E8F0),
                width: inCart ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Imagen o badge de marca ───
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(McSpacing.radiusMd)),
                    child: SizedBox(
                      height: 72,
                      width: double.infinity,
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: McColors.mutedLight,
                          child: const Icon(Icons.inventory_2_outlined, size: 24, color: McColors.textSecondaryLight),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: McColors.mutedLight,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(McSpacing.sm, McSpacing.sm, McSpacing.sm, 0),
                    child: product.brandName != null
                        ? BrandBadge(
                            brandName: product.brandName!,
                            size: BrandBadgeSize.sm,
                            width: double.infinity,
                          )
                        : Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: McColors.mutedLight,
                              borderRadius: BorderRadius.circular(McSpacing.radiusSm),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                size: 16, color: McColors.textSecondaryLight),
                          ),
                  ),

                // ─── Nombre ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(McSpacing.sm, McSpacing.xs, McSpacing.sm, 0),
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ─── Categoría ───
                if (product.categoryName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: McSpacing.sm),
                    child: Text(
                      product.categoryName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: McColors.textSecondaryLight,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const Spacer(),

                // ─── Precio + indicador de múltiples variantes ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(McSpacing.sm, 0, McSpacing.sm, McSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          defaultVariant?.price.formatted ?? '—',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: McColors.primary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeVariants.length > 1)
                        Tooltip(
                          message: '${activeVariants.length} variantes',
                          child: const Icon(Icons.expand_more,
                              size: 16, color: McColors.textSecondaryLight),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Badge de cantidad en carrito ───
          if (inCart)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24),
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: McColors.primary,
                  borderRadius: BorderRadius.circular(McSpacing.radiusFull),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$cartQty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chip de categoría ───

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: McSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? McColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(McSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? McColors.primary : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? Colors.white : McColors.textFg2,
            ),
          ),
        ),
      ),
    );
  }
}
