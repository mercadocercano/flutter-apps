import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/business_types_bloc.dart';

class BusinessTypesScreen extends StatefulWidget {
  const BusinessTypesScreen({super.key});

  @override
  State<BusinessTypesScreen> createState() => _BusinessTypesScreenState();
}

class _BusinessTypesScreenState extends State<BusinessTypesScreen> {
  bool? _filterIsActive;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _applyActiveFilter(bool? isActive) {
    setState(() => _filterIsActive = isActive);
    context
        .read<BusinessTypesBloc>()
        .add(LoadBusinessTypesEvent(isActive: isActive));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessTypesBloc, BusinessTypesState>(
      listener: _onBlocStateChange,
      child: BlocBuilder<BusinessTypesBloc, BusinessTypesState>(
        builder: (context, state) {
          final types = state is BusinessTypesLoaded ? state.types : <BusinessType>[];
          final isLoading = state is BusinessTypesLoading;
          final error = state is BusinessTypesError ? state.message : null;

          return Column(
            children: [
              _ActiveFilterBar(
                selected: _filterIsActive,
                onChanged: _applyActiveFilter,
              ),
              Expanded(
                child: AdminDataTable<BusinessType>(
                  items: types,
                  isLoading: isLoading,
                  error: error,
                  onRetry: () => context
                      .read<BusinessTypesBloc>()
                      .add(RefreshBusinessTypesEvent()),
                  currentPage: 1,
                  pageSize: types.isNotEmpty ? types.length : 20,
                  totalItems: types.length,
                  onPageChanged: (_) {},
                  searchHint: 'Buscar tipo de negocio...',
                  createLabel: 'Nuevo tipo',
                  onCreateTap: () =>
                      context.push('/quickstart/business-types/new'),
                  columns: _buildColumns(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AdminColumn<BusinessType>> _buildColumns(BuildContext context) {
    return [
      AdminColumn(
        label: 'Icono',
        width: 60,
        builder: (item) => _IconCell(icon: item.icon),
      ),
      AdminColumn(
        label: 'Nombre',
        builder: (item) => _NameCell(name: item.name, slug: item.slug),
      ),
      AdminColumn(
        label: 'Estado',
        width: 100,
        builder: (item) => _ActiveBadge(isActive: item.isActive),
      ),
      AdminColumn(
        label: 'Templates',
        width: 90,
        builder: (item) => Text(
          '${item.templateCount}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      AdminColumn(
        label: 'Acciones',
        width: 160,
        builder: (item) => _RowActions(businessType: item),
      ),
    ];
  }

  void _onBlocStateChange(BuildContext context, BusinessTypesState state) {
    if (state is BusinessTypesError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// --- Filtro por estado activo ---

class _ActiveFilterBar extends StatelessWidget {
  final bool? selected;
  final ValueChanged<bool?> onChanged;

  const _ActiveFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Activos'),
            selected: selected == true,
            onSelected: (_) => onChanged(true),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Inactivos'),
            selected: selected == false,
            onSelected: (_) => onChanged(false),
          ),
        ],
      ),
    );
  }
}

// --- Celda de icono ---

class _IconCell extends StatelessWidget {
  final String icon;

  const _IconCell({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Text(
      icon,
      style: const TextStyle(fontSize: 20),
      textAlign: TextAlign.center,
    );
  }
}

// --- Celda de nombre + slug ---

class _NameCell extends StatelessWidget {
  final String name;
  final String slug;

  const _NameCell({required this.name, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          slug,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600], fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

// --- Badge de estado activo/inactivo ---

class _ActiveBadge extends StatelessWidget {
  final bool isActive;

  const _ActiveBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    final label = isActive ? 'Activo' : 'Inactivo';

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withAlpha(26),
      side: BorderSide(color: color.withAlpha(77)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// --- Acciones de fila ---

class _RowActions extends StatelessWidget {
  final BusinessType businessType;

  const _RowActions({required this.businessType});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.list_alt_outlined, size: 18),
          tooltip: 'Ver templates',
          onPressed: () => context
              .push('/quickstart/templates/${businessType.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () => context
              .push('/quickstart/business-types/${businessType.id}/edit'),
        ),
        IconButton(
          icon: Icon(
            businessType.isActive
                ? Icons.toggle_on_outlined
                : Icons.toggle_off_outlined,
            size: 18,
            color: businessType.isActive ? Colors.green[700] : Colors.grey[600],
          ),
          tooltip: businessType.isActive ? 'Desactivar' : 'Activar',
          onPressed: () => _toggleActive(context),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _toggleActive(BuildContext context) {
    if (businessType.isActive) {
      context
          .read<BusinessTypesBloc>()
          .add(DeactivateBusinessTypeEvent(businessType.id));
    } else {
      context
          .read<BusinessTypesBloc>()
          .add(ActivateBusinessTypeEvent(businessType.id));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar tipo de negocio',
      message:
          '¿Eliminar "${businessType.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<BusinessTypesBloc>()
          .add(DeleteBusinessTypeEvent(businessType.id));
    }
  }
}
