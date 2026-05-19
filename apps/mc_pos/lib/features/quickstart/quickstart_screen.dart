import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'brand_badge.dart';

/// Quickstart — el comerciante configura su catálogo inicial.
/// Flujo: elegir rubro → seleccionar catálogo → confirmar → importar → stock → listo.
class QuickstartScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final QuickstartPort quickstartPort;
  final StockPort stockPort;

  const QuickstartScreen({
    super.key,
    required this.onCompleted,
    required this.quickstartPort,
    required this.stockPort,
  });

  @override
  State<QuickstartScreen> createState() => _QuickstartScreenState();
}

class _QuickstartScreenState extends State<QuickstartScreen> {
  _QuickstartStep _step = _QuickstartStep.selectType;
  BusinessTypeInfo? _selectedType;
  QuickstartTemplate? _template;
  QuickstartImportResult? _result;
  String? _error;

  bool _isLoadingTypes = true;
  List<BusinessTypeInfo> _businessTypes = [];

  // sku → cantidad ingresada para stock inicial
  final Map<String, int> _stockQuantities = {};
  bool _savingStock = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessTypes();
  }

  Future<void> _loadBusinessTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _error = null;
    });
    try {
      final types = await widget.quickstartPort.listBusinessTypes();
      setState(() {
        _businessTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No pudimos cargar los tipos de comercio. Verificá tu conexión.';
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _selectType(BusinessTypeInfo type) async {
    setState(() {
      _selectedType = type;
      _error = null;
    });

    try {
      final templates = await widget.quickstartPort.listTemplates(
        businessTypeId: type.id,
      );

      if (!mounted) return;

      if (templates.isNotEmpty) {
        setState(() {
          _template = templates.first;
          _step = _QuickstartStep.selectCatalog;
        });
      } else {
        setState(() => _step = _QuickstartStep.confirm);
      }
    } catch (_) {
      // Si no hay templates disponibles, avanzar directamente a confirmar
      if (mounted) setState(() => _step = _QuickstartStep.confirm);
    }
  }

  Future<void> _applyTemplate() async {
    setState(() {
      _step = _QuickstartStep.applying;
      _error = null;
    });

    try {
      final result = await widget.quickstartPort.importFromBusinessType(
        businessTypeId: _selectedType!.id,
      );

      // TODO: cuando el endpoint soporte filtros, pasar las categorías/marcas
      // seleccionadas desde _template para filtrado server-side.

      if (!mounted) return;
      setState(() {
        _result = result;
        _step = _QuickstartStep.stockSetup;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar el catálogo. Intentá de nuevo.';
        _step = _QuickstartStep.confirm;
      });
    }
  }

  Future<void> _saveStock() async {
    setState(() => _savingStock = true);

    // Seed ALL products — entered qty o 100 por defecto.
    // Garantiza que ningún SKU quede sin entrada en stock-service.
    for (final product in (_result?.products ?? []).where((p) => p.sku.isNotEmpty)) {
      final qty = _stockQuantities[product.sku] ?? 100;
      try {
        await widget.stockPort.createStockEntry(
          variantSku: product.sku,
          productName: product.name,
          quantity: qty,
        );
      } catch (_) {
        // Error silencioso — no bloquear el flujo por stock parcial
      }
    }

    if (mounted) {
      setState(() => _savingStock = false);
      _finish();
    }
  }

  void _finish() => widget.onCompleted();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: McTheme.light,
      child: Scaffold(
      backgroundColor: McColors.cobaltTint,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: switch (_step) {
              _QuickstartStep.selectType => _SelectTypeView(
                  isLoading: _isLoadingTypes,
                  error: _error,
                  businessTypes: _businessTypes,
                  onSelected: _selectType,
                  onRetry: _loadBusinessTypes,
                ),
              _QuickstartStep.selectCatalog => _SelectCatalogView(
                  template: _template!,
                  typeName: _selectedType!.name,
                  onContinue: () => setState(() => _step = _QuickstartStep.confirm),
                  onBack: () => setState(() => _step = _QuickstartStep.selectType),
                ),
              _QuickstartStep.confirm => _ConfirmView(
                  type: _selectedType!,
                  template: _template,
                  error: _error,
                  onConfirm: _applyTemplate,
                  onBack: () => setState(
                    () => _step = _template != null
                        ? _QuickstartStep.selectCatalog
                        : _QuickstartStep.selectType,
                  ),
                ),
              _QuickstartStep.applying => _ApplyingView(
                  typeName: _selectedType!.name,
                ),
              _QuickstartStep.stockSetup => _StockSetupView(
                  result: _result!,
                  stockQuantities: _stockQuantities,
                  isSaving: _savingStock,
                  onQuantityChanged: (sku, qty) {
                    setState(() => _stockQuantities[sku] = qty);
                  },
                  onSkipStock: _saveStock,
                  onSaveStock: _saveStock,
                ),
              _QuickstartStep.done => _DoneView(
                  typeName: _selectedType!.name,
                  result: _result!,
                  onContinue: _finish,
                ),
            },
          ),
        ),
      ),
    ),
    );
  }
}

enum _QuickstartStep {
  selectType,
  selectCatalog,
  confirm,
  applying,
  stockSetup,
  done,
}

// ─── Helpers de mapeo ───

IconData _iconFromString(String s) => switch (s.toLowerCase()) {
      'store' || 'almacen' || 'minimarket' => Icons.store,
      'storefront' || 'kiosco' => Icons.storefront,
      'hardware' || 'ferreteria' || 'tools' => Icons.hardware,
      'spa' || 'perfumeria' || 'beauty' => Icons.spa,
      'bakery_dining' || 'panaderia' || 'bakery' => Icons.bakery_dining,
      'shopping_cart' || 'supermercado' => Icons.shopping_cart,
      'restaurant' || 'gastronomia' => Icons.restaurant,
      _ => Icons.storefront,
    };

Color _colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  return McColors.primary;
}

// ─── Step 1: Elegir tipo de negocio ───

class _SelectTypeView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<BusinessTypeInfo> businessTypes;
  final ValueChanged<BusinessTypeInfo> onSelected;
  final VoidCallback onRetry;

  const _SelectTypeView({
    required this.isLoading,
    required this.error,
    required this.businessTypes,
    required this.onSelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: McSpacing.lg),
          Text(
            '¡Bienvenido a Mercado Cercano!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: McSpacing.xs),
          Text(
            '¿Qué tipo de comercio tenés?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: McColors.textFg2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: McSpacing.lg),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: McSpacing.md),
            McButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ),
      );
    }

    if (businessTypes.isEmpty) {
      return Center(
        child: Text(
          'No hay tipos de comercio disponibles.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: businessTypes.length,
      separatorBuilder: (context, index) => const SizedBox(height: McSpacing.md),
      itemBuilder: (_, i) => _BusinessTypeCard(
        type: businessTypes[i],
        onTap: () => onSelected(businessTypes[i]),
      ),
    );
  }
}

class _BusinessTypeCard extends StatelessWidget {
  final BusinessTypeInfo type;
  final VoidCallback onTap;

  const _BusinessTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(type.color);
    final icon = _iconFromString(type.icon);

    return McCard(
      onTap: onTap,
      padding: const EdgeInsets.all(McSpacing.base),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(McSpacing.radiusMd),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: McSpacing.md),
          Expanded(
            child: Text(
              type.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

// ─── Step 2: Selección granular de catálogo ───

class _SelectCatalogView extends StatefulWidget {
  final QuickstartTemplate template;
  final String typeName;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _SelectCatalogView({
    required this.template,
    required this.typeName,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<_SelectCatalogView> createState() => _SelectCatalogViewState();
}

class _SelectCatalogViewState extends State<_SelectCatalogView> {
  void _setAllCategories(bool value) {
    setState(() {
      for (final c in widget.template.categories) {
        c.isSelected = value;
      }
    });
  }

  void _setAllBrands(bool value) {
    setState(() {
      for (final b in widget.template.brands) {
        b.isSelected = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              McSpacing.lg,
              McSpacing.lg,
              McSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué querés incluir?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: McSpacing.xs),
                Text(
                  widget.typeName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: McColors.textFg2,
                      ),
                ),
                const SizedBox(height: McSpacing.md),
                const TabBar(
                  tabs: [
                    Tab(text: 'Categorías'),
                    Tab(text: 'Marcas'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CategoryTab(
                  categories: widget.template.categories,
                  onSelectAll: () => _setAllCategories(true),
                  onSelectNone: () => _setAllCategories(false),
                  onToggle: (c, v) => setState(() => c.isSelected = v),
                ),
                _BrandTab(
                  brands: widget.template.brands,
                  onSelectAll: () => _setAllBrands(true),
                  onSelectNone: () => _setAllBrands(false),
                  onToggle: (b, v) => setState(() => b.isSelected = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(McSpacing.lg),
            child: Column(
              children: [
                McButton(
                  label: 'Continuar',
                  icon: Icons.arrow_forward,
                  size: McButtonSize.lg,
                  expand: true,
                  onPressed: widget.onContinue,
                ),
                const SizedBox(height: McSpacing.sm),
                McButton(
                  label: 'Atrás',
                  variant: McButtonVariant.ghost,
                  onPressed: widget.onBack,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final List<TemplateCategory> categories;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;
  final void Function(TemplateCategory, bool) onToggle;

  const _CategoryTab({
    required this.categories,
    required this.onSelectAll,
    required this.onSelectNone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: McSpacing.lg,
            vertical: McSpacing.xs,
          ),
          child: Row(
            children: [
              TextButton(onPressed: onSelectAll, child: const Text('Todos')),
              const SizedBox(width: McSpacing.sm),
              TextButton(onPressed: onSelectNone, child: const Text('Ninguno')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: McSpacing.lg,
              vertical: McSpacing.xs,
            ),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: McSpacing.xs),
            itemBuilder: (_, i) {
              final cat = categories[i];
              return McCard(
                onTap: () => onToggle(cat, !cat.isSelected),
                padding: const EdgeInsets.symmetric(
                  horizontal: McSpacing.md,
                  vertical: McSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      cat.isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: cat.isSelected
                          ? McColors.primary
                          : McColors.textSecondaryLight,
                      size: 22,
                    ),
                    const SizedBox(width: McSpacing.md),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: cat.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
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

class _BrandTab extends StatelessWidget {
  final List<TemplateBrand> brands;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;
  final void Function(TemplateBrand, bool) onToggle;

  const _BrandTab({
    required this.brands,
    required this.onSelectAll,
    required this.onSelectNone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: McSpacing.lg,
            vertical: McSpacing.xs,
          ),
          child: Row(
            children: [
              TextButton(onPressed: onSelectAll, child: const Text('Todos')),
              const SizedBox(width: McSpacing.sm),
              TextButton(onPressed: onSelectNone, child: const Text('Ninguno')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: McSpacing.lg,
              vertical: McSpacing.xs,
            ),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(height: McSpacing.xs),
            itemBuilder: (_, i) {
              final brand = brands[i];
              return McCard(
                onTap: () => onToggle(brand, !brand.isSelected),
                padding: const EdgeInsets.symmetric(
                  horizontal: McSpacing.md,
                  vertical: McSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      brand.isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: brand.isSelected
                          ? McColors.primary
                          : McColors.textSecondaryLight,
                      size: 22,
                    ),
                    const SizedBox(width: McSpacing.md),
                    BrandBadge(
                      brandName: brand.name,
                      size: BrandBadgeSize.sm,
                    ),
                    const SizedBox(width: McSpacing.sm),
                    Expanded(
                      child: Text(
                        brand.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: brand.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
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

// ─── Step 3: Confirmar ───

class _ConfirmView extends StatelessWidget {
  final BusinessTypeInfo type;
  final QuickstartTemplate? template;
  final String? error;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const _ConfirmView({
    required this.type,
    required this.template,
    required this.error,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(type.color);
    final icon = _iconFromString(type.icon);
    final selectedCategories = template?.categories.where((c) => c.isSelected).toList() ?? [];
    final selectedBrands = template?.brands.where((b) => b.isSelected).toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: McSpacing.md),
          Text(
            type.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: McSpacing.xs),
          if (template != null)
            Text(
              '${selectedCategories.length} categorías · ${selectedBrands.length} marcas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: McColors.textFg2,
                  ),
            ),
          const SizedBox(height: McSpacing.lg),

          if (selectedBrands.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Marcas que vas a tener',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: McSpacing.sm),
            Wrap(
              spacing: McSpacing.sm,
              runSpacing: McSpacing.sm,
              children: selectedBrands
                  .map((b) => BrandBadge(
                        brandName: b.name,
                        size: BrandBadgeSize.lg,
                      ))
                  .toList(),
            ),
            const SizedBox(height: McSpacing.lg),
          ],

          if (selectedCategories.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Categorías incluidas',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: McSpacing.sm),
            _CategoriesGrid(categories: selectedCategories),
            const SizedBox(height: McSpacing.lg),
          ],

          if (error != null) ...[
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: McSpacing.md),
          ],

          McButton(
            label: 'Cargar catálogo',
            icon: Icons.rocket_launch,
            size: McButtonSize.lg,
            expand: true,
            onPressed: onConfirm,
          ),
          const SizedBox(height: McSpacing.md),
          McButton(
            label: 'Elegir otro rubro',
            variant: McButtonVariant.ghost,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  final List<TemplateCategory> categories;

  const _CategoriesGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    // Dividir la lista en dos columnas manualmente para evitar
    // GridView con childAspectRatio frágil ante textos largos.
    final mid = (categories.length / 2).ceil();
    final leftColumn = categories.take(mid).toList();
    final rightColumn = categories.skip(mid).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _CategoryColumn(items: leftColumn)),
        const SizedBox(width: McSpacing.sm),
        Expanded(child: _CategoryColumn(items: rightColumn)),
      ],
    );
  }
}

class _CategoryColumn extends StatelessWidget {
  final List<TemplateCategory> items;

  const _CategoryColumn({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: McSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: McColors.textFg2,
                    ),
                  ),
                  const SizedBox(width: McSpacing.xs),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Step 4: Aplicando ───

class _ApplyingView extends StatelessWidget {
  final String typeName;

  const _ApplyingView({required this.typeName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: McSpacing.lg),
          Text(
            'Preparando tu $typeName...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: McSpacing.sm),
          Text(
            'Cargando categorías, productos y marcas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: McColors.textFg2,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5: Stock inicial ───

class _StockSetupView extends StatefulWidget {
  final QuickstartImportResult result;
  final Map<String, int> stockQuantities;
  final bool isSaving;
  final void Function(String sku, int qty) onQuantityChanged;
  final VoidCallback onSkipStock;
  final VoidCallback onSaveStock;

  const _StockSetupView({
    required this.result,
    required this.stockQuantities,
    required this.isSaving,
    required this.onQuantityChanged,
    required this.onSkipStock,
    required this.onSaveStock,
  });

  @override
  State<_StockSetupView> createState() => _StockSetupViewState();
}

class _StockSetupViewState extends State<_StockSetupView> {
  bool _showStockForm = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: McSpacing.lg),
          Text(
            '¿Registrás el stock inicial?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: McSpacing.xs),
          Text(
            'Podés cargarlo ahora o después desde el inventario.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: McColors.textFg2,
                ),
          ),
          const SizedBox(height: McSpacing.lg),

          _StockOptionCard(
            title: 'Sí, cargo las cantidades',
            subtitle: 'Ingresá cuántas unidades tenés de cada producto.',
            icon: Icons.inventory_2_outlined,
            isSelected: _showStockForm,
            onTap: () => setState(() => _showStockForm = true),
          ),
          const SizedBox(height: McSpacing.sm),
          _StockOptionCard(
            title: 'Empezar sin stock',
            subtitle: 'Lo cargás más adelante desde el inventario.',
            icon: Icons.skip_next_outlined,
            isSelected: !_showStockForm,
            onTap: () => setState(() => _showStockForm = false),
          ),

          if (_showStockForm) ...[
            const SizedBox(height: McSpacing.lg),
            Text(
              'Cantidades iniciales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: McSpacing.sm),
            ...widget.result.products.take(20).map(
                  (p) => _StockProductRow(
                    product: p,
                    quantity: widget.stockQuantities[p.sku] ?? 0,
                    onChanged: (qty) => widget.onQuantityChanged(p.sku, qty),
                  ),
                ),
          ],

          const SizedBox(height: McSpacing.xl),

          if (widget.isSaving)
            const Center(child: CircularProgressIndicator())
          else ...[
            McButton(
              label: _showStockForm ? 'Guardar y empezar' : 'Empezar',
              icon: Icons.storefront,
              size: McButtonSize.lg,
              expand: true,
              onPressed: _showStockForm ? widget.onSaveStock : widget.onSkipStock,
            ),
          ],
        ],
      ),
    );
  }
}

class _StockOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StockOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return McCard(
      onTap: onTap,
      padding: const EdgeInsets.all(McSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected ? McColors.primary : McColors.textSecondaryLight,
          ),
          const SizedBox(width: McSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? McColors.primary : null,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: McColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: McColors.primary),
        ],
      ),
    );
  }
}

class _StockProductRow extends StatelessWidget {
  final ImportedProduct product;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _StockProductRow({
    required this.product,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: McSpacing.md),
          SizedBox(
            width: 80,
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: McSpacing.sm,
                  vertical: McSpacing.xs,
                ),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 6: Listo ───

class _DoneView extends StatelessWidget {
  final String typeName;
  final QuickstartImportResult result;
  final VoidCallback onContinue;

  const _DoneView({
    required this.typeName,
    required this.result,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: McColors.success),
          const SizedBox(height: McSpacing.lg),
          Text(
            '¡Tu $typeName está lista!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: McSpacing.lg),
          McCard(
            child: Column(
              children: [
                _ResultRow('Categorías', '${result.categoriesCreated}'),
                _ResultRow('Productos', '${result.productsImported}'),
                _ResultRow('Marcas', '${result.brandsImported}'),
              ],
            ),
          ),
          const SizedBox(height: McSpacing.base),
          Text(
            'Ya podés empezar a vender. Los precios son de referencia — podés ajustarlos después.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: McColors.textFg2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: McSpacing.xl),
          McButton(
            label: '¡A vender!',
            icon: Icons.storefront,
            size: McButtonSize.lg,
            expand: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: McSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
