import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../blocs/source_form_bloc.dart';

/// Pantalla de creación/edición de una WebSource.
///
/// En modo creación el [sourceId] es null. En edición carga la fuente
/// existente y pre-llena el formulario.
class SourceFormScreen extends StatefulWidget {
  final String? sourceId;

  const SourceFormScreen({super.key, this.sourceId});

  bool get isEditing => sourceId != null;

  @override
  State<SourceFormScreen> createState() => _SourceFormScreenState();
}

class _SourceFormScreenState extends State<SourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _scheduleController = TextEditingController();

  List<String> _selectedBusinessTypeIds = [];
  String _status = 'active';
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      context.read<SourceFormBloc>().add(LoadSourceEvent(widget.sourceId!));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  void _populateForm(WebSource source) {
    _nameController.text = source.name;
    _urlController.text = source.url;
    _scheduleController.text = source.schedule ?? '';
    setState(() {
      _selectedBusinessTypeIds = List.from(source.businessTypeIds);
      _status = source.status.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final source = WebSource(
      id: widget.sourceId ?? '',
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      status: WebSourceStatus.values.firstWhere(
        (s) => s.name == _status,
        orElse: () => WebSourceStatus.active,
      ),
      schedule: _scheduleController.text.trim().isEmpty
          ? null
          : _scheduleController.text.trim(),
      businessTypeIds: _selectedBusinessTypeIds,
      createdAt: now,
      updatedAt: now,
    );

    context.read<SourceFormBloc>().add(SubmitSourceFormEvent(source));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SourceFormBloc, SourceFormState>(
      listener: _onStateChange,
      child: BlocBuilder<SourceFormBloc, SourceFormState>(
        builder: (context, state) {
          if (state is SourceFormLoading && widget.isEditing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is SourceFormSuccess && !_isSubmitting) {
            _populateForm(state.source);
          }

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Fuente' : 'Nueva Fuente',
            isLoading: state is SourceFormLoading,
            errorMessage: _error,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              _buildNameField(enabled: state is! SourceFormLoading),
              const SizedBox(height: 16),
              _buildUrlField(enabled: state is! SourceFormLoading),
              const SizedBox(height: 16),
              _buildScheduleField(enabled: state is! SourceFormLoading),
              const SizedBox(height: 16),
              _buildStatusDropdown(enabled: state is! SourceFormLoading),
              const SizedBox(height: 16),
              _buildBusinessTypesSection(enabled: state is! SourceFormLoading),
            ],
          );
        },
      ),
    );
  }

  void _onStateChange(BuildContext context, SourceFormState state) {
    if (state is SourceFormSuccess) {
      setState(() {
        _isSubmitting = false;
        _error = null;
      });
      AdminSnackbars.showSuccess(
        context,
        widget.isEditing ? 'Fuente actualizada' : 'Fuente creada',
      );
      context.pop();
    }
    if (state is SourceFormError) {
      setState(() {
        _isSubmitting = false;
        _error = state.message;
      });
    }
    if (state is SourceFormLoading) {
      setState(() => _isSubmitting = true);
    }
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
        if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
        return null;
      },
    );
  }

  Widget _buildUrlField({required bool enabled}) {
    return TextFormField(
      controller: _urlController,
      enabled: enabled,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'URL *',
        border: OutlineInputBorder(),
        hintText: 'https://ejemplo.com/productos',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'La URL es obligatoria';
        final uri = Uri.tryParse(v.trim());
        if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
          return 'Ingresa una URL válida (ej: https://ejemplo.com)';
        }
        return null;
      },
    );
  }

  Widget _buildScheduleField({required bool enabled}) {
    return TextFormField(
      controller: _scheduleController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Schedule (cron)',
        border: OutlineInputBorder(),
        hintText: '0 * * * *',
        helperText: 'Expresión cron opcional. Vacío = solo ejecución manual.',
      ),
    );
  }

  Widget _buildStatusDropdown({required bool enabled}) {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Activo')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
      ],
      onChanged: enabled ? (v) => setState(() => _status = v!) : null,
    );
  }

  Widget _buildBusinessTypesSection({required bool enabled}) {
    // Chips de selección múltiple para business type IDs
    // En producción se cargaría la lista de tipos disponibles desde un BLoC.
    // Por ahora permite agregar IDs manualmente como chips.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipos de negocio',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ..._selectedBusinessTypeIds.map((id) => Chip(
                  label: Text(id, style: const TextStyle(fontSize: 12)),
                  onDeleted: enabled
                      ? () => setState(
                          () => _selectedBusinessTypeIds.remove(id))
                      : null,
                )),
            if (enabled)
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Agregar tipo'),
                onPressed: () => _showAddBusinessTypeDialog(context),
              ),
          ],
        ),
        if (_selectedBusinessTypeIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Sin tipos asignados. Los productos se crean sin clasificar.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddBusinessTypeDialog(BuildContext context) async {
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar tipo de negocio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ID del tipo',
            hintText: 'ej: ferreteria',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (id != null && id.isNotEmpty && !_selectedBusinessTypeIds.contains(id)) {
      setState(() => _selectedBusinessTypeIds.add(id));
    }
  }
}
