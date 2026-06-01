import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

BusinessType buildBusinessType({
  String id = 'bt-1',
  String name = 'Ferretería',
  String slug = 'ferreteria',
  String? description,
  String icon = 'hardware',
  bool isActive = true,
  int templateCount = 0,
}) {
  final now = DateTime(2025, 1, 15);
  return BusinessType(
    id: id,
    name: name,
    slug: slug,
    description: description,
    icon: icon,
    isActive: isActive,
    templateCount: templateCount,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BusinessType entity', () {
    test('construye correctamente con campos obligatorios', () {
      final bt = buildBusinessType();
      expect(bt.id, 'bt-1');
      expect(bt.name, 'Ferretería');
      expect(bt.slug, 'ferreteria');
      expect(bt.icon, 'hardware');
      expect(bt.isActive, isTrue);
      expect(bt.templateCount, 0);
      expect(bt.description, isNull);
    });

    test('defaults correctos — isActive true y templateCount 0', () {
      final now = DateTime(2025, 1, 15);
      final bt = BusinessType(
        id: 'x',
        name: 'X',
        slug: 'x',
        icon: 'store',
        createdAt: now,
        updatedAt: now,
      );
      expect(bt.isActive, isTrue);
      expect(bt.templateCount, 0);
      expect(bt.description, isNull);
    });

    test('construye con todos los campos opcionales', () {
      final bt = buildBusinessType(
        description: 'Comercio de herramientas',
        isActive: false,
        templateCount: 3,
      );
      expect(bt.description, 'Comercio de herramientas');
      expect(bt.isActive, isFalse);
      expect(bt.templateCount, 3);
    });

    test('igualdad por valor (Equatable)', () {
      final bt1 = buildBusinessType();
      final bt2 = buildBusinessType();
      expect(bt1, equals(bt2));
    });

    test('distintos ids generan entidades distintas', () {
      final bt1 = buildBusinessType(id: 'bt-1');
      final bt2 = buildBusinessType(id: 'bt-2');
      expect(bt1, isNot(equals(bt2)));
    });

    test('distinto isActive genera entidades distintas', () {
      final bt1 = buildBusinessType(isActive: true);
      final bt2 = buildBusinessType(isActive: false);
      expect(bt1, isNot(equals(bt2)));
    });

    test('distinto templateCount genera entidades distintas', () {
      final bt1 = buildBusinessType(templateCount: 0);
      final bt2 = buildBusinessType(templateCount: 5);
      expect(bt1, isNot(equals(bt2)));
    });

    group('copyWith', () {
      test('cambia solo el name', () {
        final original = buildBusinessType(name: 'Ferretería');
        final updated = original.copyWith(name: 'Panadería');
        expect(updated.name, 'Panadería');
        expect(updated.id, original.id);
        expect(updated.slug, original.slug);
        expect(updated.icon, original.icon);
      });

      test('cambia el slug', () {
        final original = buildBusinessType(slug: 'ferreteria');
        final updated = original.copyWith(slug: 'panaderia');
        expect(updated.slug, 'panaderia');
        expect(updated.name, original.name);
      });

      test('cambia el icon', () {
        final original = buildBusinessType(icon: 'hardware');
        final updated = original.copyWith(icon: 'bakery');
        expect(updated.icon, 'bakery');
        expect(updated.id, original.id);
      });

      test('cambia isActive', () {
        final original = buildBusinessType(isActive: true);
        final updated = original.copyWith(isActive: false);
        expect(updated.isActive, isFalse);
        expect(updated.id, original.id);
      });

      test('cambia templateCount', () {
        final original = buildBusinessType(templateCount: 0);
        final updated = original.copyWith(templateCount: 5);
        expect(updated.templateCount, 5);
        expect(updated.id, original.id);
      });

      test('cambia la description', () {
        final original = buildBusinessType(description: null);
        final updated = original.copyWith(description: 'Nueva descripción');
        expect(updated.description, 'Nueva descripción');
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildBusinessType();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('puede sobreescribir createdAt y updatedAt', () {
        final original = buildBusinessType();
        final newDate = DateTime(2026, 1, 1);
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
      final bt = buildBusinessType(description: 'desc');
      expect(
        bt.props,
        containsAll([
          bt.id,
          bt.name,
          bt.slug,
          bt.description,
          bt.icon,
          bt.isActive,
          bt.templateCount,
          bt.createdAt,
          bt.updatedAt,
        ]),
      );
    });

    test('distinta description genera entidades distintas', () {
      final bt1 = buildBusinessType(description: 'A');
      final bt2 = buildBusinessType(description: 'B');
      expect(bt1, isNot(equals(bt2)));
    });

    test('distinto icon genera entidades distintas', () {
      final bt1 = buildBusinessType(icon: 'hardware');
      final bt2 = buildBusinessType(icon: 'bakery');
      expect(bt1, isNot(equals(bt2)));
    });
  });
}
