import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../http/admin_http_client.dart';
import 'iam_mappers.dart';

/// Implementacion HTTP del TenantRepository.
/// Consume /iam/api/v1/tenants vía Kong.
class TenantRepositoryImpl implements TenantRepository {
  static const _base = '/iam/api/v1/tenants';

  final KongClient _client;

  TenantRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<Tenant>> getAll(
    int page,
    int pageSize, {
    TenantStatus? status,
    TenantType? type,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (status != null) 'status': tenantStatusToString(status),
      if (type != null) 'type': tenantTypeToString(type),
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    final data = _requireData(response);
    return paginatedFromJson<Tenant>(data, tenantFromJson);
  }

  @override
  Future<Tenant> getById(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/$id');
    return tenantFromJson(_requireData(response));
  }

  @override
  Future<Tenant> create(CreateTenantParams params) async {
    final body = {
      'name': params.name,
      'slug': params.slug,
      'type': tenantTypeToString(params.type),
      'owner_id': params.ownerId,
      if (params.description != null) 'description': params.description,
      if (params.domain != null) 'domain': params.domain,
    };

    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: body,
    );
    return tenantFromJson(_requireData(response));
  }

  @override
  Future<Tenant> update(String id, UpdateTenantParams params) async {
    final body = <String, dynamic>{
      if (params.name != null) 'name': params.name,
      if (params.description != null) 'description': params.description,
      if (params.domain != null) 'domain': params.domain,
      if (params.status != null)
        'status': tenantStatusToString(params.status!),
      if (params.type != null) 'type': tenantTypeToString(params.type!),
      if (params.settings != null) 'settings': params.settings,
    };

    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id',
      data: body,
    );
    return tenantFromJson(_requireData(response));
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
