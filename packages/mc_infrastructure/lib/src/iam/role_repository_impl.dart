import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../http/admin_http_client.dart';
import 'iam_mappers.dart';

/// Implementacion HTTP del RoleRepository.
/// Consume /iam/api/v1/roles vía Kong.
class RoleRepositoryImpl implements RoleRepository {
  static const _base = '/iam/api/v1/roles';

  final KongClient _client;

  RoleRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<Role>> getAll(
    int page,
    int pageSize, {
    RoleType? type,
    String? name,
    RoleStatus? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (type != null) 'type': roleTypeToString(type),
      if (name != null && name.isNotEmpty) 'name': name,
      if (status != null) 'status': roleStatusToString(status),
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    final data = _requireData(response);
    return paginatedFromJson<Role>(data, roleFromJson);
  }

  @override
  Future<Role> getById(String id) async {
    final response = await _client.get<Map<String, dynamic>>('$_base/$id');
    return roleFromJson(_requireData(response));
  }

  @override
  Future<Role> create(UpsertRoleParams params) async {
    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: _paramsToBody(params),
    );
    return roleFromJson(_requireData(response));
  }

  @override
  Future<Role> update(String id, UpsertRoleParams params) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id',
      data: _paramsToBody(params),
    );
    return roleFromJson(_requireData(response));
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  Map<String, dynamic> _paramsToBody(UpsertRoleParams params) {
    return {
      'name': params.name,
      if (params.description != null) 'description': params.description,
      'type': roleTypeToString(params.type),
      if (params.tenantId != null) 'tenant_id': params.tenantId,
      'permissions': params.permissions,
      'status': roleStatusToString(params.status),
    };
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
