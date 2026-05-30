import '../../../core/api/kong_client.dart';
import '../domain/models/dev_metrics_model.dart';

class DevMetricsApi {
  final KongClient _kong;

  DevMetricsApi(this._kong);

  Future<DevMetrics> fetchMetrics({int days = 30}) async {
    final response = await _kong.get<Map<String, dynamic>>(
      '/ai-gateway/ai/dev-metrics',
      queryParameters: {'days': days},
    );
    final data = response.data;
    if (data == null) return DevMetrics.empty();
    return DevMetrics.fromJson(data);
  }
}
