import 'package:mc_application/mc_application.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del StockPort — habla con stock-service via Kong.
class StockHttpAdapter implements StockPort {
  final McHttpClient _client;

  StockHttpAdapter(this._client);

  @override
  Future<int> getStockBySku(String sku) async {
    final response = await _client.get(ApiEndpoints.stockForSku(sku));
    final data = response.data as Map<String, dynamic>;
    return (data['available'] ?? data['available_quantity'] ?? 0).toInt();
  }

  @override
  Future<Map<String, int>> getStockForSkus(List<String> skus) async {
    final response = await _client.post(
      ApiEndpoints.stockBySku,
      data: {'skus': skus},
    );

    final items = response.data['items'] as List? ?? [];
    final result = <String, int>{};
    for (final item in items) {
      final sku = item['product_sku'] ?? item['sku'] ?? '';
      final qty = (item['available'] ?? item['available_quantity'] ?? 0).toInt();
      result[sku] = qty;
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
}
