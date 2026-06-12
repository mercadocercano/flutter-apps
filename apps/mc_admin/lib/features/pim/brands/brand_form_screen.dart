import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../core/utils/color_utils.dart';
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
  final _nameFocusNode = FocusNode();

  String? _nameConflictError;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onNameFocusChange);
    // Refresca el preview en vivo a medida que se editan estos campos.
    _nameController.addListener(_onPreviewChanged);
    _backgroundColorController.addListener(_onPreviewChanged);
    _textColorController.addListener(_onPreviewChanged);
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

  void _onPreviewChanged() {
    if (mounted) setState(() {});
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        context.read<BrandFormBloc>().add(
              ValidateBrandNameEvent(name, excludeId: widget.brandId),
            );
      }
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChange);
    _nameFocusNode.dispose();
    _nameController.removeListener(_onPreviewChanged);
    _backgroundColorController.removeListener(_onPreviewChanged);
    _textColorController.removeListener(_onPreviewChanged);
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
    if (_nameConflictError != null) return;
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
        } else if (state is BrandFormNameValidated) {
          setState(() {
            _nameConflictError = state.isConflict
                ? 'Ya existe una marca con ese nombre'
                : null;
          });
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
            isLoading: isLoading || _nameConflictError != null,
            errorMessage: errorMsg,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildNameField(enabled: !isLoading),
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
              _buildColorPreview(),
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

  Widget _buildColorPreview() {
    final bg = parseHexColor(_backgroundColorController.text);
    final fg = parseHexColor(_textColorController.text);
    final name = _nameController.text.trim();
    final displayName = name.isEmpty ? 'Nombre de la marca' : name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg ?? Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontStyle: name.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: fg ?? Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField({required bool enabled}) {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        border: const OutlineInputBorder(),
        errorText: _nameConflictError,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Nombre es obligatorio';
        return null;
      },
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
