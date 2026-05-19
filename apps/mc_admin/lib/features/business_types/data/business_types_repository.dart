import '../../../core/api/kong_client.dart';
import '../domain/models/business_type_model.dart';
import '../domain/models/business_type_template_model.dart';
import 'business_types_api.dart';

class BusinessTypesRepository {
  late final BusinessTypesApi _api;

  BusinessTypesRepository(KongClient kong) : _api = BusinessTypesApi(kong);

  Future<List<BusinessType>> getAll({bool onlyActive = true}) async {
    final items = await _api.getAll(onlyActive: onlyActive);
    return items.map(BusinessType.fromJson).toList();
  }

  Future<List<BusinessTypeTemplate>> getTemplates(String businessTypeId) async {
    final items = await _api.getTemplates(businessTypeId);
    return items.map(BusinessTypeTemplate.fromJson).toList();
  }

  Future<BusinessTypeTemplate> updateTemplate(BusinessTypeTemplate template) {
    return _api.updateTemplate(template);
  }

  Future<void> reorder(List<BusinessType> ordered) async {
    final items = ordered
        .asMap()
        .entries
        .map((e) => {'id': e.value.id, 'display_order': e.key})
        .toList();
    await _api.reorder(items);
  }
}
