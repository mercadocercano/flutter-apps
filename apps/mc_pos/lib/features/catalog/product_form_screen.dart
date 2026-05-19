import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/product_card_pos.dart' show fmtAR;
import '../../widgets/pos/pos_modal.dart';

/// Formulario de creación / edición de producto.
/// Si [editing] es null → crea. Sino → edita.
class ProductFormScreen extends StatefulWidget {
  final Product? editing;

  const ProductFormScreen({super.key, this.editing});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _categoryId;
  String? _categoryName;
  String? _brandId;
  String? _brandName;

  List<Category> _categories = [];
  List<Brand> _brands = [];

  bool _loading = false;
  bool _loadingMeta = true;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.editing!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _categoryName = p.categoryName;
      _brandName = p.brandName;
    }
    _loadMeta();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final cats = await context.read<CategoryPort>().listCategories(pageSize: 200);
      final brandPage = await context.read<BrandPort>().listBrands(pageSize: 200);
      if (!mounted) return;
      setState(() {
        _categories = cats.where((c) => c.active).toList();
        _brands = brandPage.items.where((b) => b.isActive).toList();
        // Resolver IDs desde los nombres pre-cargados (edit mode)
        if (_isEdit) {
          final matchCat = _categories
              .where((c) => c.name == widget.editing!.categoryName)
              .firstOrNull;
          final matchBrand = _brands
              .where((b) => b.name == widget.editing!.brandName)
              .firstOrNull;
          _categoryId = matchCat?.id;
          _brandId = matchBrand?.id;
        }
        _loadingMeta = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('El nombre es obligatorio');
      return;
    }
    setState(() => _loading = true);
    try {
      final catalog = context.read<CatalogPort>();
      if (!_isEdit) {
        await catalog.createProduct(
          name: name,
          description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
          categoryId: _categoryId,
          brandId: _brandId,
        );
      } else {
        await catalog.updateProduct(
          productId: widget.editing!.id,
          name: name,
          description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
          categoryId: _categoryId,
          brandId: _brandId,
          status: widget.editing!.status.name,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('No pudimos guardar el producto. Intentá de nuevo.');
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showPosConfirm(
      context: context,
      title: 'Eliminar producto',
      message: '¿Eliminar "${widget.editing!.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      confirmColor: McColors.error,
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await context.read<CatalogPort>().deleteProduct(widget.editing!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('No pudimos eliminar el producto. Intentá de nuevo.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: McColors.error),
    );
  }

  void _showCategoryPicker() {
    _showPickerSheet(
      title: 'Categoría',
      items: _categories.map((c) => (id: c.id, name: c.name)).toList(),
      selectedId: _categoryId,
      onSelect: (id, name) => setState(() {
        _categoryId = id;
        _categoryName = name;
      }),
      onClear: () => setState(() {
        _categoryId = null;
        _categoryName = null;
      }),
    );
  }

  void _showBrandPicker() {
    _showPickerSheet(
      title: 'Marca',
      items: _brands.map((b) => (id: b.id, name: b.name)).toList(),
      selectedId: _brandId,
      onSelect: (id, name) => setState(() {
        _brandId = id;
        _brandName = name;
      }),
      onClear: () => setState(() {
        _brandId = null;
        _brandName = null;
      }),
    );
  }

  void _showPickerSheet({
    required String title,
    required List<({String id, String name})> items,
    required String? selectedId,
    required void Function(String id, String name) onSelect,
    required VoidCallback onClear,
  }) {
    final searchCtrl = TextEditingController();
    showPosModal(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setInner) {
          final filtered = items
              .where((i) =>
                  i.name.toLowerCase().contains(searchCtrl.text.toLowerCase()))
              .toList();
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: McColors.foregroundLight,
                        ),
                      ),
                      const Spacer(),
                      if (selectedId != null)
                        TextButton(
                          onPressed: () {
                            onClear();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Quitar',
                            style: TextStyle(color: McColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: McTextField(
                    controller: searchCtrl,
                    hint: 'Buscar $title...',
                    prefixIcon: Icons.search,
                    onChanged: (_) => setInner(() {}),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 8),
                // Lista
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final isSelected = item.id == selectedId;
                      return ListTile(
                        tileColor: Colors.transparent,
                        title: Text(
                          item.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? McColors.primary
                                : McColors.foregroundLight,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: McColors.primary, size: 20)
                            : null,
                        onTap: () {
                          onSelect(item.id, item.name);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: Column(
        children: [
          // Top bar
          PosTopBar(
            title: _isEdit ? 'Editar producto' : 'Nuevo producto',
            subtitle: _isEdit ? widget.editing!.name : 'Carga manual',
            leading: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: McColors.mutedLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(38, 38),
              ),
            ),
            trailing: _isEdit
                ? TextButton(
                    onPressed: _loading ? null : _delete,
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(
                        color: McColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                : null,
          ),

          if (_loadingMeta)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header foto (edit) ──────────────────────────────
                    if (_isEdit) _buildPhotoHeader(),

                    const SizedBox(height: 4),

                    // ─── Sección datos básicos ───────────────────────────
                    _buildSection(
                      title: 'Información básica',
                      children: [
                        _LabeledField(
                          label: 'Nombre del producto *',
                          child: McTextField(
                            controller: _nameCtrl,
                            hint: 'Ej: Coca Cola 500ml',
                            autofocus: !_isEdit,
                          ),
                        ),
                        const SizedBox(height: McSpacing.md),
                        _LabeledField(
                          label: 'Descripción (opcional)',
                          child: McTextField(
                            controller: _descCtrl,
                            hint: 'Descripción breve del producto',
                          ),
                        ),
                      ],
                    ),

                    // ─── Categoría y marca ───────────────────────────────
                    _buildSection(
                      title: 'Clasificación',
                      children: [
                        _LabeledField(
                          label: 'Categoría',
                          child: _PickerTile(
                            value: _categoryName,
                            placeholder: 'Seleccionar categoría',
                            icon: Icons.label_outline,
                            onTap: _categories.isNotEmpty
                                ? _showCategoryPicker
                                : null,
                          ),
                        ),
                        const SizedBox(height: McSpacing.md),
                        _LabeledField(
                          label: 'Marca',
                          child: _PickerTile(
                            value: _brandName,
                            placeholder: 'Seleccionar marca',
                            icon: Icons.storefront_outlined,
                            onTap: _brands.isNotEmpty ? _showBrandPicker : null,
                          ),
                        ),
                      ],
                    ),

                    // ─── Variantes / presentaciones ──────────────────────
                    if (_isEdit && widget.editing!.variants.isNotEmpty)
                      _buildVariantsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

          // ─── Footer CTA ────────────────────────────────────────────────
          _buildFooter(),
        ],
      ),
    );
  }

  // ─── Widgets internos ──────────────────────────────────────────────────────

  Widget _buildPhotoHeader() {
    final p = widget.editing!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Foto
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: McColors.mutedLight,
                  borderRadius: BorderRadius.circular(McSpacing.radiusLg),
                  border: Border.all(color: McColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                    ? Image.network(
                        p.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: McColors.textSecondaryLight,
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: McColors.textSecondaryLight,
                      ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: McColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 14,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.brandName != null) ...[
                  McBrandChip(
                    brandName: p.brandName!,
                    palette: McBrandPalette.fromBrandDto(
                      brightness: Theme.of(context).brightness,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: McColors.foregroundLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (p.categoryName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.categoryName!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: McColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        border: Border.all(color: McColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: McColors.textSecondaryLight,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    final variants = widget.editing!.variants
        .where((v) => v.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        border: Border.all(color: McColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  'PRESENTACIONES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: McColors.textSecondaryLight,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: McColors.cobaltTint,
                    borderRadius: BorderRadius.circular(McSpacing.radiusFull),
                  ),
                  child: Text(
                    '${variants.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: McColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...variants.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(
                      height: 1, color: McColors.borderLight,
                      indent: 16, endIndent: 16),
                _VariantTile(variant: v),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final valid = _nameCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: McColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: _isEdit
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(McSpacing.radiusLg),
                        ),
                        side: const BorderSide(color: McColors.borderLight),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: McColors.textFg2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: McButton(
                      label: 'Guardar cambios',
                      icon: Icons.check,
                      size: McButtonSize.lg,
                      expand: true,
                      isLoading: _loading,
                      onPressed: valid && !_loading ? _save : null,
                    ),
                  ),
                ],
              )
            : McButton(
                label: 'Crear producto',
                icon: Icons.add,
                size: McButtonSize.lg,
                expand: true,
                isLoading: _loading,
                onPressed: valid && !_loading ? _save : null,
              ),
      ),
    );
  }
}

// ─── Widgets de apoyo ──────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: McColors.textFg2,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onTap;

  const _PickerTile({
    required this.placeholder,
    required this.icon,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasValue ? McColors.primary : const Color(0xFFE2E8F0),
            width: hasValue ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(McSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: hasValue ? McColors.primary : McColors.textSecondaryLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: hasValue
                      ? McColors.foregroundLight
                      : McColors.textSecondaryLight,
                  fontWeight:
                      hasValue ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: McColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  final ProductVariant variant;

  const _VariantTile({required this.variant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Icono variante
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: McColors.cobaltTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers_outlined,
                size: 18, color: McColors.primary),
          ),
          const SizedBox(width: 12),
          // Nombre + SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: McColors.foregroundLight,
                  ),
                ),
                if (variant.sku != null)
                  Text(
                    variant.sku!.value,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: McColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          // Precio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtAR(variant.price.amount),
                style: McTypography.mono(15, color: McColors.primary),
              ),
              if (variant.stock > 0)
                Text(
                  '${variant.stock} en stock',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: McColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  'Sin stock',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: McColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
