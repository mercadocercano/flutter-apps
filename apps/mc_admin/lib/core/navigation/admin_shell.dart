import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_design_system/mc_design_system.dart';

/// Wrapper para todas las rutas autenticadas.
/// NO usa Scaffold propio — provee solo la top bar encima del child.
/// Así evitamos el problema de nested Scaffolds donde el inner Scaffold
/// cubre el AppBar del outer Scaffold.
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  static const _navItems = [
    _NavItem('/brands', 'Marcas', Icons.branding_watermark_outlined),
    _NavItem('/global-products', 'Productos', Icons.inventory_2_outlined),
    _NavItem('/categories', 'Categorías', Icons.category_outlined),
    _NavItem('/business-types', 'Rubros', Icons.store_outlined),
  ];

  static String _titleFor(String location) {
    if (location.startsWith('/brands')) return 'Marcas';
    if (location.startsWith('/global-products')) return 'Productos globales';
    if (location.startsWith('/categories')) return 'Categorías';
    if (location.startsWith('/business-types')) return 'Tipos de comercio';
    return 'MC Admin';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleFor(location);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Top bar — fuera del Scaffold para evitar nested Scaffold issue
          Material(
            color: colorScheme.surface,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      // Logo mark
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: McColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _NavMenu(currentLocation: location, items: _navItems),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Body
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;

  const _NavItem(this.path, this.label, this.icon);
}

class _NavMenu extends StatelessWidget {
  final String currentLocation;
  final List<_NavItem> items;

  const _NavMenu({
    required this.currentLocation,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.apps),
      tooltip: 'Navegación',
      onSelected: (path) => context.go(path),
      itemBuilder: (context) => items.map((item) {
        final isActive = currentLocation.startsWith(item.path);
        return PopupMenuItem<String>(
          value: item.path,
          child: Row(
            children: [
              Icon(item.icon,
                  size: 18, color: isActive ? primary : null),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? primary : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
