import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/status_badge.dart';
import 'roles_bloc.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RolesBloc, RolesState>(
      builder: (context, state) {
        final roles = state is RolesLoaded ? state.roles : <Role>[];
        final isLoading = state is RolesLoading;
        final error = state is RolesError ? state.message : null;
        final currentPage = state is RolesLoaded ? state.currentPage : 1;
        final pageSize = state is RolesLoaded ? state.pageSize : 20;
        final totalItems = state is RolesLoaded ? state.totalItems : 0;

        return AdminDataTable<Role>(
          items: roles,
          isLoading: isLoading,
          error: error,
          onRetry: () => context.read<RolesBloc>().add(LoadRolesEvent()),
          currentPage: currentPage,
          pageSize: pageSize,
          totalItems: totalItems,
          onPageChanged: (page) =>
              context.read<RolesBloc>().add(ChangeRolesPageEvent(page)),
          searchHint: 'Buscar rol...',
          onSearch: (query) => context.read<RolesBloc>().add(
                LoadRolesEvent(searchQuery: query.isEmpty ? null : query),
              ),
          createLabel: 'Nuevo Rol',
          onCreateTap: () => context.push('/iam/roles/new'),
          columns: [
            AdminColumn<Role>(
              label: 'Nombre',
              builder: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AdminColumn<Role>(
              label: 'Tipo',
              builder: (item) => Chip(
                label: Text(
                  item.type == RoleType.system ? 'Sistema' : 'Tenant',
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            AdminColumn<Role>(
              label: 'Permisos',
              builder: (item) => Text('${item.permissions.length} permiso(s)'),
            ),
            AdminColumn<Role>(
              label: 'Estado',
              builder: (item) => StatusBadge.fromString(item.status.name),
            ),
            AdminColumn<Role>(
              label: 'Acciones',
              builder: (item) => _RoleRowActions(role: item),
            ),
          ],
        );
      },
    );
  }
}

class _RoleRowActions extends StatelessWidget {
  final Role role;
  const _RoleRowActions({required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () => context.push('/iam/roles/${role.id}/edit'),
        ),
      ],
    );
  }
}
