import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../common/money.dart';
import '../common/tenant_id.dart';
import 'pos_sale_item.dart';

/// Venta POS — aggregate root del flujo de venta del comerciante.
class PosSale extends Equatable {
  final String id;
  final TenantId tenantId;
  final String? customerId;
  final String? paymentMethodId;
  final List<PosSaleItem> items;
  final Money discountAmount;
  final Money amountPaid;
  final String currency;
  final DateTime createdAt;

  const PosSale({
    required this.id,
    required this.tenantId,
    this.customerId,
    this.paymentMethodId,
    this.items = const [],
    this.discountAmount = Money.zero,
    this.amountPaid = Money.zero,
    this.currency = 'ARS',
    required this.createdAt,
  });

  factory PosSale.start({required TenantId tenantId}) {
    return PosSale(
      id: const Uuid().v4(),
      tenantId: tenantId,
      createdAt: DateTime.now(),
    );
  }

  // ─── Cálculos ───

  Money get totalAmount =>
      items.fold(Money.zero, (sum, item) => sum + item.subtotal);

  Money get finalAmount {
    final result = totalAmount - discountAmount;
    return result.isNegative ? Money.zero : result;
  }

  Money get change {
    final diff = amountPaid - finalAmount;
    return diff.isNegative ? Money.zero : diff;
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get canComplete => items.isNotEmpty && amountPaid >= finalAmount;

  // ─── Commands ───

  PosSale addItem(PosSaleItem item) {
    // Si ya existe el SKU, sumar cantidad
    final existing = items.where((i) => i.sku == item.sku).firstOrNull;
    if (existing != null) {
      return _replaceItem(
        existing.id,
        existing.withQuantity(existing.quantity + item.quantity),
      );
    }
    return copyWith(items: [...items, item]);
  }

  PosSale updateItemQuantity(String itemId, int quantity) {
    final item = items.firstWhere((i) => i.id == itemId);
    return _replaceItem(itemId, item.withQuantity(quantity));
  }

  PosSale removeItem(String itemId) {
    return copyWith(items: items.where((i) => i.id != itemId).toList());
  }

  PosSale applyDiscount(Money discount) {
    if (discount.isNegative) throw ArgumentError('Descuento no puede ser negativo');
    return copyWith(discountAmount: discount);
  }

  PosSale pay(Money amount, {String? paymentMethodId}) {
    if (!amount.isPositive) throw ArgumentError('Monto debe ser positivo');
    return copyWith(amountPaid: amount, paymentMethodId: paymentMethodId);
  }

  PosSale setCustomer(String customerId) {
    return copyWith(customerId: customerId);
  }

  PosSale _replaceItem(String itemId, PosSaleItem updated) {
    return copyWith(
      items: items.map((i) => i.id == itemId ? updated : i).toList(),
    );
  }

  PosSale copyWith({
    String? customerId,
    String? paymentMethodId,
    List<PosSaleItem>? items,
    Money? discountAmount,
    Money? amountPaid,
  }) {
    return PosSale(
      id: id,
      tenantId: tenantId,
      customerId: customerId ?? this.customerId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
