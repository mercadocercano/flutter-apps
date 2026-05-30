import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'role_form_bloc.dart';
import 'roles_bloc.dart';

const _knownPermissions = [
  'sales.read',
  'sales.write',
  'stock.read',
  'stock.write',
  'pim.read',
  'pim.write',
  'iam.read',
  'iam.write',
  'reports.read',
];

class RoleFormScreen extends StatefulWidget {
  final String? roleId;

  const RoleFormScreen({super.key, this.roleId});

  bool get isEditing => roleId != null;

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  RoleType _selectedType = RoleType.tenant;
  RoleStatus _selectedStatus = RoleStatus.active;
  final Set<String> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _prefillFromBloc();
    }
  }

  void _prefillFromBloc() {
    final state = context.read<RolesBloc>().state;
    if (state is RolesLoaded) {
      final role = state.roles
          .where((r) => r.id == widget.roleId)
          .firstOrNull;
      if (role != null) {
        _nameController.text = role.name;
        _descriptionController.text = role.description ?? '';
        setState(() {
          _selectedType = role.type;
          _selectedStatus = role.status;
          _selectedPermissions.addAll(role.permissions);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final params = UpsertRoleParams(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      permissions: _selectedPermissions.toList(),
      status: _selectedStatus,
    );

    if (widget.isEditing) {
      context.read<RoleFormBloc>().add(
            SubmitUpdateRoleEvent(id: widget.roleId!, params: params),
          );
    } else {
      context.read<RoleFormBloc>().add(SubmitCreateRoleEvent(params));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar Rol',
      message:
          '¿Eliminar el rol "${_nameController.text}"? Esta accion no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && mounted) {
      context.read<RoleFormBloc>().add(DeleteRoleFormEvent(widget.roleId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleFormBloc, RoleFormState>(
      listener: (context, state) {
        if (state is RoleFormSuccess) {
          AdminSnackbars.showSuccess(
            context,
            widget.isEditing ? 'Rol actualizado' : 'Rol creado',
          );
          context.go('/iam/roles');
        } else if (state is RoleFormDeleted) {
          AdminSnackbars.showSuccess(context, 'Rol eliminado');
          context.go('/iam/roles');
        } else if (state is RoleFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<RoleFormBloc, RoleFormState>(
        builder: (context, state) {
          final isLoading = state is RoleFormSubmitting;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Rol' : 'Nuevo Rol',
            isLoading: isLoading,
            onSave: _save,
            onCancel: () => context.pop(),
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !isLoading,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoleType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: RoleType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t == RoleType.system ? 'Sistema' : 'Tenant',
                          ),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoleStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: RoleStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child:
                              Text(s == RoleStatus.active ? 'Activo' : 'Inactivo'),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedStatus = v!),
              ),
              const SizedBox(height: 20),
              Text(
                'Permisos',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _knownPermissions.map((perm) {
                  final selected = _selectedPermissions.contains(perm);
                  return FilterChip(
                    label: Text(perm, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: isLoading
                        ? null
                        : (checked) => setState(() {
                              if (checked) {
                                _selectedPermissions.add(perm);
                              } else {
                                _selectedPermissions.remove(perm);
                              }
                            }),
                  );
                }).toList(),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Eliminar Rol',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: isLoading ? null : _confirmDelete,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
