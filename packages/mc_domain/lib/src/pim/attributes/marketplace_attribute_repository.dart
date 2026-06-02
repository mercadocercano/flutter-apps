import '../../iam/paginated_result.dart';
import 'attribute_type.dart';
import 'attribute_value.dart';
import 'marketplace_attribute.dart';

/// Puerto de repositorio para los atributos del marketplace.
/// Implementado en mc_infrastructure por MarketplaceAttributeRepositoryImpl.
abstract interface class MarketplaceAttributeRepository {
  Future<PaginatedResult<MarketplaceAttribute>> listAttributes({
    String? search,
    AttributeType? type,
    int page = 1,
    int pageSize = 20,
  });

  Future<MarketplaceAttribute> getAttribute(String id);

  Future<MarketplaceAttribute> createAttribute(MarketplaceAttribute attr);

  Future<MarketplaceAttribute> updateAttribute(MarketplaceAttribute attr);

  Future<void> deleteAttribute(String id);

  Future<List<AttributeValue>> listValues(String attributeId);

  Future<AttributeValue> createValue(AttributeValue value);

  Future<AttributeValue> updateValue(AttributeValue value);

  Future<void> deleteValue(String attributeId, String valueId);
}
