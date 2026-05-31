import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMarketplaceCategoryRepository extends Mock
    implements MarketplaceCategoryRepository {}

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

PaginatedResult<MarketplaceCategory> _buildPage([int count = 2]) {
  return PaginatedResult<MarketplaceCategory>(
    items: List.generate(count, (i) => _buildCat(id: 'cat-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

CategoryTree _buildTree() {
  return CategoryTree.fromFlat([
    _buildCat(id: 'r1'),
    _buildCat(id: 'c1', parentId: 'r1'),
  ]);
}

void main() {
  late MockMarketplaceCategoryRepository repository;

  setUp(() {
    repository = MockMarketplaceCategoryRepository();
    registerFallbackValue(
      const CreateCategoryParams(name: 'x', slug: 'x'),
    );
    registerFallbackValue(const UpdateCategoryParams());
  });

  group('GetCategoryTreeUseCase', () {
    test('delega a repository.getTree', () async {
      when(() => repository.getTree())
          .thenAnswer((_) async => _buildTree());
      final useCase = GetCategoryTreeUseCase(repository);

      final result = await useCase.execute();

      expect(result.roots.isNotEmpty, isTrue);
      verify(() => repository.getTree()).called(1);
    });

    test('propaga excepción del repositorio', () {
      when(() => repository.getTree())
          .thenThrow(Exception('Network error'));
      final useCase = GetCategoryTreeUseCase(repository);

      expect(() => useCase.execute(), throwsException);
    });
  });

  group('GetCategoriesUseCase', () {
    test('delega a repository.getAll con parámetros correctos', () async {
      when(() => repository.getAll(1, 20))
          .thenAnswer((_) async => _buildPage());
      final useCase = GetCategoriesUseCase(repository);

      final result = await useCase.execute(1, 20);

      expect(result.items.length, 2);
      verify(() => repository.getAll(1, 20)).called(1);
    });

    test('pasa filtros name y parentId al repositorio', () async {
      when(() => repository.getAll(
            1,
            10,
            name: 'audio',
            parentId: 'cat-1',
          )).thenAnswer((_) async => _buildPage(1));
      final useCase = GetCategoriesUseCase(repository);

      await useCase.execute(1, 10, name: 'audio', parentId: 'cat-1');

      verify(() => repository.getAll(
            1,
            10,
            name: 'audio',
            parentId: 'cat-1',
          )).called(1);
    });

    test('propaga excepción del repositorio', () {
      when(() => repository.getAll(any(), any()))
          .thenThrow(Exception('Error'));
      final useCase = GetCategoriesUseCase(repository);

      expect(() => useCase.execute(1, 20), throwsException);
    });
  });

  group('GetCategoryUseCase', () {
    test('retorna la categoría correcta', () async {
      final cat = _buildCat(id: 'specific-id');
      when(() => repository.getById('specific-id'))
          .thenAnswer((_) async => cat);
      final useCase = GetCategoryUseCase(repository);

      final result = await useCase.execute('specific-id');

      expect(result.id, 'specific-id');
      verify(() => repository.getById('specific-id')).called(1);
    });

    test('propaga not found', () {
      when(() => repository.getById('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetCategoryUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  group('CreateCategoryUseCase', () {
    test('crea categoría y retorna entidad', () async {
      const params = CreateCategoryParams(name: 'Audio', slug: 'audio');
      final created = _buildCat(id: 'new-id');
      when(() => repository.create(params)).thenAnswer((_) async => created);
      final useCase = CreateCategoryUseCase(repository);

      final result = await useCase.execute(params);

      expect(result.id, 'new-id');
      verify(() => repository.create(params)).called(1);
    });

    test('crea categoría con parentId', () async {
      const params = CreateCategoryParams(
        name: 'Audio',
        slug: 'audio',
        parentId: 'r1',
      );
      final created = _buildCat(id: 'c1', parentId: 'r1');
      when(() => repository.create(params)).thenAnswer((_) async => created);
      final useCase = CreateCategoryUseCase(repository);

      final result = await useCase.execute(params);

      expect(result.parentId, 'r1');
    });

    test('propaga error del repositorio', () {
      when(() => repository.create(any()))
          .thenThrow(Exception('Conflict'));
      final useCase = CreateCategoryUseCase(repository);

      expect(
        () => useCase.execute(
          const CreateCategoryParams(name: 'x', slug: 'x'),
        ),
        throwsException,
      );
    });
  });

  group('UpdateCategoryUseCase', () {
    test('actualiza categoría y retorna entidad actualizada', () async {
      const params = UpdateCategoryParams(name: 'Audio Actualizado');
      final updated = _buildCat(id: 'cat-1');
      when(() => repository.update('cat-1', params))
          .thenAnswer((_) async => updated);
      final useCase = UpdateCategoryUseCase(repository);

      final result = await useCase.execute('cat-1', params);

      expect(result.id, 'cat-1');
      verify(() => repository.update('cat-1', params)).called(1);
    });

    test('propaga error del repositorio', () {
      when(() => repository.update(any(), any()))
          .thenThrow(Exception('Not found'));
      final useCase = UpdateCategoryUseCase(repository);

      expect(
        () => useCase.execute('missing', const UpdateCategoryParams()),
        throwsException,
      );
    });
  });

  group('DeleteCategoryUseCase', () {
    test('elimina categoría correctamente', () async {
      when(() => repository.delete('cat-1')).thenAnswer((_) async {});
      final useCase = DeleteCategoryUseCase(repository);

      await useCase.execute('cat-1');

      verify(() => repository.delete('cat-1')).called(1);
    });

    test('propaga 409 cuando categoría tiene subcategorías', () {
      when(() => repository.delete('cat-with-kids'))
          .thenThrow(Exception('409 Conflict: has children'));
      final useCase = DeleteCategoryUseCase(repository);

      expect(() => useCase.execute('cat-with-kids'), throwsException);
    });

    test('propaga error genérico del repositorio', () {
      when(() => repository.delete(any()))
          .thenThrow(Exception('Forbidden'));
      final useCase = DeleteCategoryUseCase(repository);

      expect(() => useCase.execute('cat-x'), throwsException);
    });
  });
}
