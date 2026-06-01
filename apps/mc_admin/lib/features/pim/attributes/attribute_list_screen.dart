import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'blocs/attribute_form_bloc.dart';
import 'blocs/attribute_list_bloc.dart';

class AttributeListScreen extends StatefulWidget {
  const AttributeListScreen({super.key});

  @override
  State<AttributeListScreen> createState() => _AttributeListScreenState();
}

class _AttributeListScreenState extends State<AttributeListScreen> {
  AttributeType? _filterType;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<AttributeListBloc>().add(LoadAttributesEvent(
            search: query.isEmpty ? null : query,
            type: _filterType,
          ));
    });
  }

  void _applyTypeFilter(AttributeType? type) {
    setState(() => _filterType = type);
    context.read<AttributeListBloc>().add(LoadAttributesEvent(type: type));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttributeFormBloc, AttributeFormState>(
      listener: _onFormStateChange,
      child: BlocBuilder<AttributeListBloc, AttributeListState>(
        builder: (context, state) {
          final attributes = state is AttributeListLoaded
              ? state.attributes
              : <MarketplaceAttribute>[];
          final isLoading = state is AttributeListLoading;
          final error =
              state is AttributeListError ? state.message : null;
          final currentPage =
              state is AttributeListLoaded ? state.currentPage : 1;
          final pageSize =
              state is AttributeListLoaded ? state.pageSize : 20;
          final totalItems =
              state is AttributeListLoaded ? state.totalItems : 0;

          return Column(
            children: [
              _TypeFilterBar(
                selectedType: _filterType,
                onTypeChanged: _applyTypeFilter,
              ),
              Expanded(
                child: AdminDataTable<MarketplaceAttribute>(
                  items: attributes,
                  isLoading: isLoading,
                  error: error,
                  onRetry: () => context
                      .read<AttributeListBloc>()
                      .add(RefreshAttributesEvent()),
                  currentPage: currentPage,
                  pageSize: pageSize,
                  totalItems: totalItems,
                  onPageChanged: (page) => context
                      .read<AttributeListBloc>()
                      .add(LoadAttributesEvent(page: page, type: _filterType)),
                  searchHint: 'Buscar por nombre o slug...',
                  onSearch: _onSearch,
                  createLabel: 'Nuevo atributo',
                  onCreateTap: () => context.push('/pim/attributes/new'),
                  columns: [
                    AdminColumn(
                      label: 'Nombre',
                      builder: (item) => _NameCell(
                        name: item.name,
                        slug: item.slug,
                      ),
                    ),
                    AdminColumn(
                      label: 'Tipo',
                      width: 120,
                      builder: (item) => _TypeChip(type: item.type),
                    ),
                    AdminColumn(
                      label: 'Obligatorio',
                      width: 110,
                      builder: (item) => _BoolIcon(value: item.isRequired),
                    ),
                    AdminColumn(
                      label: 'Filtrable',
                      width: 90,
                      builder: (item) => _BoolIcon(value: item.isFilterable),
                    ),
                    AdminColumn(
                      label: 'Valores',
                      width: 80,
                      builder: (item) => _ValuesCount(attribute: item),
                    ),
                    AdminColumn(
                      label: 'Acciones',
                      width: 120,
                      builder: (item) => _RowActions(attribute: item),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onFormStateChange(BuildContext context, AttributeFormState state) {
    if (state is AttributeFormSuccess) {
      AdminSnackbars.showSuccess(context, 'Operación realizada correctamente');
      context.read<AttributeListBloc>().add(RefreshAttributesEvent());
    } else if (state is AttributeFormError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// --- Filter bar ---

class _TypeFilterBar extends StatelessWidget {
  final AttributeType? selectedType;
  final ValueChanged<AttributeType?> onTypeChanged;

  const _TypeFilterBar({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Todos'),
              selected: selectedType == null,
              onSelected: (_) => onTypeChanged(null),
            ),
            const SizedBox(width: 8),
            ...AttributeType.values.map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.displayLabel),
                  selected: selectedType == type,
                  onSelected: (_) => onTypeChanged(type),
                ),
              ),
            ),
          ],
        ),
      ),
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

// --- Chip de tipo ---

class _TypeChip extends StatelessWidget {
  final AttributeType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
    return Chip(
      label: Text(
        type.displayLabel,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: color.withAlpha(26),
      side: BorderSide(color: color.withAlpha(77)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _colorForType(AttributeType type) => switch (type) {
        AttributeType.text => Colors.blue,
        AttributeType.number => Colors.purple,
        AttributeType.boolean => Colors.orange,
        AttributeType.select => Colors.green,
        AttributeType.multiSelect => Colors.teal,
      };
}

// --- Icono booleano ---

class _BoolIcon extends StatelessWidget {
  final bool value;

  const _BoolIcon({required this.value});

  @override
  Widget build(BuildContext context) {
    return Icon(
      value ? Icons.check_circle_outline : Icons.radio_button_unchecked,
      size: 18,
      color: value ? Colors.green[700] : Colors.grey[400],
    );
  }
}

// --- Contador de valores ---

class _ValuesCount extends StatelessWidget {
  final MarketplaceAttribute attribute;

  const _ValuesCount({required this.attribute});

  @override
  Widget build(BuildContext context) {
    if (!attribute.type.hasValues) {
      return Text('—', style: TextStyle(color: Colors.grey[400]));
    }
    return Text(
      '${attribute.values.length}',
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}

// --- Acciones de fila ---

class _RowActions extends StatelessWidget {
  final MarketplaceAttribute attribute;

  const _RowActions({required this.attribute});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'Ver detalle',
          onPressed: () =>
              context.push('/pim/attributes/${attribute.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () =>
              context.push('/pim/attributes/${attribute.id}/edit'),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar atributo',
      message:
          '¿Eliminar "${attribute.name}"? Este atributo puede estar en uso en productos.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<AttributeListBloc>().add(DeleteAttributeEvent(attribute.id));
    }
  }
}

// --- Extensión de display labels ---

extension _AttributeTypeLabel on AttributeType {
  String get displayLabel => switch (this) {
        AttributeType.text => 'Texto',
        AttributeType.number => 'Número',
        AttributeType.boolean => 'Booleano',
        AttributeType.select => 'Selección',
        AttributeType.multiSelect => 'Multi-selección',
      };
}
