import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/templates_bloc.dart';
import 'blocs/template_form_bloc.dart';

class TemplatesScreen extends StatelessWidget {
  final String businessTypeId;

  const TemplatesScreen({super.key, required this.businessTypeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TemplatesBloc, TemplatesState>(
          listener: _onTemplatesBlocChange,
        ),
        BlocListener<TemplateFormBloc, TemplateFormState>(
          listener: _onFormBlocChange,
        ),
      ],
      child: BlocBuilder<TemplatesBloc, TemplatesState>(
        builder: (context, state) {
          final templates = state is TemplatesLoaded
              ? state.templates
              : <BusinessTypeTemplate>[];
          final isLoading = state is TemplatesLoading;
          final error = state is TemplatesError ? state.message : null;

          return AdminDataTable<BusinessTypeTemplate>(
            items: templates,
            isLoading: isLoading,
            error: error,
            onRetry: () => context
                .read<TemplatesBloc>()
                .add(RefreshTemplatesEvent()),
            currentPage: 1,
            pageSize: templates.isNotEmpty ? templates.length : 20,
            totalItems: templates.length,
            onPageChanged: (_) {},
            searchHint: 'Buscar template...',
            createLabel: 'Nueva plantilla',
            onCreateTap: () => context
                .push('/quickstart/templates/$businessTypeId/new'),
            columns: _buildColumns(context),
          );
        },
      ),
    );
  }

  List<AdminColumn<BusinessTypeTemplate>> _buildColumns(BuildContext context) {
    return [
      AdminColumn(
        label: 'Nombre',
        builder: (item) => _NameCell(name: item.name, description: item.description),
      ),
      AdminColumn(
        label: 'Categorías',
        width: 90,
        builder: (item) => Text(
          '${item.categoryIds.length}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      AdminColumn(
        label: 'Productos base',
        width: 110,
        builder: (item) => Text(
          '${item.baseProductIds.length}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      AdminColumn(
        label: 'Copia',
        width: 70,
        builder: (item) => item.isDuplicate
            ? const _DuplicateBadge()
            : const SizedBox.shrink(),
      ),
      AdminColumn(
        label: 'Acciones',
        width: 180,
        builder: (item) => _RowActions(
          template: item,
          businessTypeId: businessTypeId,
        ),
      ),
    ];
  }

  void _onTemplatesBlocChange(BuildContext context, TemplatesState state) {
    if (state is TemplatesError) {
      AdminSnackbars.showError(context, state.message);
    }
  }

  void _onFormBlocChange(BuildContext context, TemplateFormState state) {
    if (state is TemplateFormSuccess) {
      AdminSnackbars.showSuccess(context, 'Operación realizada correctamente');
      context.read<TemplatesBloc>().add(RefreshTemplatesEvent());
    } else if (state is TemplateFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// --- Celda de nombre + descripción ---

class _NameCell extends StatelessWidget {
  final String name;
  final String? description;

  const _NameCell({required this.name, this.description});

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
        if (description != null && description!.isNotEmpty)
          Text(
            description!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

// --- Badge de copia ---

class _DuplicateBadge extends StatelessWidget {
  const _DuplicateBadge();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text('Copia', style: TextStyle(fontSize: 11)),
      backgroundColor: Colors.orange.withAlpha(26),
      side: BorderSide(color: Colors.orange.withAlpha(77)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// --- Acciones de fila ---

class _RowActions extends StatelessWidget {
  final BusinessTypeTemplate template;
  final String businessTypeId;

  const _RowActions({required this.template, required this.businessTypeId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () => context.push(
            '/quickstart/templates/$businessTypeId/${template.id}/edit',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 18),
          tooltip: 'Duplicar',
          onPressed: () => _confirmDuplicate(context),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_outlined, size: 18),
          tooltip: 'Analytics',
          onPressed: () => context.push(
            '/quickstart/templates/$businessTypeId/${template.id}/analytics',
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _confirmDuplicate(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Duplicar plantilla',
      message:
          '¿Duplicar "${template.name}"? Se creará una copia con el nombre "${template.name} (copia)".',
      confirmLabel: 'Duplicar',
    );
    if (confirmed == true && context.mounted) {
      context
          .read<TemplatesBloc>()
          .add(DuplicateTemplateEvent(template.id));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar plantilla',
      message: '¿Eliminar "${template.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<TemplatesBloc>()
          .add(DeleteTemplateEvent(template.id));
    }
  }
}
