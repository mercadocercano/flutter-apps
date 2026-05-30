import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../domain/models/dev_metrics_model.dart';
import '../bloc/dev_metrics_bloc.dart';

const _kLangfuseNotConfiguredMsg =
    'Sin datos. Verificá que LANGFUSE_PUBLIC_KEY y LANGFUSE_SECRET_KEY estén configurados en commerce-ai-service.';

class DevMetricsScreen extends StatefulWidget {
  const DevMetricsScreen({super.key});

  @override
  State<DevMetricsScreen> createState() => _DevMetricsScreenState();
}

class _DevMetricsScreenState extends State<DevMetricsScreen> {
  int _selectedDays = 30;

  static const _dayOptions = [7, 14, 30, 90];

  @override
  void initState() {
    super.initState();
    context
        .read<DevMetricsBloc>()
        .add(LoadDevMetricsEvent(days: _selectedDays));
  }

  void _onDaysChanged(int days) {
    setState(() => _selectedDays = days);
    context.read<DevMetricsBloc>().add(LoadDevMetricsEvent(days: days));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
      body: BlocBuilder<DevMetricsBloc, DevMetricsState>(
        builder: (context, state) {
          if (state is DevMetricsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DevMetricsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<DevMetricsBloc>()
                  .add(LoadDevMetricsEvent(days: _selectedDays)),
            );
          }
          if (state is DevMetricsLoaded) {
            return _MetricsBody(
              metrics: state.metrics,
              selectedDays: _selectedDays,
              dayOptions: _dayOptions,
              onDaysChanged: _onDaysChanged,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Body con datos ───

class _MetricsBody extends StatelessWidget {
  final DevMetrics metrics;
  final int selectedDays;
  final List<int> dayOptions;
  final ValueChanged<int> onDaysChanged;

  const _MetricsBody({
    required this.metrics,
    required this.selectedDays,
    required this.dayOptions,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNotConfigured = metrics.totalSessions == 0 &&
        metrics.totalAgentCalls == 0 &&
        metrics.totalDeploys == 0 &&
        metrics.callsByStage.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(McSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top stat cards
          _StatCardsRow(metrics: metrics),
          const SizedBox(height: McSpacing.base),

          // Days selector
          _DaysSelector(
            selected: selectedDays,
            options: dayOptions,
            onChanged: onDaysChanged,
          ),
          const SizedBox(height: McSpacing.md),

          if (isNotConfigured) ...[
            _NotConfiguredBanner(),
          ] else ...[
            if (metrics.callsByStage.isNotEmpty) ...[
              _SectionTitle('Agent calls por stage'),
              const SizedBox(height: McSpacing.sm),
              _HorizBarSection(
                data: metrics.callsByStage,
                colorFor: _stageColor,
              ),
              const SizedBox(height: McSpacing.md),
            ],
            if (metrics.callsByScenario.isNotEmpty) ...[
              _SectionTitle('Calls por escenario'),
              const SizedBox(height: McSpacing.sm),
              _HorizBarSection(
                data: metrics.callsByScenario,
                colorFor: _scenarioColor,
              ),
              const SizedBox(height: McSpacing.md),
            ],
            if (metrics.callsByLevel.isNotEmpty) ...[
              _SectionTitle('Calls por nivel'),
              const SizedBox(height: McSpacing.sm),
              _HorizBarSection(
                data: metrics.callsByLevel,
                colorFor: (_) => McColors.primary,
              ),
              const SizedBox(height: McSpacing.md),
            ],
            if (metrics.callsBySpec.isNotEmpty) ...[
              _SectionTitle('Specs trabajados'),
              const SizedBox(height: McSpacing.sm),
              _SpecList(data: metrics.callsBySpec),
              const SizedBox(height: McSpacing.md),
            ],
            if (metrics.deploysByService.isNotEmpty) ...[
              _SectionTitle('CI Deploys por servicio'),
              const SizedBox(height: McSpacing.sm),
              _DeployTable(data: metrics.deploysByService),
              const SizedBox(height: McSpacing.md),
            ],
          ],
          const SizedBox(height: McSpacing.xl),
        ],
      ),
    );
  }
}

Color _stageColor(String stage) {
  return switch (stage) {
    'implement' => Colors.green,
    'classify' => Colors.cyan,
    'design' => Colors.blue,
    'validate' => Colors.orange,
    'deploy' => Colors.red,
    'gate' => Colors.amber,
    'review' => Colors.purple,
    _ => Colors.grey,
  };
}

Color _scenarioColor(String scenario) {
  return switch (scenario) {
    'feature' => Colors.green,
    'bugfix' => Colors.orange,
    'hotfix' => Colors.red,
    'refactor' => Colors.blue,
    _ => Colors.grey,
  };
}

// ─── Stat cards ───

class _StatCardsRow extends StatelessWidget {
  final DevMetrics metrics;

  const _StatCardsRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return Column(
            children: [
              _StatCard(
                label: 'Sesiones',
                value: metrics.totalSessions,
                icon: Icons.terminal,
                color: Colors.blue,
              ),
              const SizedBox(height: McSpacing.sm),
              _StatCard(
                label: 'Agent Calls',
                value: metrics.totalAgentCalls,
                icon: Icons.smart_toy_outlined,
                color: Colors.green,
              ),
              const SizedBox(height: McSpacing.sm),
              _StatCard(
                label: 'CI Deploys',
                value: metrics.totalDeploys,
                icon: Icons.rocket_launch_outlined,
                color: Colors.orange,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Sesiones',
                value: metrics.totalSessions,
                icon: Icons.terminal,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: McSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'Agent Calls',
                value: metrics.totalAgentCalls,
                icon: Icons.smart_toy_outlined,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: McSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'CI Deploys',
                value: metrics.totalDeploys,
                icon: Icons.rocket_launch_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        side: BorderSide(color: McColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: McSpacing.base,
          vertical: McSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(McSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: McSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: McColors.foregroundLight,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: McColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selector de días ───

class _DaysSelector extends StatelessWidget {
  final int selected;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _DaysSelector({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Periodo:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: McColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: McSpacing.sm),
        SegmentedButton<int>(
          segments: options
              .map((d) => ButtonSegment<int>(value: d, label: Text('${d}d')))
              .toList(),
          selected: {selected},
          onSelectionChanged: (s) => onChanged(s.first),
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sección de barras horizontales ───

class _HorizBarSection extends StatelessWidget {
  final Map<String, int> data;
  final Color Function(String) colorFor;

  const _HorizBarSection({required this.data, required this.colorFor});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        side: BorderSide(color: McColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.base),
        child: Column(
          children: data.entries
              .map((e) => _HorizBar(
                    label: e.key,
                    value: e.value,
                    maxValue: maxVal,
                    color: colorFor(e.key),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _HorizBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _HorizBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: McColors.foregroundLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: McSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 14,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: McSpacing.sm),
          SizedBox(
            width: 36,
            child: Text(
              value.toString(),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de specs ───

class _SpecList extends StatelessWidget {
  final Map<String, int> data;

  const _SpecList({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        side: BorderSide(color: McColors.borderLight),
      ),
      child: Column(
        children: data.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final spec = entry.value;
          final isLast = idx == data.length - 1;

          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: McColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: McColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  spec.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: McColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(McSpacing.radiusFull),
                  ),
                  child: Text(
                    spec.value.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: McColors.primary,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tabla de CI deploys ───

class _DeployTable extends StatelessWidget {
  final Map<String, DeployCount> data;

  const _DeployTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        side: BorderSide(color: McColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(
            McColors.backgroundLight,
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Servicio',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'OK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'FAIL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              numeric: true,
            ),
          ],
          rows: entries
              .map(
                (e) => DataRow(cells: [
                  DataCell(
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      e.value.ok.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      e.value.fail.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            e.value.fail > 0 ? Colors.red : McColors.textFg2,
                      ),
                    ),
                  ),
                ]),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ─── Título de sección ───

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: McColors.foregroundLight,
      ),
    );
  }
}

// ─── Banner no configurado ───

class _NotConfiguredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.base),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.amber.shade700, size: 28),
            const SizedBox(width: McSpacing.sm),
            Expanded(
              child: Text(
                _kLangfuseNotConfiguredMsg,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: McColors.error),
          const SizedBox(height: McSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: McSpacing.base),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
