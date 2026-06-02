import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';

/// Pantalla de creación/edición de un BusinessType.
///
/// Se provee su propio BLoC de forma, aprovechando el [BusinessTypesBloc]
/// del ancestro para refrescar la lista tras guardar.
class BusinessTypeFormScreen extends StatefulWidget {
  final String? businessTypeId;

  const BusinessTypeFormScreen({super.key, this.businessTypeId});

  bool get isEditing => businessTypeId != null;

  @override
  State<BusinessTypeFormScreen> createState() => _BusinessTypeFormScreenState();
}

class _BusinessTypeFormScreenState extends State<BusinessTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();

  bool _isActive = true;
  bool _slugEdited = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  late final _repo = QuickstartRepositoryImpl(KongClient());

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    if (widget.isEditing) _loadBusinessType();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
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

  Future<void> _loadBusinessType() async {
    setState(() => _isLoading = true);
    try {
      final useCase = GetBusinessTypeUseCase(_repo);
      final bt = await useCase.execute(widget.businessTypeId!);
      _populateForm(bt);
    } catch (e) {
      setState(() => _error = 'Error al cargar tipo de negocio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm(BusinessType bt) {
    _nameController.text = bt.name;
    _slugController.text = bt.slug;
    _descriptionController.text = bt.description ?? '';
    _iconController.text = bt.icon;
    setState(() {
      _isActive = bt.isActive;
      _slugEdited = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final bt = BusinessType(
        id: widget.businessTypeId ?? '',
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _iconController.text.trim().isEmpty
            ? '🏪'
            : _iconController.text.trim(),
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await UpdateBusinessTypeUseCase(_repo).execute(bt);
      } else {
        await CreateBusinessTypeUseCase(_repo).execute(bt);
      }

      if (mounted) {
        AdminSnackbars.showSuccess(
          context,
          widget.isEditing
              ? 'Tipo de negocio actualizado'
              : 'Tipo de negocio creado',
        );
        context.go('/quickstart/business-types');
      }
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _isLoading || _isSubmitting;

    return AdminCrudForm(
      formKey: _formKey,
      title: widget.isEditing
          ? 'Editar Tipo de Negocio'
          : 'Nuevo Tipo de Negocio',
      isLoading: isDisabled,
      errorMessage: _error,
      onSave: _save,
      onCancel: () => context.pop(),
      children: [
        _buildIconField(enabled: !isDisabled),
        const SizedBox(height: 16),
        _buildNameField(enabled: !isDisabled),
        const SizedBox(height: 16),
        _buildSlugField(enabled: !isDisabled),
        const SizedBox(height: 16),
        _buildDescriptionField(enabled: !isDisabled),
        const SizedBox(height: 16),
        _buildActiveToggle(enabled: !isDisabled),
      ],
    );
  }

  Widget _buildIconField({required bool enabled}) {
    return TextFormField(
      controller: _iconController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Icono',
        border: OutlineInputBorder(),
        helperText: 'Emoji o texto corto (ej: 🛒, ferreteria)',
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
        helperText: 'Identificador único. Se genera desde el nombre.',
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

  Widget _buildActiveToggle({required bool enabled}) {
    return SwitchListTile(
      title: const Text('Activo'),
      subtitle: const Text('Aparece en el selector del onboarding'),
      value: _isActive,
      onChanged: enabled ? (v) => setState(() => _isActive = v) : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
