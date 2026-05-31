import '../../iam/paginated_result.dart';
import 'category_params.dart';
import 'category_tree.dart';
import 'marketplace_category.dart';

/// Puerto de repositorio para categorías del marketplace.
/// Implementado en mc_infrastructure por MarketplaceCategoryRepositoryImpl.
abstract interface class MarketplaceCategoryRepository {
  Future<PaginatedResult<MarketplaceCategory>> getAll(
    int page,
    int pageSize, {
    String? name,
    String? parentId,
  });

  Future<CategoryTree> getTree();

  Future<MarketplaceCategory> getById(String id);

  Future<MarketplaceCategory> create(CreateCategoryParams params);

  Future<MarketplaceCategory> update(String id, UpdateCategoryParams params);

  Future<void> delete(String id);
}
