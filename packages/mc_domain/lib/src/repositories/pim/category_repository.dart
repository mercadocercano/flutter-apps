import '../../models/pim/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<List<Category>> getTree();
  Future<List<Category>> getChildren(String parentId);
  Future<Category> create(Category category);
  Future<Category> update(Category category);
  Future<void> delete(String id);
}