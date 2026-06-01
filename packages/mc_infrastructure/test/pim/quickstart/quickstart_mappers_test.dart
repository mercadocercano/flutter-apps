import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------------------------
  // Fixtures
  // -------------------------------------------------------------------------

  final baseBTJson = <String, dynamic>{
    'id': 'bt-uuid-1',
    'name': 'Ferretería',
    'slug': 'ferreteria',
    'description': 'Tienda de herramientas y materiales de construcción',
    'icon': 'hardware',
    'is_active': true,
    'template_count': 3,
    'created_at': '2024-06-15T10:00:00Z',
    'updated_at': '2024-06-15T10:00:00Z',
  };

  final baseTemplateJson = <String, dynamic>{
    'id': 'tpl-uuid-1',
    'business_type_id': 'bt-uuid-1',
    'name': 'Ferretería Básica',
    'description': 'Template para ferreterías pequeñas',
    'category_ids': ['cat-1', 'cat-2'],
    'base_product_ids': ['prod-1', 'prod-2', 'prod-3'],
    'is_duplicate': false,
    'created_at': '2024-06-15T10:00:00Z',
    'updated_at': '2024-06-15T10:00:00Z',
  };

  final baseAnalyticsJson = <String, dynamic>{
    'tenants_count': 42,
    'last_activated_at': '2024-06-20T15:30:00Z',
    'completion_rate': 0.78,
  };

  // -------------------------------------------------------------------------
  // businessTypeFromJson
  // -------------------------------------------------------------------------

  group('businessTypeFromJson', () {
    test('mapea todos los campos correctamente', () {
      final bt = businessTypeFromJson(baseBTJson);
      expect(bt.id, 'bt-uuid-1');
      expect(bt.name, 'Ferretería');
      expect(bt.slug, 'ferreteria');
      expect(bt.description, 'Tienda de herramientas y materiales de construcción');
      expect(bt.icon, 'hardware');
      expect(bt.isActive, isTrue);
      expect(bt.templateCount, 3);
    });

    test('campos opcionales con valores por defecto cuando están ausentes', () {
      final minJson = <String, dynamic>{
        'id': 'bt-min',
        'name': 'Mínimo',
        'slug': 'minimo',
        'created_at': '2024-06-15T10:00:00Z',
        'updated_at': '2024-06-15T10:00:00Z',
      };
      final bt = businessTypeFromJson(minJson);
      expect(bt.description, isNull);
      expect(bt.icon, '');
      expect(bt.isActive, isTrue);
      expect(bt.templateCount, 0);
    });

    test('is_active false se mapea correctamente', () {
      final json = Map<String, dynamic>.from(baseBTJson)..['is_active'] = false;
      expect(businessTypeFromJson(json).isActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // businessTypeToJson
  // -------------------------------------------------------------------------

  group('businessTypeToJson', () {
    test('serializa todos los campos requeridos', () {
      final now = DateTime(2024, 6, 15);
      final bt = BusinessType(
        id: 'bt-1',
        name: 'Ferretería',
        slug: 'ferreteria',
        description: 'Descripción',
        icon: 'hardware',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      final json = businessTypeToJson(bt);
      expect(json['name'], 'Ferretería');
      expect(json['slug'], 'ferreteria');
      expect(json['description'], 'Descripción');
      expect(json['icon'], 'hardware');
      expect(json['is_active'], isTrue);
    });

    test('description omitida cuando es null', () {
      final now = DateTime(2024, 6, 15);
      final bt = BusinessType(
        id: 'bt-1',
        name: 'Sin descripción',
        slug: 'sin-desc',
        icon: 'store',
        createdAt: now,
        updatedAt: now,
      );
      final json = businessTypeToJson(bt);
      expect(json.containsKey('description'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // paginatedBusinessTypesFromJson
  // -------------------------------------------------------------------------

  group('paginatedBusinessTypesFromJson', () {
    test('parsea business_types key y pagination object correctamente', () {
      final json = <String, dynamic>{
        'business_types': [baseBTJson],
        'pagination': {
          'page': 2,
          'page_size': 10,
          'total': 25,
          'total_pages': 3,
        },
      };

      final result = paginatedBusinessTypesFromJson(json);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Ferretería');
      expect(result.totalCount, 25);
      expect(result.page, 2);
      expect(result.pageSize, 10);
      expect(result.totalPages, 3);
    });

    test('business_types null resulta en lista vacía', () {
      final json = <String, dynamic>{
        'pagination': {
          'page': 1,
          'page_size': 20,
          'total': 0,
          'total_pages': 0,
        },
      };

      final result = paginatedBusinessTypesFromJson(json);
      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });

    test('pagination ausente usa valores por defecto', () {
      final json = <String, dynamic>{
        'business_types': [baseBTJson],
      };

      final result = paginatedBusinessTypesFromJson(json);
      expect(result.items.length, 1);
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalPages, 1);
    });
  });

  // -------------------------------------------------------------------------
  // templateFromJson
  // -------------------------------------------------------------------------

  group('templateFromJson', () {
    test('mapea todos los campos correctamente', () {
      final template = templateFromJson(baseTemplateJson);
      expect(template.id, 'tpl-uuid-1');
      expect(template.businessTypeId, 'bt-uuid-1');
      expect(template.name, 'Ferretería Básica');
      expect(template.description, 'Template para ferreterías pequeñas');
      expect(template.categoryIds, ['cat-1', 'cat-2']);
      expect(template.baseProductIds, ['prod-1', 'prod-2', 'prod-3']);
      expect(template.isDuplicate, isFalse);
    });

    test('listas vacías cuando no están presentes', () {
      final minJson = <String, dynamic>{
        'id': 'tpl-min',
        'business_type_id': 'bt-1',
        'name': 'Mínimo',
        'created_at': '2024-06-15T10:00:00Z',
        'updated_at': '2024-06-15T10:00:00Z',
      };
      final template = templateFromJson(minJson);
      expect(template.categoryIds, isEmpty);
      expect(template.baseProductIds, isEmpty);
      expect(template.description, isNull);
      expect(template.isDuplicate, isFalse);
    });

    test('is_duplicate true se mapea correctamente', () {
      final json = Map<String, dynamic>.from(baseTemplateJson)
        ..['is_duplicate'] = true;
      expect(templateFromJson(json).isDuplicate, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // templateToJson
  // -------------------------------------------------------------------------

  group('templateToJson', () {
    test('serializa todos los campos requeridos', () {
      final now = DateTime(2024, 6, 15);
      final template = BusinessTypeTemplate(
        id: 'tpl-1',
        businessTypeId: 'bt-1',
        name: 'Ferretería Básica',
        description: 'Descripción',
        categoryIds: const ['cat-1'],
        baseProductIds: const ['prod-1', 'prod-2'],
        createdAt: now,
        updatedAt: now,
      );
      final json = templateToJson(template);
      expect(json['business_type_id'], 'bt-1');
      expect(json['name'], 'Ferretería Básica');
      expect(json['description'], 'Descripción');
      expect(json['category_ids'], ['cat-1']);
      expect(json['base_product_ids'], ['prod-1', 'prod-2']);
    });

    test('description omitida cuando es null', () {
      final now = DateTime(2024, 6, 15);
      final template = BusinessTypeTemplate(
        id: 'tpl-1',
        businessTypeId: 'bt-1',
        name: 'Sin desc',
        createdAt: now,
        updatedAt: now,
      );
      final json = templateToJson(template);
      expect(json.containsKey('description'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // templatesFromJson
  // -------------------------------------------------------------------------

  group('templatesFromJson', () {
    test('parsea templates key correctamente', () {
      final json = <String, dynamic>{
        'templates': [baseTemplateJson],
      };

      final result = templatesFromJson(json);
      expect(result.length, 1);
      expect(result.first.name, 'Ferretería Básica');
    });

    test('templates null resulta en lista vacía', () {
      final json = <String, dynamic>{};
      final result = templatesFromJson(json);
      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // templateAnalyticsFromJson
  // -------------------------------------------------------------------------

  group('templateAnalyticsFromJson', () {
    test('parsea analytics desde clave analytics anidada', () {
      final json = <String, dynamic>{'analytics': baseAnalyticsJson};

      final analytics = templateAnalyticsFromJson('tpl-1', json);
      expect(analytics.templateId, 'tpl-1');
      expect(analytics.tenantsCount, 42);
      expect(analytics.lastActivatedAt, isNotNull);
      expect(analytics.completionRate, closeTo(0.78, 0.001));
    });

    test('parsea analytics desde raíz cuando no hay clave analytics', () {
      final analytics = templateAnalyticsFromJson('tpl-1', baseAnalyticsJson);
      expect(analytics.templateId, 'tpl-1');
      expect(analytics.tenantsCount, 42);
    });

    test('last_activated_at null resulta en null', () {
      final json = <String, dynamic>{
        'tenants_count': 0,
        'completion_rate': 0.0,
      };

      final analytics = templateAnalyticsFromJson('tpl-1', json);
      expect(analytics.lastActivatedAt, isNull);
      expect(analytics.hasBeenUsed, isFalse);
    });

    test('completion_rate ausente resulta en 0.0', () {
      final json = <String, dynamic>{'tenants_count': 5};

      final analytics = templateAnalyticsFromJson('tpl-1', json);
      expect(analytics.completionRate, 0.0);
      expect(analytics.isCompletionAcceptable, isFalse);
    });

    test('isCompletionAcceptable es true con rate >= 0.5', () {
      final analytics = templateAnalyticsFromJson('tpl-1', baseAnalyticsJson);
      expect(analytics.isCompletionAcceptable, isTrue);
    });
  });
}
