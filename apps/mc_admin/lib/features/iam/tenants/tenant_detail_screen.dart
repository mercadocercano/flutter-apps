import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/status_badge.dart';
import 'tenants_bloc.dart';
import 'tenant_form_bloc.dart';

class TenantDetailScreen extends StatelessWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TenantFormBloc, TenantFormState>(
      listener: (context, state) {
        if (state is TenantFormDeleted) {
          AdminSnackbars.showSuccess(context, 'Tenant eliminado');
          context.go('/iam/tenants');
        } else if (state is TenantFormError) {
          AdminSnackbars.showError(context, state.message);
        }
      },
      child: BlocBuilder<TenantsBloc, TenantsState>(
        builder: (context, state) {
          Tenant? tenant;
          if (state is TenantsLoaded) {
            tenant = state.tenants
                .where((t) => t.id == tenantId)
                .firstOrNull;
          }

          if (tenant == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detalle de Tenant')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return _TenantDetailView(tenant: tenant);
        },
      ),
    );
  }
}

class _TenantDetailView extends StatelessWidget {
  final Tenant tenant;
  const _TenantDetailView({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            onPressed: () => context.push('/iam/tenants/${tenant.id}/edit'),
          ),
          TextButton.icon(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
            label: Text(
              'Eliminar',
              style: TextStyle(color: Colors.red[700]),
            ),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCard(
                  title: 'Informacion General',
                  children: [
                    _InfoRow('ID', tenant.id),
                    _InfoRow('Nombre', tenant.name),
                    _InfoRow('Slug', tenant.slug),
                    _InfoRow('Tipo', _tenantTypeLabel(tenant.type)),
                    _InfoRow(
                      'Estado',
                      tenant.status.name,
                      statusWidget: StatusBadge.fromString(
                        tenant.status.name,
                        customLabel: _tenantStatusLabel(tenant.status),
                      ),
                    ),
                    if (tenant.description != null)
                      _InfoRow('Descripcion', tenant.description!),
                    if (tenant.domain != null)
                      _InfoRow('Dominio', tenant.domain!),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Propietario y Plan',
                  children: [
                    _InfoRow('Owner ID', tenant.ownerId),
                    if (tenant.planId != null)
                      _InfoRow('Plan ID', tenant.planId!),
                    _InfoRow('Usuarios', '${tenant.userCount} / ${tenant.maxUsers}'),
                    if (tenant.expiresAt != null)
                      _InfoRow('Expira', _formatDate(tenant.expiresAt!)),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Fechas',
                  children: [
                    _InfoRow('Creado', _formatDate(tenant.createdAt)),
                    _InfoRow('Actualizado', _formatDate(tenant.updatedAt)),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  String _tenantStatusLabel(TenantStatus status) {
    return switch (status) {
      TenantStatus.active => 'Activo',
      TenantStatus.inactive => 'Inactivo',
      TenantStatus.suspended => 'Suspendido',
      TenantStatus.deleted => 'Eliminado',
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar Tenant',
      message: '¿Eliminar "${tenant.name}"? Esta accion no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<TenantFormBloc>().add(DeleteTenantFormEvent(tenant.id));
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? statusWidget;

  const _InfoRow(this.label, this.value, {this.statusWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: statusWidget ??
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
          ),
        ],
      ),
    );
  }
}
