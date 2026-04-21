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
    final items = (json['items'] as List? ?? []).map((item) {
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

    return PosSale(
      id: json['pos_sale_id'] ?? json['id'] ?? '',
      tenantId: TenantId(json['tenant_id'] ?? ''),
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
