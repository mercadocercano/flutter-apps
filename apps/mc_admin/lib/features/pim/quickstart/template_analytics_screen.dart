import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_domain/mc_domain.dart';

import 'blocs/template_analytics_bloc.dart';

class TemplateAnalyticsScreen extends StatelessWidget {
  final String templateId;

  const TemplateAnalyticsScreen({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics de plantilla'),
      ),
      body: BlocBuilder<TemplateAnalyticsBloc, TemplateAnalyticsState>(
        builder: (context, state) {
          return switch (state) {
            TemplateAnalyticsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            TemplateAnalyticsLoaded(:final analytics) =>
              _AnalyticsBody(analytics: analytics),
            TemplateAnalyticsError(:final message) =>
              _ErrorBody(message: message, templateId: templateId),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

// --- Cuerpo principal de analytics ---

class _AnalyticsBody extends StatelessWidget {
  final TemplateAnalytics analytics;

  const _AnalyticsBody({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricCard(
            icon: Icons.store_outlined,
            label: 'Comercios que lo usaron',
            value: analytics.tenantsCount.toString(),
          ),
          const SizedBox(height: 16),
          _MetricCard(
            icon: Icons.calendar_today_outlined,
            label: 'Última activación',
            value: analytics.lastActivatedAt != null
                ? _formatDate(analytics.lastActivatedAt!)
                : 'Nunca',
          ),
          const SizedBox(height: 16),
          _CompletionRateCard(rate: analytics.completionRate),
        ],
      ),
    );
  }
}

// --- Tarjeta de métrica genérica ---

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tarjeta de tasa de completitud con barra de progreso ---

class _CompletionRateCard extends StatelessWidget {
  final double rate;

  const _CompletionRateCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    final percentage = (rate * 100).round();
    final color = rate >= 0.75
        ? Colors.green
        : rate >= 0.5
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasa de completitud',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              color: color,
              backgroundColor: color.withAlpha(51),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Estado de error ---

class _ErrorBody extends StatelessWidget {
  final String message;
  final String templateId;

  const _ErrorBody({required this.message, required this.templateId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.red[700])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context
                .read<TemplateAnalyticsBloc>()
                .add(LoadTemplateAnalyticsEvent(templateId)),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
