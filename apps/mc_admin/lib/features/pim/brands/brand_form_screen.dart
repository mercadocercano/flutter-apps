import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import 'blocs/brand_form_bloc.dart';

class BrandFormScreen extends StatefulWidget {
  final String? brandId;
  final MarketplaceBrand? initialBrand;

  const BrandFormScreen({super.key, this.brandId, this.initialBrand});

  bool get isEditing => brandId != null;

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _websiteController = TextEditingController();
  final _backgroundColorController = TextEditingController();
  final _textColorController = TextEditingController();
  final _typographyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final brand = widget.initialBrand;
    if (brand != null) {
      _nameController.text = brand.name;
      _descriptionController.text = brand.description ?? '';
      _logoUrlController.text = brand.logoUrl ?? '';
      _websiteController.text = brand.website ?? '';
      _backgroundColorController.text = brand.backgroundColor ?? '';
      _textColorController.text = brand.textColor ?? '';
      _typographyController.text = brand.typography ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _websiteController.dispose();
    _backgroundColorController.dispose();
    _textColorController.dispose();
    _typographyController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String text) =>
      text.trim().isEmpty ? null : text.trim();

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      context.read<BrandFormBloc>().add(SubmitUpdateBrandEvent(
            id: widget.brandId!,
            params: UpdateBrandParams(
              name: _nameController.text.trim(),
              description: _nullIfEmpty(_descriptionController.text),
              logoUrl: _nullIfEmpty(_logoUrlController.text),
              website: _nullIfEmpty(_websiteController.text),
              backgroundColor:
                  _nullIfEmpty(_backgroundColorController.text),
              textColor: _nullIfEmpty(_textColorController.text),
              typography: _nullIfEmpty(_typographyController.text),
            ),
          ));
    } else {
      context.read<BrandFormBloc>().add(SubmitCreateBrandEvent(
            CreateBrandParams(
              name: _nameController.text.trim(),
              description: _nullIfEmpty(_descriptionController.text),
              logoUrl: _nullIfEmpty(_logoUrlController.text),
              website: _nullIfEmpty(_websiteController.text),
              backgroundColor:
                  _nullIfEmpty(_backgroundColorController.text),
              textColor: _nullIfEmpty(_textColorController.text),
              typography: _nullIfEmpty(_typographyController.text),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BrandFormBloc, BrandFormState>(
      listener: (context, state) {
        if (state is BrandFormSuccess) {
          AdminSnackbars.showSuccess(
            context,
            widget.isEditing
                ? 'Marca actualizada correctamente'
                : 'Marca creada correctamente',
          );
          context.go('/pim/brands');
        } else if (state is BrandFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<BrandFormBloc, BrandFormState>(
        builder: (context, state) {
          final isLoading = state is BrandFormSubmitting;
          final errorMsg =
              state is BrandFormError ? state.message : null;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Marca' : 'Nueva Marca',
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
                controller: _descriptionController,
                label: 'Descripcion',
                maxLines: 3,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _logoUrlController,
                label: 'URL de Logo',
                enabled: !isLoading,
                hint: 'https://cdn.example.com/logo.png',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _websiteController,
                label: 'Sitio Web',
                enabled: !isLoading,
                hint: 'https://example.com',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _backgroundColorController,
                      label: 'Color de fondo',
                      enabled: !isLoading,
                      hint: '#FFFFFF',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _textColorController,
                      label: 'Color de texto',
                      enabled: !isLoading,
                      hint: '#000000',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _typographyController,
                label: 'Tipografia',
                enabled: !isLoading,
                hint: 'Helvetica',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    bool enabled = true,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) {
                return '$label es obligatorio';
              }
              return null;
            }
          : null,
    );
  }
}
