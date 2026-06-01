import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../taxonomy/blocs/taxonomy_bloc.dart';
import 'blocs/product_form_bloc.dart';

class ProductFormScreen extends StatefulWidget {
  /// Si no es null, modo edición.
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;
  List<String> _selectedBusinessTypeIds = [];
  List<_AttributeEntry> _attributes = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      context.read<ProductFormBloc>().add(LoadProductEvent(widget.productId!));
    }
    context.read<TaxonomyBloc>().add(LoadTaxonomyEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _populateForm(GlobalProduct product) {
    _nameController.text = product.name;
    _skuController.text = product.sku;
    _barcodeController.text = product.barcode ?? '';
    _descriptionController.text = product.description ?? '';
    _imageUrlController.text = product.imageUrl ?? '';
    setState(() {
      _selectedCategoryId = product.categoryId;
      _selectedBusinessTypeIds = List.from(product.businessTypeIds);
      _attributes = product.attributes.entries
          .map((e) => _AttributeEntry(
                key: e.key,
                value: e.value?.toString() ?? '',
              ))
          .toList();
    });
  }

  String? _nullIfEmpty(String text) =>
      text.trim().isEmpty ? null : text.trim();

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final attribMap = <String, dynamic>{
      for (final a in _attributes)
        if (a.key.trim().isNotEmpty) a.key.trim(): a.value.trim(),
    };

    final now = DateTime.now();
    final product = GlobalProduct(
      id: widget.productId ?? '',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _nullIfEmpty(_barcodeController.text),
      description: _nullIfEmpty(_descriptionController.text),
      imageUrl: _nullIfEmpty(_imageUrlController.text),
      categoryId: _selectedCategoryId,
      businessTypeIds: _selectedBusinessTypeIds,
      attributes: attribMap,
      createdAt: now,
      updatedAt: now,
    );

    if (widget.isEditing) {
      context
          .read<ProductFormBloc>()
          .add(SubmitUpdateProductEvent(product));
    } else {
      context
          .read<ProductFormBloc>()
          .add(SubmitCreateProductEvent(product));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormBloc, ProductFormState>(
      listener: _onFormStateChange,
      child: BlocBuilder<ProductFormBloc, ProductFormState>(
        builder: (context, state) {
          if (state is ProductFormLoaded && widget.isEditing) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _populateForm(state.product),
            );
          }

          final isLoading =
              state is ProductFormLoading || state is ProductFormSubmitting;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Producto' : 'Nuevo Producto',
            isLoading: isLoading,
            errorMessage:
                state is ProductFormError ? state.message : null,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildNameField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildSkuField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildBarcodeField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildDescriptionField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildImageUrlField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildCategorySelector(context, enabled: !isLoading),
              const SizedBox(height: 16),
              _buildBusinessTypesSelector(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildAttributesSection(enabled: !isLoading),
              if (widget.isEditing) ...[
                const SizedBox(height: 24),
                _buildDeleteButton(context, enabled: !isLoading),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNameField({required bool enabled}) {
    return TextFormField(
      controller: _nameController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Nombre *',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Nombre es obligatorio';
        return null;
      },
    );
  }

  Widget _buildSkuField({required bool enabled}) {
    return TextFormField(
      controller: _skuController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'SKU *',
        border: OutlineInputBorder(),
        helperText: 'Identificador único del producto',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'SKU es obligatorio';
        return null;
      },
    );
  }

  Widget _buildBarcodeField({required bool enabled}) {
    return TextFormField(
      controller: _barcodeController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Código de barras',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField({required bool enabled}) {
    return TextFormField(
      controller: _descriptionController,
      enabled: enabled,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImageUrlField({required bool enabled}) {
    return TextFormField(
      controller: _imageUrlController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'URL de imagen',
        border: OutlineInputBorder(),
        hintText: 'https://cdn.example.com/product.png',
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context,
      {required bool enabled}) {
    return BlocBuilder<TaxonomyBloc, TaxonomyState>(
      builder: (context, state) {
        final categoryName = _resolveCategoryName(state);
        return InkWell(
          onTap: enabled && state is TaxonomyLoaded
              ? () => _showCategoryPicker(context, state)
              : null,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName ?? 'Sin categoría',
                    style: TextStyle(
                      color: categoryName == null ? Colors.grey : null,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _resolveCategoryName(TaxonomyState state) {
    if (_selectedCategoryId == null) return null;
    if (state is TaxonomyLoaded) {
      return state.tree.findById(_selectedCategoryId!)?.name;
    }
    return _selectedCategoryId;
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    TaxonomyLoaded state,
  ) async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) => _CategoryPickerDialog(
        tree: state.tree,
        selectedId: _selectedCategoryId,
      ),
    );
    if (selected != null) {
      setState(() => _selectedCategoryId = selected);
    } else if (selected == null && mounted) {
      setState(() => _selectedCategoryId = null);
    }
  }

  Widget _buildBusinessTypesSelector({required bool enabled}) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Tipos de comercio',
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedBusinessTypeIds.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _selectedBusinessTypeIds
                  .map(
                    (id) => Chip(
                      label: Text(id, style: const TextStyle(fontSize: 12)),
                      onDeleted: enabled
                          ? () => setState(
                                () => _selectedBusinessTypeIds.remove(id),
                              )
                          : null,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          if (enabled)
            TextButton.icon(
              onPressed: () => _addBusinessType(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar tipo'),
            ),
        ],
      ),
    );
  }

  Future<void> _addBusinessType(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar tipo de comercio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ID del tipo de comercio',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_selectedBusinessTypeIds.contains(result)) {
          _selectedBusinessTypeIds = [..._selectedBusinessTypeIds, result];
        }
      });
    }
  }

  Widget _buildAttributesSection({required bool enabled}) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Atributos',
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._attributes.asMap().entries.map(
                (entry) => _AttributeRow(
                  entry: entry.value,
                  enabled: enabled,
                  onChanged: (key, value) {
                    setState(() {
                      _attributes[entry.key] =
                          _AttributeEntry(key: key, value: value);
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _attributes = List.from(_attributes)
                        ..removeAt(entry.key);
                    });
                  },
                ),
              ),
          if (enabled)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _attributes = [
                    ..._attributes,
                    _AttributeEntry(key: '', value: ''),
                  ];
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar atributo'),
            ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, {required bool enabled}) {
    return OutlinedButton.icon(
      onPressed: enabled ? () => _confirmDelete(context) : null,
      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
      label: Text('Eliminar producto',
          style: TextStyle(color: Colors.red[700])),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.red[300]!),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar producto',
      message:
          '¿Eliminar "${_nameController.text}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<ProductFormBloc>()
          .add(DeleteProductEvent(widget.productId!));
    }
  }

  void _onFormStateChange(BuildContext context, ProductFormState state) {
    if (state is ProductFormSuccess) {
      AdminSnackbars.showSuccess(
        context,
        widget.isEditing
            ? 'Producto actualizado correctamente'
            : 'Producto creado correctamente',
      );
      context.go('/pim/global-catalog');
    } else if (state is ProductFormDeleted) {
      AdminSnackbars.showSuccess(context, 'Producto eliminado');
      context.go('/pim/global-catalog');
    } else if (state is ProductFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// --- Entrada mutable para atributos ---

class _AttributeEntry {
  final String key;
  final String value;

  _AttributeEntry({required this.key, required this.value});
}

// --- Fila de atributo clave-valor ---

class _AttributeRow extends StatefulWidget {
  final _AttributeEntry entry;
  final bool enabled;
  final void Function(String key, String value) onChanged;
  final VoidCallback onRemove;

  const _AttributeRow({
    required this.entry,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_AttributeRow> createState() => _AttributeRowState();
}

class _AttributeRowState extends State<_AttributeRow> {
  late final TextEditingController _keyController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.entry.key);
    _valueController = TextEditingController(text: widget.entry.value);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _keyController,
              enabled: widget.enabled,
              onChanged: (v) =>
                  widget.onChanged(v, _valueController.text),
              decoration: const InputDecoration(
                labelText: 'Clave',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _valueController,
              enabled: widget.enabled,
              onChanged: (v) =>
                  widget.onChanged(_keyController.text, v),
              decoration: const InputDecoration(
                labelText: 'Valor',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          if (widget.enabled)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.red[700]),
              onPressed: widget.onRemove,
              tooltip: 'Eliminar atributo',
            ),
        ],
      ),
    );
  }
}

// --- Dialog para seleccionar categoría ---

class _CategoryPickerDialog extends StatelessWidget {
  final CategoryTree tree;
  final String? selectedId;

  const _CategoryPickerDialog({
    required this.tree,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar categoría'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 360,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Sin categoría'),
                selected: selectedId == null,
                onTap: () => Navigator.of(context).pop(''),
              ),
              const Divider(height: 1),
              _CategoryPickerTree(
                categories: tree.roots,
                selectedId: selectedId,
                onSelect: (id) => Navigator.of(context).pop(id),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _CategoryPickerTree extends StatelessWidget {
  final List<MarketplaceCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CategoryPickerTree({
    required this.categories,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categories
          .map(
            (cat) => _CategoryPickerTile(
              category: cat,
              selectedId: selectedId,
              onSelect: onSelect,
            ),
          )
          .toList(),
    );
  }
}

class _CategoryPickerTile extends StatelessWidget {
  final MarketplaceCategory category;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CategoryPickerTile({
    required this.category,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final indent = category.level * 16.0;
    return Column(
      children: [
        ListTile(
          contentPadding:
              EdgeInsets.only(left: 16 + indent, right: 16),
          leading: Icon(
            category.hasChildren
                ? Icons.folder_outlined
                : Icons.label_outline,
            size: 18,
          ),
          title: Text(category.name),
          selected: selectedId == category.id,
          onTap: () => onSelect(category.id),
        ),
        if (category.hasChildren)
          _CategoryPickerTree(
            categories: category.children,
            selectedId: selectedId,
            onSelect: onSelect,
          ),
      ],
    );
  }
}
