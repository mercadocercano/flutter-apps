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
