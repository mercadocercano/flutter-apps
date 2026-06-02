import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../blocs/sources_bloc.dart';

/// Lista de fuentes de datos (web scraping sources).
///
/// Incluye filtros por estado, tabla con acciones por fila
/// (editar, trigger, eliminar) y botón de creación.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  String? _statusFilter;

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<SourcesBloc>().add(LoadSourcesEvent(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SourcesBloc, SourcesState>(
      listener: _onStateChange,
      child: BlocBuilder<SourcesBloc, SourcesState>(
        builder: (context, state) {
          final sources =
              state is SourcesLoaded ? state.sources : <WebSource>[];
          final isLoading = state is SourcesLoading;
          final error = state is SourcesError ? state.message : null;

          return Column(
            children: [
              _StatusFilterBar(
                selected: _statusFilter,
                onChanged: _applyFilter,
              ),
              Expanded(
                child: AdminDataTable<WebSource>(
                  items: sources,
                  isLoading: isLoading,
                  error: error,
                  onRetry: () =>
                      context.read<SourcesBloc>().add(RefreshSourcesEvent()),
                  currentPage: 1,
                  pageSize: sources.isNotEmpty ? sources.length : 20,
                  totalItems: sources.length,
                  onPageChanged: (_) {},
                  searchHint: 'Buscar fuente...',
                  createLabel: 'Nueva fuente',
                  onCreateTap: () => context.push('/web-data/sources/new'),
                  columns: _buildColumns(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AdminColumn<WebSource>> _buildColumns(BuildContext context) {
    return [
      AdminColumn(
        label: 'Nombre',
        builder: (item) => _NameCell(name: item.name),
      ),
      AdminColumn(
        label: 'URL',
        builder: (item) => _UrlCell(url: item.url),
      ),
      AdminColumn(
        label: 'Estado',
        width: 110,
        builder: (item) => StatusBadge.fromString(item.status.name),
      ),
      AdminColumn(
        label: 'Schedule',
        width: 140,
        builder: (item) => Text(
          item.schedule ?? '—',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdminColumn(
        label: 'Tipos negocio',
        width: 110,
        builder: (item) => Text(
          '${item.businessTypeIds.length}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      AdminColumn(
        label: 'Acciones',
        width: 140,
        builder: (item) => _RowActions(source: item),
      ),
    ];
  }

  void _onStateChange(BuildContext context, SourcesState state) {
    if (state is SourcesError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Filtro por estado
// ---------------------------------------------------------------------------

class _StatusFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _StatusFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <String?, String>{
      null: 'Todos',
      'active': 'Activo',
      'inactive': 'Inactivo',
      'running': 'Corriendo',
      'error': 'Error',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        children: filters.entries.map((entry) {
          return FilterChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => onChanged(entry.key),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Celdas de tabla
// ---------------------------------------------------------------------------

class _NameCell extends StatelessWidget {
  final String name;

  const _NameCell({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _UrlCell extends StatelessWidget {
  final String url;

  const _UrlCell({required this.url});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: url,
      child: Text(
        url,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Acciones de fila
// ---------------------------------------------------------------------------

class _RowActions extends StatelessWidget {
  final WebSource source;

  const _RowActions({required this.source});

  @override
  Widget build(BuildContext context) {
    final isRunning = !source.canTrigger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Editar',
          onPressed: () =>
              context.push('/web-data/sources/${source.id}/edit'),
        ),
        IconButton(
          icon: Icon(
            Icons.play_circle_outline,
            size: 18,
            color: isRunning ? Colors.grey : Colors.green[700],
          ),
          tooltip: isRunning ? 'Ya está corriendo' : 'Ejecutar ahora',
          onPressed: isRunning ? null : () => _triggerSource(context),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
          tooltip: 'Eliminar',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _triggerSource(BuildContext context) {
    context.read<SourcesBloc>().add(TriggerSourceEvent(source.id));
    AdminSnackbars.showSuccess(context, 'Job iniciado');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar fuente',
      message:
          '¿Eliminar "${source.name}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<SourcesBloc>().add(DeleteSourceEvent(source.id));
    }
  }
}
