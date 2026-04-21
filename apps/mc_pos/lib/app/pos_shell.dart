import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';
import '../features/sale/sale_screen.dart';
import '../features/sale/sales_history_screen.dart';
import '../features/sale/cash_register_close_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/stock/stock_screen.dart';
import '../features/settings/settings_screen.dart';

/// Shell principal del POS — bottom navigation con 4 tabs.
class PosShell extends StatefulWidget {
  const PosShell({super.key});

  @override
  State<PosShell> createState() => _PosShellState();
}

class _PosShellState extends State<PosShell> {
  int _currentIndex = 0;
  final List<CompletedSale> _completedSales = [];

  void _onSaleCompleted(CompletedSale sale) {
    setState(() => _completedSales.add(sale));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SaleScreen(
            completedSales: _completedSales,
            onSaleCompleted: _onSaleCompleted,
            onShowHistory: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SalesHistoryScreen(sales: _completedSales),
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
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Vender',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
