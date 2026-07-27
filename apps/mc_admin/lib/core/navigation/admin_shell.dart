import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../api/auth_helper.dart';
import '../themes/theme_cubit.dart';

/// Layout principal de mc_admin: sidebar izquierdo + área de contenido.
/// Sidebar colapsable en pantallas < 1024px (drawer).
class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 1024;
    final location = GoRouterState.of(context).matchedLocation;

    if (isNarrow) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_titleFor(location)),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: const [_ThemeToggleButton()],
        ),
        drawer: Drawer(
          child: _SidebarContent(currentLocation: location),
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _sidebarExpanded ? 240 : 64,
            child: _SidebarContent(
              currentLocation: location,
              collapsed: !_sidebarExpanded,
              onToggleCollapse: () =>
                  setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  static String _titleFor(String location) {
    if (location.startsWith('/dashboard')) return 'Dashboard';
    if (location.startsWith('/iam/tenants')) return 'Tenants';
    if (location.startsWith('/iam/roles')) return 'Roles';
    if (location.startsWith('/iam/plans')) return 'Planes';
    if (location.startsWith('/pim/taxonomy')) return 'Taxonomía';
    if (location.startsWith('/pim/brands')) return 'Marcas';
    if (location.startsWith('/pim/global-catalog')) return 'Catálogo Global';
    if (location.startsWith('/pim/attributes')) return 'Atributos';
    if (location.startsWith('/web-data/dashboard')) return 'Web Data';
    if (location.startsWith('/web-data/sources')) return 'Fuentes';
    if (location.startsWith('/web-data/jobs')) return 'Jobs';
    if (location.startsWith('/web-data/products')) return 'Productos Web';
    if (location.startsWith('/quickstart/business-types')) return 'Tipos de Negocio';
    if (location.startsWith('/quickstart/templates')) return 'Templates';
    return 'MC Admin';
  }
}

// ---------------------------------------------------------------------------

class _SidebarContent extends StatefulWidget {
  final String currentLocation;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  const _SidebarContent({
    required this.currentLocation,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<_SidebarContent> createState() => _SidebarContentState();
}

class _SidebarContentState extends State<_SidebarContent> {
  // Secciones expandidas por defecto según la ruta activa
  late final Map<String, bool> _expanded = {
    'iam': widget.currentLocation.startsWith('/iam'),
    'pim': widget.currentLocation.startsWith('/pim'),
    'webdata': widget.currentLocation.startsWith('/web-data'),
    'quickstart': widget.currentLocation.startsWith('/quickstart'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Material(
      color: c.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header logo
          _SidebarHeader(
            collapsed: widget.collapsed,
            onToggle: widget.onToggleCollapse,
          ),
          const Divider(height: 1),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  path: '/dashboard',
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  currentLocation: widget.currentLocation,
                  collapsed: widget.collapsed,
                ),
                const SizedBox(height: 4),
                _NavSection(
                  key: const ValueKey('iam'),
                  label: 'Identity & Access',
                  icon: Icons.shield_outlined,
                  isExpanded: !widget.collapsed && (_expanded['iam'] ?? false),
                  collapsed: widget.collapsed,
                  onTap: widget.collapsed
                      ? null
                      : () => setState(
                            () => _expanded['iam'] = !(_expanded['iam'] ?? false),
                          ),
                  children: [
                    _NavItem(
                      path: '/iam/tenants',
                      label: 'Tenants',
                      icon: Icons.corporate_fare_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/iam/roles',
                      label: 'Roles',
                      icon: Icons.manage_accounts_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/iam/plans',
                      label: 'Planes',
                      icon: Icons.card_membership_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _NavSection(
                  key: const ValueKey('pim'),
                  label: 'Marketplace PIM',
                  icon: Icons.layers_outlined,
                  isExpanded: !widget.collapsed && (_expanded['pim'] ?? false),
                  collapsed: widget.collapsed,
                  onTap: widget.collapsed
                      ? null
                      : () => setState(
                            () => _expanded['pim'] = !(_expanded['pim'] ?? false),
                          ),
                  children: [
                    _NavItem(
                      path: '/pim/taxonomy',
                      label: 'Taxonomía',
                      icon: Icons.account_tree_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/pim/brands',
                      label: 'Marcas',
                      icon: Icons.branding_watermark_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/pim/global-catalog',
                      label: 'Catálogo Global',
                      icon: Icons.shopping_cart_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/pim/attributes',
                      label: 'Atributos',
                      icon: Icons.tune_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _NavSection(
                  key: const ValueKey('webdata'),
                  label: 'Web Data',
                  icon: Icons.sync_alt_outlined,
                  isExpanded: !widget.collapsed && (_expanded['webdata'] ?? false),
                  collapsed: widget.collapsed,
                  onTap: widget.collapsed
                      ? null
                      : () => setState(
                            () => _expanded['webdata'] =
                                !(_expanded['webdata'] ?? false),
                          ),
                  children: [
                    _NavItem(
                      path: '/web-data/dashboard',
                      label: 'Dashboard',
                      icon: Icons.bar_chart_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/web-data/sources',
                      label: 'Fuentes',
                      icon: Icons.language_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/web-data/jobs',
                      label: 'Jobs',
                      icon: Icons.schedule_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/web-data/products',
                      label: 'Productos',
                      icon: Icons.inventory_2_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _NavSection(
                  key: const ValueKey('quickstart'),
                  label: 'Quickstart Dinámico',
                  icon: Icons.rocket_launch_outlined,
                  isExpanded: !widget.collapsed && (_expanded['quickstart'] ?? false),
                  collapsed: widget.collapsed,
                  onTap: widget.collapsed
                      ? null
                      : () => setState(
                            () => _expanded['quickstart'] =
                                !(_expanded['quickstart'] ?? false),
                          ),
                  children: [
                    _NavItem(
                      path: '/quickstart/business-types',
                      label: 'Tipos de Negocio',
                      icon: Icons.store_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                    _NavItem(
                      path: '/quickstart/templates',
                      label: 'Templates',
                      icon: Icons.description_outlined,
                      currentLocation: widget.currentLocation,
                      collapsed: false,
                      indent: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Footer: toggle de tema + logout
          _ThemeToggleTile(collapsed: widget.collapsed),
          _LogoutTile(collapsed: widget.collapsed),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final VoidCallback? onToggle;

  const _SidebarHeader({required this.collapsed, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: McColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront_outlined,
                  color: Colors.white, size: 18),
            ),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MC Admin',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (onToggle != null)
              IconButton(
                icon: Icon(
                  collapsed ? Icons.chevron_right : Icons.chevron_left,
                  size: 18,
                ),
                onPressed: onToggle,
                tooltip: collapsed ? 'Expandir' : 'Colapsar',
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _NavSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isExpanded;
  final bool collapsed;
  final VoidCallback? onTap;
  final List<Widget> children;

  const _NavSection({
    super.key,
    required this.label,
    required this.icon,
    required this.isExpanded,
    required this.collapsed,
    this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Tooltip(
          message: label,
          child: IconButton(
            icon: Icon(icon, size: 20, color: c.onSurfaceVariant),
            onPressed: onTap,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: c.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: c.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: c.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: isExpanded
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final String path;
  final String label;
  final IconData icon;
  final String currentLocation;
  final bool collapsed;
  final bool indent;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.currentLocation,
    required this.collapsed,
    this.indent = false,
  });

  bool get _isActive => currentLocation.startsWith(path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final active = _isActive;

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Tooltip(
          message: label,
          child: Container(
            decoration: BoxDecoration(
              color: active ? c.primaryContainer : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                icon,
                size: 20,
                color: active ? c.primary : c.onSurfaceVariant,
              ),
              onPressed: () => context.go(path),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(indent ? 28 : 8, 1, 8, 1),
      child: Material(
        color: active ? c.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? c.primary : c.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: active ? c.primary : c.onSurface,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Tile del sidebar para alternar claro/oscuro. Reactivo al ThemeCubit.
class _ThemeToggleTile extends StatelessWidget {
  final bool collapsed;

  const _ThemeToggleTile({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final icon = isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    final label = isDark ? 'Modo claro' : 'Modo oscuro';

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Tooltip(
          message: label,
          child: IconButton(
            icon: Icon(icon, size: 20, color: c.onSurfaceVariant),
            onPressed: () => context.read<ThemeCubit>().toggle(),
          ),
        ),
      );
    }
    return ListTile(
      leading: Icon(icon, color: c.onSurfaceVariant, size: 18),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () => context.read<ThemeCubit>().toggle(),
      dense: true,
    );
  }
}

// ---------------------------------------------------------------------------

/// Botón de toggle para el AppBar (modo narrow).
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
      onPressed: () => context.read<ThemeCubit>().toggle(),
    );
  }
}

// ---------------------------------------------------------------------------

class _LogoutTile extends StatelessWidget {
  final bool collapsed;

  const _LogoutTile({required this.collapsed});

  Future<void> _logout(BuildContext context) async {
    await AuthHelper.clearTokens();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Tooltip(
          message: 'Cerrar Sesión',
          child: IconButton(
            icon: Icon(Icons.logout, size: 20, color: c.error),
            onPressed: () => _logout(context),
          ),
        ),
      );
    }
    return ListTile(
      leading: Icon(Icons.logout, color: c.error, size: 18),
      title: Text(
        'Cerrar Sesión',
        style: TextStyle(color: c.error, fontSize: 14),
      ),
      onTap: () => _logout(context),
      dense: true,
    );
  }
}
