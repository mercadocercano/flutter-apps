import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../core/utils/color_utils.dart';
import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import 'blocs/brand_form_bloc.dart';

class BrandFormScreen extends StatefulWidget {
  final String? brandId;
  final MarketplaceBrand? initialBrand;

  /// Carga la marca por id cuando se edita sin un [initialBrand] precargado
  /// (p. ej. al entrar directo a la URL `/pim/brands/:id/edit`).
  final GetBrandUseCase? getBrand;

  const BrandFormScreen({
    super.key,
    this.brandId,
    this.initialBrand,
    this.getBrand,
  });

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
  bool _isLoadingBrand = false;

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
      _populate(brand);
    } else if (widget.isEditing && widget.getBrand != null) {
      // Editando por URL directa: no llegó initialBrand, cargar por id.
      _loadBrand();
    }
  }

  void _populate(MarketplaceBrand brand) {
    _nameController.text = brand.name;
    _descriptionController.text = brand.description ?? '';
    _logoUrlController.text = brand.logoUrl ?? '';
    _websiteController.text = brand.website ?? '';
    _backgroundColorController.text = brand.backgroundColor ?? '';
    _textColorController.text = brand.textColor ?? '';
    _typographyController.text = brand.typography ?? '';
  }

  Future<void> _loadBrand() async {
    setState(() => _isLoadingBrand = true);
    try {
      final brand = await widget.getBrand!.execute(widget.brandId!);
      if (!mounted) return;
      setState(() {
        _populate(brand);
        _isLoadingBrand = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingBrand = false);
      AdminSnackbars.showError(context, 'Error al cargar la marca: $e');
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
          final isLoading = state is BrandFormSubmitting || _isLoadingBrand;
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
                    child: _buildColorField(
                      controller: _backgroundColorController,
                      label: 'Color de fondo',
                      enabled: !isLoading,
                      hint: '#FFFFFF',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildColorField(
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

  Widget _buildColorField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? hint,
  }) {
    final current = parseHexColor(controller.text);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: enabled ? () => _pickColor(controller) : null,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: current ?? Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: current == null
                  ? Icon(Icons.colorize, size: 16, color: Colors.grey[500])
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickColor(TextEditingController controller) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegir color'),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorPalette.map((hex) {
              final color = parseHexColor(hex)!;
              final isSelected =
                  controller.text.trim().toUpperCase() == hex.toUpperCase();
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => Navigator.of(ctx).pop(hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected != null) {
      controller.text = selected;
    }
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

/// Paleta de presets para el picker de colores de marca.
const List<String> _colorPalette = [
  '#FFFFFF', '#F8FAFC', '#E2E8F0', '#94A3B8', '#475569', '#1E293B', '#000000',
  '#EF4444', '#F97316', '#F59E0B', '#EAB308', '#84CC16', '#22C55E', '#10B981',
  '#14B8A6', '#06B6D4', '#0EA5E9', '#3B82F6', '#6366F1', '#8B5CF6', '#A855F7',
  '#D946EF', '#EC4899', '#F43F5E', '#0A21C0', '#9333EA', '#16A34A', '#DC2626',
];
