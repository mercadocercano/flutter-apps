import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';
import '../../iam/iam_mappers.dart';
import 'brand_mappers.dart';

/// Implementación HTTP de MarketplaceBrandRepository.
/// Consume /pim/api/v1/marketplace-brands vía Kong.
class MarketplaceBrandRepositoryImpl implements MarketplaceBrandRepository {
  static const _base = '/pim/api/v1/marketplace-brands';

  final KongClient _client;

  MarketplaceBrandRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<MarketplaceBrand>> getAll(
    int page,
    int pageSize, {
    String? name,
    BrandVerificationStatus? verificationStatus,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (name != null && name.isNotEmpty) 'name': name,
      if (verificationStatus != null)
        'status': verificationStatus.toApiString(),
      if (isActive case final active?) 'active': active,
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    return paginatedFromJson(_requireData(response), brandFromJson);
  }

  @override
  Future<MarketplaceBrand> getById(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/$id');
    return brandFromJson(_requireData(response));
  }

  @override
  Future<MarketplaceBrand> create(CreateBrandParams params) async {
    final body = <String, dynamic>{
      'name': params.name,
      if (params.description != null) 'description': params.description,
      if (params.logoUrl != null) 'logo_url': params.logoUrl,
      if (params.website != null) 'website': params.website,
      if (params.backgroundColor != null)
        'background_color': params.backgroundColor,
      if (params.textColor != null) 'text_color': params.textColor,
      if (params.typography != null) 'typography': params.typography,
    };

    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: body,
    );
    return brandFromJson(_requireData(response));
  }

  @override
  Future<MarketplaceBrand> update(String id, UpdateBrandParams params) async {
    final body = <String, dynamic>{
      if (params.name != null) 'name': params.name,
      if (params.description != null) 'description': params.description,
      if (params.logoUrl != null) 'logo_url': params.logoUrl,
      if (params.website != null) 'website': params.website,
      if (params.backgroundColor != null)
        'background_color': params.backgroundColor,
      if (params.textColor != null) 'text_color': params.textColor,
      if (params.typography != null) 'typography': params.typography,
    };

    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id',
      data: body,
    );
    return brandFromJson(_requireData(response));
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  @override
  Future<MarketplaceBrand> verify(String id) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id/verify',
    );
    return brandFromJson(_requireData(response));
  }

  @override
  Future<MarketplaceBrand> unverify(String id) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id/unverify',
    );
    return brandFromJson(_requireData(response));
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
