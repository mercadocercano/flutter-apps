import 'package:dio/dio.dart';
import 'package:mc_application/mc_application.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

class TenantConfigHttpAdapter implements TenantConfigPort {
  final McHttpClient _client;

  TenantConfigHttpAdapter(this._client);

  @override
  Future<String?> getConfig(String key) async {
    try {
      final response = await _client.get(ApiEndpoints.tenantConfig(key));
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['value']?.toString();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> setConfig(String key, String value) async {
    await _client.post(
      ApiEndpoints.tenantConfigBase,
      data: {'key': key, 'value': value},
    );
  }
}
