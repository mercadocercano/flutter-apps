import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/taxonomy/blocs/taxonomy_bloc.dart';
import 'package:mc_admin/features/pim/taxonomy/blocs/category_form_bloc.dart';

class MockGetCategoryTreeUseCase extends Mock
    implements GetCategoryTreeUseCase {}

class MockCreateCategoryUseCase extends Mock implements CreateCategoryUseCase {}

class MockUpdateCategoryUseCase extends Mock implements UpdateCategoryUseCase {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

MarketplaceCategory _buildCat({String id = 'cat-1', String? parentId}) {
  final now = DateTime(2024, 6, 1);
  return MarketplaceCategory(
    id: id,
    name: 'Electrónica',
    slug: 'electronica',
    parentId: parentId,
    createdAt: now,
    updatedAt: now,
  );
}

CategoryTree _buildTree() {
  return CategoryTree.fromFlat([
    _buildCat(id: 'r1'),
    _buildCat(id: 'c1', parentId: 'r1'),
  ]);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreateCategoryParams(name: 'x', slug: 'x'),
    );
    registerFallbackValue(const UpdateCategoryParams());
  });

  group('TaxonomyBloc', () {
    late MockGetCategoryTreeUseCase getTreeUseCase;

    setUp(() {
      getTreeUseCase = MockGetCategoryTreeUseCase();
    });

    TaxonomyBloc buildBloc() =>
        TaxonomyBloc(getTree: getTreeUseCase);

    blocTest<TaxonomyBloc, TaxonomyState>(
      'emite [Loading, Loaded] al cargar el árbol exitosamente',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTaxonomyEvent()),
      expect: () => [
        isA<TaxonomyLoading>(),
        isA<TaxonomyLoaded>(),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'emite [Loading, Error] cuando getTree falla',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTaxonomyEvent()),
      expect: () => [
        isA<TaxonomyLoading>(),
        isA<TaxonomyError>(),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'TaxonomyLoaded contiene el árbol correcto',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTaxonomyEvent()),
      expect: () => [
        isA<TaxonomyLoading>(),
        isA<TaxonomyLoaded>().having(
          (s) => s.tree.roots.isNotEmpty,
          'tree has roots',
          isTrue,
        ),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'SearchCategoriesEvent actualiza searchQuery en estado Loaded',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTaxonomyEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(SearchCategoriesEvent('audio'));
      },
      skip: 2,
      expect: () => [
        isA<TaxonomyLoaded>()
            .having((s) => s.searchQuery, 'searchQuery', 'audio'),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'SearchCategoriesEvent con cadena vacía limpia searchQuery',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTaxonomyEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(SearchCategoriesEvent('audio'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(SearchCategoriesEvent(''));
      },
      // Skip Loading, Loaded, Loaded(audio) → expect Loaded(null)
      skip: 3,
      expect: () => [
        isA<TaxonomyLoaded>()
            .having((s) => s.searchQuery, 'searchQuery', isNull),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'ToggleCategoryExpansionEvent agrega id a expandedIds',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTaxonomyEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ToggleCategoryExpansionEvent('r1'));
      },
      skip: 2,
      expect: () => [
        isA<TaxonomyLoaded>().having(
          (s) => s.expandedIds.contains('r1'),
          'r1 expanded',
          isTrue,
        ),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'ToggleCategoryExpansionEvent remueve id si ya estaba expandido',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTaxonomyEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ToggleCategoryExpansionEvent('r1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ToggleCategoryExpansionEvent('r1'));
      },
      skip: 3,
      expect: () => [
        isA<TaxonomyLoaded>().having(
          (s) => s.expandedIds.contains('r1'),
          'r1 not expanded',
          isFalse,
        ),
      ],
    );

    blocTest<TaxonomyBloc, TaxonomyState>(
      'RefreshTaxonomyEvent preserva expandedIds previos',
      build: () {
        when(() => getTreeUseCase.execute())
            .thenAnswer((_) async => _buildTree());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTaxonomyEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ToggleCategoryExpansionEvent('r1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(RefreshTaxonomyEvent());
      },
      skip: 3,
      expect: () => [
        isA<TaxonomyLoading>(),
        isA<TaxonomyLoaded>().having(
          (s) => s.expandedIds.contains('r1'),
          'r1 still expanded after refresh',
          isTrue,
        ),
      ],
    );

    test('TaxonomyError guarda el mensaje', () {
      final state = TaxonomyError('Error de red');
      expect(state.message, 'Error de red');
    });

    test('estado inicial es TaxonomyInitial', () {
      when(() => getTreeUseCase.execute())
          .thenAnswer((_) async => _buildTree());
      final bloc = buildBloc();
      expect(bloc.state, isA<TaxonomyInitial>());
    });
  });

  group('CategoryFormBloc', () {
    late MockCreateCategoryUseCase createUseCase;
    late MockUpdateCategoryUseCase updateUseCase;
    late MockDeleteCategoryUseCase deleteUseCase;

    setUp(() {
      createUseCase = MockCreateCategoryUseCase();
      updateUseCase = MockUpdateCategoryUseCase();
      deleteUseCase = MockDeleteCategoryUseCase();
    });

    CategoryFormBloc buildBloc() => CategoryFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );

    blocTest<CategoryFormBloc, CategoryFormState>(
      'emite [Submitting, Success] al crear exitosamente',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildCat());
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitCreateCategoryEvent(
        const CreateCategoryParams(name: 'Audio', slug: 'audio'),
      )),
      expect: () => [
        isA<CategoryFormSubmitting>(),
        isA<CategoryFormSuccess>(),
      ],
    );

    blocTest<CategoryFormBloc, CategoryFormState>(
      'emite [Submitting, Error] cuando crear falla',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenThrow(Exception('Error de red'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitCreateCategoryEvent(
        const CreateCategoryParams(name: 'x', slug: 'x'),
      )),
      expect: () => [
        isA<CategoryFormSubmitting>(),
        isA<CategoryFormError>(),
      ],
    );

    blocTest<CategoryFormBloc, CategoryFormState>(
      'emite [Submitting, Success] al actualizar exitosamente',
      build: () {
        when(() => updateUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildCat());
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitUpdateCategoryEvent(
        id: 'cat-1',
        params: const UpdateCategoryParams(name: 'Actualizado'),
      )),
      expect: () => [
        isA<CategoryFormSubmitting>(),
        isA<CategoryFormSuccess>(),
      ],
    );

    blocTest<CategoryFormBloc, CategoryFormState>(
      'emite [Submitting, Deleted] al eliminar exitosamente',
      build: () {
        when(() => deleteUseCase.execute(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteCategoryEvent('cat-1')),
      expect: () => [
        isA<CategoryFormSubmitting>(),
        isA<CategoryFormDeleted>(),
      ],
    );

    blocTest<CategoryFormBloc, CategoryFormState>(
      'emite Error con mensaje adecuado cuando eliminar falla con excepción genérica',
      build: () {
        when(() => deleteUseCase.execute(any()))
            .thenThrow(Exception('Forbidden'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteCategoryEvent('cat-1')),
      expect: () => [
        isA<CategoryFormSubmitting>(),
        isA<CategoryFormError>(),
      ],
    );

    blocTest<CategoryFormBloc, CategoryFormState>(
      'emite [Submitting, Error] cuando actualizar falla',
      build: () {
        when(() => updateUseCase.execute(any(), any()))
            .thenThrow(Exception('Not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitUpdateCategoryEvent(
        id: 'missing',
        params: const UpdateCategoryParams(),
      )),
      expect: () => [
        isA<CategoryFormSubmitting>(),
        isA<CategoryFormError>(),
      ],
    );

    test('estado inicial es CategoryFormInitial', () {
      when(() => createUseCase.execute(any()))
          .thenAnswer((_) async => _buildCat());
      final bloc = buildBloc();
      expect(bloc.state, isA<CategoryFormInitial>());
    });
  });
}
