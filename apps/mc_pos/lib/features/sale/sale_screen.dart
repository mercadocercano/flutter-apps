import 'package:dio/dio.dart';
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
import '../../widgets/pos/pos_top_bar.dart';
import '../../widgets/pos/pos_search_bar.dart';
import '../../widgets/pos/sync_pill.dart';
import '../../widgets/pos/cart_bar.dart';
import '../../constants/pos_constants.dart';
import 'cash_checkout_screen.dart';
import 'sale_confirmed_screen.dart';
import '../../widgets/pos/pos_modal.dart';

/// Pantalla principal del POS — flujo de venta.
/// Layout adaptativo: mobile (1 col) / tablet (2 col).
class SaleScreen extends StatefulWidget {
  final List<CompletedSale> completedSales;
  final ValueChanged<CompletedSale> onSaleCompleted;
  final ValueChanged<String>? onSaleSynced; // saleId cuando API confirma
  final VoidCallback? onShowHistory;
  final VoidCallback? onShowCashClose;

  const SaleScreen({
    super.key,
    required this.completedSales,
    required this.onSaleCompleted,
    this.onSaleSynced,
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
  List<PaymentMethod> _paymentMethods = [];
  bool _initialized = false;
  late final TextEditingController _searchController;

  TenantId get _tenantId {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) return TenantId(authState.session.tenantId);
    return TenantId('unknown');
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _sale = PosSale.start(tenantId: _tenantId);
      _initialized = true;
      _loadPaymentMethods();
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods =
          await context.read<PaymentMethodPort>().listPaymentMethods();
      if (mounted && methods.isNotEmpty) {
        setState(() => _paymentMethods = methods);
      }
    } catch (_) {
      // fallback: PaymentMethodSelector uses its own defaults
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _persistSale(PosSale sale) async {
    try {
      final salePort = context.read<SalePort>();
      await salePort.createSale(sale);
      // Notificar que el backend confirmó — remover de pendientes
      if (mounted) widget.onSaleSynced?.call(sale.id);
    } catch (e) {
      if (mounted) {
        final msg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar venta: $msg'),
            backgroundColor: McColors.error,
          ),
        );
      }
    }
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final serverMsg = data['error'] as String? ?? data['message'] as String?;
        if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) return 'Stock insuficiente o no inicializado';
      if (statusCode == 502) return 'Error de comunicación con el servidor';
      if (statusCode == null) return 'Sin conexión. Verificá tu internet.';
    }
    return 'No pudimos completar la venta. Intentá de nuevo.';
  }

  void _confirmLogout(BuildContext context) {
    showPosConfirm(
      context: context,
      title: 'Cerrar sesión',
      message: '¿Seguro que querés cerrar sesión?',
      confirmLabel: 'Cerrar sesión',
      confirmColor: McColors.error,
    ).then((confirmed) {
      if (confirmed && mounted) context.read<AuthCubit>().logout();
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _sale = _sale.removeItem(itemId);
    });
  }

  void _clearCart() {
    setState(() {
      _sale = PosSale.start(tenantId: _tenantId);
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

    final isWide = MediaQuery.sizeOf(context).width >= McSpacing.breakpointTablet;
    if (isWide) {
      _showCheckoutSheet();
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CashCheckoutScreen(
          sale: _sale,
          onComplete: _handleCheckoutComplete,
        ),
      ));
    }
  }

  void _showCheckoutSheet() {
    showPosDialog<void>(
      context: context,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: _CheckoutSheet(
          total: _sale.finalAmount,
          customer: _customer,
          paymentMethod: _paymentMethod,
          paymentMethods: _paymentMethods,
          onComplete: (customer, paymentMethod, amountPaid) {
            Navigator.of(context).pop();
            _handleCheckoutComplete(customer, paymentMethod, amountPaid);
          },
        ),
      ),
    );
  }

  void _handleCheckoutComplete(
    Customer customer,
    PaymentMethod paymentMethod,
    Money amountPaid,
  ) {
    // Completar la venta con cliente y pago
    final paidSale = _sale
        .setCustomer(customer.id)
        .pay(amountPaid, paymentMethodId: paymentMethod.id);

    final completedSale = CompletedSale.fromPosSale(
      paidSale,
      customerName: customer.name,
      paymentMethodName: paymentMethod.name,
    );
    widget.onSaleCompleted(completedSale);
    _persistSale(paidSale); // fire-and-forget con snapshot de la venta

    // Capturar datos para SaleConfirmedScreen antes de limpiar estado
    final saleNumber = '${widget.completedSales.length}';
    final totalAmount = paidSale.finalAmount.amount;
    final receivedAmount = amountPaid.amount;
    final methodName = paymentMethod.name;
    final tenantId = _tenantId;

    // Limpiar carrito inmediatamente — no esperar a que el usuario pulse "Nueva venta"
    setState(() {
      _sale = PosSale.start(tenantId: tenantId);
      _customer = null;
      _paymentMethod = null;
    });

    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => SaleConfirmedScreen(
        saleNumber: saleNumber,
        total: totalAmount,
        received: receivedAmount,
        paymentMethodName: methodName,
        onNewSale: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          // Carrito ya limpio — no necesita setState aquí
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.backgroundLight,
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

  Widget _buildAccountMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined, color: McColors.textFg2),
      tooltip: 'Cuenta',
      onSelected: (value) {
        if (value == 'logout') _confirmLogout(context);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }

  /// Tablet: 2 columnas — búsqueda izq, carrito der.
  Widget _buildTabletLayout() {
    return Column(
      children: [
        PosTopBar(
          title: 'Vender',
          subtitle: 'Lo que más sale',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncPill(status: PosSyncStatus.synced),
              if (widget.completedSales.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  color: McColors.textFg2,
                  onPressed: widget.onShowHistory,
                  tooltip: 'Ventas del día',
                ),
              IconButton(
                icon: const Icon(Icons.point_of_sale),
                color: McColors.textFg2,
                onPressed: widget.onShowCashClose,
                tooltip: 'Cierre de caja',
              ),
              _buildAccountMenu(),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    PosSearchBar(
                      controller: _searchController,
                      hint: 'Buscar producto o escanear código',
                    ),
                    Expanded(
                      child: ProductSearch(
                        onVariantSelected: _addVariant,
                        cartItems: _sale.items,
                        externalSearchController: _searchController,
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: CartPanel(
                  sale: _sale,
                  onRemoveItem: _removeItem,
                  onUpdateQuantity: _updateQuantity,
                  onComplete: _completeSale,
                  onClear: _clearCart,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile: 1 columna — búsqueda arriba, carrito como bottom sheet.
  Widget _buildMobileLayout() {
    return Column(
      children: [
        PosTopBar(
          title: 'Vender',
          subtitle: 'Lo que más sale',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncPill(status: PosSyncStatus.synced),
              if (widget.completedSales.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  color: McColors.textFg2,
                  onPressed: widget.onShowHistory,
                  tooltip: 'Ventas del día',
                ),
              IconButton(
                icon: const Icon(Icons.point_of_sale),
                color: McColors.textFg2,
                onPressed: widget.onShowCashClose,
                tooltip: 'Cierre de caja',
              ),
              _buildAccountMenu(),
            ],
          ),
        ),
        PosSearchBar(
          controller: _searchController,
          hint: 'Buscar producto o escanear código',
        ),
        Expanded(
          child: Stack(
            children: [
              ProductSearch(
                onVariantSelected: _addVariant,
                cartItems: _sale.items,
                externalSearchController: _searchController,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CartBar(
                  count: _sale.totalItems,
                  total: _sale.finalAmount.amount,
                  onTap: _showCartSheet,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCartSheet() {
    showPosModal(
      context: context,
      isScrollControlled: true,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => CartPanel(
          sale: _sale,
          onRemoveItem: _removeItem,
          onUpdateQuantity: _updateQuantity,
          onComplete: _completeSale,
          onClear: _clearCart,
          scrollController: scrollController,
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
  final List<PaymentMethod> paymentMethods;
  final void Function(Customer, PaymentMethod, Money amountPaid) onComplete;

  const _CheckoutSheet({
    required this.total,
    this.customer,
    this.paymentMethod,
    this.paymentMethods = const [],
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
                methods: widget.paymentMethods,
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
