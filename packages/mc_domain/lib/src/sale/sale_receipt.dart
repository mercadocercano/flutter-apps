import 'package:equatable/equatable.dart';
import '../common/money.dart';
import '../common/tenant_id.dart';

/// Comprobante de venta POS — vista de detalle completa de una venta ya
/// registrada en el backend (`GET /sales/api/v1/sales/pos/{id}`).
///
/// A diferencia de [PosSale] (aggregate del flujo de venta en construcción),
/// `SaleReceipt` es un snapshot inmutable de lo que el servidor devuelve:
/// incluye número de comprobante, totales calculados, vuelto, medio de pago
/// y datos del cliente ya resueltos por el backend.
class SaleReceipt extends Equatable {
  final String id;
  final TenantId tenantId;

  /// Número de comprobante legible para el comerciante (ej: "0001-00001234").
  final String saleNumber;

  final List<SaleReceiptItem> items;

  /// Suma de subtotales antes de descuento.
  final Money total;
  final Money discount;

  /// Total final cobrado (total - descuento).
  final Money finalAmount;
  final Money amountPaid;
  final Money change;

  final String currency;

  final String? paymentMethodId;
  final String? paymentMethodName;

  final String? customerId;
  final String? customerName;

  final DateTime createdAt;

  const SaleReceipt({
    required this.id,
    required this.tenantId,
    required this.saleNumber,
    required this.items,
    required this.total,
    required this.discount,
    required this.finalAmount,
    required this.amountPaid,
    required this.change,
    required this.currency,
    this.paymentMethodId,
    this.paymentMethodName,
    this.customerId,
    this.customerName,
    required this.createdAt,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get hasDiscount => discount.isPositive;

  /// Nombre del cliente o "Consumidor Final" si la venta fue anónima.
  String get customerDisplayName =>
      (customerName != null && customerName!.isNotEmpty)
          ? customerName!
          : 'Consumidor Final';

  @override
  List<Object?> get props => [id];
}

/// Línea de un comprobante.
class SaleReceiptItem extends Equatable {
  final String sku;
  final String productName;
  final int quantity;
  final Money unitPrice;
  final Money subtotal;

  const SaleReceiptItem({
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  @override
  List<Object?> get props => [sku, productName, quantity, unitPrice, subtotal];
}
