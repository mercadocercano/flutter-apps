import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/kpi_card.dart';
import '../../widgets/pos/pos_modal.dart';
import '../quickstart/brand_badge.dart';

/// Pantalla de stock — grid de variantes con KPIs, filtros y ajuste rápido.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'todos'; // todos, bajo, sin
  String? _selectedCategory;
  String? _selectedBrand;
  List<_StockItem> _stockItems = [];
  bool _isLoading = true;
  static const _minStock = 5;

  final _categoryScrollCtrl = ScrollController();
  final _brandScrollCtrl = ScrollController();
  bool _canScrollCatsLeft = false;
  bool _canScrollCatsRight = true;
  bool _canScrollBrandsLeft = false;
  bool _canScrollBrandsRight = true;

  @override
  void initState() {
    super.initState();
    _categoryScrollCtrl.addListener(_onCategoryScroll);
    _brandScrollCtrl.addListener(_onBrandScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_categoryScrollCtrl.hasClients) _onCategoryScroll();
        if (_brandScrollCtrl.hasClients) _onBrandScroll();
      });
    });
    _loadStock();
  }

  @override
  void dispose() {
    _categoryScrollCtrl.dispose();
    _brandScrollCtrl.dispose();
    super.dispose();
  }

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
      (_categoryScrollCtrl.offset + delta)
          .clamp(0, _categoryScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _scrollBrands(double delta) {
    _brandScrollCtrl.animateTo(
      (_brandScrollCtrl.offset + delta)
          .clamp(0, _brandScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadStock() async {
    setState(() => _isLoading = true);
    try {
      final catalog = context.read<CatalogPort>();
      final stockPort = context.read<StockPort>();

      final page =
          await catalog.listProducts(status: ProductStatus.active, pageSize: 200);
      final products = page.items;

      final variants = <_StockItem>[];
      for (final product in products) {
        for (final variant in product.variants.where((v) => v.isActive)) {
          if (variant.sku != null) {
            variants.add(_StockItem(
              productName: product.name,
              variantName: variant.name,
              sku: variant.sku!.value,
              price: variant.price.amount,
              brandName: product.brandName,
              brandBg: product.brandBg,
              brandFg: product.brandFg,
              brandFont: product.brandFont,
              categoryName: product.categoryName,
              imageUrl: product.imageUrl,
              stock: 0,
              minStock: _minStock,
            ));
          }
        }
      }

      final skus = variants.map((v) => v.sku).toList();
      final stockMap = skus.isNotEmpty
          ? await stockPort.getStockForSkus(skus)
          : <String, int>{};

      final items = variants
          .map((v) => v.copyWith(stock: stockMap[v.sku] ?? 0))
          .toList();

      if (mounted) {
        setState(() {
          _stockItems = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final cats = <String>{};
    for (final s in _stockItems) {
      if (s.categoryName != null) cats.add(s.categoryName!);
    }
    return cats.toList()..sort();
  }

  List<String> get _brands {
    final brands = <String>{};
    for (final s in _stockItems) {
      if (s.brandName != null) brands.add(s.brandName!);
    }
    return brands.toList()..sort();
  }

  List<_StockItem> get _filtered {
    var list = switch (_filter) {
      'bajo' =>
        _stockItems.where((s) => s.stock > 0 && s.stock <= s.minStock).toList(),
      'sin' => _stockItems.where((s) => s.stock == 0).toList(),
      _ => _stockItems,
    };
    if (_selectedCategory != null) {
      list = list.where((s) => s.categoryName == _selectedCategory).toList();
    }
    if (_selectedBrand != null) {
      list = list.where((s) => s.brandName == _selectedBrand).toList();
    }
    return list;
  }

  int get _lowStockCount =>
      _stockItems.where((s) => s.stock > 0 && s.stock <= s.minStock).length;
  int get _outOfStockCount =>
      _stockItems.where((s) => s.stock == 0).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          PosTopBar(
            title: 'Stock',
            subtitle: '${_stockItems.length} variantes',
          ),
          // ─── KPI cards ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
                McSpacing.md, McSpacing.md, McSpacing.md, 0),
            child: Row(
              children: [
                KpiCard(
                  value: '${_stockItems.length}',
                  label: 'Total',
                  toneColor: McColors.primary,
                ),
                const SizedBox(width: McSpacing.sm),
                KpiCard(
                  value: '$_lowStockCount',
                  label: 'Bajo stock',
                  toneColor: McColors.warning,
                ),
                const SizedBox(width: McSpacing.sm),
                KpiCard(
                  value: '$_outOfStockCount',
                  label: 'Agotados',
                  toneColor: McColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: McSpacing.sm),
          // ─── Tabs filtro ───
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _FilterTab(
                  label: 'Todos',
                  isSelected: _filter == 'todos',
                  onTap: () => setState(() => _filter = 'todos'),
                ),
                _FilterTab(
                  label: 'Bajo stock',
                  isSelected: _filter == 'bajo',
                  onTap: () => setState(() => _filter = 'bajo'),
                ),
                _FilterTab(
                  label: 'Agotados',
                  isSelected: _filter == 'sin',
                  onTap: () => setState(() => _filter = 'sin'),
                ),
              ],
            ),
          ),
          // ─── Chips de categoría ───
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
                        _ChipFilter(
                          label: 'Todas las categorías',
                          isSelected: _selectedCategory == null,
                          onTap: () =>
                              setState(() => _selectedCategory = null),
                        ),
                        ..._categories.map((cat) => _ChipFilter(
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
                      onTap: _canScrollCatsRight ? () => _scrollCats(200) : null,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Chips de marca ───
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
                        _ChipFilter(
                          label: 'Todas las marcas',
                          isSelected: _selectedBrand == null,
                          onTap: () => setState(() => _selectedBrand = null),
                        ),
                        ..._brands.map((brand) => _ChipFilter(
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
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _filter == 'bajo'
                      ? 'No hay productos con bajo stock'
                      : _filter == 'sin'
                          ? 'Todos los productos tienen stock'
                          : 'No hay productos',
                  style: const TextStyle(color: McColors.textSecondaryLight),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStock,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: McSpacing.md),
                      sliver: SliverLayoutBuilder(
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
                              (_, i) => _StockCard(
                                item: filtered[i],
                                onAdjust: () =>
                                    _showAdjustStock(context, filtered[i]),
                              ),
                              childCount: filtered.length,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: McSpacing.sm,
                              mainAxisSpacing: McSpacing.sm,
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 24),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAdjustStock(BuildContext context, _StockItem item) {
    final controller = TextEditingController();
    String type = 'RECEIPT';

    showPosModal(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(McSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.productName} — ${item.variantName}',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: McSpacing.xs),
                  Text('Stock actual: ${item.stock}'),
                  const SizedBox(height: McSpacing.lg),
                  Text('Tipo de movimiento',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: McSpacing.sm),
                  Wrap(
                    spacing: McSpacing.sm,
                    children: [
                      _MovementChip(
                        label: 'Compra',
                        icon: Icons.add_shopping_cart,
                        isSelected: type == 'RECEIPT',
                        onTap: () => setSheetState(() => type = 'RECEIPT'),
                      ),
                      _MovementChip(
                        label: 'Ajuste',
                        icon: Icons.tune,
                        isSelected: type == 'ADJUSTMENT',
                        onTap: () =>
                            setSheetState(() => type = 'ADJUSTMENT'),
                      ),
                      _MovementChip(
                        label: 'Devolución',
                        icon: Icons.undo,
                        isSelected: type == 'RETURN',
                        onTap: () => setSheetState(() => type = 'RETURN'),
                      ),
                    ],
                  ),
                  const SizedBox(height: McSpacing.base),
                  McTextField(
                    label: 'Cantidad',
                    controller: controller,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.numbers,
                    autofocus: true,
                  ),
                  const SizedBox(height: McSpacing.lg),
                  McButton(
                    label: 'Registrar movimiento',
                    icon: Icons.check,
                    size: McButtonSize.lg,
                    expand: true,
                    onPressed: () async {
                      final qty = double.tryParse(controller.text) ?? 0;
                      if (qty <= 0) return;

                      Navigator.of(ctx).pop();
                      final stockPort = context.read<StockPort>();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await stockPort.adjustStock(
                          sku: item.sku,
                          quantity: qty,
                          entryType: type,
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Stock de ${item.productName} actualizado'),
                              backgroundColor: McColors.success,
                            ),
                          );
                          _loadStock();
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('No pudimos actualizar el stock. Intentá de nuevo.'),
                              backgroundColor: McColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stock Card — grid card con stock destacado ───

class _StockCard extends StatelessWidget {
  final _StockItem item;
  final VoidCallback onAdjust;

  const _StockCard({required this.item, required this.onAdjust});

  bool get _isOut => item.stock <= 0;
  bool get _isLow =>
      !_isOut && item.stock <= item.minStock;

  Color get _stockColor {
    if (_isOut) return McColors.error;
    if (_isLow) return McColors.warning;
    return McColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdjust,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _isOut
                ? McColors.error
                : _isLow
                    ? McColors.warning
                    : McColors.borderLight,
            width: (_isOut || _isLow) ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. IMAGEN / ICONO
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: McColors.mutedLight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(McSpacing.radiusLg - 1),
                  ),
                ),
                child: Stack(
                  children: [
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Opacity(
                          opacity: _isOut ? 0.4 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  '📦',
                                  style: TextStyle(
                                    fontSize: 42,
                                    color: Colors.black.withValues(
                                        alpha: _isOut ? 0.4 : 1.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          '📦',
                          style: TextStyle(
                            fontSize: 42,
                            color: Colors.black
                                .withValues(alpha: _isOut ? 0.4 : 1.0),
                          ),
                        ),
                      ),
                    // Badge estado en esquina top-right
                    if (_isOut)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge('AGOTADO', McColors.error),
                      )
                    else if (_isLow)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge('BAJO', McColors.warning),
                      ),
                  ],
                ),
              ),
            ),

            // 2. INFO: brand + nombre + stock destacado
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandBadge(
                    brandName: item.brandName ?? '—',
                    size: BrandBadgeSize.sm,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.productName,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: McColors.foregroundLight,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variantName.isNotEmpty &&
                      item.variantName != 'Default' &&
                      item.variantName != item.productName)
                    Text(
                      item.variantName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: McColors.textFg2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  // ─ Stock prominente ─
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${item.stock}',
                        style: McTypography.mono(20,
                            color: _stockColor),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'u',
                        style: TextStyle(
                          fontSize: 11,
                          color: _stockColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Botón reponer pequeño
                      GestureDetector(
                        onTap: onAdjust,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: McColors.cobaltTint,
                            borderRadius:
                                BorderRadius.circular(McSpacing.radiusSm),
                            border: Border.all(color: McColors.primary),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: McColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

// ─── Chip de filtro (categoría / marca) ───

class _ChipFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipFilter({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

// ─── Tab de filtro ───

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: McSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? McColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? McColors.primary : McColors.textFg2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Badge pequeño ───

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Chip de movimiento ───

class _MovementChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MovementChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: McSpacing.xs),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

// ─── Modelo interno ───

class _StockItem {
  final String productName;
  final String variantName;
  final String sku;
  final double price;
  final String? brandName;
  final String? brandBg;
  final String? brandFg;
  final String? brandFont;
  final String? categoryName;
  final String? imageUrl;
  final int stock;
  final int minStock;

  const _StockItem({
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.price,
    this.brandName,
    this.brandBg,
    this.brandFg,
    this.brandFont,
    this.categoryName,
    this.imageUrl,
    required this.stock,
    this.minStock = 5,
  });

  _StockItem copyWith({int? stock}) => _StockItem(
        productName: productName,
        variantName: variantName,
        sku: sku,
        price: price,
        brandName: brandName,
        brandBg: brandBg,
        brandFg: brandFg,
        brandFont: brandFont,
        categoryName: categoryName,
        imageUrl: imageUrl,
        stock: stock ?? this.stock,
        minStock: minStock,
      );
}
