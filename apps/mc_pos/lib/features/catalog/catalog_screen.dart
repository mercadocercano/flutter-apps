import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import 'product_form_screen.dart';
import 'categories_screen.dart';
import 'brands_screen.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/product_card_pos.dart';

/// Pantalla de catálogo — grid de productos con buscador, filtro y paginado.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _categoryScrollCtrl = ScrollController();
  final _brandScrollCtrl = ScrollController();
  bool _canScrollCatsLeft = false;
  bool _canScrollCatsRight = true;
  bool _canScrollBrandsLeft = false;
  bool _canScrollBrandsRight = true;

  List<Product> _products = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _selectedCategory;
  String? _selectedBrand;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _categoryScrollCtrl.addListener(_onCategoryScroll);
    _brandScrollCtrl.addListener(_onBrandScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_categoryScrollCtrl.hasClients) _onCategoryScroll();
        if (_brandScrollCtrl.hasClients) _onBrandScroll();
      });
    });
    _loadPage(1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollCtrl.dispose();
    _categoryScrollCtrl.dispose();
    _brandScrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _query.isNotEmpty) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadPage(int page) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _products = [];
      });
    }
    try {
      final result = await context.read<CatalogPort>().listProducts(
            page: page,
            pageSize: _pageSize,
            search: _query.isEmpty ? null : _query,
          );
      if (mounted) {
        setState(() {
          if (page == 1) {
            _products = result.items;
          } else {
            _products = [..._products, ...result.items];
          }
          _currentPage = page;
          _totalCount = result.totalCount;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_currentPage + 1);
  }

  Future<void> _refresh() => _loadPage(1);

  bool get _hasMore => _currentPage * _pageSize < _totalCount;

  void _onCategoryScroll() {
    final pos = _categoryScrollCtrl.position;
    setState(() {
      _canScrollCatsLeft = pos.pixels > 4;
      _canScrollCatsRight = pos.pixels < pos.maxScrollExtent - 4;
    });
  }

  void _onBrandScroll() {
    final pos = _brandScrollCtrl.position;
    setState(() {
      _canScrollBrandsLeft = pos.pixels > 4;
      _canScrollBrandsRight = pos.pixels < pos.maxScrollExtent - 4;
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

  void _scrollBrands(double delta) {
    _brandScrollCtrl.animateTo(
      (_brandScrollCtrl.offset + delta).clamp(
        0,
        _brandScrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  List<String> get _categories {
    final cats = <String>{};
    for (final p in _products) {
      if (p.categoryName != null) cats.add(p.categoryName!);
    }
    return cats.toList()..sort();
  }

  List<String> get _brands {
    final brands = <String>{};
    for (final p in _products) {
      if (p.brandName != null) brands.add(p.brandName!);
    }
    return brands.toList()..sort();
  }

  List<Product> get _filtered {
    var list = _products;
    if (_selectedCategory != null) {
      list = list.where((p) => p.categoryName == _selectedCategory).toList();
    }
    if (_selectedBrand != null) {
      list = list.where((p) => p.brandName == _selectedBrand).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final totalLabel = _isLoading
        ? ''
        : _query.isNotEmpty || _selectedCategory != null || _selectedBrand != null
            ? '${_filtered.length} productos'
            : '$_totalCount productos';

    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (created == true) _refresh();
        },
        backgroundColor: McColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          PosTopBar(
            title: 'Mis productos',
            subtitle: totalLabel,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.label_outline),
                  color: McColors.textFg2,
                  tooltip: 'Categorías',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.storefront_outlined),
                  color: McColors.textFg2,
                  tooltip: 'Marcas',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BrandsScreen()),
                  ),
                ),
              ],
            ),
          ),

          // ─── Buscador ───
          Padding(
            padding: const EdgeInsets.all(McSpacing.md),
            child: McTextField(
              hint: 'Buscar por nombre, marca o código...',
              controller: _searchController,
              prefixIcon: Icons.search,
              onChanged: (v) {
                _query = v.toLowerCase();
                _loadPage(1);
              },
            ),
          ),

          // ─── Chips de categoría con flechas ───
          if (_categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: _canScrollCatsLeft ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _ArrowBtn(
                      icon: Icons.chevron_left,
                      onTap: _canScrollCatsLeft ? () => _scrollCats(-200) : null,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _categoryScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: McSpacing.sm, vertical: 4),
                      children: [
                        _CategoryChip(
                          label: 'Todas las categorías',
                          isSelected: _selectedCategory == null,
                          onTap: () =>
                              setState(() => _selectedCategory = null),
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
                  AnimatedOpacity(
                    opacity: _canScrollCatsRight ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _ArrowBtn(
                      icon: Icons.chevron_right,
                      onTap:
                          _canScrollCatsRight ? () => _scrollCats(200) : null,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Chips de marca con flechas ───
          if (_brands.isNotEmpty)
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: _canScrollBrandsLeft ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _ArrowBtn(
                      icon: Icons.chevron_left,
                      onTap: _canScrollBrandsLeft
                          ? () => _scrollBrands(-200)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _brandScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: McSpacing.sm, vertical: 4),
                      children: [
                        _CategoryChip(
                          label: 'Todas las marcas',
                          isSelected: _selectedBrand == null,
                          onTap: () => setState(() => _selectedBrand = null),
                        ),
                        ..._brands.map((brand) => _CategoryChip(
                              label: brand,
                              isSelected: _selectedBrand == brand,
                              onTap: () =>
                                  setState(() => _selectedBrand = brand),
                            )),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _canScrollBrandsRight ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _ArrowBtn(
                      icon: Icons.chevron_right,
                      onTap: _canScrollBrandsRight
                          ? () => _scrollBrands(200)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: McSpacing.sm),

          // ─── Grid ───
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: McSpacing.md),
                      sliver: _filtered.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  _query.isNotEmpty
                                      ? 'Sin resultados'
                                      : 'Sin productos',
                                  style: const TextStyle(
                                      color: McColors.textSecondaryLight),
                                ),
                              ),
                            )
                          : SliverLayoutBuilder(
                              builder: (_, constraints) {
                                final w = constraints.crossAxisExtent;
                                final cols = w < 400
                                    ? 2
                                    : w < 700
                                        ? 3
                                        : w < 1000
                                            ? 4
                                            : 5;
                                return SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => _ProductCard(
                                      product: _filtered[i],
                                      onEdited: _refresh,
                                    ),
                                    childCount: _filtered.length,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: McSpacing.sm,
                                    mainAxisSpacing: McSpacing.sm,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Paginado ───
          if (!_isLoading && _query.isEmpty && _selectedCategory == null && _selectedBrand == null)
            _PaginationBar(
              isLoadingMore: _isLoadingMore,
              hasMore: _hasMore,
              currentPage: _currentPage,
              totalCount: _totalCount,
              pageSize: _pageSize,
              onLoadMore: _loadMore,
            ),
        ],
      ),
    );
  }
}

// ─── Barra de paginado ───

class _PaginationBar extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final VoidCallback onLoadMore;

  const _PaginationBar({
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.totalCount,
    required this.pageSize,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore && totalCount <= pageSize) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: McSpacing.md,
        vertical: McSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página $currentPage · $totalCount total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: McColors.textSecondaryLight,
                ),
          ),
          if (isLoadingMore)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (hasMore)
            FilledButton.tonal(
              onPressed: onLoadMore,
              child: const Text('Cargar más'),
            )
          else
            Text(
              'Fin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: McColors.textSecondaryLight,
                  ),
            ),
        ],
      ),
    );
  }
}

// ─── Card de producto ───

/// Card de producto del catálogo — wrapper de [ProductCardPos] con botón editar.
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdited;

  const _ProductCard({required this.product, this.onEdited});

  @override
  Widget build(BuildContext context) {
    final activeVariants = product.variants.where((v) => v.isActive).toList();
    final defaultVariant =
        activeVariants.where((v) => v.isDefault).firstOrNull ??
            activeVariants.firstOrNull;

    return Stack(
      children: [
        ProductCardPos(
          productName: product.name,
          brandName: product.brandName,
          brandBg: product.brandBg,
          brandFg: product.brandFg,
          brandFont: product.brandFont,
          imageUrl: product.imageUrl,
          categoryName: product.categoryName,
          price: defaultVariant?.price.amount ?? 0,
          onTap: () async {
            final edited = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ProductFormScreen(editing: product),
              ),
            );
            if (edited == true) onEdited?.call();
          },
        ),
        // Botón editar superpuesto en la esquina inferior derecha
        Positioned(
          bottom: McSpacing.sm,
          right: McSpacing.sm,
          child: GestureDetector(
            onTap: () async {
              final edited = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProductFormScreen(editing: product),
                ),
              );
              if (edited == true) onEdited?.call();
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: McColors.cobaltTint,
                borderRadius: BorderRadius.circular(McSpacing.radiusSm),
                border: Border.all(color: McColors.primary),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 14,
                color: McColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Flecha de scroll ───

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
          constraints: const BoxConstraints(minHeight: 36),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? McColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(McSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? McColors.primary : McColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.white : McColors.textFg2,
            ),
          ),
        ),
      ),
    );
  }
}
