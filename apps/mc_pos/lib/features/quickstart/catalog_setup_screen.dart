import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import 'brand_badge.dart';

/// Pantalla de configuración del catálogo — el comerciante elige qué vende.
/// Después del quickstart, se muestran productos/categorías/marcas del template
/// para que acepte o descarte. También puede importar desde CSV.
class CatalogSetupScreen extends StatefulWidget {
  final String businessTypeName;
  final List<_TemplateCategory> categories;
  final VoidCallback onComplete;

  const CatalogSetupScreen({
    super.key,
    required this.businessTypeName,
    required this.categories,
    required this.onComplete,
  });

  @override
  State<CatalogSetupScreen> createState() => _CatalogSetupScreenState();
}

class _CatalogSetupScreenState extends State<CatalogSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado de selección
  final Set<String> _deselectedCategories = {};
  final Set<String> _deselectedBrands = {};
  final Set<String> _deselectedProducts = {};

  int get _totalProducts => widget.categories
      .where((c) => !_deselectedCategories.contains(c.name))
      .expand((c) => c.products)
      .where((p) =>
          !_deselectedProducts.contains(p.id) &&
          !_deselectedBrands.contains(p.brand))
      .length;

  int get _totalCategories =>
      widget.categories.length - _deselectedCategories.length;

  Set<String> get _allBrands =>
      widget.categories.expand((c) => c.products).map((p) => p.brand).toSet();

  int get _totalBrands =>
      _allBrands.where((b) => !_deselectedBrands.contains(b)).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_deselectedCategories.contains(name)) {
        _deselectedCategories.remove(name);
      } else {
        _deselectedCategories.add(name);
      }
    });
  }

  void _toggleBrand(String brand) {
    setState(() {
      if (_deselectedBrands.contains(brand)) {
        _deselectedBrands.remove(brand);
      } else {
        _deselectedBrands.add(brand);
      }
    });
  }

  void _toggleProduct(String id) {
    setState(() {
      if (_deselectedProducts.contains(id)) {
        _deselectedProducts.remove(id);
      } else {
        _deselectedProducts.add(id);
      }
    });
  }

  void _importProducts() {
    // TODO: llamar a POST /pim/api/v1/products/import con los productos seleccionados
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Importar catálogo?'),
        content: Text(
          'Se van a importar $_totalProducts productos de $_totalCategories categorías y $_totalBrands marcas a tu comercio.',
        ),
        actions: [
          McButton(
            label: 'Cancelar',
            variant: McButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          McButton(
            label: 'Importar',
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onComplete();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo — ${widget.businessTypeName}'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Categorías ($_totalCategories)'),
            Tab(text: 'Marcas ($_totalBrands)'),
            Tab(text: 'Productos ($_totalProducts)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.all(McSpacing.md),
            color: McColors.info.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: McColors.info),
                const SizedBox(width: McSpacing.sm),
                Expanded(
                  child: Text(
                    'Desactivá lo que no vendés. Después podés agregar más.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: McColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CategoriesTab(
                  categories: widget.categories,
                  deselected: _deselectedCategories,
                  onToggle: _toggleCategory,
                ),
                _BrandsTab(
                  brands: _allBrands.toList()..sort(),
                  deselected: _deselectedBrands,
                  onToggle: _toggleBrand,
                  categories: widget.categories,
                ),
                _ProductsTab(
                  categories: widget.categories,
                  deselectedCategories: _deselectedCategories,
                  deselectedBrands: _deselectedBrands,
                  deselectedProducts: _deselectedProducts,
                  onToggle: _toggleProduct,
                ),
              ],
            ),
          ),
          // Footer con acción
          _SetupFooter(
            totalProducts: _totalProducts,
            onImport: _importProducts,
            onCsv: _showCsvImport,
          ),
        ],
      ),
    );
  }

  void _showCsvImport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CsvImportSheet(),
    );
  }
}

// ─── Tab: Categorías ───

class _CategoriesTab extends StatelessWidget {
  final List<_TemplateCategory> categories;
  final Set<String> deselected;
  final ValueChanged<String> onToggle;

  const _CategoriesTab({
    required this.categories,
    required this.deselected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final isActive = !deselected.contains(cat.name);
        return SwitchListTile(
          title: Text(
            cat.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isActive ? null : McColors.textSecondaryLight,
              decoration: isActive ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Text('${cat.products.length} productos'),
          secondary: Icon(
            cat.icon,
            color: isActive ? McColors.primary : McColors.textSecondaryLight,
          ),
          value: isActive,
          onChanged: (_) => onToggle(cat.name),
        );
      },
    );
  }
}

// ─── Tab: Marcas ───

class _BrandsTab extends StatelessWidget {
  final List<String> brands;
  final Set<String> deselected;
  final ValueChanged<String> onToggle;
  final List<_TemplateCategory> categories;

  const _BrandsTab({
    required this.brands,
    required this.deselected,
    required this.onToggle,
    required this.categories,
  });

  int _productCountForBrand(String brand) {
    return categories
        .expand((c) => c.products)
        .where((p) => p.brand == brand)
        .length;
  }

  String? _logoForBrand(String brand) {
    for (final cat in categories) {
      for (final p in cat.products) {
        if (p.brand == brand && p.brandLogoUrl != null) return p.brandLogoUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: brands.length,
      itemBuilder: (_, i) {
        final brand = brands[i];
        final isActive = !deselected.contains(brand);
        final count = _productCountForBrand(brand);
        final logo = _logoForBrand(brand);
        return Opacity(
          opacity: isActive ? 1.0 : 0.4,
          child: SwitchListTile(
            secondary: BrandBadge(brandName: brand, size: BrandBadgeSize.lg),
            title: Text(
              brand,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text('$count productos'),
            value: isActive,
            onChanged: (_) => onToggle(brand),
          ),
        );
      },
    );
  }
}

// ─── Tab: Productos ───

class _ProductsTab extends StatelessWidget {
  final List<_TemplateCategory> categories;
  final Set<String> deselectedCategories;
  final Set<String> deselectedBrands;
  final Set<String> deselectedProducts;
  final ValueChanged<String> onToggle;

  const _ProductsTab({
    required this.categories,
    required this.deselectedCategories,
    required this.deselectedBrands,
    required this.deselectedProducts,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activeCategories = categories
        .where((c) => !deselectedCategories.contains(c.name))
        .toList();

    return ListView.builder(
      itemCount: activeCategories.length,
      itemBuilder: (_, i) {
        final cat = activeCategories[i];
        final activeProducts = cat.products
            .where((p) => !deselectedBrands.contains(p.brand))
            .toList();

        return ExpansionTile(
          title: Text(cat.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${activeProducts.length} productos'),
          initiallyExpanded: i == 0,
          children: activeProducts.map((p) {
            final isActive = !deselectedProducts.contains(p.id);
            return Opacity(
              opacity: isActive ? 1.0 : 0.4,
              child: ListTile(
                leading: _ProductImage(
                  imageUrl: p.imageUrl,
                  categoryIcon: cat.icon,
                  size: 48,
                ),
                title: Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Row(
                  children: [
                    BrandBadgeSmall(brandName: p.brand),
                    const Spacer(),
                    Text(
                      p.price.formatted,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                trailing: Checkbox(
                  value: isActive,
                  onChanged: (_) => onToggle(p.id),
                ),
                onTap: () => onToggle(p.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Footer ───

class _SetupFooter extends StatelessWidget {
  final int totalProducts;
  final VoidCallback onImport;
  final VoidCallback onCsv;

  const _SetupFooter({
    required this.totalProducts,
    required this.onImport,
    required this.onCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(McSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // CSV import
            McButton(
              label: 'Importar CSV',
              icon: Icons.upload_file,
              variant: McButtonVariant.outline,
              size: McButtonSize.md,
              onPressed: onCsv,
            ),
            const SizedBox(width: McSpacing.md),
            // Import selected
            Expanded(
              child: McButton(
                label: 'Importar $totalProducts productos',
                icon: Icons.check_circle,
                size: McButtonSize.lg,
                onPressed: totalProducts > 0 ? onImport : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CSV Import Sheet ───

class _CsvImportSheet extends StatelessWidget {
  const _CsvImportSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: McSpacing.lg),
            Text('Importar desde archivo',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: McSpacing.md),
            Text(
              'Subí un CSV o Excel con tus productos. Las columnas aceptadas son:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: McSpacing.md),
            Wrap(
              spacing: McSpacing.sm,
              runSpacing: McSpacing.sm,
              children: [
                'nombre',
                'precio',
                'categoría',
                'marca',
                'sku',
                'stock',
                'descripción',
              ]
                  .map((col) => Chip(
                        label: Text(col),
                        backgroundColor: McColors.mutedLight,
                      ))
                  .toList(),
            ),
            const SizedBox(height: McSpacing.lg),
            // TODO: integrar file_picker para selección de archivo
            McButton(
              label: 'Seleccionar archivo',
              icon: Icons.folder_open,
              size: McButtonSize.lg,
              expand: true,
              onPressed: () {
                // TODO: file_picker → parse CSV → preview
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Importación CSV próximamente — usá los productos del template por ahora'),
                  ),
                );
              },
            ),
            const SizedBox(height: McSpacing.md),
            McButton(
              label: 'Descargar template CSV',
              icon: Icons.download,
              variant: McButtonVariant.outline,
              expand: true,
              onPressed: () {
                // TODO: descargar CSV de ejemplo del rubro
              },
            ),
            const SizedBox(height: McSpacing.base),
          ],
        ),
      ),
    );
  }
}

// ─── Data Models ───

class _TemplateProduct {
  final String id;
  final String name;
  final String brand;
  final String? brandLogoUrl;
  final Money price;
  final String category;
  final String? imageUrl;

  const _TemplateProduct({
    required this.id,
    required this.name,
    required this.brand,
    this.brandLogoUrl,
    required this.price,
    required this.category,
    this.imageUrl,
  });
}

class _TemplateCategory {
  final String name;
  final IconData icon;
  final List<_TemplateProduct> products;

  const _TemplateCategory({
    required this.name,
    required this.icon,
    required this.products,
  });
}

/// Imagen de producto — muestra imagen real o placeholder con icono de categoría.
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final IconData categoryIcon;
  final double size;

  const _ProductImage({
    this.imageUrl,
    required this.categoryIcon,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(McSpacing.radiusSm),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: McColors.mutedLight,
        borderRadius: BorderRadius.circular(McSpacing.radiusSm),
      ),
      child: Icon(categoryIcon, color: McColors.textSecondaryLight, size: size * 0.5),
    );
  }
}

/// Logo de marca para el catalog setup — más grande que en quickstart.
class _BrandLogoLarge extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final double size;

  const _BrandLogoLarge({
    required this.name,
    this.logoUrl,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: McColors.borderLight, width: 0.5),
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: logoUrl != null
          ? Image.network(
              logoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _initial(context),
            )
          : _initial(context),
    );
  }

  Widget _initial(BuildContext context) {
    return Center(
      child: Text(
        name[0],
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: McColors.primary,
        ),
      ),
    );
  }
}

// TODO: reemplazar con datos reales del endpoint GET /pim/api/v1/quickstart/templates
List<_TemplateCategory> buildDemoCategories(String businessType) {
  if (businessType == 'almacen') return _almacenCategories;
  if (businessType == 'kiosco') return _kioscoCategories;
  return _almacenCategories;
}

const _api = 'https://logos-api.apistemic.com/domain:';

final _almacenCategories = [
  _TemplateCategory(name: 'Almacén Seco', icon: Icons.inventory_2, products: [
    _TemplateProduct(id: 'a1', name: 'Yerba Taragüi 1kg', brand: 'Taragüi', brandLogoUrl: '${_api}taragui.com', price: Money.ars(4500), category: 'Almacén Seco'),
    _TemplateProduct(id: 'a2', name: 'Yerba Playadito 1kg', brand: 'Playadito', price: Money.ars(4800), category: 'Almacén Seco'),
    _TemplateProduct(id: 'a3', name: 'Café Cabrales 500g', brand: 'Cabrales', brandLogoUrl: '${_api}cabrales.com', price: Money.ars(5500), category: 'Almacén Seco'),
    _TemplateProduct(id: 'a4', name: 'Azúcar Ledesma 1kg', brand: 'Ledesma', brandLogoUrl: '${_api}ledesma.com.ar', price: Money.ars(1500), category: 'Almacén Seco'),
    _TemplateProduct(id: 'a5', name: 'Sal Dos Anclas 500g', brand: 'Dos Anclas', price: Money.ars(600), category: 'Almacén Seco'),
  ]),
  _TemplateCategory(name: 'Bebidas', icon: Icons.local_drink, products: [
    _TemplateProduct(id: 'b1', name: 'Coca-Cola 2.25L', brand: 'Coca-Cola', brandLogoUrl: '${_api}coca-cola.com', price: Money.ars(3200), category: 'Bebidas'),
    _TemplateProduct(id: 'b2', name: 'Sprite 2.25L', brand: 'Coca-Cola', brandLogoUrl: '${_api}coca-cola.com', price: Money.ars(2600), category: 'Bebidas'),
    _TemplateProduct(id: 'b3', name: 'Agua Villavicencio 2L', brand: 'Villavicencio', price: Money.ars(1200), category: 'Bebidas'),
    _TemplateProduct(id: 'b4', name: 'Cerveza Quilmes 1L', brand: 'Quilmes', brandLogoUrl: '${_api}quilmes.com.ar', price: Money.ars(2500), category: 'Bebidas'),
    _TemplateProduct(id: 'b5', name: 'Fernet Branca 750ml', brand: 'Branca', price: Money.ars(8500), category: 'Bebidas'),
  ]),
  _TemplateCategory(name: 'Lácteos', icon: Icons.egg, products: [
    _TemplateProduct(id: 'l1', name: 'Leche La Serenísima 1L', brand: 'La Serenísima', brandLogoUrl: '${_api}laserenisima.com.ar', price: Money.ars(1800), category: 'Lácteos'),
    _TemplateProduct(id: 'l2', name: 'Yogur La Serenísima 1kg', brand: 'La Serenísima', brandLogoUrl: '${_api}laserenisima.com.ar', price: Money.ars(3500), category: 'Lácteos'),
    _TemplateProduct(id: 'l3', name: 'Queso cremoso kg', brand: 'La Serenísima', brandLogoUrl: '${_api}laserenisima.com.ar', price: Money.ars(8000), category: 'Lácteos'),
    _TemplateProduct(id: 'l4', name: 'Manteca 200g', brand: 'La Serenísima', brandLogoUrl: '${_api}laserenisima.com.ar', price: Money.ars(3200), category: 'Lácteos'),
  ]),
  _TemplateCategory(name: 'Harinas', icon: Icons.bakery_dining, products: [
    _TemplateProduct(id: 'h1', name: 'Harina 000 Cañuelas 1kg', brand: 'Cañuelas', price: Money.ars(1100), category: 'Harinas'),
    _TemplateProduct(id: 'h2', name: 'Harina Pureza 1kg', brand: 'Pureza', price: Money.ars(1250), category: 'Harinas'),
    _TemplateProduct(id: 'h3', name: 'Polenta Presto Pronta 500g', brand: 'Presto Pronta', price: Money.ars(900), category: 'Harinas'),
  ]),
  _TemplateCategory(name: 'Limpieza', icon: Icons.cleaning_services, products: [
    _TemplateProduct(id: 'li1', name: 'Detergente Magistral 500ml', brand: 'Magistral', price: Money.ars(2200), category: 'Limpieza'),
    _TemplateProduct(id: 'li2', name: 'Lavandina Ayudín 1L', brand: 'Ayudín', price: Money.ars(800), category: 'Limpieza'),
    _TemplateProduct(id: 'li3', name: 'Jabón Skip 800g', brand: 'Skip', brandLogoUrl: '${_api}skip.com.ar', price: Money.ars(3500), category: 'Limpieza'),
  ]),
  _TemplateCategory(name: 'Fiambrería', icon: Icons.lunch_dining, products: [
    _TemplateProduct(id: 'f1', name: 'Jamón cocido kg', brand: 'Paladini', brandLogoUrl: '${_api}paladini.com.ar', price: Money.ars(12000), category: 'Fiambrería'),
    _TemplateProduct(id: 'f2', name: 'Salchicha Vienissima x6', brand: 'Vienissima', price: Money.ars(2400), category: 'Fiambrería'),
    _TemplateProduct(id: 'f3', name: 'Mortadela Paladini 200g', brand: 'Paladini', brandLogoUrl: '${_api}paladini.com.ar', price: Money.ars(2000), category: 'Fiambrería'),
  ]),
];

final _kioscoCategories = [
  _TemplateCategory(name: 'Bebidas', icon: Icons.local_drink, products: [
    _TemplateProduct(id: 'kb1', name: 'Coca-Cola 500ml', brand: 'Coca-Cola', brandLogoUrl: '${_api}coca-cola.com', price: Money.ars(2000), category: 'Bebidas'),
    _TemplateProduct(id: 'kb2', name: 'Sprite 500ml', brand: 'Coca-Cola', brandLogoUrl: '${_api}coca-cola.com', price: Money.ars(1900), category: 'Bebidas'),
    _TemplateProduct(id: 'kb3', name: 'Speed Max 473ml', brand: 'Speed', price: Money.ars(2500), category: 'Bebidas'),
    _TemplateProduct(id: 'kb4', name: 'Red Bull 250ml', brand: 'Red Bull', brandLogoUrl: '${_api}redbull.com', price: Money.ars(3000), category: 'Bebidas'),
    _TemplateProduct(id: 'kb5', name: 'Cerveza Quilmes 473ml', brand: 'Quilmes', brandLogoUrl: '${_api}quilmes.com.ar', price: Money.ars(1800), category: 'Bebidas'),
  ]),
  _TemplateCategory(name: 'Golosinas', icon: Icons.cake, products: [
    _TemplateProduct(id: 'kg1', name: 'Alfajor Havanna', brand: 'Havanna', brandLogoUrl: '${_api}havanna.com.ar', price: Money.ars(1200), category: 'Golosinas'),
    _TemplateProduct(id: 'kg2', name: 'Alfajor Guaymallén triple', brand: 'Guaymallén', price: Money.ars(500), category: 'Golosinas'),
    _TemplateProduct(id: 'kg3', name: 'Chocolate Milka 55g', brand: 'Milka', brandLogoUrl: '${_api}milka.com', price: Money.ars(1500), category: 'Golosinas'),
    _TemplateProduct(id: 'kg4', name: 'Bon o Bon', brand: 'Arcor', brandLogoUrl: '${_api}arcor.com', price: Money.ars(350), category: 'Golosinas'),
    _TemplateProduct(id: 'kg5', name: 'Gomitas Mogul', brand: 'Arcor', brandLogoUrl: '${_api}arcor.com', price: Money.ars(1200), category: 'Golosinas'),
  ]),
  _TemplateCategory(name: 'Snacks', icon: Icons.restaurant, products: [
    _TemplateProduct(id: 'ks1', name: 'Papas Lays 47g', brand: 'Lays', brandLogoUrl: '${_api}lays.com', price: Money.ars(2000), category: 'Snacks'),
    _TemplateProduct(id: 'ks2', name: 'Doritos 45g', brand: 'Lays', brandLogoUrl: '${_api}lays.com', price: Money.ars(1800), category: 'Snacks'),
    _TemplateProduct(id: 'ks3', name: 'Cheetos 40g', brand: 'Cheetos', price: Money.ars(1600), category: 'Snacks'),
  ]),
  _TemplateCategory(name: 'Galletitas', icon: Icons.cookie, products: [
    _TemplateProduct(id: 'kga1', name: 'Oreo 118g', brand: 'Oreo', brandLogoUrl: '${_api}oreo.com', price: Money.ars(1500), category: 'Galletitas'),
    _TemplateProduct(id: 'kga2', name: 'Criollitas 100g', brand: 'Bagley', brandLogoUrl: '${_api}bagley.com.ar', price: Money.ars(800), category: 'Galletitas'),
    _TemplateProduct(id: 'kga3', name: 'Pepitos 118g', brand: 'Bagley', brandLogoUrl: '${_api}bagley.com.ar', price: Money.ars(1400), category: 'Galletitas'),
  ]),
];
