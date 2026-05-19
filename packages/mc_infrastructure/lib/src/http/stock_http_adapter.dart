import 'package:mc_application/mc_application.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del StockPort — habla con stock-service via Kong.
class StockHttpAdapter implements StockPort {
  final McHttpClient _client;

  StockHttpAdapter(this._client);

  @override
  Future<int> getStockBySku(String sku) async {
    final response = await _client.get(
      ApiEndpoints.stockAvailability,
      queryParameters: {'sku': sku},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    return (data['available_quantity'] as num? ?? 0).toInt();
  }

  @override
  Future<Map<String, int>> getStockForSkus(List<String> skus) async {
    // Stock service has no batch-by-sku endpoint — fetch all and filter.
    final response = await _client.get(
      ApiEndpoints.stockAvailability,
      queryParameters: {'page': 1, 'page_size': 500},
    );

    final data = response.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List? ?? []).whereType<Map<String, dynamic>>();
    final skuSet = skus.toSet();
    final result = <String, int>{};
    for (final item in items) {
      final itemSku = item['product_sku'] as String? ?? '';
      if (skuSet.contains(itemSku)) {
        result[itemSku] = (item['available_quantity'] as num? ?? 0).toInt();
      }
    }
    return result;
  }

  @override
  Future<void> adjustStock({
    required String sku,
    required double quantity,
    required String entryType,
    String? notes,
  }) async {
    await _client.post(
      ApiEndpoints.stockEntries,
      data: {
        'variant_sku': sku,
        'entry_type': entryType,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      },
    );
  }

  @override
  Future<void> createStockEntry({
    required String variantSku,
    required String productName,
    required int quantity,
  }) async {
    await _client.post(
      ApiEndpoints.stockEntries,
      data: {
        'variant_sku': variantSku,
        'product_name': productName,
        'entry_type': 'initial_stock',
        'quantity': quantity,
        'unit_of_measure': 'unit',
        'notes': 'Carga inicial desde Quickstart',
      },
    );
  }
}
