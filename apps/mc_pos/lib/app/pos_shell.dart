import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'theme_cubit.dart';
import '../features/sale/sale_screen.dart';
import '../features/sale/sales_history_screen.dart';
import '../features/sale/cash_register_close_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/stock/stock_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

// ─── Tabs del POS ───────────────────────────────────────────────────────────

enum _PosTab {
  sell(Icons.shopping_cart_outlined, Icons.shopping_cart, 'Vender'),
  products(Icons.inventory_2_outlined, Icons.inventory_2, 'Productos'),
  stock(Icons.bar_chart_outlined, Icons.bar_chart, 'Stock'),
  summary(Icons.analytics_outlined, Icons.analytics, 'Resumen');

  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _PosTab(this.icon, this.activeIcon, this.label);
}

// ─── Shell ──────────────────────────────────────────────────────────────────

/// Shell principal del POS.
/// Mobile: bottom nav custom. Tablet/Desktop: sidebar navy.
class PosShell extends StatefulWidget {
  const PosShell({super.key});

  @override
  State<PosShell> createState() => _PosShellState();
}

class _PosShellState extends State<PosShell> {
  _PosTab _currentTab = _PosTab.sell;
  int _dashboardRefreshKey = 0;
  final List<CompletedSale> _completedSales = [];

  void _onSaleCompleted(CompletedSale sale) {
    setState(() {
      _completedSales.add(sale);
      _dashboardRefreshKey++;
    });
  }

  void _onSaleSynced(String saleId) {
    setState(() {
      _completedSales.removeWhere((s) => s.id == saleId);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureStockInitialized());
  }

  Future<void> _ensureStockInitialized() async {
    try {
      final catalogPort = context.read<CatalogPort>();
      final stockPort = context.read<StockPort>();

      final page = await catalogPort.listProducts(pageSize: 50);
      if (page.items.isEmpty) return;

      final skus = page.items
          .expand((p) => p.variants)
          .where((v) => v.sku != null)
          .map((v) => v.sku!.value)
          .toList();
      if (skus.isEmpty) return;

      final stockMap = await stockPort.getStockForSkus(skus);

      for (final product in page.items) {
        for (final variant in product.variants) {
          final sku = variant.sku?.value;
          if (sku == null || sku.isEmpty) continue;
          if (stockMap.containsKey(sku)) continue;
          await stockPort.createStockEntry(
            variantSku: sku,
            productName: '${product.name} - ${variant.name}',
            quantity: 100,
          );
        }
      }
    } catch (_) {
      // Silencioso — no bloquear POS si falla
    }
  }

  void _onCashRegisterClosed() {
    setState(() => _completedSales.clear());
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caja cerrada. ¡Buen día de ventas!'),
        backgroundColor: McColors.success,
      ),
    );
  }

  void _onTabSelected(int i) {
    setState(() {
      _currentTab = _PosTab.values[i];
      if (_currentTab == _PosTab.summary) _dashboardRefreshKey++;
    });
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentTab.index,
      children: [
        SaleScreen(
          completedSales: _completedSales,
          onSaleCompleted: _onSaleCompleted,
          onSaleSynced: _onSaleSynced,
          onShowHistory: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SalesHistoryScreen(localSales: _completedSales),
            ),
          ),
          onShowCashClose: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CashRegisterCloseScreen(
                sales: _completedSales,
                onClose: _onCashRegisterClosed,
              ),
            ),
          ),
        ),
        const CatalogScreen(),
        const StockScreen(),
        DashboardScreen(refreshTrigger: _dashboardRefreshKey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= McSpacing.breakpointTablet;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _PosSidebar(
              current: _currentTab,
              onSelected: _onTabSelected,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _PosBottomNav(
        current: _currentTab,
        onSelected: _onTabSelected,
      ),
    );
  }
}

// ─── Bottom Nav (mobile) ────────────────────────────────────────────────────

class _PosBottomNav extends StatelessWidget {
  final _PosTab current;
  final ValueChanged<int> onSelected;

  const _PosBottomNav({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: _PosTab.values.indexed.map((entry) {
              final (i, tab) = entry;
              final isActive = tab == current;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        size: 22,
                        color: isActive ? McColors.primary : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? McColors.primary : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (isActive)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: McColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Sidebar (tablet / desktop) ─────────────────────────────────────────────

class _PosSidebar extends StatelessWidget {
  final _PosTab current;
  final ValueChanged<int> onSelected;

  const _PosSidebar({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF050C40), // navy
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Logo ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: McColors.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mercado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9333EA),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'CERCANO',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                          color: McColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Color(0x14FFFFFF), height: 1),
            ),
            const SizedBox(height: 8),

            // ─── Nav items ───
            ..._PosTab.values.indexed.map((entry) {
              final (i, tab) = entry;
              final isActive = tab == current;
              return _SidebarItem(
                tab: tab,
                isActive: isActive,
                onTap: () => onSelected(i),
              );
            }),

            const Spacer(),

            // ─── Divider + toggle de tema ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Color(0x14FFFFFF), height: 1),
            ),
            const SizedBox(height: 8),
            const _SidebarThemeToggle(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Toggle de tema para el sidebar navy del POS (tablet/desktop).
class _SidebarThemeToggle extends StatelessWidget {
  const _SidebarThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => context.read<ThemeCubit>().toggle(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 9),
              Text(
                isDark ? 'Modo claro' : 'Modo oscuro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _PosTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0x800A21C0) // rgba cobalt 50%
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? tab.activeIcon : tab.icon,
                size: 15,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 9),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
