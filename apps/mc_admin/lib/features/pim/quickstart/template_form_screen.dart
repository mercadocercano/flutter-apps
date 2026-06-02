import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import 'blocs/template_form_bloc.dart';
import 'widgets/ai_generation_sheet.dart';

class TemplateFormScreen extends StatefulWidget {
  final String businessTypeId;
  final String? templateId;

  const TemplateFormScreen({
    super.key,
    required this.businessTypeId,
    this.templateId,
  });

  bool get isEditing => templateId != null;

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryIdsController = TextEditingController();
  final _productIdsController = TextEditingController();

  bool _populated = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      context.read<TemplateFormBloc>().add(LoadTemplateEvent(widget.templateId!));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryIdsController.dispose();
    _productIdsController.dispose();
    super.dispose();
  }

  void _populateForm(BusinessTypeTemplate template) {
    if (_populated) return;
    _populated = true;
    _nameController.text = template.name;
    _descriptionController.text = template.description ?? '';
    _categoryIdsController.text = template.categoryIds.join(', ');
    _productIdsController.text = template.baseProductIds.join(', ');
  }

  /// Parsea una lista de IDs desde un campo de texto separado por comas.
  List<String> _parseIds(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final template = BusinessTypeTemplate(
      id: widget.templateId ?? '',
      businessTypeId: widget.businessTypeId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryIds: _parseIds(_categoryIdsController.text),
      baseProductIds: _parseIds(_productIdsController.text),
      createdAt: now,
      updatedAt: now,
    );

    context.read<TemplateFormBloc>().add(SubmitTemplateFormEvent(template));
  }

  Future<void> _openAISheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TemplateFormBloc>(),
        child: AIGenerationSheet(
          businessTypeId: widget.businessTypeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateFormBloc, TemplateFormState>(
      listener: _onFormStateChange,
      child: BlocBuilder<TemplateFormBloc, TemplateFormState>(
        builder: (context, state) {
          if ((state is TemplateFormSuccess || state is TemplateFormAISuccess) &&
              widget.isEditing) {
            final template = state is TemplateFormSuccess
                ? state.template
                : (state as TemplateFormAISuccess).template;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _populateForm(template),
            );
          }

          if (state is TemplateFormAISuccess) {
            // Resetear _populated para re-completar con datos de IA
            _populated = false;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _populateForm(state.template),
            );
          }

          final isLoading = state is TemplateFormLoading ||
              state is TemplateFormAIGenerating;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Plantilla' : 'Nueva Plantilla',
            isLoading: isLoading,
            errorMessage:
                state is TemplateFormError ? state.message : null,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildNameField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildDescriptionField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildCategoryIdsField(enabled: !isLoading),
              const SizedBox(height: 16),
              _buildProductIdsField(enabled: !isLoading),
              const SizedBox(height: 24),
              _buildAIButton(context, enabled: !isLoading),
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

  Widget _buildCategoryIdsField({required bool enabled}) {
    return TextFormField(
      controller: _categoryIdsController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'IDs de categorías',
        border: OutlineInputBorder(),
        helperText: 'Separados por coma. Ej: cat-1, cat-2, cat-3',
      ),
    );
  }

  Widget _buildProductIdsField({required bool enabled}) {
    return TextFormField(
      controller: _productIdsController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'IDs de productos base',
        border: OutlineInputBorder(),
        helperText: 'Separados por coma. Ej: prod-1, prod-2',
      ),
    );
  }

  Widget _buildAIButton(BuildContext context, {required bool enabled}) {
    return OutlinedButton.icon(
      onPressed: enabled ? _openAISheet : null,
      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
      label: const Text('Generar con IA'),
    );
  }

  void _onFormStateChange(BuildContext context, TemplateFormState state) {
    if (state is TemplateFormSuccess && !widget.isEditing) {
      AdminSnackbars.showSuccess(context, 'Plantilla creada correctamente');
      context.go(
        '/quickstart/templates/${widget.businessTypeId}',
      );
    } else if (state is TemplateFormSuccess && widget.isEditing) {
      AdminSnackbars.showSuccess(
          context, 'Plantilla actualizada correctamente');
    } else if (state is TemplateFormAISuccess) {
      AdminSnackbars.showSuccess(
        context,
        'Sugerencia de IA aplicada. Revisá y guardá.',
      );
    } else if (state is TemplateFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}
