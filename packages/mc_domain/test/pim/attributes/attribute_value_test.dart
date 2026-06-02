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

void main() {
  group('AttributeValue entity', () {
    test('construye correctamente con campos obligatorios', () {
      final val = buildValue();
      expect(val.id, 'val-1');
      expect(val.attributeId, 'attr-1');
      expect(val.value, 'rojo');
      expect(val.label, 'Rojo');
      expect(val.sortOrder, 0);
    });

    test('sortOrder por defecto es 0', () {
      final now = DateTime(2024, 6, 15);
      final val = AttributeValue(
        id: 'v',
        attributeId: 'a',
        value: 'x',
        label: 'X',
        createdAt: now,
        updatedAt: now,
      );
      expect(val.sortOrder, 0);
    });

    test('igualdad por valor (Equatable)', () {
      final v1 = buildValue();
      final v2 = buildValue();
      expect(v1, equals(v2));
    });

    test('distintos ids generan entidades distintas', () {
      final v1 = buildValue(id: 'val-1');
      final v2 = buildValue(id: 'val-2');
      expect(v1, isNot(equals(v2)));
    });

    test('distintos values generan entidades distintas', () {
      final v1 = buildValue(value: 'rojo');
      final v2 = buildValue(value: 'azul');
      expect(v1, isNot(equals(v2)));
    });

    test('distintos sortOrder generan entidades distintas', () {
      final v1 = buildValue(sortOrder: 0);
      final v2 = buildValue(sortOrder: 1);
      expect(v1, isNot(equals(v2)));
    });

    group('copyWith', () {
      test('cambia solo el label', () {
        final original = buildValue(label: 'Rojo');
        final updated = original.copyWith(label: 'Rojo/Red');
        expect(updated.label, 'Rojo/Red');
        expect(updated.id, original.id);
        expect(updated.value, original.value);
        expect(updated.attributeId, original.attributeId);
      });

      test('cambia el sortOrder', () {
        final original = buildValue(sortOrder: 3);
        final updated = original.copyWith(sortOrder: 1);
        expect(updated.sortOrder, 1);
        expect(updated.id, original.id);
      });

      test('cambia el attributeId', () {
        final original = buildValue(attributeId: 'attr-1');
        final updated = original.copyWith(attributeId: 'attr-2');
        expect(updated.attributeId, 'attr-2');
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildValue();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('cambia las fechas', () {
        final original = buildValue();
        final newDate = DateTime(2025, 1, 1);
        final updated = original.copyWith(updatedAt: newDate);
        expect(updated.updatedAt, newDate);
        expect(updated.createdAt, original.createdAt);
      });
    });

    test('props incluye todos los campos', () {
      final val = buildValue();
      expect(
        val.props,
        containsAll([
          val.id,
          val.attributeId,
          val.value,
          val.label,
          val.sortOrder,
          val.createdAt,
          val.updatedAt,
        ]),
      );
    });
  });
}
