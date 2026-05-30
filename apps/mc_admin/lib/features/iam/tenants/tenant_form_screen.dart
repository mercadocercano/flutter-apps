import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import 'tenant_form_bloc.dart';

class TenantFormScreen extends StatefulWidget {
  final String? tenantId;

  const TenantFormScreen({super.key, this.tenantId});

  bool get isEditing => tenantId != null;

  @override
  State<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends State<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerIdController = TextEditingController();
  final _domainController = TextEditingController();
  TenantType _selectedType = TenantType.business;

  bool _slugManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _ownerIdController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_slugManuallyEdited) {
      final slug = _nameController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .trim();
      _slugController.text = slug;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      context.read<TenantFormBloc>().add(SubmitUpdateTenantEvent(
            id: widget.tenantId!,
            params: UpdateTenantParams(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              domain: _domainController.text.trim().isEmpty
                  ? null
                  : _domainController.text.trim(),
              type: _selectedType,
            ),
          ));
    } else {
      context.read<TenantFormBloc>().add(SubmitCreateTenantEvent(
            CreateTenantParams(
              name: _nameController.text.trim(),
              slug: _slugController.text.trim(),
              type: _selectedType,
              ownerId: _ownerIdController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              domain: _domainController.text.trim().isEmpty
                  ? null
                  : _domainController.text.trim(),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TenantFormBloc, TenantFormState>(
      listener: (context, state) {
        if (state is TenantFormSuccess) {
          AdminSnackbars.showSuccess(
            context,
            widget.isEditing
                ? 'Tenant actualizado correctamente'
                : 'Tenant creado correctamente',
          );
          context.go('/iam/tenants');
        } else if (state is TenantFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<TenantFormBloc, TenantFormState>(
        builder: (context, state) {
          final isLoading = state is TenantFormSubmitting;
          final errorMsg =
              state is TenantFormError ? state.message : null;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Tenant' : 'Nuevo Tenant',
            isLoading: isLoading,
            errorMessage: errorMsg,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nombre',
                required: true,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _slugController,
                label: 'Slug',
                required: true,
                enabled: !isLoading && !widget.isEditing,
                hint: 'mi-comercio',
                onChanged: (_) => _slugManuallyEdited = true,
              ),
              const SizedBox(height: 16),
              if (!widget.isEditing) ...[
                _buildTextField(
                  controller: _ownerIdController,
                  label: 'Owner ID (UUID)',
                  required: true,
                  enabled: !isLoading,
                  hint: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Owner ID es obligatorio';
                    }
                    final uuidRegex = RegExp(
                      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                      caseSensitive: false,
                    );
                    if (!uuidRegex.hasMatch(v.trim())) {
                      return 'Debe ser un UUID valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<TenantType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: TenantType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_tenantTypeLabel(t)),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descripcion',
                maxLines: 3,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _domainController,
                label: 'Dominio',
                enabled: !isLoading,
                hint: 'micomercio.com',
              ),
            ],
          );
        },
      ),
    );
  }

  String _tenantTypeLabel(TenantType type) {
    return switch (type) {
      TenantType.personal => 'Personal',
      TenantType.startup => 'Startup',
      TenantType.business => 'Business',
      TenantType.enterprise => 'Enterprise',
    };
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    bool enabled = true,
    String? hint,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (required
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '$label es obligatorio';
                  }
                  return null;
                }
              : null),
    );
  }
}
