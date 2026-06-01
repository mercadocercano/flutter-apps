import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

BusinessTypeTemplate buildTemplate({
  String id = 'tmpl-1',
  String businessTypeId = 'bt-1',
  String name = 'Ferretería Básica',
  String? description,
  List<String>? categoryIds,
  List<String>? baseProductIds,
  bool isDuplicate = false,
}) {
  final now = DateTime(2025, 1, 15);
  return BusinessTypeTemplate(
    id: id,
    businessTypeId: businessTypeId,
    name: name,
    description: description,
    categoryIds: categoryIds ?? const [],
    baseProductIds: baseProductIds ?? const [],
    isDuplicate: isDuplicate,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BusinessTypeTemplate entity', () {
    test('construye correctamente con campos obligatorios', () {
      final tmpl = buildTemplate();
      expect(tmpl.id, 'tmpl-1');
      expect(tmpl.businessTypeId, 'bt-1');
      expect(tmpl.name, 'Ferretería Básica');
      expect(tmpl.description, isNull);
      expect(tmpl.categoryIds, isEmpty);
      expect(tmpl.baseProductIds, isEmpty);
      expect(tmpl.isDuplicate, isFalse);
    });

    test('defaults correctos — listas vacías e isDuplicate false', () {
      final now = DateTime(2025, 1, 15);
      final tmpl = BusinessTypeTemplate(
        id: 'x',
        businessTypeId: 'bt-x',
        name: 'X',
        createdAt: now,
        updatedAt: now,
      );
      expect(tmpl.categoryIds, isEmpty);
      expect(tmpl.baseProductIds, isEmpty);
      expect(tmpl.isDuplicate, isFalse);
      expect(tmpl.description, isNull);
    });

    test('construye con todos los campos opcionales', () {
      final tmpl = buildTemplate(
        description: 'Template para ferreterías medianas',
        categoryIds: ['cat-1', 'cat-2', 'cat-3'],
        baseProductIds: ['prod-1', 'prod-2'],
        isDuplicate: true,
      );
      expect(tmpl.description, 'Template para ferreterías medianas');
      expect(tmpl.categoryIds.length, 3);
      expect(tmpl.baseProductIds.length, 2);
      expect(tmpl.isDuplicate, isTrue);
    });

    test('igualdad por valor (Equatable)', () {
      final t1 = buildTemplate();
      final t2 = buildTemplate();
      expect(t1, equals(t2));
    });

    test('distintos ids generan entidades distintas', () {
      final t1 = buildTemplate(id: 'tmpl-1');
      final t2 = buildTemplate(id: 'tmpl-2');
      expect(t1, isNot(equals(t2)));
    });

    test('distinto businessTypeId genera entidades distintas', () {
      final t1 = buildTemplate(businessTypeId: 'bt-1');
      final t2 = buildTemplate(businessTypeId: 'bt-2');
      expect(t1, isNot(equals(t2)));
    });

    test('distintas categoryIds generan entidades distintas', () {
      final t1 = buildTemplate(categoryIds: ['cat-1']);
      final t2 = buildTemplate(categoryIds: ['cat-2']);
      expect(t1, isNot(equals(t2)));
    });

    test('distintas baseProductIds generan entidades distintas', () {
      final t1 = buildTemplate(baseProductIds: ['prod-1']);
      final t2 = buildTemplate(baseProductIds: ['prod-2']);
      expect(t1, isNot(equals(t2)));
    });

    test('distinto isDuplicate genera entidades distintas', () {
      final t1 = buildTemplate(isDuplicate: false);
      final t2 = buildTemplate(isDuplicate: true);
      expect(t1, isNot(equals(t2)));
    });

    group('copyWith', () {
      test('cambia solo el name', () {
        final original = buildTemplate(name: 'Ferretería Básica');
        final updated = original.copyWith(name: 'Ferretería Básica (copia)');
        expect(updated.name, 'Ferretería Básica (copia)');
        expect(updated.id, original.id);
        expect(updated.businessTypeId, original.businessTypeId);
      });

      test('cambia el businessTypeId', () {
        final original = buildTemplate(businessTypeId: 'bt-1');
        final updated = original.copyWith(businessTypeId: 'bt-2');
        expect(updated.businessTypeId, 'bt-2');
        expect(updated.id, original.id);
      });

      test('cambia las categoryIds', () {
        final original = buildTemplate(categoryIds: []);
        final updated =
            original.copyWith(categoryIds: ['cat-1', 'cat-2']);
        expect(updated.categoryIds.length, 2);
        expect(updated.id, original.id);
      });

      test('cambia las baseProductIds', () {
        final original = buildTemplate(baseProductIds: []);
        final updated =
            original.copyWith(baseProductIds: ['prod-1', 'prod-2', 'prod-3']);
        expect(updated.baseProductIds.length, 3);
        expect(updated.id, original.id);
      });

      test('cambia isDuplicate', () {
        final original = buildTemplate(isDuplicate: false);
        final updated = original.copyWith(isDuplicate: true);
        expect(updated.isDuplicate, isTrue);
        expect(updated.id, original.id);
      });

      test('cambia la description', () {
        final original = buildTemplate(description: null);
        final updated = original.copyWith(description: 'Nueva descripción');
        expect(updated.description, 'Nueva descripción');
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildTemplate(
          categoryIds: ['cat-1'],
          baseProductIds: ['prod-1'],
        );
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('puede sobreescribir fechas', () {
        final original = buildTemplate();
        final newDate = DateTime(2026, 6, 1);
        final updated = original.copyWith(
          createdAt: newDate,
          updatedAt: newDate,
        );
        expect(updated.createdAt, newDate);
        expect(updated.updatedAt, newDate);
        expect(updated.id, original.id);
      });
    });

    test('props incluye todos los campos', () {
      final tmpl = buildTemplate(
        description: 'desc',
        categoryIds: ['cat-1'],
        baseProductIds: ['prod-1'],
      );
      expect(
        tmpl.props,
        containsAll([
          tmpl.id,
          tmpl.businessTypeId,
          tmpl.name,
          tmpl.description,
          tmpl.categoryIds,
          tmpl.baseProductIds,
          tmpl.isDuplicate,
          tmpl.createdAt,
          tmpl.updatedAt,
        ]),
      );
    });
  });
}
