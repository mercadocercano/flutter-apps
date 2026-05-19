import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../../widgets/pos/product_card_pos.dart';
import '../../../widgets/pos/section_header.dart';
import '../../../widgets/pos/pos_modal.dart';

/// Búsqueda de productos para el POS — misma UI que CatalogScreen.
/// Grid con buscador y chips de categoría. Tap → agrega variante al carrito.
class ProductSearch extends StatefulWidget {
  final void Function(ProductVariant variant, String productName)
      onVariantSelected;

  /// Items actuales del carrito — para mostrar badge de cantidad en las cards.
  final List<PosSaleItem> cartItems;

  /// Controlador externo de búsqueda (viene de PosSearchBar en SaleScreen).
  /// Si se provee, el buscador interno queda oculto.
  final TextEditingController? externalSearchController;

  const ProductSearch({
    super.key,
    required this.onVariantSelected,
    this.cartItems = const [],
    this.externalSearchController,
  });

  @override
  State<ProductSearch> createState() => _ProductSearchState();
}

class _ProductSearchState extends State<ProductSearch> {
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _categoryScrollCtrl = ScrollController();
  Timer? _debounce;

  List<Product> _products = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _selectedCategory;
  String _query = '';

  bool get _hasExternalSearch => widget.externalSearchController != null;

  bool _canScrollCatsLeft = false;
  bool _canScrollCatsRight = true; // asume que hay overflow hasta verificar

  void _onCategoryScroll() {
    final pos = _categoryScrollCtrl.position;
    setState(() {
      _canScrollCatsLeft = pos.pixels > 4;
      _canScrollCatsRight = pos.pixels < pos.maxScrollExtent - 4;
    });
  }

  void _scrollCats(double delta) {
    _categoryScrollCtrl.animateTo(
      (_categoryScrollCtrl.offset + delta).clamp(
        0,
        _categoryScrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _categoryScrollCtrl.addListener(_onCategoryScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Segundo frame: layout ya completo, leer maxScrollExtent real
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_categoryScrollCtrl.hasClients) _onCategoryScroll();
      });
    });
    if (_hasExternalSearch) {
      widget.externalSearchController!.addListener(_onExternalSearchChanged);
    }
    _loadPage(1);
  }

  void _onExternalSearchChanged() {
    _onSearchChanged(widget.externalSearchController!.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollCtrl.dispose();
    _categoryScrollCtrl.dispose();
    if (_hasExternalSearch) {
      widget.externalSearchController!.removeListener(_onExternalSearchChanged);
    }
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
    showPosModal(
      context: context,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(McSpacing.md, McSpacing.sm, McSpacing.md, McSpacing.sm),
              child: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Divider(height: 1, color: McColors.borderLight),
            ...variants.map((v) => ListTile(
                  tileColor: Colors.transparent,
                  title: Text(v.name),
                  subtitle: v.sku != null ? Text(v.sku!.value) : null,
                  trailing: Text(v.price.formatted,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: McColors.primary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onVariantSelected(v, product.name);
                  },
                )),
            const SizedBox(height: McSpacing.md),
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
        // ─── Buscador interno (solo si no hay externo) ───
        if (!_hasExternalSearch)
          Padding(
            padding: const EdgeInsets.all(McSpacing.md),
            child: McTextField(
              hint: 'Buscar producto o escanear código...',
              controller: _searchController,
              prefixIcon: Icons.search,
              onChanged: _onSearchChanged,
              suffix: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {},
              ),
            ),
          ),

        // ─── Chips de categoría con flechas de navegación ───
        if (_categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: Row(
              children: [
                // Flecha izquierda
                AnimatedOpacity(
                  opacity: _canScrollCatsLeft ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: _ArrowBtn(
                    icon: Icons.chevron_left,
                    onTap: _canScrollCatsLeft ? () => _scrollCats(-200) : null,
                  ),
                ),
                // Lista de chips
                Expanded(
                  child: ListView(
                    controller: _categoryScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: McSpacing.sm,
                      vertical: 4,
                    ),
                    children: [
                      _CategoryChip(
                        label: 'Todos',
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      ..._categories.map((cat) => _CategoryChip(
                            label: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                          )),
                    ],
                  ),
                ),
                // Flecha derecha
                AnimatedOpacity(
                  opacity: _canScrollCatsRight ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: _ArrowBtn(
                    icon: Icons.chevron_right,
                    onTap: _canScrollCatsRight ? () => _scrollCats(200) : null,
                  ),
                ),
              ],
            ),
          ),

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
                // Encabezado de sección
                if (_query.isEmpty)
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      'Lo que más sale',
                      subtitle: 'Tus productos más vendidos',
                    ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
                  sliver: SliverLayoutBuilder(
                    builder: (_, constraints) {
                      final width = constraints.crossAxisExtent;
                      final cols = width < 400
                          ? 2
                          : width < 700
                              ? 3
                              : width < 1000
                                  ? 4
                                  : 5;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final product = filtered[i];
                            final cartQty = widget.cartItems
                                .where((item) =>
                                    item.productName.startsWith(product.name))
                                .fold(0, (sum, item) => sum + item.quantity);
                            final activeVariants = product.variants
                                .where((v) => v.isActive)
                                .toList();
                            final defaultVariant = activeVariants
                                    .where((v) => v.isDefault)
                                    .firstOrNull ??
                                activeVariants.firstOrNull;

                            return ProductCardPos(
                              productName: product.name,
                              brandName: product.brandName,
                              brandBg: product.brandBg,
                              brandFg: product.brandFg,
                              brandFont: product.brandFont,
                              imageUrl: product.imageUrl,
                              categoryName: product.categoryName,
                              price: defaultVariant?.price.amount ?? 0,
                              qtyInCart: cartQty,
                              onTap: () => _onProductTap(product),
                            );
                          },
                          childCount: filtered.length,
                        ),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          // imagen cuadrada 1:1 + ~85px info
                          childAspectRatio: 0.65,
                          crossAxisSpacing: McSpacing.sm,
                          mainAxisSpacing: McSpacing.sm,
                        ),
                      );
                    },
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
                  padding: EdgeInsets.only(bottom: 80),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Botón de flecha para scroll de categorías ───

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ArrowBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: McColors.borderLight),
          borderRadius: BorderRadius.circular(McSpacing.radiusFull),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14050C40),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: McColors.textFg2),
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
