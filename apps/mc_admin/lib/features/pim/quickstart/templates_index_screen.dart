import 'package:flutter/material.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

/// Catálogo de templates del Quickstart (`/quickstart/templates`).
///
/// Muestra los templates curados base (uno por rubro) que devuelve
/// GET /pim/api/v1/quickstart/templates: icono, nombre, rubro, #categorías,
/// #productos, y al expandir las categorías y marcas del template.
///
/// Es read-only (catálogo). La edición de templates editables por rubro vive en
/// "Tipos de Negocio" → "Ver templates" (/quickstart/templates/:businessTypeId).
class TemplatesIndexScreen extends StatefulWidget {
  final ListQuickstartTemplatesUseCase listTemplates;
  final GetQuickstartTemplateProductsUseCase getProducts;

  const TemplatesIndexScreen({
    super.key,
    required this.listTemplates,
    required this.getProducts,
  });

  @override
  State<TemplatesIndexScreen> createState() => _TemplatesIndexScreenState();
}

class _TemplatesIndexScreenState extends State<TemplatesIndexScreen> {
  late Future<List<QuickstartTemplateSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<QuickstartTemplateSummary>> _load() =>
      widget.listTemplates.execute(status: 'active');

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuickstartTemplateSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorView(
            message: 'No se pudieron cargar los templates: ${snapshot.error}',
            onRetry: _refresh,
          );
        }
        final templates = snapshot.data ?? const [];
        if (templates.isEmpty) {
          return const Center(child: Text('No hay templates disponibles.'));
        }
        return Column(
          children: [
            _Header(count: templates.length, onRefresh: _refresh),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _TemplateCard(
                  template: templates[i],
                  getProducts: widget.getProducts,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onRefresh;

  const _Header({required this.count, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text('Templates del Quickstart',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Chip(
            label: Text('$count'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final QuickstartTemplateSummary template;
  final GetQuickstartTemplateProductsUseCase getProducts;

  const _TemplateCard({required this.template, required this.getProducts});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  // Future cacheado: se dispara una sola vez, en la primera expansión (lazy).
  Future<List<QuickstartTemplateProduct>>? _productsFuture;

  void _onExpansionChanged(bool expanded) {
    if (expanded && _productsFuture == null) {
      setState(() {
        _productsFuture = widget.getProducts.execute(widget.template.slug);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        onExpansionChanged: _onExpansionChanged,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_iconData(template.icon), size: 20),
        ),
        title: Text(template.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          template.description.isNotEmpty
              ? template.description
              : template.slug,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountChip(
                icon: Icons.category_outlined, value: template.totalCategories),
            const SizedBox(width: 6),
            _CountChip(
                icon: Icons.inventory_2_outlined, value: template.totalProducts),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _Section(
            label: 'Categorías (${template.categories.length})',
            chips: template.categories,
          ),
          const SizedBox(height: 12),
          _Section(
            label: 'Marcas (${template.brands.length})',
            chips: template.brands,
          ),
          const SizedBox(height: 12),
          _ProductsSection(future: _productsFuture),
        ],
      ),
    );
  }
}

/// Surtido del template, cargado lazy al expandir. Muestra hasta 30 productos
/// (el backend topea), con loading/empty/error.
class _ProductsSection extends StatelessWidget {
  final Future<List<QuickstartTemplateProduct>>? future;

  const _ProductsSection({required this.future});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(color: Colors.grey[700]);

    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<QuickstartTemplateProduct>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Cargando productos…'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Productos', style: labelStyle),
              const SizedBox(height: 6),
              Text('No se pudieron cargar los productos.',
                  style: TextStyle(color: Colors.grey[500])),
            ],
          );
        }
        final products = snapshot.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Productos (${products.length})', style: labelStyle),
            const SizedBox(height: 6),
            if (products.isEmpty)
              Text('—', style: TextStyle(color: Colors.grey[500]))
            else
              ...products.map((p) => _ProductRow(product: p)),
          ],
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  final QuickstartTemplateProduct product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _ProductThumb(imageUrl: product.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (product.brand.isNotEmpty)
                  Text(product.brand,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String imageUrl;

  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.inventory_2_outlined,
          size: 18, color: Colors.grey[500]),
    );
    if (imageUrl.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int value;

  const _CountChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('$value', style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<String> chips;

  const _Section({required this.label, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 6),
        if (chips.isEmpty)
          Text('—', style: TextStyle(color: Colors.grey[500]))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Mapea el string de icono del backend a un IconData de Material.
IconData _iconData(String name) => switch (name) {
      'store' => Icons.store,
      'storefront' => Icons.storefront,
      'shopping_basket' => Icons.shopping_basket,
      'hardware' => Icons.hardware,
      'restaurant' => Icons.restaurant,
      'set_meal' => Icons.set_meal,
      'toys' => Icons.toys,
      'menu_book' => Icons.menu_book,
      'bakery_dining' => Icons.bakery_dining,
      'content_cut' => Icons.content_cut,
      'waves' => Icons.waves,
      'checkroom' => Icons.checkroom,
      'eco' => Icons.eco,
      'pets' => Icons.pets,
      'ac_unit' => Icons.ac_unit,
      'medical_services' => Icons.medical_services,
      'electrical_services' => Icons.electrical_services,
      'sparkles' => Icons.auto_awesome,
      'zap' => Icons.bolt,
      'wine' => Icons.wine_bar,
      _ => Icons.inventory_2_outlined,
    };
