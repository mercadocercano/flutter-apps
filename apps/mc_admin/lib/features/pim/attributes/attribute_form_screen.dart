import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/attribute_form_bloc.dart';
import 'blocs/attribute_values_bloc.dart';

class AttributeFormScreen extends StatefulWidget {
  /// Si no es null, modo edición.
  final String? attributeId;

  const AttributeFormScreen({super.key, this.attributeId});

  bool get isEditing => attributeId != null;

  @override
  State<AttributeFormScreen> createState() => _AttributeFormScreenState();
}

class _AttributeFormScreenState extends State<AttributeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();

  AttributeType _selectedType = AttributeType.text;
  bool _isRequired = false;
  bool _isFilterable = false;
  bool _slugEdited = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      context
          .read<AttributeFormBloc>()
          .add(LoadAttributeEvent(widget.attributeId!));
    }
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_slugEdited) {
      _slugController.text = _generateSlug(_nameController.text);
    }
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  void _populateForm(MarketplaceAttribute attribute) {
    _nameController.text = attribute.name;
    _slugController.text = attribute.slug;
    _descriptionController.text = attribute.description ?? '';
    setState(() {
      _selectedType = attribute.type;
      _isRequired = attribute.isRequired;
      _isFilterable = attribute.isFilterable;
      _slugEdited = true;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final attribute = MarketplaceAttribute(
      id: widget.attributeId ?? '',
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      type: _selectedType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isRequired: _isRequired,
      isFilterable: _isFilterable,
      createdAt: now,
      updatedAt: now,
    );

    context
        .read<AttributeFormBloc>()
        .add(SubmitAttributeFormEvent(attribute));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttributeFormBloc, AttributeFormState>(
      listener: _onFormStateChange,
      child: BlocBuilder<AttributeFormBloc, AttributeFormState>(
        builder: (context, state) {
          if (state is AttributeFormLoaded && widget.isEditing) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _populateForm(state.attribute),
            );
          }

          final isLoading =
              state is AttributeFormLoading || state is AttributeFormSubmitting;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Atributo' : 'Nuevo Atributo',
            isLoading: isLoading,
            errorMessage: state is AttributeFormError ? state.message : null,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildNameField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildSlugField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildTypeDropdown(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildDescriptionField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildToggles(enabled: !isLoading),
              if (_selectedType.hasValues) ...[
                const SizedBox(height: 24),
                _buildValuesSection(),
              ],
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

  Widget _buildSlugField({required bool enabled}) {
    return TextFormField(
      controller: _slugController,
      enabled: enabled,
      onChanged: (_) => _slugEdited = true,
      decoration: const InputDecoration(
        labelText: 'Slug *',
        border: OutlineInputBorder(),
        helperText: 'Identificador único. Se genera automáticamente desde el nombre.',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Slug es obligatorio';
        if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
          return 'Solo minúsculas, números y guiones';
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown({required bool enabled}) {
    return DropdownButtonFormField<AttributeType>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Tipo *',
        border: OutlineInputBorder(),
      ),
      items: AttributeType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type.displayLabel),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (type) => setState(() => _selectedType = type ?? AttributeType.text)
          : null,
      validator: (_) => null,
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

  Widget _buildToggles({required bool enabled}) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: const Text('Obligatorio'),
            subtitle: const Text('El producto debe incluir este atributo'),
            value: _isRequired,
            onChanged: enabled ? (v) => setState(() => _isRequired = v) : null,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SwitchListTile(
            title: const Text('Filtrable'),
            subtitle: const Text('Aparece como filtro en catálogo'),
            value: _isFilterable,
            onChanged:
                enabled ? (v) => setState(() => _isFilterable = v) : null,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildValuesSection() {
    if (!widget.isEditing) {
      return _ValuesPlaceholder();
    }
    return _AttributeValuesSection(attributeId: widget.attributeId!);
  }

  Widget _buildDeleteButton(BuildContext context, {required bool enabled}) {
    return OutlinedButton.icon(
      onPressed: enabled ? () => _confirmDelete(context) : null,
      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
      label: Text(
        'Eliminar atributo',
        style: TextStyle(color: Colors.red[700]),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.red[300]!),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar atributo',
      message:
          '¿Eliminar "${_nameController.text}"? Este atributo puede estar en uso en productos.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      // La eliminación se maneja desde la lista, acá sólo navegamos atrás
      context.go('/pim/attributes');
    }
  }

  void _onFormStateChange(BuildContext context, AttributeFormState state) {
    if (state is AttributeFormSuccess) {
      AdminSnackbars.showSuccess(
        context,
        widget.isEditing
            ? 'Atributo actualizado correctamente'
            : 'Atributo creado correctamente',
      );
      if (widget.isEditing) {
        // Recargar para sincronizar
        context
            .read<AttributeFormBloc>()
            .add(LoadAttributeEvent(widget.attributeId!));
      } else {
        context.go('/pim/attributes/${state.attribute.id}');
      }
    } else if (state is AttributeFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// --- Placeholder cuando el atributo es nuevo (aún no tiene id para values) ---

class _ValuesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valores',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 16),
            const Text(
              'Guardá primero el atributo para poder agregar valores.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Sección de gestión de valores inline ---

class _AttributeValuesSection extends StatelessWidget {
  final String attributeId;

  const _AttributeValuesSection({required this.attributeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttributeValuesBloc, AttributeValuesState>(
      builder: (context, state) {
        final values =
            state is AttributeValuesLoaded ? state.values : <AttributeValue>[];
        final isLoading = state is AttributeValuesLoading;
        final error =
            state is AttributeValuesError ? state.message : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Valores',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (error != null)
                  Text(error, style: TextStyle(color: Colors.red[700]))
                else ...[
                  ...values.map(
                    (v) => _ValueRow(
                      value: v,
                      onDelete: () => _deleteValue(context, v),
                      onEdit: (updated) => _updateValue(context, updated),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AddValueForm(attributeId: attributeId),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteValue(BuildContext context, AttributeValue value) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar valor',
      message: '¿Eliminar "${value.label}"?',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<AttributeValuesBloc>().add(
            DeleteAttributeValueEvent(
              attributeId: value.attributeId,
              valueId: value.id,
            ),
          );
    }
  }

  void _updateValue(BuildContext context, AttributeValue updated) {
    context.read<AttributeValuesBloc>().add(UpdateAttributeValueEvent(updated));
  }
}

// --- Fila de valor con edición inline ---

class _ValueRow extends StatefulWidget {
  final AttributeValue value;
  final VoidCallback onDelete;
  final ValueChanged<AttributeValue> onEdit;

  const _ValueRow({
    required this.value,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_ValueRow> createState() => _ValueRowState();
}

class _ValueRowState extends State<_ValueRow> {
  bool _editing = false;
  late final TextEditingController _labelController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.value.label);
    _valueController = TextEditingController(text: widget.value.value);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.value.copyWith(
      label: _labelController.text.trim(),
      value: _valueController.text.trim(),
    );
    widget.onEdit(updated);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return _EditingRow(
        labelController: _labelController,
        valueController: _valueController,
        onSave: _save,
        onCancel: () => setState(() => _editing = false),
      );
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(widget.value.label),
      subtitle: Text(
        widget.value.value,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${widget.value.sortOrder}',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            tooltip: 'Editar',
            onPressed: () => setState(() => _editing = true),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[700]),
            tooltip: 'Eliminar',
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _EditingRow extends StatelessWidget {
  final TextEditingController labelController;
  final TextEditingController valueController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditingRow({
    required this.labelController,
    required this.valueController,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Etiqueta',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Valor (clave)',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18, color: Colors.green),
            tooltip: 'Guardar',
            onPressed: onSave,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Cancelar',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

// --- Formulario de agregar valor ---

class _AddValueForm extends StatefulWidget {
  final String attributeId;

  const _AddValueForm({required this.attributeId});

  @override
  State<_AddValueForm> createState() => _AddValueFormState();
}

class _AddValueFormState extends State<_AddValueForm> {
  bool _expanded = false;
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_labelController.text.trim().isEmpty) return;
    final now = DateTime.now();
    final value = AttributeValue(
      id: '',
      attributeId: widget.attributeId,
      label: _labelController.text.trim(),
      value: _valueController.text.trim().isNotEmpty
          ? _valueController.text.trim()
          : _labelController.text.trim().toLowerCase().replaceAll(' ', '_'),
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    context.read<AttributeValuesBloc>().add(CreateAttributeValueEvent(value));
    _labelController.clear();
    _valueController.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return TextButton.icon(
        onPressed: () => setState(() => _expanded = true),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Agregar valor'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Etiqueta *',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Valor (clave)',
                hintText: 'Auto desde etiqueta',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18, color: Colors.green),
            tooltip: 'Agregar',
            onPressed: _submit,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Cancelar',
            onPressed: () => setState(() => _expanded = false),
          ),
        ],
      ),
    );
  }
}

// --- Extensión de display labels ---

extension _AttributeTypeLabel on AttributeType {
  String get displayLabel => switch (this) {
        AttributeType.text => 'Texto',
        AttributeType.number => 'Número',
        AttributeType.boolean => 'Booleano',
        AttributeType.select => 'Selección',
        AttributeType.multiSelect => 'Multi-selección',
      };
}
