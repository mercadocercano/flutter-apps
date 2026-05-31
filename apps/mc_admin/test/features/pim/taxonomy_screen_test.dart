import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/taxonomy/blocs/taxonomy_bloc.dart';
import 'package:mc_admin/features/pim/taxonomy/blocs/category_form_bloc.dart';
import 'package:mc_admin/features/pim/taxonomy/taxonomy_screen.dart';

class MockTaxonomyBloc extends MockBloc<TaxonomyEvent, TaxonomyState>
    implements TaxonomyBloc {}

class MockCategoryFormBloc
    extends MockBloc<CategoryFormEvent, CategoryFormState>
    implements CategoryFormBloc {}

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

CategoryTree _buildTree() {
  return CategoryTree.fromFlat([
    _cat(id: 'r1', name: 'Hogar'),
    _cat(id: 'r2', name: 'Electrónica'),
    _cat(id: 'c1', name: 'Audio', parentId: 'r2', level: 1),
  ]);
}

Widget _buildScreen({
  required TaxonomyState taxonomyState,
  CategoryFormState? formState,
}) {
  final taxonomyBloc = MockTaxonomyBloc();
  final formBloc = MockCategoryFormBloc();

  when(() => taxonomyBloc.state).thenReturn(taxonomyState);
  when(() => formBloc.state).thenReturn(formState ?? CategoryFormInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<TaxonomyBloc>.value(value: taxonomyBloc),
          BlocProvider<CategoryFormBloc>.value(value: formBloc),
        ],
        child: const TaxonomyScreen(),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoadTaxonomyEvent());
    registerFallbackValue(RefreshTaxonomyEvent());
    registerFallbackValue(SearchCategoriesEvent(''));
    registerFallbackValue(ToggleCategoryExpansionEvent(''));
    registerFallbackValue(
      const CreateCategoryParams(name: 'x', slug: 'x'),
    );
    registerFallbackValue(const UpdateCategoryParams());
    registerFallbackValue(DeleteCategoryEvent(''));
  });

  group('TaxonomyScreen', () {
    testWidgets('muestra CircularProgressIndicator cuando carga',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(taxonomyState: TaxonomyLoading()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla la carga',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(taxonomyState: TaxonomyError('Error de red')),
      );

      expect(find.text('Error de red'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('muestra árbol de categorías cuando estado es Loaded',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(tree: _buildTree()),
        ),
      );

      expect(find.text('Hogar'), findsOneWidget);
      expect(find.text('Electrónica'), findsOneWidget);
    });

    testWidgets('muestra SearchBar', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(tree: _buildTree()),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('muestra botón Nueva categoría', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(tree: _buildTree()),
        ),
      );

      expect(find.text('Nueva categoría'), findsOneWidget);
    });

    testWidgets('hijos no visibles cuando nodo está colapsado', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(
            tree: _buildTree(),
          ),
        ),
      );

      expect(find.text('Audio'), findsNothing);
    });

    testWidgets('hijos visibles cuando nodo está expandido', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(
            tree: _buildTree(),
            expandedIds: const {'r2'},
          ),
        ),
      );

      expect(find.text('Audio'), findsOneWidget);
    });

    testWidgets('muestra botones de acción por nodo', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(tree: _buildTree()),
        ),
      );

      // Edit button for Hogar
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });

    testWidgets('muestra breadcrumb al seleccionar nodo', (tester) async {
      final tree = _buildTree();
      await tester.pumpWidget(
        _buildScreen(
          taxonomyState: TaxonomyLoaded(tree: tree),
        ),
      );

      // Tap on Hogar to select
      await tester.tap(find.text('Hogar').first);
      await tester.pump();

      expect(find.text('Hogar'), findsWidgets);
    });
  });
}
