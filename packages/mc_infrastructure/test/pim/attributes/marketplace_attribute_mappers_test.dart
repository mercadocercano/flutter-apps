import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  final baseAttrJson = <String, dynamic>{
    'id': 'attr-uuid-1',
    'name': 'Color',
    'slug': 'color',
    'type': 'select',
    'description': 'Color del producto',
    'is_required': true,
    'is_filterable': true,
    'values': <dynamic>[],
    'created_at': '2024-06-15T10:00:00Z',
    'updated_at': '2024-06-15T10:00:00Z',
  };

  final baseValueJson = <String, dynamic>{
    'id': 'val-uuid-1',
    'attribute_id': 'attr-uuid-1',
    'value': 'rojo',
    'label': 'Rojo',
    'sort_order': 0,
    'created_at': '2024-06-15T10:00:00Z',
    'updated_at': '2024-06-15T10:00:00Z',
  };

  group('attributeFromJson', () {
    test('mapea todos los campos correctamente', () {
      final attr = attributeFromJson(baseAttrJson);
      expect(attr.id, 'attr-uuid-1');
      expect(attr.name, 'Color');
      expect(attr.slug, 'color');
      expect(attr.type, AttributeType.select);
      expect(attr.description, 'Color del producto');
      expect(attr.isRequired, isTrue);
      expect(attr.isFilterable, isTrue);
      expect(attr.values, isEmpty);
    });

    test('campos opcionales nulos cuando no están presentes', () {
      final minJson = <String, dynamic>{
        'id': 'attr-min',
        'name': 'Material',
        'slug': 'material',
        'type': 'text',
        'created_at': '2024-06-15T10:00:00Z',
        'updated_at': '2024-06-15T10:00:00Z',
      };
      final attr = attributeFromJson(minJson);
      expect(attr.description, isNull);
      expect(attr.isRequired, isFalse);
      expect(attr.isFilterable, isFalse);
    });

    test('type text se parsea correctamente', () {
      final json = Map<String, dynamic>.from(baseAttrJson)..['type'] = 'text';
      expect(attributeFromJson(json).type, AttributeType.text);
    });

    test('type number se parsea correctamente', () {
      final json = Map<String, dynamic>.from(baseAttrJson)..['type'] = 'number';
      expect(attributeFromJson(json).type, AttributeType.number);
    });

    test('type boolean se parsea correctamente', () {
      final json = Map<String, dynamic>.from(baseAttrJson)
        ..['type'] = 'boolean';
      expect(attributeFromJson(json).type, AttributeType.boolean);
    });

    test('type multi_select se parsea correctamente', () {
      final json = Map<String, dynamic>.from(baseAttrJson)
        ..['type'] = 'multi_select';
      expect(attributeFromJson(json).type, AttributeType.multiSelect);
    });

    test('type desconocido cae a text', () {
      final json = Map<String, dynamic>.from(baseAttrJson)
        ..['type'] = 'unknown';
      expect(attributeFromJson(json).type, AttributeType.text);
    });

    test('values se mapean correctamente cuando están presentes', () {
      final json = Map<String, dynamic>.from(baseAttrJson)
        ..['values'] = [baseValueJson];
      final attr = attributeFromJson(json);
      expect(attr.values.length, 1);
      expect(attr.values.first.value, 'rojo');
    });
  });

  group('attributeToJson', () {
    test('serializa todos los campos requeridos', () {
      final now = DateTime(2024, 6, 15);
      final attr = MarketplaceAttribute(
        id: 'attr-1',
        name: 'Color',
        slug: 'color',
        type: AttributeType.select,
        description: 'Color del producto',
        isRequired: true,
        isFilterable: true,
        createdAt: now,
        updatedAt: now,
      );
      final json = attributeToJson(attr);
      expect(json['name'], 'Color');
      expect(json['slug'], 'color');
      expect(json['type'], 'select');
      expect(json['description'], 'Color del producto');
      expect(json['is_required'], isTrue);
      expect(json['is_filterable'], isTrue);
    });

    test('description omitida cuando es null', () {
      final now = DateTime(2024, 6, 15);
      final attr = MarketplaceAttribute(
        id: 'attr-1',
        name: 'Talla',
        slug: 'talla',
        type: AttributeType.text,
        createdAt: now,
        updatedAt: now,
      );
      final json = attributeToJson(attr);
      expect(json.containsKey('description'), isFalse);
    });

    test('type multi_select serializa como multi_select', () {
      final now = DateTime(2024, 6, 15);
      final attr = MarketplaceAttribute(
        id: 'attr-1',
        name: 'Tags',
        slug: 'tags',
        type: AttributeType.multiSelect,
        createdAt: now,
        updatedAt: now,
      );
      expect(attributeToJson(attr)['type'], 'multi_select');
    });
  });

  group('attributeValueFromJson', () {
    test('mapea todos los campos correctamente', () {
      final value = attributeValueFromJson(baseValueJson);
      expect(value.id, 'val-uuid-1');
      expect(value.attributeId, 'attr-uuid-1');
      expect(value.value, 'rojo');
      expect(value.label, 'Rojo');
      expect(value.sortOrder, 0);
    });

    test('sort_order null resulta en 0', () {
      final json = Map<String, dynamic>.from(baseValueJson)
        ..remove('sort_order');
      expect(attributeValueFromJson(json).sortOrder, 0);
    });
  });

  group('attributeValueToJson', () {
    test('serializa value, label y sort_order', () {
      final now = DateTime(2024, 6, 15);
      final value = AttributeValue(
        id: 'val-1',
        attributeId: 'attr-1',
        value: 'rojo',
        label: 'Rojo',
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      );
      final json = attributeValueToJson(value);
      expect(json['value'], 'rojo');
      expect(json['label'], 'Rojo');
      expect(json['sort_order'], 2);
    });
  });

  group('paginatedAttributesFromJson', () {
    test('parsea attributes key y pagination object correctamente', () {
      final json = <String, dynamic>{
        'attributes': [baseAttrJson],
        'pagination': {
          'page': 2,
          'page_size': 10,
          'total': 50,
          'total_pages': 5,
        },
      };

      final result = paginatedAttributesFromJson(json);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Color');
      expect(result.totalCount, 50);
      expect(result.page, 2);
      expect(result.pageSize, 10);
      expect(result.totalPages, 5);
    });

    test('attributes null resulta en lista vacía', () {
      final json = <String, dynamic>{
        'pagination': {
          'page': 1,
          'page_size': 20,
          'total': 0,
          'total_pages': 0,
        },
      };

      final result = paginatedAttributesFromJson(json);
      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });

    test('pagination ausente usa valores por defecto', () {
      final json = <String, dynamic>{
        'attributes': [baseAttrJson],
      };

      final result = paginatedAttributesFromJson(json);
      expect(result.items.length, 1);
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalPages, 1);
    });
  });
}
