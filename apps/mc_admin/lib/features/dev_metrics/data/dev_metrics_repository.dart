import '../../../core/api/kong_client.dart';
import '../domain/models/dev_metrics_model.dart';
import 'dev_metrics_api.dart';

class DevMetricsRepository {
  late final DevMetricsApi _api;

  DevMetricsRepository(KongClient kong) : _api = DevMetricsApi(kong);

  Future<DevMetrics> fetchMetrics({int days = 30}) =>
      _api.fetchMetrics(days: days);
}
