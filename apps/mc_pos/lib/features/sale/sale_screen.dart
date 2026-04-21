import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';
import '../auth/auth_cubit.dart';
import 'widgets/cart_panel.dart';
import 'widgets/customer_selector.dart';
import 'widgets/payment_method_selector.dart';
import 'widgets/product_search.dart';
import 'sales_history_screen.dart';

/// Pantalla principal del POS — flujo de venta.
/// Layout adaptativo: mobile (1 col) / tablet (2 col).
class SaleScreen extends StatefulWidget {
  final List<CompletedSale> completedSales;
  final ValueChanged<CompletedSale> onSaleCompleted;
  final VoidCallback? onShowHistory;
  final VoidCallback? onShowCashClose;

  const SaleScreen({
    super.key,
    required this.completedSales,
    required this.onSaleCompleted,
    this.onShowHistory,
    this.onShowCashClose,
  });

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  late PosSale _sale;
  Customer? _customer;
  PaymentMethod? _paymentMethod;
  bool _initialized = false;

  TenantId get _tenantId {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) return TenantId(authState.session.tenantId);
    return TenantId('unknown');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _sale = PosSale.start(tenantId: _tenantId);
      _initialized = true;
    }
  }

  void _addVariant(ProductVariant variant, String productName) {
    final sku = variant.sku?.value ?? variant.id;
    setState(() {
      _sale = _sale.addItem(PosSaleItem.create(
        sku: sku,
        productName: '$productName - ${variant.name}',
        quantity: 1,
        unitPrice: variant.price,
      ));
    });
  }

  Future<void> _persistSale() async {
    try {
      final salePort = context.read<SalePort>();
      await salePort.createSale(_sale);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar venta: $e'),
            backgroundColor: McColors.error,
          ),
        );
      }
    }
  }

  void _removeItem(String itemId) {
    setState(() {
      _sale = _sale.removeItem(itemId);
    });
  }

  void _updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      _removeItem(itemId);
      return;
    }
    setState(() {
      _sale = _sale.updateItemQuantity(itemId, quantity);
    });
  }

  void _completeSale() {
    if (_sale.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CheckoutSheet(
        total: _sale.finalAmount,
        customer: _customer,
        paymentMethod: _paymentMethod,
        onComplete: (customer, paymentMethod, amountPaid) {
          setState(() {
            _customer = customer;
            _paymentMethod = paymentMethod;
            _sale = _sale
                .setCustomer(customer.id)
                .pay(amountPaid, paymentMethodId: paymentMethod.id);
          });
          Navigator.of(context).pop();
          _showReceipt();
        },
      ),
    );
  }

  void _showReceipt() {
    final change = _sale.change;
    final methodName = _paymentMethod?.name ?? 'Efectivo';
    final customerName = _customer?.name ?? 'Consumidor Final';

    // Registrar venta completada localmente
    widget.onSaleCompleted(CompletedSale.fromPosSale(
      _sale,
      customerName: customerName,
      paymentMethodName: methodName,
    ));

    // Persistir en el backend
    _persistSale();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Venta #${widget.completedSales.length + 1} completada ($methodName). Vuelto: ${change.formatted}'),
        backgroundColor: McColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
    // Nueva venta
    setState(() {
      _sale = PosSale.start(tenantId: _tenantId);
      _customer = null;
      _paymentMethod = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MC POS'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.completedSales.isNotEmpty)
            Badge(
              label: Text('${widget.completedSales.length}'),
              child: IconButton(
                icon: const Icon(Icons.receipt_long),
                onPressed: widget.onShowHistory,
                tooltip: 'Ventas del día',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.point_of_sale),
            onPressed: widget.onShowCashClose,
            tooltip: 'Cierre de caja',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= McSpacing.breakpointTablet) {
            return _buildTabletLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  /// Tablet: 2 columnas — búsqueda izq, carrito der.
  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ProductSearch(onVariantSelected: _addVariant),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: CartPanel(
            sale: _sale,
            onRemoveItem: _removeItem,
            onUpdateQuantity: _updateQuantity,
            onComplete: _completeSale,
          ),
        ),
      ],
    );
  }

  /// Mobile: 1 columna — búsqueda arriba, carrito como bottom sheet.
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        ProductSearch(onVariantSelected: _addVariant),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MobileCartBar(
            sale: _sale,
            onTap: () => _showCartSheet(),
            onComplete: _completeSale,
          ),
        ),
      ],
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => CartPanel(
          sale: _sale,
          onRemoveItem: _removeItem,
          onUpdateQuantity: _updateQuantity,
          onComplete: _completeSale,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Barra fija en mobile que muestra total y abre el carrito.
class _MobileCartBar extends StatelessWidget {
  final PosSale sale;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _MobileCartBar({
    required this.sale,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (sale.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(McSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sale.totalItems} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      sale.finalAmount.formatted,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            McButton(
              label: 'Cobrar',
              icon: Icons.payment,
              size: McButtonSize.lg,
              onPressed: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de checkout — cliente + medio de pago + monto.
class _CheckoutSheet extends StatefulWidget {
  final Money total;
  final Customer? customer;
  final PaymentMethod? paymentMethod;
  final void Function(Customer, PaymentMethod, Money amountPaid) onComplete;

  const _CheckoutSheet({
    required this.total,
    this.customer,
    this.paymentMethod,
    required this.onComplete,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late final TextEditingController _amountController;
  late Customer? _customer;
  late PaymentMethod? _paymentMethod;
  double _enteredAmount = 0;

  @override
  void initState() {
    super.initState();
    _enteredAmount = widget.total.amount;
    _amountController = TextEditingController(
      text: widget.total.amount.toStringAsFixed(0),
    );
    _amountController.addListener(_onAmountChanged);
    _customer = widget.customer;
    _paymentMethod = widget.paymentMethod;
  }

  void _onAmountChanged() {
    setState(() {
      _enteredAmount = double.tryParse(_amountController.text) ?? 0;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  Money get _change {
    final diff = Money.ars(_enteredAmount) - widget.total;
    return diff.isNegative ? Money.zero : diff;
  }

  bool get _canComplete =>
      _paymentMethod != null && _enteredAmount >= widget.total.amount;

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || !_canComplete) return;

    final customer = _customer ??
        const Customer(
          id: 'default',
          tenantId: 'demo',
          name: 'Consumidor Final',
        );

    widget.onComplete(customer, _paymentMethod!, Money.ars(amount));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(McSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: McSpacing.base),

              // Total
              Center(
                child: Column(
                  children: [
                    Text('Total a cobrar',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      widget.total.formatted,
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: McColors.primary,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: McSpacing.lg),

              // Cliente
              Text('Cliente',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: McSpacing.sm),
              CustomerSelector(
                selected: _customer,
                onSelected: (c) => setState(() => _customer = c),
              ),
              const SizedBox(height: McSpacing.lg),

              // Medio de pago
              Text('Medio de pago',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: McSpacing.sm),
              PaymentMethodSelector(
                selected: _paymentMethod,
                onSelected: (pm) => setState(() {
                  _paymentMethod = pm;
                  // Si no es efectivo, el monto es exacto
                  if (!pm.isCash) {
                    _amountController.text =
                        widget.total.amount.toStringAsFixed(0);
                  }
                }),
              ),
              const SizedBox(height: McSpacing.lg),

              // Monto recibido (solo para efectivo)
              if (_paymentMethod?.isCash ?? true) ...[
                Text('Monto recibido',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: McSpacing.sm),
                McTextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                  autofocus: false,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: McSpacing.sm),
                // Botones rápidos de monto
                Wrap(
                  spacing: McSpacing.sm,
                  children: [500, 1000, 2000, 5000, 10000].map((v) {
                    return ActionChip(
                      label: Text('\$$v'),
                      onPressed: () {
                        _amountController.text = v.toString();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: McSpacing.md),

                // Vuelto en tiempo real
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(McSpacing.base),
                  decoration: BoxDecoration(
                    color: _change.isPositive
                        ? McColors.success.withValues(alpha: 0.1)
                        : _enteredAmount < widget.total.amount
                            ? McColors.error.withValues(alpha: 0.1)
                            : McColors.mutedLight,
                    borderRadius: BorderRadius.circular(McSpacing.radiusLg),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _enteredAmount < widget.total.amount
                            ? 'Falta'
                            : 'Vuelto',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _enteredAmount < widget.total.amount
                            ? (widget.total - Money.ars(_enteredAmount)).formatted
                            : _change.formatted,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _enteredAmount < widget.total.amount
                                  ? McColors.error
                                  : McColors.success,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: McSpacing.lg),
              ],

              // Botón confirmar
              McButton(
                label: _paymentMethod == null
                    ? 'Elegí un medio de pago'
                    : _enteredAmount < widget.total.amount
                        ? 'Monto insuficiente'
                        : 'Confirmar venta — ${_change.isPositive ? "Vuelto: ${_change.formatted}" : "Monto exacto"}',
                icon: Icons.check_circle,
                size: McButtonSize.lg,
                expand: true,
                onPressed: _canComplete ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
