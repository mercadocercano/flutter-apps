import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('paginatedGlobalProductsFromJson', () {
    test('parsea lista y paginación correctamente', () {
      final json = {
        'products': [
          _productJson('p1', 'Tornillo M6'),
          _productJson('p2', 'Tuerca M6'),
        ],
        'pagination': {
          'page': 1,
          'page_size': 20,
          'total': 2,
          'total_pages': 1,
        },
      };

      final result = paginatedGlobalProductsFromJson(json);

      expect(result.items.length, 2);
      expect(result.totalCount, 2);
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalPages, 1);
      expect(result.items.first.id, 'p1');
    });

    test('usa valores por defecto si pagination ausente', () {
      final json = {'products': <dynamic>[]};

      final result = paginatedGlobalProductsFromJson(json);

      expect(result.items, isEmpty);
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalPages, 1);
    });

    test('lista vacía produce items vacíos', () {
      final json = {
        'products': <dynamic>[],
        'pagination': {
          'page': 1,
          'page_size': 20,
          'total': 0,
          'total_pages': 0,
        },
      };

      final result = paginatedGlobalProductsFromJson(json);

      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });
  });

  group('globalProductFromJson', () {
    test('parsea todos los campos correctamente', () {
      final json = {
        'id': 'prod-1',
        'name': 'Tornillo M6x20',
        'sku': 'TORN-M6-20',
        'barcode': '7701234567890',
        'description': 'Tornillo métrico M6',
        'image_url': 'https://cdn.example.com/img.jpg',
        'business_type_ids': ['bt-1', 'bt-2'],
        'category_id': 'cat-1',
        'attributes': {'material': 'acero', 'longitud_mm': 20},
        'is_verified': true,
        'verified_at': '2024-06-01T10:00:00Z',
        'created_at': '2024-01-15T08:00:00Z',
        'updated_at': '2024-06-01T10:00:00Z',
      };

      final product = globalProductFromJson(json);

      expect(product.id, 'prod-1');
      expect(product.name, 'Tornillo M6x20');
      expect(product.sku, 'TORN-M6-20');
      expect(product.barcode, '7701234567890');
      expect(product.description, 'Tornillo métrico M6');
      expect(product.imageUrl, 'https://cdn.example.com/img.jpg');
      expect(product.businessTypeIds, ['bt-1', 'bt-2']);
      expect(product.categoryId, 'cat-1');
      expect(product.attributes['material'], 'acero');
      expect(product.isVerified, isTrue);
      expect(product.verifiedAt, isNotNull);
    });

    test('usa valores por defecto para campos opcionales ausentes', () {
      final json = {
        'id': 'prod-2',
        'name': 'Tuerca M6',
        'sku': 'TU-M6',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final product = globalProductFromJson(json);

      expect(product.barcode, isNull);
      expect(product.description, isNull);
      expect(product.imageUrl, isNull);
      expect(product.businessTypeIds, isEmpty);
      expect(product.categoryId, isNull);
      expect(product.attributes, isEmpty);
      expect(product.isVerified, isFalse);
      expect(product.verifiedAt, isNull);
    });

    test('parsea business_type_ids como lista de strings', () {
      final json = {
        'id': 'p3',
        'name': 'Producto',
        'sku': 'SKU-3',
        'business_type_ids': ['bt-a', 'bt-b', 'bt-c'],
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final product = globalProductFromJson(json);

      expect(product.businessTypeIds.length, 3);
      expect(product.businessTypeIds, containsAll(['bt-a', 'bt-b', 'bt-c']));
    });
  });

  group('globalProductToJson', () {
    test('serializa campos obligatorios', () {
      final product = _buildProduct();

      final json = globalProductToJson(product);

      expect(json['name'], 'Tornillo M6x20');
      expect(json['sku'], 'TORN-M6-20');
      expect(json['business_type_ids'], isA<List>());
    });

    test('omite campos nulos opcionales', () {
      final product = _buildProduct(
        barcode: null,
        description: null,
        imageUrl: null,
        categoryId: null,
      );

      final json = globalProductToJson(product);

      expect(json.containsKey('barcode'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('image_url'), isFalse);
      expect(json.containsKey('category_id'), isFalse);
    });

    test('incluye campos opcionales cuando están presentes', () {
      final product = _buildProduct(
        barcode: '1234567890',
        description: 'Descripción del producto',
        imageUrl: 'https://img.example.com/img.png',
        categoryId: 'cat-99',
      );

      final json = globalProductToJson(product);

      expect(json['barcode'], '1234567890');
      expect(json['description'], 'Descripción del producto');
      expect(json['image_url'], 'https://img.example.com/img.png');
      expect(json['category_id'], 'cat-99');
    });
  });

  group('bulkImportResultFromJson', () {
    test('parsea resultado exitoso sin errores', () {
      final json = {
        'total_rows': 50,
        'imported_count': 50,
        'failed_count': 0,
        'errors': <dynamic>[],
      };

      final result = bulkImportResultFromJson(json);

      expect(result.totalRows, 50);
      expect(result.importedCount, 50);
      expect(result.failedCount, 0);
      expect(result.errors, isEmpty);
      expect(result.isFullSuccess, isTrue);
    });

    test('parsea resultado con errores mixtos', () {
      final json = {
        'total_rows': 52,
        'imported_count': 50,
        'failed_count': 2,
        'errors': [
          {'row_number': 12, 'sku': 'SKU-BAD-1', 'reason': 'SKU duplicado'},
          {'row_number': 37, 'sku': null, 'reason': 'Nombre requerido'},
        ],
      };

      final result = bulkImportResultFromJson(json);

      expect(result.totalRows, 52);
      expect(result.importedCount, 50);
      expect(result.failedCount, 2);
      expect(result.errors.length, 2);
      expect(result.hasErrors, isTrue);
      expect(result.errors.first.rowNumber, 12);
      expect(result.errors.first.sku, 'SKU-BAD-1');
      expect(result.errors.first.reason, 'SKU duplicado');
      expect(result.errors.last.sku, isNull);
    });

    test('usa valores por defecto si faltan campos', () {
      final json = <String, dynamic>{};

      final result = bulkImportResultFromJson(json);

      expect(result.totalRows, 0);
      expect(result.importedCount, 0);
      expect(result.errors, isEmpty);
    });
  });
}

Map<String, dynamic> _productJson(String id, String name) => {
      'id': id,
      'name': name,
      'sku': 'SKU-$id',
      'is_verified': false,
      'business_type_ids': <dynamic>[],
      'attributes': <String, dynamic>{},
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };

GlobalProduct _buildProduct({
  String? barcode,
  String? description,
  String? imageUrl,
  String? categoryId,
}) {
  final now = DateTime(2024, 1, 1);
  return GlobalProduct(
    id: 'p-1',
    name: 'Tornillo M6x20',
    sku: 'TORN-M6-20',
    barcode: barcode,
    description: description,
    imageUrl: imageUrl,
    categoryId: categoryId,
    createdAt: now,
    updatedAt: now,
  );
}
