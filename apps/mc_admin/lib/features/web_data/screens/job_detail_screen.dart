import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../blocs/jobs_bloc.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  WebJob? _job;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final useCase = context.read<GetJobUseCase>();
      final job = await useCase.execute(widget.jobId);
      if (mounted) setState(() => _job = job);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar job: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Job #${widget.jobId.substring(0, 8)}...'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJob,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_job == null) return const SizedBox.shrink();
    return _JobDetailBody(
      job: _job!,
      onCancel: _onCancel,
      onRetry: _onRetry,
    );
  }

  Future<void> _onCancel() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancelar job',
      message: '¿Cancelar el job en curso? El progreso no se puede recuperar.',
      confirmLabel: 'Cancelar job',
      isDangerous: true,
    );
    if (confirmed == true && mounted) {
      context.read<JobsBloc>().add(CancelJobEvent(_job!.id));
      _loadJob();
    }
  }

  void _onRetry() {
    context.read<JobsBloc>().add(RetryJobEvent(_job!.id));
    AdminSnackbars.showSuccess(context, 'Job reiniciado.');
    _loadJob();
  }
}

// ---------------------------------------------------------------------------
// Cuerpo del detalle
// ---------------------------------------------------------------------------

class _JobDetailBody extends StatelessWidget {
  final WebJob job;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _JobDetailBody({
    required this.job,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildProgressSection(context),
          const SizedBox(height: 24),
          _buildStatsSection(context),
          if (job.errorLog != null) ...[
            const SizedBox(height: 24),
            _buildErrorLogSection(context),
          ],
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Job de scraping — ${job.sourceId}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(width: 16),
        StatusBadge.fromString(job.status.name),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: job.progress),
            const SizedBox(height: 8),
            Text('${(job.progress * 100).toStringAsFixed(1)}% completado'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadísticas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _StatRow(label: 'Productos encontrados', value: '${job.productsFound}'),
            _StatRow(
              label: 'Iniciado',
              value: _formatDateTime(job.startedAt),
            ),
            if (job.finishedAt != null)
              _StatRow(
                label: 'Finalizado',
                value: _formatDateTime(job.finishedAt!),
              ),
            if (job.durationSeconds != null)
              _StatRow(
                label: 'Duración',
                value: _formatDuration(job.durationSeconds!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorLogSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Log de error',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  job.errorLog!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (job.status == WebJobStatus.running)
          FilledButton.tonal(
            onPressed: onCancel,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Cancelar job'),
          ),
        if (job.status == WebJobStatus.failed) ...[
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
