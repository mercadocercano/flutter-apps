import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('paginatedCategoriesFromJson', () {
    test('parsea lista paginada correctamente', () {
      final json = {
        'categories': [
          _catJson('c1', 'Electrónica'),
          _catJson('c2', 'Hogar'),
        ],
        'total': 10,
        'page': 2,
        'page_size': 5,
        'total_pages': 2,
      };

      final result = paginatedCategoriesFromJson(json);

      expect(result.items.length, 2);
      expect(result.totalCount, 10);
      expect(result.page, 2);
      expect(result.pageSize, 5);
      expect(result.totalPages, 2);
      expect(result.items.first.id, 'c1');
    });

    test('maneja lista vacía', () {
      final json = {
        'categories': <dynamic>[],
        'total': 0,
        'page': 1,
        'page_size': 20,
        'total_pages': 0,
      };

      final result = paginatedCategoriesFromJson(json);

      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });

    test('usa valores por defecto si faltan campos de paginación', () {
      final json = {
        'categories': <dynamic>[],
      };

      final result = paginatedCategoriesFromJson(json);

      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalPages, 1);
    });
  });

  group('treeFromJson', () {
    test('parsea árbol con un nivel', () {
      final json = {
        'categories': [
          _catJson('r1', 'Hogar'),
          _catJson('r2', 'Ropa'),
        ],
      };

      final tree = treeFromJson(json);

      expect(tree.roots.length, 2);
      expect(tree.roots.first.name, 'Hogar');
    });

    test('parsea árbol con hijos anidados', () {
      final json = {
        'categories': [
          {
            'id': 'r1',
            'name': 'Electrónica',
            'slug': 'electronica',
            'parent_id': null,
            'level': 0,
            'is_active': true,
            'sort_order': 0,
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-01T00:00:00Z',
            'children': [
              {
                'id': 'c1',
                'name': 'Audio',
                'slug': 'audio',
                'parent_id': 'r1',
                'level': 1,
                'is_active': true,
                'sort_order': 0,
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-01T00:00:00Z',
                'children': <dynamic>[],
              },
            ],
          },
        ],
      };

      final tree = treeFromJson(json);

      expect(tree.roots.length, 1);
      expect(tree.roots.first.children.length, 1);
      expect(tree.roots.first.children.first.name, 'Audio');
    });

    test('árbol vacío produce CategoryTree sin raíces', () {
      final json = {'categories': <dynamic>[]};
      final tree = treeFromJson(json);
      expect(tree.roots, isEmpty);
    });
  });

  group('categoryFromJson', () {
    test('parsea todos los campos correctamente', () {
      final json = {
        'id': 'cat-1',
        'name': 'Electrónica',
        'slug': 'electronica',
        'description': 'Desc electronica',
        'parent_id': 'root-1',
        'level': 1,
        'is_active': false,
        'sort_order': 5,
        'created_at': '2024-03-10T10:00:00Z',
        'updated_at': '2024-03-15T08:00:00Z',
        'children': <dynamic>[],
      };

      final cat = categoryFromJson(json);

      expect(cat.id, 'cat-1');
      expect(cat.name, 'Electrónica');
      expect(cat.slug, 'electronica');
      expect(cat.description, 'Desc electronica');
      expect(cat.parentId, 'root-1');
      expect(cat.level, 1);
      expect(cat.isActive, isFalse);
      expect(cat.sortOrder, 5);
      expect(cat.children, isEmpty);
    });

    test('usa valores por defecto si faltan campos opcionales', () {
      final json = {
        'id': 'cat-2',
        'name': 'Hogar',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final cat = categoryFromJson(json);

      expect(cat.slug, '');
      expect(cat.description, isNull);
      expect(cat.parentId, isNull);
      expect(cat.level, 0);
      expect(cat.isActive, isTrue);
      expect(cat.sortOrder, 0);
      expect(cat.children, isEmpty);
    });

    test('parsea children de forma recursiva', () {
      final json = {
        'id': 'r1',
        'name': 'Raíz',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'children': [
          {
            'id': 'c1',
            'name': 'Hijo',
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-01T00:00:00Z',
            'children': <dynamic>[],
          },
        ],
      };

      final cat = categoryFromJson(json);

      expect(cat.children.length, 1);
      expect(cat.children.first.name, 'Hijo');
    });
  });
}

Map<String, dynamic> _catJson(String id, String name) => {
      'id': id,
      'name': name,
      'slug': name.toLowerCase(),
      'parent_id': null,
      'level': 0,
      'is_active': true,
      'sort_order': 0,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'children': <dynamic>[],
    };
