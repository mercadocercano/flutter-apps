import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../http/admin_http_client.dart';
import 'iam_mappers.dart';

/// Implementacion HTTP del PlanRepository.
/// Consume /iam/api/v1/plans vía Kong.
class PlanRepositoryImpl implements PlanRepository {
  static const _base = '/iam/api/v1/plans';

  final KongClient _client;

  PlanRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<Plan>> getAll(
    int page,
    int pageSize, {
    PlanType? type,
    String? name,
    PlanStatus? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (type != null) 'type': planTypeToString(type),
      if (name != null && name.isNotEmpty) 'name': name,
      if (status != null) 'status': planStatusToString(status),
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    final data = _requireData(response);
    return paginatedFromJson<Plan>(data, planFromJson);
  }

  @override
  Future<Plan> getById(String id) async {
    final response = await _client.get<Map<String, dynamic>>('$_base/$id');
    return planFromJson(_requireData(response));
  }

  @override
  Future<Plan> create(UpsertPlanParams params) async {
    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: _paramsToBody(params),
    );
    return planFromJson(_requireData(response));
  }

  @override
  Future<Plan> update(String id, UpsertPlanParams params) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id',
      data: _paramsToBody(params),
    );
    return planFromJson(_requireData(response));
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  Map<String, dynamic> _paramsToBody(UpsertPlanParams params) {
    return {
      'name': params.name,
      if (params.description != null) 'description': params.description,
      'type': planTypeToString(params.type),
      'price': params.price,
      'currency': params.currency,
      'features': params.features,
      'limits': params.limits,
      'status': planStatusToString(params.status),
    };
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
