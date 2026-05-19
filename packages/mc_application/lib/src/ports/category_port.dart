import 'package:mc_domain/mc_domain.dart';

/// Puerto de categorías — CRUD para el tenant.
abstract interface class CategoryPort {
  Future<List<Category>> listCategories({int page = 1, int pageSize = 50});
  Future<Category> getCategory(String categoryId);
  Future<Category> createCategory({required String name, String? description, String? parentId});
  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    String? description,
    String? parentId,
    bool active = true,
  });
  Future<void> deleteCategory(String categoryId);
}
