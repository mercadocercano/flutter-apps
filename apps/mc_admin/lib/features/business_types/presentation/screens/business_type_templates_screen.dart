import 'package:flutter/material.dart';

import '../../data/business_types_repository.dart';
import '../../domain/models/business_type_model.dart';
import '../../domain/models/business_type_template_model.dart';
import '../../../../core/api/kong_client.dart';

class BusinessTypeTemplatesScreen extends StatefulWidget {
  final BusinessType businessType;

  const BusinessTypeTemplatesScreen({super.key, required this.businessType});

  @override
  State<BusinessTypeTemplatesScreen> createState() =>
      _BusinessTypeTemplatesScreenState();
}

class _BusinessTypeTemplatesScreenState
    extends State<BusinessTypeTemplatesScreen> {
  late final BusinessTypesRepository _repository;

  List<BusinessTypeTemplate>? _templates;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repository = BusinessTypesRepository(KongClient());
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final templates = await _repository.getTemplates(widget.businessType.id);
      setState(() => _templates = templates);
    } catch (e) {
      setState(() => _error = 'Error al cargar templates: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save(BusinessTypeTemplate updated) async {
    try {
      final saved = await _repository.updateTemplate(updated);
      setState(() {
        final idx = _templates!.indexWhere((t) => t.id == saved.id);
        if (idx >= 0) _templates![idx] = saved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template guardado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_templates == null || _templates!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sin templates configurados.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showCreateTemplateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Crear template'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _templates!.map((t) => _TemplateEditor(
          template: t,
          onSave: _save,
        )).toList(),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    // TODO: Implement create template dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función en desarrollo')),
    );
  }
}

// ─── Template editor widget ───────────────────────────────────────────────────

class _TemplateEditor extends StatefulWidget {
  final BusinessTypeTemplate template;
  final Future<void> Function(BusinessTypeTemplate) onSave;

  const _TemplateEditor({required this.template, required this.onSave});

  @override
  State<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<_TemplateEditor> {
  late BusinessTypeTemplate _local;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _local = widget.template;
  }

  void _markDirty(BusinessTypeTemplate updated) {
    setState(() { _local = updated; _dirty = true; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_local);
      setState(() => _dirty = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_local.name,
                              style: Theme.of(context).textTheme.titleSmall),
                          if (_local.isDefault) ...[
                            const SizedBox(width: 8),
                            _StatusBadge(label: 'DEFAULT', color: Colors.green),
                          ],
                          if (_dirty) ...[
                            const SizedBox(width: 8),
                            _StatusBadge(label: 'SIN GUARDAR', color: Colors.orange),
                          ],
                        ],
                      ),
                      Text('v${_local.version} · ${_local.region}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                if (_dirty)
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 16),
                    label: const Text('Guardar'),
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
          ),

          // ─── Summary chips ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _CountChip(Icons.category_outlined, _local.categories.length, 'categorías'),
                _CountChip(Icons.label_outline, _local.brands.length, 'marcas'),
                _CountChip(Icons.inventory_2_outlined, _local.products.length, 'productos'),
              ],
            ),
          ),

          const Divider(height: 1),

          // ─── Sections ─────────────────────────────────────────────────────────
          _CategoriesSection(
            categories: _local.categories,
            onChanged: (cats) => _markDirty(_local.copyWith(categories: cats)),
          ),
          _BrandsSection(
            brands: _local.brands,
            onChanged: (brands) => _markDirty(_local.copyWith(brands: brands)),
          ),
          _ProductsSection(
            products: _local.products,
            onChanged: (products) => _markDirty(_local.copyWith(products: products)),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Categories section ───────────────────────────────────────────────────────

class _CategoriesSection extends StatefulWidget {
  final List<CategoryTemplateItem> categories;
  final void Function(List<CategoryTemplateItem>) onChanged;

  const _CategoriesSection({required this.categories, required this.onChanged});

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.category_outlined,
          title: 'Categorías',
          count: widget.categories.length,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          onAdd: () => _showAddDialog(),
        ),
        if (_expanded) ...[
          ...widget.categories.asMap().entries.map((entry) {
            final cat = entry.value;
            return _DismissibleItem(
              key: Key('cat-${cat.slug}-${entry.key}'),
              onDismiss: () {
                final updated = List<CategoryTemplateItem>.from(widget.categories)
                  ..removeAt(entry.key);
                widget.onChanged(updated);
              },
              child: Padding(
                padding: EdgeInsets.only(
                    left: 16.0 + cat.level * 12, right: 8, bottom: 4, top: 4),
                child: Row(
                  children: [
                    Icon(
                      cat.level == 0 ? Icons.folder_outlined : Icons.subdirectory_arrow_right,
                      size: 14,
                      color: cat.level == 0 ? Colors.blueGrey : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: cat.level == 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(cat.slug,
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<CategoryTemplateItem>(
      context: context,
      builder: (ctx) => const _AddCategoryDialog(),
    );
    if (result != null) {
      widget.onChanged([...widget.categories, result]);
    }
  }
}

// ─── Brands section ───────────────────────────────────────────────────────────

class _BrandsSection extends StatefulWidget {
  final List<BrandTemplateItem> brands;
  final void Function(List<BrandTemplateItem>) onChanged;

  const _BrandsSection({required this.brands, required this.onChanged});

  @override
  State<_BrandsSection> createState() => _BrandsSectionState();
}

class _BrandsSectionState extends State<_BrandsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.label_outline,
          title: 'Marcas',
          count: widget.brands.length,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          onAdd: () => _showAddDialog(),
        ),
        if (_expanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.brands.asMap().entries.map((entry) {
                return _BrandCard(
                  brand: entry.value,
                  onDelete: () {
                    final updated = List<BrandTemplateItem>.from(widget.brands)
                      ..removeAt(entry.key);
                    widget.onChanged(updated);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<BrandTemplateItem>(
      context: context,
      builder: (ctx) => const _AddBrandDialog(),
    );
    if (result != null) {
      widget.onChanged([...widget.brands, result]);
    }
  }
}

class _BrandCard extends StatelessWidget {
  final BrandTemplateItem brand;
  final VoidCallback onDelete;

  const _BrandCard({required this.brand, required this.onDelete});

  Color get _avatarColor {
    final hash = brand.name.codeUnits.fold(0, (a, b) => a + b);
    const colors = [
      Color(0xFF4F46E5), Color(0xFF0891B2), Color(0xFF16A34A),
      Color(0xFFDC2626), Color(0xFFD97706), Color(0xFF7C3AED),
      Color(0xFFDB2777), Color(0xFF0F766E),
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 160),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 24, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _avatarColor,
                  child: Text(
                    brand.name.isNotEmpty ? brand.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    brand.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(12),
              child: const Icon(Icons.close, size: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Products section ─────────────────────────────────────────────────────────

class _ProductsSection extends StatefulWidget {
  final List<ProductTemplateItem> products;
  final void Function(List<ProductTemplateItem>) onChanged;

  const _ProductsSection({required this.products, required this.onChanged});

  @override
  State<_ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<_ProductsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.inventory_2_outlined,
          title: 'Productos sugeridos',
          count: widget.products.length,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          onAdd: () => _showAddDialog(),
        ),
        if (_expanded) ...[
          ...widget.products.asMap().entries.map((entry) {
            return _DismissibleItem(
              key: Key('prod-${entry.key}'),
              onDismiss: () {
                final updated = List<ProductTemplateItem>.from(widget.products)
                  ..removeAt(entry.key);
                widget.onChanged(updated);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: _ProductRow(product: entry.value),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<ProductTemplateItem>(
      context: context,
      builder: (ctx) => const _AddProductDialog(),
    );
    if (result != null) {
      widget.onChanged([...widget.products, result]);
    }
  }
}

class _ProductRow extends StatelessWidget {
  final ProductTemplateItem product;

  const _ProductRow({required this.product});

  Color get _categoryColor {
    final slug = product.categorySlug ?? '';
    if (slug.contains('bebida') || slug.contains('gaseosa') || slug.contains('cerveza')) {
      return const Color(0xFF0891B2);
    }
    if (slug.contains('lacteo') || slug.contains('leche')) return const Color(0xFF7C3AED);
    if (slug.contains('limpieza')) return const Color(0xFF0F766E);
    if (slug.contains('golosina') || slug.contains('snack')) return const Color(0xFFD97706);
    if (slug.contains('panaderia') || slug.contains('pan')) return const Color(0xFFDC2626);
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Image / placeholder
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _categoryColor.withValues(alpha: 0.2)),
          ),
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _a, _b) => Icon(
                      Icons.shopping_bag_outlined,
                      size: 20,
                      color: _categoryColor,
                    ),
                  ),
                )
              : Icon(Icons.shopping_bag_outlined, size: 20, color: _categoryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                [
                  if (product.brand?.isNotEmpty == true) product.brand!,
                  if (product.categorySlug?.isNotEmpty == true) product.categorySlug!,
                ].join(' · '),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (product.priceReference != null && product.priceReference! > 0)
          Text(
            '\$${product.priceReference!.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500),
          ),
      ],
    );
  }
}

// ─── Add dialogs ──────────────────────────────────────────────────────────────

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _parentSlugCtrl = TextEditingController();
  int _level = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _parentSlugCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar categoría'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Nombre *', hintText: 'ej: Bebidas'),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _slugCtrl,
            decoration: const InputDecoration(
                labelText: 'Slug *', hintText: 'ej: bebidas'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Nivel: '),
              DropdownButton<int>(
                value: _level,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0 – Raíz')),
                  DropdownMenuItem(value: 1, child: Text('1 – Sub')),
                  DropdownMenuItem(value: 2, child: Text('2 – Sub-sub')),
                ],
                onChanged: (v) => setState(() => _level = v ?? 0),
              ),
            ],
          ),
          if (_level > 0) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _parentSlugCtrl,
              decoration: const InputDecoration(
                  labelText: 'Slug padre', hintText: 'ej: bebidas'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _nameCtrl.text.isEmpty || _slugCtrl.text.isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    CategoryTemplateItem(
                      name: _nameCtrl.text.trim(),
                      slug: _slugCtrl.text.trim().toLowerCase(),
                      level: _level,
                      parentSlug: _parentSlugCtrl.text.trim().isNotEmpty
                          ? _parentSlugCtrl.text.trim()
                          : null,
                    ),
                  );
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _AddBrandDialog extends StatefulWidget {
  const _AddBrandDialog();

  @override
  State<_AddBrandDialog> createState() => _AddBrandDialogState();
}

class _AddBrandDialogState extends State<_AddBrandDialog> {
  final _nameCtrl = TextEditingController();
  final _catsCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar marca'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Nombre de la marca *', hintText: 'ej: Coca Cola'),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _catsCtrl,
            decoration: const InputDecoration(
              labelText: 'Categorías (separadas por coma)',
              hintText: 'ej: bebidas, gaseosas',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _nameCtrl.text.isEmpty
              ? null
              : () {
                  final cats = _catsCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  Navigator.pop(
                    context,
                    BrandTemplateItem(
                      name: _nameCtrl.text.trim(),
                      suggestedForCategories: cats,
                    ),
                  );
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog();

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar producto sugerido'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *', hintText: 'ej: Coca Cola 1.5L'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                  labelText: 'Marca', hintText: 'ej: Coca Cola'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                  labelText: 'Slug de categoría', hintText: 'ej: gaseosas'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Precio ref.', prefixText: '\$'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Unidad', hintText: 'unidad'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _nameCtrl.text.isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    ProductTemplateItem(
                      name: _nameCtrl.text.trim(),
                      brand: _brandCtrl.text.trim().isNotEmpty
                          ? _brandCtrl.text.trim()
                          : null,
                      categorySlug: _categoryCtrl.text.trim().isNotEmpty
                          ? _categoryCtrl.text.trim()
                          : null,
                      priceReference: double.tryParse(_priceCtrl.text),
                      unit: _unitCtrl.text.trim().isNotEmpty
                          ? _unitCtrl.text.trim()
                          : 'unidad',
                    ),
                  );
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _CountChip(this.icon, this.count, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text('$count $label',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              '$title ($count)',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.blueGrey.shade700),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: onAdd,
              color: Colors.blueGrey,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Agregar',
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissibleItem extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _DismissibleItem({super.key, required this.child, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar?'),
            content: const Text('Este item será eliminado del template.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Eliminar')),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDismiss(),
      child: child,
    );
  }
}
