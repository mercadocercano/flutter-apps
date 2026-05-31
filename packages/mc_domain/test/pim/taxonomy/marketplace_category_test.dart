import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

MarketplaceCategory _cat({
  required String id,
  required String name,
  String? parentId,
  int level = 0,
  int sortOrder = 0,
  List<MarketplaceCategory> children = const [],
}) {
  final now = DateTime(2024, 1, 1);
  return MarketplaceCategory(
    id: id,
    name: name,
    slug: name.toLowerCase(),
    parentId: parentId,
    level: level,
    sortOrder: sortOrder,
    children: children,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MarketplaceCategory', () {
    test('isRoot retorna true si parentId es null', () {
      final cat = _cat(id: 'r1', name: 'Root');
      expect(cat.isRoot, isTrue);
    });

    test('isRoot retorna false si tiene parentId', () {
      final cat = _cat(id: 'c1', name: 'Child', parentId: 'r1');
      expect(cat.isRoot, isFalse);
    });

    test('hasChildren retorna true si tiene hijos', () {
      final cat = _cat(
        id: 'r1',
        name: 'Root',
        children: [_cat(id: 'c1', name: 'Child')],
      );
      expect(cat.hasChildren, isTrue);
    });

    test('hasChildren retorna false si no tiene hijos', () {
      final cat = _cat(id: 'r1', name: 'Root');
      expect(cat.hasChildren, isFalse);
    });

    test('copyWith actualiza campos correctamente', () {
      final original = _cat(id: 'r1', name: 'Original');
      final copy = original.copyWith(name: 'Actualizado', isActive: false);
      expect(copy.name, 'Actualizado');
      expect(copy.isActive, isFalse);
      expect(copy.id, original.id);
    });

    test('Equatable props iguales para misma data', () {
      final now = DateTime(2024, 1, 1);
      final a = MarketplaceCategory(
        id: 'x',
        name: 'X',
        slug: 'x',
        createdAt: now,
        updatedAt: now,
      );
      final b = MarketplaceCategory(
        id: 'x',
        name: 'X',
        slug: 'x',
        createdAt: now,
        updatedAt: now,
      );
      expect(a, equals(b));
    });
  });

  group('CategoryTree.fromFlat', () {
    test('lista vacía produce árbol vacío', () {
      final tree = CategoryTree.fromFlat([]);
      expect(tree.roots, isEmpty);
      expect(tree.isEmpty, isTrue);
    });

    test('construye árbol con un solo nodo raíz', () {
      final tree = CategoryTree.fromFlat([_cat(id: 'r1', name: 'Hogar')]);
      expect(tree.roots.length, 1);
      expect(tree.roots.first.name, 'Hogar');
    });

    test('construye árbol con raíz y un hijo', () {
      final flat = [
        _cat(id: 'r1', name: 'Hogar'),
        _cat(id: 'c1', name: 'Cocina', parentId: 'r1', level: 1),
      ];
      final tree = CategoryTree.fromFlat(flat);

      expect(tree.roots.length, 1);
      expect(tree.roots.first.children.length, 1);
      expect(tree.roots.first.children.first.name, 'Cocina');
    });

    test('construye árbol de 3 niveles', () {
      final flat = [
        _cat(id: 'r1', name: 'Electrónica'),
        _cat(id: 'c1', name: 'Audio', parentId: 'r1', level: 1),
        _cat(id: 'g1', name: 'Auriculares', parentId: 'c1', level: 2),
      ];
      final tree = CategoryTree.fromFlat(flat);

      final audio = tree.roots.first.children.first;
      expect(audio.children.length, 1);
      expect(audio.children.first.name, 'Auriculares');
    });

    test('ordena hijos por sortOrder', () {
      final flat = [
        _cat(id: 'r1', name: 'Raíz'),
        _cat(id: 'c2', name: 'Segundo', parentId: 'r1', sortOrder: 2),
        _cat(id: 'c1', name: 'Primero', parentId: 'r1', sortOrder: 1),
      ];
      final tree = CategoryTree.fromFlat(flat);
      final kids = tree.roots.first.children;

      expect(kids[0].name, 'Primero');
      expect(kids[1].name, 'Segundo');
    });

    test('asigna path correcto en cadena multinivel', () {
      final flat = [
        _cat(id: 'r1', name: 'Hogar'),
        _cat(id: 'c1', name: 'Muebles', parentId: 'r1', level: 1),
        _cat(id: 'g1', name: 'Sillas', parentId: 'c1', level: 2),
      ];
      final tree = CategoryTree.fromFlat(flat);
      final sillas = tree.findById('g1');

      expect(sillas?.path, ['Hogar', 'Muebles', 'Sillas']);
    });

    test('construye múltiples raíces correctamente', () {
      final flat = [
        _cat(id: 'r1', name: 'Hogar'),
        _cat(id: 'r2', name: 'Ropa'),
        _cat(id: 'r3', name: 'Electrónica'),
      ];
      final tree = CategoryTree.fromFlat(flat);
      expect(tree.roots.length, 3);
    });
  });

  group('CategoryTree.findById', () {
    late CategoryTree tree;

    setUp(() {
      tree = CategoryTree.fromFlat([
        _cat(id: 'r1', name: 'Electrónica'),
        _cat(id: 'c1', name: 'Audio', parentId: 'r1', level: 1),
        _cat(id: 'g1', name: 'Auriculares', parentId: 'c1', level: 2),
      ]);
    });

    test('encuentra nodo raíz', () {
      final found = tree.findById('r1');
      expect(found?.name, 'Electrónica');
    });

    test('encuentra nodo hoja en nivel profundo', () {
      final found = tree.findById('g1');
      expect(found?.name, 'Auriculares');
    });

    test('retorna null si id no existe', () {
      final found = tree.findById('no-existe');
      expect(found, isNull);
    });

    test('retorna null en árbol vacío', () {
      final emptyTree = CategoryTree.fromFlat([]);
      expect(emptyTree.findById('any'), isNull);
    });
  });

  group('CategoryTree.getPath', () {
    late CategoryTree tree;

    setUp(() {
      tree = CategoryTree.fromFlat([
        _cat(id: 'r1', name: 'Hogar'),
        _cat(id: 'c1', name: 'Muebles', parentId: 'r1', level: 1),
        _cat(id: 'g1', name: 'Sillas', parentId: 'c1', level: 2),
      ]);
    });

    test('retorna path de un nodo raíz (solo él mismo)', () {
      final path = tree.getPath('r1');
      expect(path.length, 1);
      expect(path.first.name, 'Hogar');
    });

    test('retorna path desde raíz hasta nodo intermedio', () {
      final path = tree.getPath('c1');
      expect(path.map((c) => c.name).toList(), ['Hogar', 'Muebles']);
    });

    test('retorna path completo hasta nodo hoja', () {
      final path = tree.getPath('g1');
      expect(path.map((c) => c.name).toList(), ['Hogar', 'Muebles', 'Sillas']);
    });

    test('retorna lista vacía si id no existe', () {
      final path = tree.getPath('no-existe');
      expect(path, isEmpty);
    });

    test('retorna lista vacía en árbol vacío', () {
      final emptyTree = CategoryTree.fromFlat([]);
      expect(emptyTree.getPath('any'), isEmpty);
    });
  });
}
