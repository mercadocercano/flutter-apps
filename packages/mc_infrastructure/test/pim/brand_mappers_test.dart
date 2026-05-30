import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  final baseJson = <String, dynamic>{
    'id': 'brand-uuid-1',
    'name': 'Nike',
    'slug': 'nike',
    'normalized_name': 'nike',
    'description': 'Marca deportiva',
    'logo_url': 'https://cdn.example.com/nike.png',
    'website': 'https://nike.com',
    'verification_status': 'verified',
    'quality_score': 9.5,
    'product_count': 150,
    'category_tags': ['deportes', 'ropa'],
    'aliases': ['Nike Inc'],
    'sources': ['manual'],
    'is_active': true,
    'background_color': '#FFFFFF',
    'text_color': '#000000',
    'typography': 'Helvetica',
    'created_at': '2024-06-15T10:00:00Z',
    'updated_at': '2024-06-15T10:00:00Z',
  };

  group('brandFromJson', () {
    test('mapea todos los campos correctamente', () {
      final brand = brandFromJson(baseJson);
      expect(brand.id, 'brand-uuid-1');
      expect(brand.name, 'Nike');
      expect(brand.slug, 'nike');
      expect(brand.normalizedName, 'nike');
      expect(brand.description, 'Marca deportiva');
      expect(brand.logoUrl, 'https://cdn.example.com/nike.png');
      expect(brand.website, 'https://nike.com');
      expect(brand.verificationStatus, BrandVerificationStatus.verified);
      expect(brand.qualityScore, 9.5);
      expect(brand.productCount, 150);
      expect(brand.categoryTags, ['deportes', 'ropa']);
      expect(brand.aliases, ['Nike Inc']);
      expect(brand.sources, ['manual']);
      expect(brand.isActive, isTrue);
      expect(brand.backgroundColor, '#FFFFFF');
      expect(brand.textColor, '#000000');
      expect(brand.typography, 'Helvetica');
    });

    test('campos opcionales null cuando no están presentes', () {
      final minJson = <String, dynamic>{
        'id': 'brand-min',
        'name': 'Minimal',
        'slug': 'minimal',
        'created_at': '2024-06-15T10:00:00Z',
        'updated_at': '2024-06-15T10:00:00Z',
      };
      final brand = brandFromJson(minJson);
      expect(brand.description, isNull);
      expect(brand.logoUrl, isNull);
      expect(brand.website, isNull);
      expect(brand.normalizedName, isNull);
      expect(brand.backgroundColor, isNull);
      expect(brand.textColor, isNull);
      expect(brand.typography, isNull);
    });

    test('listas null resultan en listas vacías', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..remove('category_tags')
        ..remove('aliases')
        ..remove('sources');
      final brand = brandFromJson(json);
      expect(brand.categoryTags, isEmpty);
      expect(brand.aliases, isEmpty);
      expect(brand.sources, isEmpty);
    });

    test('verification_status unverified por defecto', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['verification_status'] = null;
      final brand = brandFromJson(json);
      expect(brand.verificationStatus, BrandVerificationStatus.unverified);
    });

    test('verification_status pending', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['verification_status'] = 'pending';
      final brand = brandFromJson(json);
      expect(brand.verificationStatus, BrandVerificationStatus.pending);
    });

    test('quality_score como entero se convierte a double', () {
      final json = Map<String, dynamic>.from(baseJson)..['quality_score'] = 8;
      final brand = brandFromJson(json);
      expect(brand.qualityScore, 8.0);
    });

    test('product_count null resulta en 0', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..remove('product_count');
      final brand = brandFromJson(json);
      expect(brand.productCount, 0);
    });

    test('is_active false', () {
      final json = Map<String, dynamic>.from(baseJson)..['is_active'] = false;
      final brand = brandFromJson(json);
      expect(brand.isActive, isFalse);
    });
  });

  group('paginatedFromJson con brands', () {
    test('mapea campos de paginación correctamente', () {
      final paginatedJson = <String, dynamic>{
        'items': [baseJson],
        'total_count': 50,
        'page': 2,
        'page_size': 10,
        'total_pages': 5,
      };

      final result = paginatedFromJson<MarketplaceBrand>(
        paginatedJson,
        brandFromJson,
      );

      expect(result.items.length, 1);
      expect(result.totalCount, 50);
      expect(result.page, 2);
      expect(result.pageSize, 10);
      expect(result.totalPages, 5);
      expect(result.hasNextPage, isTrue);
    });

    test('items vacíos resultan en lista vacía', () {
      final paginatedJson = <String, dynamic>{
        'items': <dynamic>[],
        'total_count': 0,
        'page': 1,
        'page_size': 10,
        'total_pages': 0,
      };

      final result = paginatedFromJson<MarketplaceBrand>(
        paginatedJson,
        brandFromJson,
      );

      expect(result.items, isEmpty);
      expect(result.isEmpty, isTrue);
    });
  });

  group('paginatedBrandsFromJson — formato real pim-service', () {
    test('parsea brands key y pagination object correctamente', () {
      final json = <String, dynamic>{
        'brands': [baseJson],
        'pagination': {
          'offset': 0,
          'limit': 20,
          'total': 100,
          'has_next': true,
          'has_prev': false,
          'total_pages': 5,
        },
      };

      final result = paginatedBrandsFromJson(json);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Nike');
      expect(result.totalCount, 100);
      expect(result.pageSize, 20);
      expect(result.totalPages, 5);
      expect(result.page, 1); // offset=0, limit=20 → page 1
    });

    test('calcula página correctamente desde offset', () {
      final json = <String, dynamic>{
        'brands': <dynamic>[],
        'pagination': {
          'offset': 40,
          'limit': 20,
          'total': 100,
          'has_next': true,
          'has_prev': true,
          'total_pages': 5,
        },
      };

      final result = paginatedBrandsFromJson(json);

      expect(result.page, 3); // offset=40, limit=20 → page 3
      expect(result.items, isEmpty);
    });

    test('maneja brands null o ausente con lista vacía', () {
      final json = <String, dynamic>{
        'pagination': {
          'offset': 0,
          'limit': 10,
          'total': 0,
          'total_pages': 0,
        },
      };

      final result = paginatedBrandsFromJson(json);

      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });

    test('maneja pagination ausente con valores por defecto', () {
      final json = <String, dynamic>{
        'brands': [baseJson],
      };

      final result = paginatedBrandsFromJson(json);

      expect(result.items.length, 1);
      expect(result.pageSize, 10);
      expect(result.totalPages, 1);
    });
  });
}
