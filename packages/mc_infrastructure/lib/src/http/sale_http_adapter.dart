import 'dart:typed_data';

import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del SalePort — habla con sales-service via Kong.
class SaleHttpAdapter implements SalePort {
  final McHttpClient _client;

  SaleHttpAdapter(this._client);

  @override
  Future<PosSale> createSale(PosSale sale) async {
    final response = await _client.post(
      ApiEndpoints.posSales,
      data: {
        // null = venta anónima (Consumidor Final) — backend acepta *uuid.UUID opcional
        if (sale.customerId != null && sale.customerId != 'default')
          'customer_id': sale.customerId,
        'items': sale.items
            .map((item) => {
                  'sku': item.sku,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice.amount.toStringAsFixed(2),
                })
            .toList(),
        'payment_method_id': sale.paymentMethodId,
        'discount_amount': sale.discountAmount.amount.toStringAsFixed(2),
        'amount_paid': sale.amountPaid.amount.toStringAsFixed(2),
        'currency': sale.currency,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return _mapSale(data);
  }

  @override
  Future<List<PosSale>> listSales({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _client.get(
      ApiEndpoints.posSales,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );

    final items = response.data['items'] as List? ?? [];
    return items.map((json) => _mapSale(json)).toList();
  }

  @override
  Future<PosSale> getSale(String saleId) async {
    final response = await _client.get(ApiEndpoints.posSale(saleId));
    return _mapSale(response.data);
  }

  @override
  Future<SaleReceipt> getReceipt(String saleId) async {
    final response = await _client.get(ApiEndpoints.posSale(saleId));
    return _mapReceipt(response.data as Map<String, dynamic>);
  }

  @override
  Future<Uint8List> downloadReceiptPdf(String saleId) async {
    final bytes = await _client.getBytes(ApiEndpoints.posSalePdf(saleId));
    return Uint8List.fromList(bytes);
  }

  // ─── Mapeo del comprobante (detalle completo) ───

  SaleReceipt _mapReceipt(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? []).map((raw) {
      final item = raw as Map<String, dynamic>;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final unitPrice = Money.ars(_toDouble(item['unit_price']));
      // subtotal explícito del backend si viene; si no, derivado.
      final subtotal = item['subtotal'] != null
          ? Money.ars(_toDouble(item['subtotal']))
          : unitPrice * quantity;
      return SaleReceiptItem(
        sku: item['sku']?.toString() ?? '',
        productName: item['product_name']?.toString() ??
            item['name']?.toString() ??
            '',
        quantity: quantity,
        unitPrice: unitPrice,
        subtotal: subtotal,
      );
    }).toList();

    final total = Money.ars(_toDouble(json['total_amount'] ?? json['total']));
    final discount =
        Money.ars(_toDouble(json['discount_amount'] ?? json['discount']));
    // total final: preferir el campo del backend; si no, total - descuento.
    final finalAmount = json['final_amount'] != null ||
            json['total_final'] != null
        ? Money.ars(_toDouble(json['final_amount'] ?? json['total_final']))
        : Money.ars(total.amount - discount.amount);
    final amountPaid = Money.ars(_toDouble(json['amount_paid']));
    final derivedChange = amountPaid.amount - finalAmount.amount;
    final change = json['change'] != null || json['change_amount'] != null
        ? Money.ars(_toDouble(json['change'] ?? json['change_amount']))
        : Money.ars(derivedChange > 0 ? derivedChange : 0.0);

    final tenantId = json['tenant_id']?.toString();

    return SaleReceipt(
      id: (json['pos_sale_id'] ?? json['id'] ?? saleIdFrom(json)).toString(),
      tenantId: TenantId(
        tenantId?.isNotEmpty == true ? tenantId! : 'unknown',
      ),
      saleNumber: (json['sale_number'] ??
              json['receipt_number'] ??
              json['number'] ??
              '')
          .toString(),
      items: items,
      total: total,
      discount: discount,
      finalAmount: finalAmount,
      amountPaid: amountPaid,
      change: change,
      currency: json['currency']?.toString() ?? 'ARS',
      paymentMethodId: json['payment_method_id']?.toString(),
      paymentMethodName: json['payment_method_name']?.toString() ??
          (json['payment_method'] is Map
              ? (json['payment_method'] as Map)['name']?.toString()
              : json['payment_method']?.toString()),
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString() ??
          (json['customer'] is Map
              ? (json['customer'] as Map)['name']?.toString()
              : null),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  static String saleIdFrom(Map<String, dynamic> json) =>
      (json['pos_sale_id'] ?? json['id'] ?? '').toString();

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  PosSale _mapSale(Map<String, dynamic> json) {
    var items = (json['items'] as List? ?? []).map((item) {
      return PosSaleItem(
        id: item['item_id'] ?? '',
        sku: item['sku'] ?? '',
        productName: item['product_name'] ?? '',
        quantity: item['quantity'] ?? 1,
        unitPrice: Money.ars(
          double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0,
        ),
      );
    }).toList();

    // El endpoint LIST no devuelve items[], solo totales.
    // Crear item sintético para que finalAmount = total_amount - discount_amount sea correcto.
    if (items.isEmpty && json['total_amount'] != null) {
      final totalAmount =
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0;
      if (totalAmount > 0) {
        items = [
          PosSaleItem(
            id: '',
            sku: '',
            productName: '',
            quantity: 1,
            unitPrice: Money.ars(totalAmount),
          ),
        ];
      }
    }

    final tenantId = json['tenant_id'] as String?;

    return PosSale(
      id: json['pos_sale_id'] ?? json['id'] ?? '',
      tenantId: TenantId(tenantId?.isNotEmpty == true ? tenantId! : 'unknown'),
      customerId: json['customer_id']?.toString(),
      paymentMethodId: json['payment_method_id']?.toString(),
      items: items,
      discountAmount: Money.ars(
        double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      ),
      amountPaid: Money.ars(
        double.tryParse(json['amount_paid']?.toString() ?? '0') ?? 0,
      ),
      currency: json['currency'] ?? 'ARS',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
