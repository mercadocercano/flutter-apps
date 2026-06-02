import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_domain/mc_domain.dart';

import 'blocs/dashboard_bloc.dart';
import 'widgets/dashboard_widgets.dart';

/// Dashboard principal de mc_admin.
///
/// Consolida métricas de IAM, PIM, Web Data y Quickstart en una sola vista.
/// Cada sección es independiente: si una falla (null), muestra hasError=true
/// y el resto carga normalmente. El auto-refresh ocurre cada 60 segundos.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              _buildTopBar(context, state),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HealthSection(state: state),
                    const SizedBox(height: 24),
                    _StatsGrid(state: state),
                    const SizedBox(height: 24),
                    _QuickActionsSection(),
                    const SizedBox(height: 24),
                    _AutoRefreshBadge(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildTopBar(BuildContext context, DashboardState state) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: const Text(
        'Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        if (state is DashboardLoaded)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _LastRefreshedLabel(refreshedAt: state.lastRefreshedAt),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _RefreshButton(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Botón de refresh manual
// ---------------------------------------------------------------------------

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final isLoading = state is DashboardLoading;
        return Semantics(
          label: 'Actualizar',
          child: IconButton(
            tooltip: 'Actualizar',
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: isLoading
                ? null
                : () => context.read<DashboardBloc>().add(AdminDashboardRefreshEvent()),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Label "Actualizado: HH:mm"
// ---------------------------------------------------------------------------

class _LastRefreshedLabel extends StatelessWidget {
  final DateTime refreshedAt;

  const _LastRefreshedLabel({required this.refreshedAt});

  @override
  Widget build(BuildContext context) {
    final h = refreshedAt.hour.toString().padLeft(2, '0');
    final m = refreshedAt.minute.toString().padLeft(2, '0');
    return Text(
      'Actualizado: $h:$m',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila de salud de servicios
// ---------------------------------------------------------------------------

class _HealthSection extends StatelessWidget {
  final DashboardState state;

  const _HealthSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final services = _servicesFromState(state);
    final isLoading = state is DashboardLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de servicios',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const _ServicesLoadingSkeleton()
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: services.isEmpty
                  ? [const _ServicesLoadingSkeleton()]
                  : services.map(_buildChip).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(ServiceHealth health) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ServiceHealthChip(
        serviceName: health.service,
        status: health.status.name,
        latencyMs: health.latencyMs,
      ),
    );
  }

  List<ServiceHealth> _servicesFromState(DashboardState state) {
    if (state is DashboardLoaded) return state.stats.services;
    return [];
  }
}

class _ServicesLoadingSkeleton extends StatelessWidget {
  const _ServicesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: 100,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid de 4 tarjetas de stats (2 × 2)
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final DashboardState state;

  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final loaded = state is DashboardLoaded ? state as DashboardLoaded : null;
    final isLoading = state is DashboardLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildIamCard(loaded, isLoading)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPimCard(loaded, isLoading)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWebDataCard(loaded, isLoading)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickstartCard(loaded, isLoading)),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildIamCard(loaded, isLoading),
            const SizedBox(height: 16),
            _buildPimCard(loaded, isLoading),
            const SizedBox(height: 16),
            _buildWebDataCard(loaded, isLoading),
            const SizedBox(height: 16),
            _buildQuickstartCard(loaded, isLoading),
          ],
        );
      },
    );
  }

  Widget _buildIamCard(DashboardLoaded? loaded, bool isLoading) {
    final iam = loaded?.stats.iam;
    return StatsSectionCard(
      title: 'IAM',
      icon: Icons.people_outline,
      color: Colors.indigo,
      isLoading: isLoading,
      hasError: loaded != null && iam == null,
      items: iam == null
          ? []
          : [
              StatItem(
                label: 'Tenants activos',
                value: iam.activeTenants,
              ),
              StatItem(
                label: 'Nuevos (24h)',
                value: iam.newTenantsLast24h,
              ),
              StatItem(label: 'Roles', value: iam.totalRoles),
              StatItem(label: 'Planes', value: iam.totalPlans),
            ],
    );
  }

  Widget _buildPimCard(DashboardLoaded? loaded, bool isLoading) {
    final pim = loaded?.stats.pim;
    return StatsSectionCard(
      title: 'PIM',
      icon: Icons.inventory_2_outlined,
      color: Colors.teal,
      isLoading: isLoading,
      hasError: loaded != null && pim == null,
      items: pim == null
          ? []
          : [
              StatItem(label: 'Categorías', value: pim.totalCategories),
              StatItem(
                label: 'Marcas',
                value: pim.totalBrands,
                subtitle: '${pim.verifiedBrands} verificadas',
              ),
              StatItem(
                label: 'Productos',
                value: pim.totalProducts,
                subtitle: '${pim.verifiedProducts} verificados',
              ),
              StatItem(label: 'Atributos', value: pim.totalAttributes),
            ],
    );
  }

  Widget _buildWebDataCard(DashboardLoaded? loaded, bool isLoading) {
    final webData = loaded?.stats.webData;
    return StatsSectionCard(
      title: 'Web Data',
      icon: Icons.cloud_outlined,
      color: Colors.orange,
      isLoading: isLoading,
      hasError: loaded != null && webData == null,
      items: webData == null
          ? []
          : [
              StatItem(label: 'Fuentes activas', value: webData.activeSources),
              StatItem(label: 'Jobs corriendo', value: webData.runningJobs),
              StatItem(
                label: 'Scrapeados hoy',
                value: webData.productsScrapedToday,
              ),
            ],
    );
  }

  Widget _buildQuickstartCard(DashboardLoaded? loaded, bool isLoading) {
    final qs = loaded?.stats.quickstart;
    return StatsSectionCard(
      title: 'Quickstart',
      icon: Icons.rocket_launch_outlined,
      color: Colors.purple,
      isLoading: isLoading,
      hasError: loaded != null && qs == null,
      items: qs == null
          ? []
          : [
              StatItem(
                label: 'Tipos de negocio',
                value: qs.activeBusinessTypes,
              ),
              StatItem(label: 'Templates', value: qs.activeTemplates),
            ],
    );
  }
}

// ---------------------------------------------------------------------------
// Accesos rápidos
// ---------------------------------------------------------------------------

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            QuickActionButton(
              label: 'Nuevo Tenant',
              icon: Icons.add_business_outlined,
              color: Colors.indigo,
              onTap: () => context.go('/iam/tenants/new'),
            ),
            QuickActionButton(
              label: 'Nueva Marca',
              icon: Icons.add_photo_alternate_outlined,
              color: Colors.teal,
              onTap: () => context.go('/pim/brands/new'),
            ),
            QuickActionButton(
              label: 'Trigger Fuente',
              icon: Icons.play_arrow_outlined,
              color: Colors.orange,
              onTap: () => context.go('/web-data/sources'),
            ),
            QuickActionButton(
              label: 'Nuevo Atributo',
              icon: Icons.add_chart_outlined,
              color: Colors.purple,
              onTap: () => context.go('/pim/attributes/new'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Badge de auto-refresh
// ---------------------------------------------------------------------------

class _AutoRefreshBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.autorenew_rounded, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          'Auto-refresh: 60s',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
              ),
        ),
      ],
    );
  }
}
