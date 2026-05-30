import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/status_badge.dart';
import 'tenants_bloc.dart';

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TenantsBloc, TenantsState>(
      builder: (context, state) {
        final tenants = state is TenantsLoaded ? state.tenants : <Tenant>[];
        final isLoading = state is TenantsLoading;
        final error = state is TenantsError ? state.message : null;
        final currentPage = state is TenantsLoaded ? state.currentPage : 1;
        final pageSize = state is TenantsLoaded ? state.pageSize : 20;
        final totalItems = state is TenantsLoaded ? state.totalItems : 0;

        return AdminDataTable<Tenant>(
          items: tenants,
          isLoading: isLoading,
          error: error,
          onRetry: () =>
              context.read<TenantsBloc>().add(LoadTenantsEvent()),
          currentPage: currentPage,
          pageSize: pageSize,
          totalItems: totalItems,
          onPageChanged: (page) =>
              context.read<TenantsBloc>().add(ChangeTenantsPageEvent(page)),
          searchHint: 'Buscar tenant...',
          onSearch: (query) => context
              .read<TenantsBloc>()
              .add(LoadTenantsEvent(searchQuery: query.isEmpty ? null : query)),
          createLabel: 'Nuevo Tenant',
          onCreateTap: () => context.push('/iam/tenants/new'),
          columns: [
            AdminColumn<Tenant>(
              label: 'Nombre',
              builder: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item.slug,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            AdminColumn<Tenant>(
              label: 'Slug',
              builder: (item) => SelectableText(item.slug),
            ),
            AdminColumn<Tenant>(
              label: 'Tipo',
              builder: (item) => _TenantTypeChip(type: item.type),
            ),
            AdminColumn<Tenant>(
              label: 'Estado',
              builder: (item) => StatusBadge.fromString(
                item.status.name,
                customLabel: _tenantStatusLabel(item.status),
              ),
            ),
            AdminColumn<Tenant>(
              label: 'Usuarios',
              builder: (item) => Text('${item.userCount}/${item.maxUsers}'),
            ),
            AdminColumn<Tenant>(
              label: 'Acciones',
              builder: (item) => _RowActions(tenant: item),
            ),
          ],
        );
      },
    );
  }

  String _tenantStatusLabel(TenantStatus status) {
    return switch (status) {
      TenantStatus.active => 'Activo',
      TenantStatus.inactive => 'Inactivo',
      TenantStatus.suspended => 'Suspendido',
      TenantStatus.deleted => 'Eliminado',
    };
  }
}

class _TenantTypeChip extends StatelessWidget {
  final TenantType type;
  const _TenantTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      TenantType.personal => 'Personal',
      TenantType.startup => 'Startup',
      TenantType.business => 'Business',
      TenantType.enterprise => 'Enterprise',
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RowActions extends StatelessWidget {
  final Tenant tenant;
  const _RowActions({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'Ver detalle',
          onPressed: () => context.push('/iam/tenants/${tenant.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () => context.push('/iam/tenants/${tenant.id}/edit'),
        ),
      ],
    );
  }
}
