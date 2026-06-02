import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

AttributeValue buildValue({
  String id = 'val-1',
  String attributeId = 'attr-1',
  String value = 'rojo',
  String label = 'Rojo',
  int sortOrder = 0,
}) {
  final now = DateTime(2024, 6, 15);
  return AttributeValue(
    id: id,
    attributeId: attributeId,
    value: value,
    label: label,
    sortOrder: sortOrder,
    createdAt: now,
    updatedAt: now,
  );
}

MarketplaceAttribute buildAttribute({
  String id = 'attr-1',
  String name = 'Color',
  String slug = 'color',
  AttributeType type = AttributeType.select,
  String? description,
  bool isRequired = false,
  bool isFilterable = false,
  List<AttributeValue>? values,
}) {
  final now = DateTime(2024, 6, 15);
  return MarketplaceAttribute(
    id: id,
    name: name,
    slug: slug,
    type: type,
    description: description,
    isRequired: isRequired,
    isFilterable: isFilterable,
    values: values ?? const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MarketplaceAttribute entity', () {
    test('construye correctamente con campos obligatorios', () {
      final attr = buildAttribute();
      expect(attr.id, 'attr-1');
      expect(attr.name, 'Color');
      expect(attr.slug, 'color');
      expect(attr.type, AttributeType.select);
      expect(attr.isRequired, isFalse);
      expect(attr.isFilterable, isFalse);
      expect(attr.values, isEmpty);
      expect(attr.description, isNull);
    });

    test('defaults correctos — isRequired e isFilterable son false', () {
      final now = DateTime(2024, 6, 15);
      final attr = MarketplaceAttribute(
        id: 'x',
        name: 'X',
        slug: 'x',
        type: AttributeType.text,
        createdAt: now,
        updatedAt: now,
      );
      expect(attr.isRequired, isFalse);
      expect(attr.isFilterable, isFalse);
      expect(attr.values, isEmpty);
    });

    test('construye con todos los campos opcionales', () {
      final attr = buildAttribute(
        description: 'Color del producto',
        isRequired: true,
        isFilterable: true,
        values: [buildValue()],
      );
      expect(attr.description, 'Color del producto');
      expect(attr.isRequired, isTrue);
      expect(attr.isFilterable, isTrue);
      expect(attr.values.length, 1);
    });

    test('igualdad por valor (Equatable)', () {
      final a1 = buildAttribute();
      final a2 = buildAttribute();
      expect(a1, equals(a2));
    });

    test('distintos ids generan entidades distintas', () {
      final a1 = buildAttribute(id: 'attr-1');
      final a2 = buildAttribute(id: 'attr-2');
      expect(a1, isNot(equals(a2)));
    });

    test('distinto type genera entidades distintas', () {
      final a1 = buildAttribute(type: AttributeType.text);
      final a2 = buildAttribute(type: AttributeType.select);
      expect(a1, isNot(equals(a2)));
    });

    group('hasValues', () {
      test('true cuando type es select', () {
        final attr = buildAttribute(type: AttributeType.select);
        expect(attr.hasValues, isTrue);
      });

      test('true cuando type es multiSelect', () {
        final attr = buildAttribute(type: AttributeType.multiSelect);
        expect(attr.hasValues, isTrue);
      });

      test('false cuando type es text', () {
        final attr = buildAttribute(type: AttributeType.text);
        expect(attr.hasValues, isFalse);
      });

      test('false cuando type es number', () {
        final attr = buildAttribute(type: AttributeType.number);
        expect(attr.hasValues, isFalse);
      });

      test('false cuando type es boolean', () {
        final attr = buildAttribute(type: AttributeType.boolean);
        expect(attr.hasValues, isFalse);
      });
    });

    group('copyWith', () {
      test('cambia solo el name', () {
        final original = buildAttribute(name: 'Color');
        final updated = original.copyWith(name: 'Talla');
        expect(updated.name, 'Talla');
        expect(updated.id, original.id);
        expect(updated.slug, original.slug);
        expect(updated.type, original.type);
      });

      test('cambia el type', () {
        final original = buildAttribute(type: AttributeType.text);
        final updated = original.copyWith(type: AttributeType.select);
        expect(updated.type, AttributeType.select);
        expect(updated.id, original.id);
      });

      test('cambia isRequired e isFilterable', () {
        final original =
            buildAttribute(isRequired: false, isFilterable: false);
        final updated =
            original.copyWith(isRequired: true, isFilterable: true);
        expect(updated.isRequired, isTrue);
        expect(updated.isFilterable, isTrue);
        expect(updated.id, original.id);
      });

      test('cambia los values', () {
        final original = buildAttribute(values: []);
        final newValues = [buildValue(id: 'v1'), buildValue(id: 'v2')];
        final updated = original.copyWith(values: newValues);
        expect(updated.values.length, 2);
        expect(updated.id, original.id);
      });

      test('cambia la description', () {
        final original = buildAttribute(description: null);
        final updated = original.copyWith(description: 'Nueva descripción');
        expect(updated.description, 'Nueva descripción');
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildAttribute();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('cambia el slug', () {
        final original = buildAttribute(slug: 'color');
        final updated = original.copyWith(slug: 'talla');
        expect(updated.slug, 'talla');
        expect(updated.name, original.name);
      });
    });

    test('props incluye todos los campos', () {
      final attr = buildAttribute();
      expect(
        attr.props,
        containsAll([
          attr.id,
          attr.name,
          attr.slug,
          attr.type,
          attr.isRequired,
          attr.isFilterable,
          attr.values,
          attr.createdAt,
          attr.updatedAt,
        ]),
      );
    });

    test('values con distintos elementos generan entidades distintas', () {
      final a1 = buildAttribute(values: [buildValue(id: 'v1')]);
      final a2 = buildAttribute(values: [buildValue(id: 'v2')]);
      expect(a1, isNot(equals(a2)));
    });
  });
}
