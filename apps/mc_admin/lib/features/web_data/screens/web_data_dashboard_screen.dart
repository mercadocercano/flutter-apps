import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../../shared/widgets/admin_snackbars.dart';
import '../../../shared/widgets/status_badge.dart';
import '../blocs/web_data_dashboard_bloc.dart';

/// Dashboard del módulo Web Data.
///
/// Muestra 4 tarjetas de métricas: Fuentes Activas, Jobs Hoy, Productos Totales
/// y Tasa de Éxito. Debajo lista los últimos 5 jobs recientes con su estado.
class WebDataDashboardScreen extends StatelessWidget {
  const WebDataDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WebDataDashboardBloc, WebDataDashboardState>(
      listener: _onStateChange,
      child: BlocBuilder<WebDataDashboardBloc, WebDataDashboardState>(
        builder: (context, state) => switch (state) {
          WebDataDashboardInitial() => const _LoadingView(),
          WebDataDashboardLoading() => const _LoadingView(),
          WebDataDashboardLoaded s => _LoadedView(
              stats: s.stats,
              recentJobs: s.recentJobs,
            ),
          WebDataDashboardError s => _ErrorView(message: s.message),
          _ => const _LoadingView(),
        },
      ),
    );
  }

  void _onStateChange(BuildContext context, WebDataDashboardState state) {
    if (state is WebDataDashboardError) {
      AdminSnackbars.showError(context, state.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-vistas
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context
                .read<WebDataDashboardBloc>()
                .add(RefreshDashboardEvent()),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final WebDataDashboardStats stats;
  final List<WebJob> recentJobs;

  const _LoadedView({required this.stats, required this.recentJobs});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context
          .read<WebDataDashboardBloc>()
          .add(RefreshDashboardEvent()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCardsRow(stats: stats),
            const SizedBox(height: 32),
            _RecentJobsSection(jobs: recentJobs),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas de estadísticas
// ---------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  final WebDataDashboardStats stats;

  const _StatCardsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              icon: Icons.hub_outlined,
              value: '${stats.activeSources}',
              label: 'Fuentes Activas',
              color: Colors.green,
            ),
            _StatCard(
              icon: Icons.work_history_outlined,
              value: '${stats.jobsToday}',
              label: 'Jobs Hoy',
              color: Colors.blue,
            ),
            _StatCard(
              icon: Icons.inventory_2_outlined,
              value: '${stats.totalProducts}',
              label: 'Productos Totales',
              color: Colors.blue,
            ),
            _StatCard(
              icon: Icons.check_circle_outline,
              value: '${stats.successRatePercent}%',
              label: 'Tasa de Éxito',
              color: stats.successRatePercent >= 70 ? Colors.green : Colors.red,
            ),
          ],

        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  /// Color base de la tarjeta. Debe ser un [MaterialColor] (ej: Colors.green).
  final MaterialColor color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color.shade50;
    final iconColor = color.shade700;
    final borderColor = color.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sección de jobs recientes
// ---------------------------------------------------------------------------

class _RecentJobsSection extends StatelessWidget {
  final List<WebJob> jobs;

  const _RecentJobsSection({required this.jobs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jobs recientes',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No hay jobs recientes')),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < jobs.length; i++) ...[
                  _RecentJobRow(job: jobs[i]),
                  if (i < jobs.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentJobRow extends StatelessWidget {
  final WebJob job;

  const _RecentJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.receipt_long_outlined, size: 20),
      title: Text(
        job.sourceId,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDateTime(job.startedAt),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey[600]),
      ),
      trailing: StatusBadge.fromString(job.status.name),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
