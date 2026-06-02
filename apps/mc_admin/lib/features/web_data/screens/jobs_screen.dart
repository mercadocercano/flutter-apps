import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_data_table.dart';
import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../blocs/jobs_bloc.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String? _statusFilter;
  String? _sourceFilter;

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobsBloc, JobsState>(
      listener: _onStateChange,
      child: BlocBuilder<JobsBloc, JobsState>(
        builder: (context, state) {
          final jobs = state is JobsLoaded ? state.jobs : <WebJob>[];
          final isLoading = state is JobsLoading;
          final error = state is JobsError ? state.message : null;
          final hasRunning = state is JobsLoaded && state.hasRunningJobs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterBar(
                selectedStatus: _statusFilter,
                onStatusChanged: _applyStatusFilter,
                hasRunningJobs: hasRunning,
              ),
              Expanded(
                child: AdminDataTable<WebJob>(
                  items: jobs,
                  isLoading: isLoading,
                  error: error,
                  onRetry: () =>
                      context.read<JobsBloc>().add(RefreshJobsEvent()),
                  currentPage: 1,
                  pageSize: jobs.isNotEmpty ? jobs.length : 20,
                  totalItems: jobs.length,
                  onPageChanged: (_) {},
                  searchHint: 'Buscar jobs...',
                  columns: _buildColumns(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AdminColumn<WebJob>> _buildColumns(BuildContext context) {
    return [
      AdminColumn(
        label: 'Fuente',
        builder: (job) => Text(
          job.sourceId,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdminColumn(
        label: 'Estado',
        width: 110,
        builder: (job) => StatusBadge.fromString(job.status.name),
      ),
      AdminColumn(
        label: 'Progreso',
        width: 130,
        builder: (job) => _ProgressCell(job: job),
      ),
      AdminColumn(
        label: 'Productos',
        width: 90,
        builder: (job) => Text('${job.productsFound}'),
      ),
      AdminColumn(
        label: 'Iniciado',
        width: 130,
        builder: (job) => _DateCell(date: job.startedAt),
      ),
      AdminColumn(
        label: 'Duración',
        width: 90,
        builder: (job) => _DurationCell(seconds: job.durationSeconds),
      ),
      AdminColumn(
        label: 'Acciones',
        width: 130,
        builder: (job) => _RowActions(job: job),
      ),
    ];
  }

  void _applyStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<JobsBloc>().add(
          LoadJobsEvent(status: status, sourceId: _sourceFilter),
        );
  }

  void _onStateChange(BuildContext context, JobsState state) {
    if (state is JobsError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final bool hasRunningJobs;

  const _FilterBar({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.hasRunningJobs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatusChip(
            label: 'Todos',
            value: null,
            selected: selectedStatus == null,
            onSelected: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Corriendo',
            value: 'running',
            selected: selectedStatus == 'running',
            onSelected: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Completados',
            value: 'completed',
            selected: selectedStatus == 'completed',
            onSelected: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Fallidos',
            value: 'failed',
            selected: selectedStatus == 'failed',
            onSelected: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Cancelados',
            value: 'cancelled',
            selected: selectedStatus == 'cancelled',
            onSelected: onStatusChanged,
          ),
          if (hasRunningJobs) ...[
            const SizedBox(width: 16),
            _AutoUpdateChip(),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final ValueChanged<String?> onSelected;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _AutoUpdateChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.sync, size: 14),
      label: const Text('Auto-actualizando cada 5s'),
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withAlpha(180),
      labelStyle: const TextStyle(fontSize: 11),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ---------------------------------------------------------------------------
// Celdas de tabla
// ---------------------------------------------------------------------------

class _ProgressCell extends StatelessWidget {
  final WebJob job;

  const _ProgressCell({required this.job});

  @override
  Widget build(BuildContext context) {
    if (job.isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(value: job.progress),
          const SizedBox(height: 4),
          Text(
            '${(job.progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      );
    }
    return Text(
      '${(job.progress * 100).toStringAsFixed(0)}%',
      style: const TextStyle(fontSize: 13),
    );
  }
}

class _DateCell extends StatelessWidget {
  final DateTime date;

  const _DateCell({required this.date});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Text(formatted, style: const TextStyle(fontSize: 12));
  }
}

class _DurationCell extends StatelessWidget {
  final int? seconds;

  const _DurationCell({required this.seconds});

  @override
  Widget build(BuildContext context) {
    if (seconds == null) return const Text('—');
    if (seconds! < 60) return Text('${seconds}s');
    final minutes = seconds! ~/ 60;
    final secs = seconds! % 60;
    return Text('${minutes}m ${secs}s');
  }
}

// ---------------------------------------------------------------------------
// Acciones de fila
// ---------------------------------------------------------------------------

class _RowActions extends StatelessWidget {
  final WebJob job;

  const _RowActions({required this.job});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'Ver detalle',
          onPressed: () => context.push('/web-data/jobs/${job.id}'),
        ),
        if (job.status == WebJobStatus.running)
          IconButton(
            icon: Icon(Icons.cancel_outlined, size: 18, color: Colors.red[700]),
            tooltip: 'Cancelar',
            onPressed: () => _confirmCancel(context),
          ),
        if (job.status == WebJobStatus.failed)
          IconButton(
            icon: Icon(Icons.replay, size: 18,
                color: Theme.of(context).colorScheme.primary),
            tooltip: 'Reintentar',
            onPressed: () =>
                context.read<JobsBloc>().add(RetryJobEvent(job.id)),
          ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancelar job',
      message: '¿Cancelar el job en curso? El progreso no se puede recuperar.',
      confirmLabel: 'Cancelar job',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<JobsBloc>().add(CancelJobEvent(job.id));
    }
  }
}
