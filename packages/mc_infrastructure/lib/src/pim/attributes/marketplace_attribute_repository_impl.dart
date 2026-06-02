import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';
import 'marketplace_attribute_mappers.dart';

/// Implementación HTTP de MarketplaceAttributeRepository.
/// Consume /pim/api/v1/marketplace/attributes vía Kong.
class MarketplaceAttributeRepositoryImpl
    implements MarketplaceAttributeRepository {
  static const _base = '/pim/api/v1/marketplace/attributes';

  final KongClient _client;

  MarketplaceAttributeRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<MarketplaceAttribute>> listAttributes({
    String? search,
    AttributeType? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null) 'type': type.toApiString(),
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    return paginatedAttributesFromJson(_requireData(response));
  }

  @override
  Future<MarketplaceAttribute> getAttribute(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/$id');
    final data = _requireData(response);
    final attrJson = data['attribute'] as Map<String, dynamic>? ?? data;
    return attributeFromJson(attrJson);
  }

  @override
  Future<MarketplaceAttribute> createAttribute(
    MarketplaceAttribute attr,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: attributeToJson(attr),
    );
    final data = _requireData(response);
    final attrJson = data['attribute'] as Map<String, dynamic>? ?? data;
    return attributeFromJson(attrJson);
  }

  @override
  Future<MarketplaceAttribute> updateAttribute(
    MarketplaceAttribute attr,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/${attr.id}',
      data: attributeToJson(attr),
    );
    final data = _requireData(response);
    final attrJson = data['attribute'] as Map<String, dynamic>? ?? data;
    return attributeFromJson(attrJson);
  }

  @override
  Future<void> deleteAttribute(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  @override
  Future<List<AttributeValue>> listValues(String attributeId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '$_base/$attributeId/values',
    );
    final data = _requireData(response);
    final rawValues = (data['values'] as List?) ?? [];
    return rawValues
        .cast<Map<String, dynamic>>()
        .map(attributeValueFromJson)
        .toList();
  }

  @override
  Future<AttributeValue> createValue(AttributeValue value) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/${value.attributeId}/values',
      data: attributeValueToJson(value),
    );
    final data = _requireData(response);
    final valueJson = data['value'] as Map<String, dynamic>? ?? data;
    return attributeValueFromJson(valueJson);
  }

  @override
  Future<AttributeValue> updateValue(AttributeValue value) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/${value.attributeId}/values/${value.id}',
      data: attributeValueToJson(value),
    );
    final data = _requireData(response);
    final valueJson = data['value'] as Map<String, dynamic>? ?? data;
    return attributeValueFromJson(valueJson);
  }

  @override
  Future<void> deleteValue(String attributeId, String valueId) async {
    await _client.delete<void>('$_base/$attributeId/values/$valueId');
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
