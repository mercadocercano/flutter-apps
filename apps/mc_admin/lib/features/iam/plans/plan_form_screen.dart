import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_crud_form.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'plan_form_bloc.dart';
import 'plans_bloc.dart';

class PlanFormScreen extends StatefulWidget {
  final String? planId;

  const PlanFormScreen({super.key, this.planId});

  bool get isEditing => planId != null;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _featureInputController = TextEditingController();
  PlanType _selectedType = PlanType.starter;
  PlanStatus _selectedStatus = PlanStatus.active;
  String _currency = 'ARS';
  final List<String> _features = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _prefillFromBloc();
    }
  }

  void _prefillFromBloc() {
    final state = context.read<PlansBloc>().state;
    if (state is PlansLoaded) {
      final plan = state.plans
          .where((p) => p.id == widget.planId)
          .firstOrNull;
      if (plan != null) {
        _nameController.text = plan.name;
        _descriptionController.text = plan.description ?? '';
        _priceController.text = plan.price.toStringAsFixed(0);
        _currency = plan.currency;
        setState(() {
          _selectedType = plan.type;
          _selectedStatus = plan.status;
          _features.addAll(plan.features);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _featureInputController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final text = _featureInputController.text.trim();
    if (text.isNotEmpty && !_features.contains(text)) {
      setState(() => _features.add(text));
      _featureInputController.clear();
    }
  }

  void _removeFeature(String feature) {
    setState(() => _features.remove(feature));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    final params = UpsertPlanParams(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      price: price,
      currency: _currency,
      features: List.unmodifiable(_features),
      limits: const {},
      status: _selectedStatus,
    );

    if (widget.isEditing) {
      context.read<PlanFormBloc>().add(
            SubmitUpdatePlanEvent(id: widget.planId!, params: params),
          );
    } else {
      context.read<PlanFormBloc>().add(SubmitCreatePlanEvent(params));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar Plan',
      message:
          '¿Eliminar el plan "${_nameController.text}"? Esta accion no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && mounted) {
      context.read<PlanFormBloc>().add(DeletePlanFormEvent(widget.planId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlanFormBloc, PlanFormState>(
      listener: (context, state) {
        if (state is PlanFormSuccess) {
          AdminSnackbars.showSuccess(
            context,
            widget.isEditing ? 'Plan actualizado' : 'Plan creado',
          );
          context.go('/iam/plans');
        } else if (state is PlanFormDeleted) {
          AdminSnackbars.showSuccess(context, 'Plan eliminado');
          context.go('/iam/plans');
        } else if (state is PlanFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<PlanFormBloc, PlanFormState>(
        builder: (context, state) {
          final isLoading = state is PlanFormSubmitting;

          return AdminCrudForm(
            formKey: _formKey,
            title: widget.isEditing ? 'Editar Plan' : 'Nuevo Plan',
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
              DropdownButtonFormField<PlanType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: PlanType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_planTypeLabel(t)),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El precio es obligatorio';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Ingresa un numero valido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ARS', child: Text('ARS')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlanStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: PlanStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s == PlanStatus.active ? 'Activo' : 'Inactivo',
                          ),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedStatus = v!),
              ),
              const SizedBox(height: 20),
              Text(
                'Features',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _featureInputController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        hintText: 'Ej: unlimited_products',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addFeature(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: 'Agregar feature',
                    onPressed: isLoading ? null : _addFeature,
                  ),
                ],
              ),
              if (_features.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _features
                      .map((f) => Chip(
                            label: Text(f, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted:
                                isLoading ? null : () => _removeFeature(f),
                          ))
                      .toList(),
                ),
              ],
              if (widget.isEditing) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Eliminar Plan',
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

  String _planTypeLabel(PlanType type) {
    return switch (type) {
      PlanType.free => 'Free',
      PlanType.starter => 'Starter',
      PlanType.professional => 'Professional',
      PlanType.enterprise => 'Enterprise',
    };
  }
}
