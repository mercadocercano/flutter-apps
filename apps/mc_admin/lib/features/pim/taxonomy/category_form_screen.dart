import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import 'blocs/category_form_bloc.dart';
import 'blocs/taxonomy_bloc.dart';

class CategoryFormScreen extends StatefulWidget {
  /// Si no es null, modo edición.
  final String? categoryId;

  /// Parent preseleccionado (desde "Agregar subcategoría").
  final String? initialParentId;

  const CategoryFormScreen({
    super.key,
    this.categoryId,
    this.initialParentId,
  });

  bool get isEditing => categoryId != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  String? _selectedParentId;
  bool _isActive = true;
  bool _showParentPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.initialParentId;
    _nameController.addListener(_onNameChanged);

    if (widget.isEditing) {
      _loadCurrentCategory();
    }
  }

  void _loadCurrentCategory() {
    final state = context.read<TaxonomyBloc>().state;
    if (state is TaxonomyLoaded) {
      final found = state.tree.findById(widget.categoryId!);
      if (found != null) _populateForm(found);
    }
  }

  void _populateForm(MarketplaceCategory cat) {
    setState(() {
      _selectedParentId = cat.parentId;
      _isActive = cat.isActive;
    });
    _nameController.text = cat.name;
    _slugController.text = cat.slug;
    _descriptionController.text = cat.description ?? '';
    _sortOrderController.text = cat.sortOrder.toString();
  }

  void _onNameChanged() {
    final slug = _nameController.text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    _slugController.text = slug;
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String text) =>
      text.trim().isEmpty ? null : text.trim();

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    if (widget.isEditing) {
      context.read<CategoryFormBloc>().add(SubmitUpdateCategoryEvent(
            id: widget.categoryId!,
            params: UpdateCategoryParams(
              name: _nameController.text.trim(),
              slug: _slugController.text.trim(),
              description: _nullIfEmpty(_descriptionController.text),
              parentId: _selectedParentId,
              isActive: _isActive,
              sortOrder: sortOrder,
            ),
          ));
    } else {
      context.read<CategoryFormBloc>().add(SubmitCreateCategoryEvent(
            CreateCategoryParams(
              name: _nameController.text.trim(),
              slug: _slugController.text.trim(),
              description: _nullIfEmpty(_descriptionController.text),
              parentId: _selectedParentId,
              sortOrder: sortOrder,
              isActive: _isActive,
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryFormBloc, CategoryFormState>(
      listener: (context, state) {
        if (state is CategoryFormSuccess) {
          AdminSnackbars.showSuccess(
            context,
            widget.isEditing
                ? 'Categoría actualizada correctamente'
                : 'Categoría creada correctamente',
          );
          context.go('/pim/taxonomy');
        } else if (state is CategoryFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<CategoryFormBloc, CategoryFormState>(
        builder: (context, state) {
          final isLoading = state is CategoryFormSubmitting;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing
                ? 'Editar Categoría'
                : 'Nueva Categoría',
            isLoading: isLoading,
            errorMessage:
                state is CategoryFormError ? state.message : null,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildNameField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildSlugField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildDescriptionField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildSortOrderField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildActiveSwitch(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildParentSelector(context, enabled: !isLoading),
              if (_showParentPicker) ...[
                const SizedBox(height: 12),
                _buildParentPicker(context),
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

  Widget _buildSlugField({required bool enabled}) {
    return TextFormField(
      controller: _slugController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Slug *',
        border: OutlineInputBorder(),
        helperText: 'Identificador URL (auto-generado desde el nombre)',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Slug es obligatorio';
        return null;
      },
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

  Widget _buildSortOrderField({required bool enabled}) {
    return TextFormField(
      controller: _sortOrderController,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Orden',
        border: OutlineInputBorder(),
        helperText: 'Orden de aparición (menor número = primero)',
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
          return 'Debe ser un número entero';
        }
        return null;
      },
    );
  }

  Widget _buildActiveSwitch({required bool enabled}) {
    return SwitchListTile(
      title: const Text('Activa'),
      subtitle: const Text('Las categorías inactivas no se muestran'),
      value: _isActive,
      onChanged: enabled ? (v) => setState(() => _isActive = v) : null,
    );
  }

  Widget _buildParentSelector(BuildContext context, {required bool enabled}) {
    final parentName = _resolveParentName(context);

    return InkWell(
      onTap: enabled
          ? () => setState(() => _showParentPicker = !_showParentPicker)
          : null,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Categoría padre (opcional)',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                parentName ?? 'Sin categoría padre (raíz)',
                style: TextStyle(
                  color: parentName == null ? Colors.grey : null,
                ),
              ),
            ),
            Icon(
              _showParentPicker
                  ? Icons.expand_less
                  : Icons.expand_more,
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveParentName(BuildContext context) {
    if (_selectedParentId == null) return null;
    final treeState = context.watch<TaxonomyBloc>().state;
    if (treeState is TaxonomyLoaded) {
      return treeState.tree.findById(_selectedParentId!)?.name;
    }
    return _selectedParentId;
  }

  Widget _buildParentPicker(BuildContext context) {
    final treeState = context.read<TaxonomyBloc>().state;
    if (treeState is! TaxonomyLoaded) {
      return const CircularProgressIndicator();
    }

    return Card(
      elevation: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Sin padre (categoría raíz)'),
                selected: _selectedParentId == null,
                onTap: () => setState(() {
                  _selectedParentId = null;
                  _showParentPicker = false;
                }),
              ),
              const Divider(height: 1),
              _ParentPickerTree(
                categories: treeState.tree.roots,
                selectedId: _selectedParentId,
                excludeId: widget.categoryId,
                onSelect: (id) => setState(() {
                  _selectedParentId = id;
                  _showParentPicker = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentPickerTree extends StatelessWidget {
  final List<MarketplaceCategory> categories;
  final String? selectedId;

  /// Id del nodo que se está editando — excluido del picker para evitar ciclos.
  final String? excludeId;
  final ValueChanged<String> onSelect;

  const _ParentPickerTree({
    required this.categories,
    this.selectedId,
    this.excludeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categories
          .where((c) => c.id != excludeId)
          .map((cat) => _PickerTile(
                category: cat,
                selectedId: selectedId,
                excludeId: excludeId,
                onSelect: onSelect,
              ))
          .toList(),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final MarketplaceCategory category;
  final String? selectedId;
  final String? excludeId;
  final ValueChanged<String> onSelect;

  const _PickerTile({
    required this.category,
    this.selectedId,
    this.excludeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final indent = category.level * 16.0;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16 + indent, right: 16),
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
          _ParentPickerTree(
            categories: category.children,
            selectedId: selectedId,
            excludeId: excludeId,
            onSelect: onSelect,
          ),
      ],
    );
  }
}
