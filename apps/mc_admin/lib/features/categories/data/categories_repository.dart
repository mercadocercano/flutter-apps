import '../../../core/api/kong_client.dart';
import '../domain/models/category_model.dart';
import 'categories_api.dart';

class CategoriesRepository {
  late final CategoriesApi _api;

  CategoriesRepository(KongClient kong) : _api = CategoriesApi(kong);

  Future<List<Category>> getAll({
    String? parentId,
    String? search,
    bool? active,
  }) async {
    final items = await _api.getAll(
      parentId: parentId,
      search: search,
      active: active,
    );
    return items.map(Category.fromJson).toList();
  }

  /// Devuelve todas las categorias; el arbol se construye en la UI.
  Future<List<Category>> getTree() => getAll();

  Future<Category> create(Category category) async {
    final json = await _api.create(category.toJson());
    return Category.fromJson(json);
  }

  Future<Category> update(String id, Category category) async {
    final json = await _api.update(id, category.toJson());
    return Category.fromJson(json);
  }

  Future<void> delete(String id) => _api.delete(id);
}
