import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'brand_badge.dart';
import 'catalog_setup_screen.dart';

/// Quickstart — el comerciante elige su rubro y recibe catálogo.
/// Se muestra una sola vez después del registro.
class QuickstartScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const QuickstartScreen({super.key, required this.onCompleted});

  @override
  State<QuickstartScreen> createState() => _QuickstartScreenState();
}

class _QuickstartScreenState extends State<QuickstartScreen> {
  _QuickstartStep _step = _QuickstartStep.selectType;
  _BusinessType? _selectedType;
  _ApplyResult? _result;

  void _selectType(_BusinessType type) {
    setState(() {
      _selectedType = type;
      _step = _QuickstartStep.confirm;
    });
  }

  Future<void> _applyTemplate() async {
    setState(() {
      _step = _QuickstartStep.applying;
    });

    // TODO: conectar con POST /pim/api/v1/quickstart/products/from-template
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _result = _ApplyResult(
        categoriesCreated: _selectedType!.categories,
        productsCreated: _selectedType!.productCount,
        brandsCreated: _selectedType!.brandCount,
      );
      _step = _QuickstartStep.done;
    });
  }

  void _goToCatalogSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogSetupScreen(
          businessTypeName: _selectedType!.name,
          categories: buildDemoCategories(_selectedType!.code),
          onComplete: widget.onCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: switch (_step) {
              _QuickstartStep.selectType => _SelectTypeView(
                  onSelected: _selectType,
                ),
              _QuickstartStep.confirm => _ConfirmView(
                  type: _selectedType!,
                  onConfirm: _applyTemplate,
                  onBack: () =>
                      setState(() => _step = _QuickstartStep.selectType),
                ),
              _QuickstartStep.applying => _ApplyingView(
                  type: _selectedType!,
                ),
              _QuickstartStep.done => _DoneView(
                  type: _selectedType!,
                  result: _result!,
                  onContinue: () => _goToCatalogSetup(),
                ),
            },
          ),
        ),
      ),
    );
  }
}

enum _QuickstartStep { selectType, confirm, applying, done }

// ─── Step 1: Elegir tipo de negocio ───

class _SelectTypeView extends StatelessWidget {
  final ValueChanged<_BusinessType> onSelected;

  const _SelectTypeView({required this.onSelected});

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
                  color: McColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: McSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: _businessTypes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: McSpacing.md),
              itemBuilder: (_, i) => _BusinessTypeCard(
                type: _businessTypes[i],
                onTap: () => onSelected(_businessTypes[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTypeCard extends StatelessWidget {
  final _BusinessType type;
  final VoidCallback onTap;

  const _BusinessTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return McCard(
      onTap: onTap,
      padding: const EdgeInsets.all(McSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icono + nombre + stats
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(McSpacing.radiusMd),
                ),
                child: Icon(type.icon, size: 28, color: type.color),
              ),
              const SizedBox(width: McSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${type.productCount} productos · ${type.categories} categorías',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: McColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: McSpacing.md),

          // Marcas como badges con colores reales
          Wrap(
            spacing: McSpacing.xs,
            runSpacing: McSpacing.xs,
            children: [
              ...type.brands.take(5).map((b) => BrandBadge(
                    brandName: b.name,
                    size: BrandBadgeSize.sm,
                  )),
              if (type.brands.length > 5)
                Container(
                  width: 40,
                  height: 28,
                  decoration: BoxDecoration(
                    color: McColors.mutedLight,
                    borderRadius: BorderRadius.circular(McSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      '+${type.brands.length - 5}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: McSpacing.sm),

          // Categorías como chips
          Wrap(
            spacing: McSpacing.xs,
            runSpacing: McSpacing.xs,
            children: type.categoryNames.take(6).map((cat) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: McSpacing.sm,
                    vertical: McSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(McSpacing.radiusSm),
                    border: Border.all(
                      color: type.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: type.color,
                        ),
                  ),
                )).toList(),
          ),
        ],
      ),
    );
  }
}

/// Logo de marca — imagen si hay URL, inicial si no.
class _BrandLogo extends StatelessWidget {
  final _Brand brand;
  final double size;

  const _BrandLogo({required this.brand, this.size = 32});

  @override
  Widget build(BuildContext context) {
    if (brand.logoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: McColors.borderLight, width: 0.5),
        ),
        padding: EdgeInsets.all(size * 0.15),
        child: Image.network(
          brand.logoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _initialContent(context),
        ),
      );
    }
    return _fallbackCircle(context);
  }

  Widget _fallbackCircle(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: McColors.mutedLight,
        shape: BoxShape.circle,
      ),
      child: Center(child: _initialContent(context)),
    );
  }

  Widget _initialContent(BuildContext context) {
    return Text(
      brand.name[0],
      style: TextStyle(
        fontSize: size * 0.4,
        fontWeight: FontWeight.bold,
        color: McColors.primary,
      ),
    );
  }
}

// ─── Step 2: Confirmar ───

class _ConfirmView extends StatelessWidget {
  final _BusinessType type;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const _ConfirmView({
    required this.type,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(McSpacing.lg),
      child: Column(
        children: [
          Icon(type.icon, size: 64, color: type.color),
          const SizedBox(height: McSpacing.md),
          Text(
            type.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: McSpacing.xs),
          Text(
            '${type.productCount} productos · ${type.categories} categorías · ${type.brandCount} marcas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: McColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: McSpacing.lg),

          // Marcas con logos
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Marcas que vas a tener',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: McSpacing.sm),
          Wrap(
            spacing: McSpacing.sm,
            runSpacing: McSpacing.sm,
            children: type.brands
                .map((b) => BrandBadge(
                      brandName: b.name,
                      size: BrandBadgeSize.lg,
                    ))
                .toList(),
          ),
          const SizedBox(height: McSpacing.lg),

          // Categorías como chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Categorías incluidas',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: McSpacing.sm),
          Wrap(
            spacing: McSpacing.sm,
            runSpacing: McSpacing.sm,
            children: type.categoryNames
                .map((cat) => Chip(
                      label: Text(cat),
                      backgroundColor: type.color.withValues(alpha: 0.1),
                      side: BorderSide(color: type.color.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
          const SizedBox(height: McSpacing.xl),

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

// ─── Step 3: Aplicando ───

class _ApplyingView extends StatelessWidget {
  final _BusinessType type;

  const _ApplyingView({required this.type});

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
            'Preparando tu ${type.name}...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: McSpacing.sm),
          Text(
            'Cargando categorías, productos y marcas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: McColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Listo ───

class _DoneView extends StatelessWidget {
  final _BusinessType type;
  final _ApplyResult result;
  final VoidCallback onContinue;

  const _DoneView({
    required this.type,
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
            '¡Tu ${type.name} está lista!',
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
                _ResultRow('Productos', '${result.productsCreated}'),
                _ResultRow('Marcas', '${result.brandsCreated}'),
              ],
            ),
          ),
          const SizedBox(height: McSpacing.base),
          Text(
            'Ya podés empezar a vender. Los precios son de referencia — podés ajustarlos después.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: McColors.textSecondaryLight,
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

// ─── Data ───

class _ApplyResult {
  final int categoriesCreated;
  final int productsCreated;
  final int brandsCreated;
  const _ApplyResult({
    required this.categoriesCreated,
    required this.productsCreated,
    required this.brandsCreated,
  });
}

class _Brand {
  final String name;
  final String? logoUrl;
  const _Brand(this.name, [this.logoUrl]);
}

class _BusinessType {
  final String code;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> categoryNames;
  final int productCount;
  final List<_Brand> brands;

  const _BusinessType({
    required this.code,
    required this.name,
    required this.icon,
    required this.color,
    required this.categoryNames,
    required this.productCount,
    required this.brands,
  });

  int get categories => categoryNames.length;
  int get brandCount => brands.length;
}

// TODO: reemplazar con GET /pim/api/v1/quickstart/templates
final _businessTypes = [
  _BusinessType(
    code: 'almacen',
    name: 'Almacén',
    icon: Icons.store,
    color: const Color(0xFF4A90E2),
    productCount: 306,
    categoryNames: const ['Almacén Seco', 'Bebidas', 'Lácteos', 'Panadería', 'Golosinas', 'Limpieza', 'Perfumería', 'Fiambrería'],
    brands: const [
      _Brand('La Serenísima', 'https://logos-api.apistemic.com/domain:laserenisima.com.ar'),
      _Brand('Arcor', 'https://logos-api.apistemic.com/domain:arcor.com'),
      _Brand('Coca-Cola', 'https://logos-api.apistemic.com/domain:coca-cola.com'),
      _Brand('Marolio', 'https://logos-api.apistemic.com/domain:marolio.com.ar'),
      _Brand('Molinos', 'https://logos-api.apistemic.com/domain:molinos.com.ar'),
      _Brand('Quilmes', 'https://logos-api.apistemic.com/domain:quilmes.com.ar'),
      _Brand('Bagley', 'https://logos-api.apistemic.com/domain:bagley.com.ar'),
      _Brand('Skip', 'https://logos-api.apistemic.com/domain:skip.com.ar'),
      _Brand('Dove', 'https://logos-api.apistemic.com/domain:dove.com'),
      _Brand('Paladini', 'https://logos-api.apistemic.com/domain:paladini.com.ar'),
      _Brand('Sancor', 'https://logos-api.apistemic.com/domain:sancor.com'),
      _Brand('Fargo', 'https://logos-api.apistemic.com/domain:fargo.com.ar'),
    ],
  ),
  _BusinessType(
    code: 'kiosco',
    name: 'Kiosco',
    icon: Icons.storefront,
    color: const Color(0xFF7B68EE),
    productCount: 285,
    categoryNames: const ['Bebidas', 'Golosinas', 'Snacks', 'Galletitas', 'Cigarrillos', 'Varios'],
    brands: const [
      _Brand('Coca-Cola', 'https://logos-api.apistemic.com/domain:coca-cola.com'),
      _Brand('Arcor', 'https://logos-api.apistemic.com/domain:arcor.com'),
      _Brand('Quilmes', 'https://logos-api.apistemic.com/domain:quilmes.com.ar'),
      _Brand('Lays', 'https://logos-api.apistemic.com/domain:lays.com'),
      _Brand('Mondelez', 'https://logos-api.apistemic.com/domain:mondelezinternational.com'),
      _Brand('Bagley', 'https://logos-api.apistemic.com/domain:bagley.com.ar'),
      _Brand('Beldent', 'https://logos-api.apistemic.com/domain:bfrench.com'),
      _Brand('Red Bull', 'https://logos-api.apistemic.com/domain:redbull.com'),
      _Brand('Havanna', 'https://logos-api.apistemic.com/domain:havanna.com.ar'),
      _Brand('Felfort', 'https://logos-api.apistemic.com/domain:felfort.com.ar'),
    ],
  ),
  _BusinessType(
    code: 'ferreteria',
    name: 'Ferretería',
    icon: Icons.hardware,
    color: const Color(0xFFFF6B35),
    productCount: 211,
    categoryNames: const ['Herramientas', 'Cerraduras', 'Pinturas', 'Electricidad', 'Plomería', 'Construcción', 'Jardín', 'Fijaciones'],
    brands: const [
      _Brand('Stanley', 'https://logos-api.apistemic.com/domain:stanleytools.com'),
      _Brand('Tramontina', 'https://logos-api.apistemic.com/domain:tramontina.com'),
      _Brand('Alba', 'https://logos-api.apistemic.com/domain:alba.com.ar'),
      _Brand('Acindar', 'https://logos-api.apistemic.com/domain:acindar.com.ar'),
      _Brand('Loma Negra', 'https://logos-api.apistemic.com/domain:lomanegra.com.ar'),
      _Brand('Lusqtoff', 'https://logos-api.apistemic.com/domain:lusqtoff.com.ar'),
      _Brand('Bahco', 'https://logos-api.apistemic.com/domain:bahco.com'),
      _Brand('Sinteplast', 'https://logos-api.apistemic.com/domain:sinteplast.com.ar'),
      _Brand('FV', 'https://logos-api.apistemic.com/domain:fv.com.ar'),
      _Brand('Tigre', 'https://logos-api.apistemic.com/domain:tigre.com.ar'),
    ],
  ),
  _BusinessType(
    code: 'perfumeria',
    name: 'Perfumería',
    icon: Icons.spa,
    color: const Color(0xFFE91E8C),
    productCount: 150,
    categoryNames: const ['Cabello', 'Cuerpo', 'Rostro', 'Maquillaje', 'Fragancias', 'Bebé'],
    brands: const [
      _Brand('Dove', 'https://logos-api.apistemic.com/domain:dove.com'),
      _Brand('Pantene', 'https://logos-api.apistemic.com/domain:pantene.com'),
      _Brand('Nivea', 'https://logos-api.apistemic.com/domain:nivea.com'),
      _Brand('Sedal', 'https://logos-api.apistemic.com/domain:sedal.com.ar'),
      _Brand('Rexona', 'https://logos-api.apistemic.com/domain:rexona.com'),
      _Brand('Maybelline', 'https://logos-api.apistemic.com/domain:maybelline.com'),
      _Brand('Colgate', 'https://logos-api.apistemic.com/domain:colgate.com'),
      _Brand('Head & Shoulders', 'https://logos-api.apistemic.com/domain:headandshoulders.com'),
    ],
  ),
  _BusinessType(
    code: 'panaderia',
    name: 'Panadería',
    icon: Icons.bakery_dining,
    color: const Color(0xFFD4A574),
    productCount: 100,
    categoryNames: const ['Panes', 'Facturas', 'Tortas', 'Galletitas', 'Sandwiches', 'Bebidas'],
    brands: const [
      _Brand('Pureza', 'https://logos-api.apistemic.com/domain:pureza.com.ar'),
      _Brand('Blancaflor', 'https://logos-api.apistemic.com/domain:blancaflor.com.ar'),
      _Brand('Ledesma', 'https://logos-api.apistemic.com/domain:ledesma.com.ar'),
      _Brand('Maizena', 'https://logos-api.apistemic.com/domain:maizena.com'),
      _Brand('Fleischmann', 'https://logos-api.apistemic.com/domain:fleischmann.com.ar'),
    ],
  ),
  _BusinessType(
    code: 'supermercado',
    name: 'Supermercado',
    icon: Icons.shopping_cart,
    color: const Color(0xFF2ECC71),
    productCount: 500,
    categoryNames: const ['Almacén', 'Bebidas', 'Lácteos', 'Carnes', 'Verduras', 'Limpieza', 'Perfumería', 'Congelados', 'Fiambrería', 'Panadería'],
    brands: const [
      _Brand('La Serenísima', 'https://logos-api.apistemic.com/domain:laserenisima.com.ar'),
      _Brand('Arcor', 'https://logos-api.apistemic.com/domain:arcor.com'),
      _Brand('Coca-Cola', 'https://logos-api.apistemic.com/domain:coca-cola.com'),
      _Brand('Unilever', 'https://logos-api.apistemic.com/domain:unilever.com'),
      _Brand('P&G', 'https://logos-api.apistemic.com/domain:pg.com'),
      _Brand('Molinos', 'https://logos-api.apistemic.com/domain:molinos.com.ar'),
      _Brand('Quilmes', 'https://logos-api.apistemic.com/domain:quilmes.com.ar'),
      _Brand('Paladini', 'https://logos-api.apistemic.com/domain:paladini.com.ar'),
    ],
  ),
];
