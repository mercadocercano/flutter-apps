import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';
import 'quickstart_mappers.dart';

/// Implementación HTTP de QuickstartRepository.
/// Consume /pim/api/v1/business-types y /pim/api/v1/business-type-templates vía Kong.
/// La generación con IA consume /ai/ai/generate-template.
class QuickstartRepositoryImpl implements QuickstartRepository {
  static const _businessTypesBase = '/pim/api/v1/business-types';
  static const _templatesBase = '/pim/api/v1/business-type-templates';
  static const _quickstartTemplatesBase = '/pim/api/v1/quickstart/templates';
  static const _quickstartProductsBase = '/pim/api/v1/quickstart/products';
  static const _aiGenerateBase = '/ai/ai/generate-template';

  final KongClient _client;

  QuickstartRepositoryImpl(this._client);

  // -------------------------------------------------------------------------
  // Business Types
  // -------------------------------------------------------------------------

  @override
  Future<PaginatedResult<BusinessType>> listBusinessTypes({
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _client.get<Map<String, dynamic>>(
      _businessTypesBase,
      queryParameters: params,
    );

    return paginatedBusinessTypesFromJson(_requireData(response));
  }

  @override
  Future<BusinessType> getBusinessType(String id) async {
    final response = await _client
        .get<Map<String, dynamic>>('$_businessTypesBase/$id');
    final data = _requireData(response);
    final btJson =
        data['business_type'] as Map<String, dynamic>? ?? data;
    return businessTypeFromJson(btJson);
  }

  @override
  Future<BusinessType> createBusinessType(BusinessType businessType) async {
    final response = await _client.post<Map<String, dynamic>>(
      _businessTypesBase,
      data: businessTypeToJson(businessType),
    );
    final data = _requireData(response);
    final btJson =
        data['business_type'] as Map<String, dynamic>? ?? data;
    return businessTypeFromJson(btJson);
  }

  @override
  Future<BusinessType> updateBusinessType(BusinessType businessType) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_businessTypesBase/${businessType.id}',
      data: businessTypeToJson(businessType),
    );
    final data = _requireData(response);
    final btJson =
        data['business_type'] as Map<String, dynamic>? ?? data;
    return businessTypeFromJson(btJson);
  }

  @override
  Future<void> deleteBusinessType(String id) async {
    await _client.delete<void>('$_businessTypesBase/$id');
  }

  @override
  Future<BusinessType> activateBusinessType(String id) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '$_businessTypesBase/$id/activate',
    );
    final data = _requireData(response);
    final btJson =
        data['business_type'] as Map<String, dynamic>? ?? data;
    return businessTypeFromJson(btJson);
  }

  @override
  Future<BusinessType> deactivateBusinessType(String id) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '$_businessTypesBase/$id/deactivate',
    );
    final data = _requireData(response);
    final btJson =
        data['business_type'] as Map<String, dynamic>? ?? data;
    return businessTypeFromJson(btJson);
  }

  // -------------------------------------------------------------------------
  // Templates
  // -------------------------------------------------------------------------

  @override
  Future<List<QuickstartTemplateSummary>> listQuickstartTemplates({
    String? status,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      _quickstartTemplatesBase,
      queryParameters: <String, dynamic>{
        if (status != null) 'status': status,
      },
    );
    final data = _requireData(response);
    final list = (data['templates'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(QuickstartTemplateSummary.fromJson)
        .toList();
    return list;
  }

  @override
  Future<List<QuickstartTemplateProduct>> getQuickstartTemplateProducts(
    String businessTypeSlug,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '$_quickstartProductsBase/$businessTypeSlug',
    );
    final data = _requireData(response);
    final list = (data['products'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(QuickstartTemplateProduct.fromJson)
        .toList();
    return list;
  }

  @override
  Future<List<BusinessTypeTemplate>> listTemplates(
    String businessTypeId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      _templatesBase,
      queryParameters: <String, dynamic>{
        'business_type_id': businessTypeId,
      },
    );
    return templatesFromJson(_requireData(response));
  }

  @override
  Future<BusinessTypeTemplate> getTemplate(String id) async {
    final response = await _client
        .get<Map<String, dynamic>>('$_templatesBase/$id');
    final data = _requireData(response);
    final tJson =
        data['template'] as Map<String, dynamic>? ?? data;
    return templateFromJson(tJson);
  }

  @override
  Future<BusinessTypeTemplate> createTemplate(
    BusinessTypeTemplate template,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      _templatesBase,
      data: templateToJson(template),
    );
    final data = _requireData(response);
    final tJson =
        data['template'] as Map<String, dynamic>? ?? data;
    return templateFromJson(tJson);
  }

  @override
  Future<BusinessTypeTemplate> updateTemplate(
    BusinessTypeTemplate template,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_templatesBase/${template.id}',
      data: templateToJson(template),
    );
    final data = _requireData(response);
    final tJson =
        data['template'] as Map<String, dynamic>? ?? data;
    return templateFromJson(tJson);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _client.delete<void>('$_templatesBase/$id');
  }

  @override
  Future<BusinessTypeTemplate> duplicateTemplate(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_templatesBase/$id/duplicate',
    );
    final data = _requireData(response);
    final tJson =
        data['template'] as Map<String, dynamic>? ?? data;
    return templateFromJson(tJson);
  }

  @override
  Future<TemplateAnalytics> getTemplateAnalytics(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '$_templatesBase/$id/analytics',
    );
    return templateAnalyticsFromJson(id, _requireData(response));
  }

  // -------------------------------------------------------------------------
  // AI
  // -------------------------------------------------------------------------

  @override
  Future<BusinessTypeTemplate> generateTemplateWithAI(
    String description,
    String businessTypeId,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      _aiGenerateBase,
      data: <String, dynamic>{
        'description': description,
        'business_type_id': businessTypeId,
      },
    );
    final data = _requireData(response);
    final tJson =
        data['template'] as Map<String, dynamic>? ?? data;
    return templateFromJson(tJson);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Map<String, dynamic> _requireData(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
