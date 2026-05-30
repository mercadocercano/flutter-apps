import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMarketplaceBrandRepository extends Mock
    implements MarketplaceBrandRepository {}

MarketplaceBrand _buildBrand({String id = 'brand-1'}) {
  final now = DateTime(2024, 6, 15);
  return MarketplaceBrand(
    id: id,
    name: 'Nike',
    slug: 'nike',
    createdAt: now,
    updatedAt: now,
  );
}

PaginatedResult<MarketplaceBrand> _buildPage([int count = 2]) {
  return PaginatedResult<MarketplaceBrand>(
    items: List.generate(count, (i) => _buildBrand(id: 'brand-$i')),
    totalCount: count,
    page: 1,
    pageSize: 10,
    totalPages: 1,
  );
}

void main() {
  late MockMarketplaceBrandRepository repository;

  setUp(() {
    repository = MockMarketplaceBrandRepository();
    registerFallbackValue(BrandVerificationStatus.unverified);
    registerFallbackValue(const CreateBrandParams(name: 'x'));
    registerFallbackValue(const UpdateBrandParams());
  });

  group('GetBrandsUseCase', () {
    test('delega a repository.getAll con parámetros correctos', () async {
      when(() => repository.getAll(1, 10))
          .thenAnswer((_) async => _buildPage());
      final useCase = GetBrandsUseCase(repository);

      final result = await useCase.execute(1, 10);

      expect(result.items.length, 2);
      verify(() => repository.getAll(1, 10)).called(1);
    });

    test('pasa filtros opcionales al repositorio', () async {
      when(() => repository.getAll(
            1,
            20,
            name: 'nike',
            verificationStatus: BrandVerificationStatus.verified,
            isActive: true,
          )).thenAnswer((_) async => _buildPage(1));
      final useCase = GetBrandsUseCase(repository);

      await useCase.execute(
        1,
        20,
        name: 'nike',
        verificationStatus: BrandVerificationStatus.verified,
        isActive: true,
      );

      verify(() => repository.getAll(
            1,
            20,
            name: 'nike',
            verificationStatus: BrandVerificationStatus.verified,
            isActive: true,
          )).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.getAll(any(), any()))
          .thenThrow(Exception('Network error'));
      final useCase = GetBrandsUseCase(repository);

      expect(() => useCase.execute(1, 10), throwsException);
    });
  });

  group('GetBrandUseCase', () {
    test('retorna la marca correcta', () async {
      final brand = _buildBrand(id: 'specific-id');
      when(() => repository.getById('specific-id'))
          .thenAnswer((_) async => brand);
      final useCase = GetBrandUseCase(repository);

      final result = await useCase.execute('specific-id');

      expect(result.id, 'specific-id');
      verify(() => repository.getById('specific-id')).called(1);
    });

    test('propaga not found', () async {
      when(() => repository.getById('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetBrandUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  group('CreateBrandUseCase', () {
    test('crea marca y retorna entidad', () async {
      const params = CreateBrandParams(name: 'Nueva Marca');
      final created = _buildBrand(id: 'new-id');
      when(() => repository.create(params)).thenAnswer((_) async => created);
      final useCase = CreateBrandUseCase(repository);

      final result = await useCase.execute(params);

      expect(result.id, 'new-id');
      verify(() => repository.create(params)).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.create(any()))
          .thenThrow(Exception('Conflict'));
      final useCase = CreateBrandUseCase(repository);

      expect(
        () => useCase.execute(const CreateBrandParams(name: 'x')),
        throwsException,
      );
    });
  });

  group('UpdateBrandUseCase', () {
    test('actualiza marca y retorna entidad actualizada', () async {
      const params = UpdateBrandParams(name: 'Actualizado');
      final updated = _buildBrand(id: 'brand-1');
      when(() => repository.update('brand-1', params))
          .thenAnswer((_) async => updated);
      final useCase = UpdateBrandUseCase(repository);

      final result = await useCase.execute('brand-1', params);

      expect(result.id, 'brand-1');
      verify(() => repository.update('brand-1', params)).called(1);
    });
  });

  group('DeleteBrandUseCase', () {
    test('elimina marca correctamente', () async {
      when(() => repository.delete('brand-1')).thenAnswer((_) async {});
      final useCase = DeleteBrandUseCase(repository);

      await useCase.execute('brand-1');

      verify(() => repository.delete('brand-1')).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.delete(any()))
          .thenThrow(Exception('Forbidden'));
      final useCase = DeleteBrandUseCase(repository);

      expect(() => useCase.execute('brand-x'), throwsException);
    });
  });

  group('VerifyBrandUseCase', () {
    test('llama verify con el id correcto', () async {
      final verified = _buildBrand(id: 'brand-1');
      when(() => repository.verify('brand-1'))
          .thenAnswer((_) async => verified);
      final useCase = VerifyBrandUseCase(repository);

      final result = await useCase.execute('brand-1');

      expect(result.id, 'brand-1');
      verify(() => repository.verify('brand-1')).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.verify(any()))
          .thenThrow(Exception('Not found'));
      final useCase = VerifyBrandUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  group('UnverifyBrandUseCase', () {
    test('llama unverify con el id correcto', () async {
      final unverified = _buildBrand(id: 'brand-1');
      when(() => repository.unverify('brand-1'))
          .thenAnswer((_) async => unverified);
      final useCase = UnverifyBrandUseCase(repository);

      final result = await useCase.execute('brand-1');

      expect(result.id, 'brand-1');
      verify(() => repository.unverify('brand-1')).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.unverify(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UnverifyBrandUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });
}
