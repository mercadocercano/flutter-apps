import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import 'product_form_screen.dart';
import 'categories_screen.dart';
import 'brands_screen.dart';
import '../quickstart/brand_badge.dart';

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

  List<Product> _products = [];
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Categorías',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Marcas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BrandsScreen()),
            ),
          ),
        ],
      ),
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

          const SizedBox(height: McSpacing.sm),

          // ─── Contador ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
            child: Row(
              children: [
                Text(
                  _isLoading
                      ? ''
                      : _query.isNotEmpty || _selectedCategory != null
                          ? '${_filtered.length} producto${_filtered.length == 1 ? '' : 's'}'
                          : '${_products.length} de $_totalCount producto${_totalCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: McColors.textSecondaryLight,
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
                      padding: const EdgeInsets.symmetric(horizontal: McSpacing.md),
                      sliver: _filtered.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  _query.isNotEmpty ? 'Sin resultados' : 'Sin productos',
                                  style: const TextStyle(color: McColors.textSecondaryLight),
                                ),
                              ),
                            )
                          : SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ProductCard(
                                  product: _filtered[i],
                                  onEdited: _refresh,
                                ),
                                childCount: _filtered.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisExtent: 180,
                                crossAxisSpacing: McSpacing.sm,
                                mainAxisSpacing: McSpacing.sm,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Paginado siempre visible ───
          if (!_isLoading && _query.isEmpty && _selectedCategory == null)
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                      child: const Icon(Icons.inventory_2_outlined, size: 16, color: McColors.textSecondaryLight),
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

          // ─── Precio + editar ───
          Padding(
            padding: const EdgeInsets.fromLTRB(McSpacing.sm, 0, McSpacing.xs, McSpacing.xs),
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final edited = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ProductFormScreen(editing: product),
                      ),
                    );
                    if (edited == true) onEdited?.call();
                  },
                ),
              ],
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
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: McColors.primary.withValues(alpha: 0.15),
        checkmarkColor: McColors.primary,
      ),
    );
  }
}
