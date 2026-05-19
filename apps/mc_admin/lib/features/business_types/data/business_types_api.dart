import '../../../core/api/kong_client.dart';
import '../domain/models/business_type_template_model.dart';

class BusinessTypesApi {
  final KongClient _kong;

  BusinessTypesApi(this._kong);

  Future<List<Map<String, dynamic>>> getAll({bool onlyActive = true}) async {
    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/business-types',
      queryParameters: {'only_active': onlyActive, 'page_size': 100},
    );

    final data = response.data;
    if (data == null) return [];

    final items = data['items'] ?? data['data'] ?? data;
    if (items is List) return items.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> getTemplates(String businessTypeId) async {
    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/business-type-templates',
      queryParameters: {'business_type_id': businessTypeId, 'include_inactive': 'true'},
    );

    final data = response.data;
    if (data == null) return [];

    final items = data['items'] ?? data['data'] ?? data;
    if (items is List) return items.cast<Map<String, dynamic>>();
    return [];
  }

  Future<BusinessTypeTemplate> updateTemplate(BusinessTypeTemplate template) async {
    final response = await _kong.put<Map<String, dynamic>>(
      '/pim/api/v1/business-type-templates/${template.id}',
      data: template.toJson(),
    );
    final data = response.data ?? {};
    return BusinessTypeTemplate.fromJson(data['template'] as Map<String, dynamic>? ?? data);
  }

  Future<void> reorder(List<Map<String, dynamic>> items) async {
    await _kong.patch<void>(
      '/pim/api/v1/business-types/reorder',
      data: {'items': items},
    );
  }
}
