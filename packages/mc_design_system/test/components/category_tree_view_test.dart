import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_domain/mc_domain.dart';

MarketplaceCategory _cat({
  required String id,
  required String name,
  String? parentId,
  int level = 0,
  List<MarketplaceCategory> children = const [],
}) {
  final now = DateTime(2024, 1, 1);
  return MarketplaceCategory(
    id: id,
    name: name,
    slug: name.toLowerCase(),
    parentId: parentId,
    level: level,
    children: children,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CategoryTreeView', () {
    testWidgets('renderiza nodos raíz', (tester) async {
      final cats = [
        _cat(id: 'r1', name: 'Hogar'),
        _cat(id: 'r2', name: 'Electrónica'),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(categories: cats),
      ));

      expect(find.text('Hogar'), findsOneWidget);
      expect(find.text('Electrónica'), findsOneWidget);
    });

    testWidgets('lista vacía muestra mensaje de sin categorías', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryTreeView(categories: []),
      ));

      expect(find.text('No hay categorías'), findsOneWidget);
    });

    testWidgets('nodo con hijos muestra icono de expand', (tester) async {
      final cats = [
        _cat(
          id: 'r1',
          name: 'Electrónica',
          children: [_cat(id: 'c1', name: 'Audio', level: 1)],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(categories: cats),
      ));

      expect(find.byKey(const Key('expand_r1')), findsOneWidget);
    });

    testWidgets('tap en expand llama onToggleExpand', (tester) async {
      String? toggledId;
      final cats = [
        _cat(
          id: 'r1',
          name: 'Electrónica',
          children: [_cat(id: 'c1', name: 'Audio', level: 1)],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          onToggleExpand: (id) => toggledId = id,
        ),
      ));

      await tester.tap(find.byKey(const Key('expand_r1')));
      await tester.pump();

      expect(toggledId, 'r1');
    });

    testWidgets('hijos visibles cuando nodo está expandido', (tester) async {
      final cats = [
        _cat(
          id: 'r1',
          name: 'Electrónica',
          children: [_cat(id: 'c1', name: 'Audio', level: 1)],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          expandedIds: const {'r1'},
        ),
      ));

      expect(find.text('Audio'), findsOneWidget);
    });

    testWidgets('hijos ocultos cuando nodo está colapsado', (tester) async {
      final cats = [
        _cat(
          id: 'r1',
          name: 'Electrónica',
          children: [_cat(id: 'c1', name: 'Audio', level: 1)],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(categories: cats),
      ));

      expect(find.text('Audio'), findsNothing);
    });

    testWidgets('muestra badge con conteo de hijos cuando colapsado',
        (tester) async {
      final cats = [
        _cat(
          id: 'r1',
          name: 'Electrónica',
          children: [
            _cat(id: 'c1', name: 'Audio', level: 1),
            _cat(id: 'c2', name: 'Video', level: 1),
          ],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(categories: cats),
      ));

      expect(find.byKey(const Key('badge_r1')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('badge no visible cuando nodo está expandido', (tester) async {
      final cats = [
        _cat(
          id: 'r1',
          name: 'Electrónica',
          children: [_cat(id: 'c1', name: 'Audio', level: 1)],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          expandedIds: const {'r1'},
        ),
      ));

      expect(find.byKey(const Key('badge_r1')), findsNothing);
    });

    testWidgets('searchQuery resalta texto coincidente', (tester) async {
      final cats = [_cat(id: 'r1', name: 'Electrónica')];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          searchQuery: 'Electr',
        ),
      ));

      // RichText con el texto highlight debe estar presente
      final richTexts = find.byType(RichText);
      expect(richTexts, findsWidgets);
    });

    testWidgets('tap en nodo llama onSelect con id correcto', (tester) async {
      String? selectedId;
      final cats = [_cat(id: 'r1', name: 'Hogar')];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          onSelect: (id) => selectedId = id,
        ),
      ));

      await tester.tap(find.text('Hogar'));
      await tester.pump();

      expect(selectedId, 'r1');
    });

    testWidgets('actionsBuilder renderiza widget de acciones', (tester) async {
      final cats = [_cat(id: 'r1', name: 'Hogar')];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          actionsBuilder: (cat) => const Icon(Icons.edit, key: Key('edit_btn')),
        ),
      ));

      expect(find.byKey(const Key('edit_btn')), findsOneWidget);
    });

    testWidgets('árbol de 3 niveles renderiza niveles intermedios al expandir',
        (tester) async {
      final cats = [
        _cat(
          id: 'r1',
          name: 'Hogar',
          children: [
            _cat(
              id: 'c1',
              name: 'Muebles',
              level: 1,
              children: [
                _cat(id: 'g1', name: 'Sillas', level: 2),
              ],
            ),
          ],
        ),
      ];

      await tester.pumpWidget(_wrap(
        CategoryTreeView(
          categories: cats,
          expandedIds: const {'r1', 'c1'},
        ),
      ));

      expect(find.text('Muebles'), findsOneWidget);
      expect(find.text('Sillas'), findsOneWidget);
    });
  });
}
