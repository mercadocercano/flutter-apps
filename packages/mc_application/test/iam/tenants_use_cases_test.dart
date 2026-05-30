import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockTenantRepository extends Mock implements TenantRepository {}

Tenant _buildTenant({String id = 'tid-1'}) {
  final now = DateTime(2024, 1, 15);
  return Tenant(
    id: id,
    name: 'Test Tenant',
    slug: 'test-tenant',
    type: TenantType.business,
    status: TenantStatus.active,
    ownerId: 'owner-1',
    settings: const {},
    createdAt: now,
    updatedAt: now,
    isActive: true,
  );
}

PaginatedResult<Tenant> _buildPage([int count = 2]) {
  return PaginatedResult<Tenant>(
    items: List.generate(count, (i) => _buildTenant(id: 'tid-$i')),
    totalCount: count,
    page: 1,
    pageSize: 10,
    totalPages: 1,
  );
}

void main() {
  late MockTenantRepository repository;

  setUp(() {
    repository = MockTenantRepository();
    registerFallbackValue(TenantStatus.active);
    registerFallbackValue(TenantType.personal);
    registerFallbackValue(
      const CreateTenantParams(
        name: 'x',
        slug: 'x',
        type: TenantType.business,
        ownerId: 'o',
      ),
    );
    registerFallbackValue(const UpdateTenantParams());
  });

  group('GetTenantsUseCase', () {
    test('delega a repository.getAll con parametros correctos', () async {
      when(() => repository.getAll(1, 10)).thenAnswer((_) async => _buildPage());
      final useCase = GetTenantsUseCase(repository);

      final result = await useCase.execute(1, 10);

      expect(result.items.length, 2);
      verify(() => repository.getAll(1, 10)).called(1);
    });

    test('pasa filtros opcionales al repositorio', () async {
      when(() => repository.getAll(
            1,
            10,
            status: TenantStatus.active,
            type: TenantType.business,
          )).thenAnswer((_) async => _buildPage());
      final useCase = GetTenantsUseCase(repository);

      await useCase.execute(1, 10, status: TenantStatus.active, type: TenantType.business);

      verify(() => repository.getAll(
            1,
            10,
            status: TenantStatus.active,
            type: TenantType.business,
          )).called(1);
    });

    test('propaga excepcion del repositorio', () async {
      when(() => repository.getAll(any(), any()))
          .thenThrow(Exception('Network error'));
      final useCase = GetTenantsUseCase(repository);

      expect(() => useCase.execute(1, 10), throwsException);
    });
  });

  group('GetTenantUseCase', () {
    test('retorna el tenant correcto', () async {
      final tenant = _buildTenant(id: 'specific-id');
      when(() => repository.getById('specific-id'))
          .thenAnswer((_) async => tenant);
      final useCase = GetTenantUseCase(repository);

      final result = await useCase.execute('specific-id');

      expect(result.id, 'specific-id');
      verify(() => repository.getById('specific-id')).called(1);
    });

    test('propaga not found', () async {
      when(() => repository.getById('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetTenantUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  group('CreateTenantUseCase', () {
    test('crea tenant y retorna entidad', () async {
      const params = CreateTenantParams(
        name: 'Nuevo',
        slug: 'nuevo',
        type: TenantType.startup,
        ownerId: 'owner-1',
      );
      final created = _buildTenant(id: 'new-id');
      when(() => repository.create(params)).thenAnswer((_) async => created);
      final useCase = CreateTenantUseCase(repository);

      final result = await useCase.execute(params);

      expect(result.id, 'new-id');
      verify(() => repository.create(params)).called(1);
    });
  });

  group('UpdateTenantUseCase', () {
    test('actualiza tenant y retorna entidad actualizada', () async {
      const params = UpdateTenantParams(name: 'Actualizado');
      final updated = _buildTenant(id: 'tid-1');
      when(() => repository.update('tid-1', params))
          .thenAnswer((_) async => updated);
      final useCase = UpdateTenantUseCase(repository);

      final result = await useCase.execute('tid-1', params);

      expect(result.id, 'tid-1');
      verify(() => repository.update('tid-1', params)).called(1);
    });
  });

  group('DeleteTenantUseCase', () {
    test('elimina tenant correctamente', () async {
      when(() => repository.delete('tid-1')).thenAnswer((_) async {});
      final useCase = DeleteTenantUseCase(repository);

      await useCase.execute('tid-1');

      verify(() => repository.delete('tid-1')).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.delete(any()))
          .thenThrow(Exception('Forbidden'));
      final useCase = DeleteTenantUseCase(repository);

      expect(() => useCase.execute('tid-x'), throwsException);
    });
  });

  group('ToggleTenantStatusUseCase', () {
    test('llama toggleStatus con id y newStatus', () async {
      final updated = _buildTenant(id: 'tid-1');
      when(() => repository.toggleStatus('tid-1', TenantStatus.inactive))
          .thenAnswer((_) async => updated);
      final useCase = ToggleTenantStatusUseCase(repository);

      final result = await useCase.execute('tid-1', TenantStatus.inactive);

      expect(result.id, 'tid-1');
      verify(() => repository.toggleStatus('tid-1', TenantStatus.inactive)).called(1);
    });

    test('propaga excepcion del repositorio', () async {
      when(() => repository.toggleStatus(any(), any(that: isA<TenantStatus>())))
          .thenThrow(Exception('Not found'));
      final useCase = ToggleTenantStatusUseCase(repository);

      expect(
        () => useCase.execute('missing', TenantStatus.active),
        throwsException,
      );
    });
  });

  group('GetTenantsUseCase — búsqueda por name', () {
    test('pasa name al repositorio', () async {
      when(() => repository.getAll(
            1,
            20,
            name: any(named: 'name'),
          )).thenAnswer((_) async => _buildPage());
      final useCase = GetTenantsUseCase(repository);

      await useCase.execute(1, 20, name: 'ferret');

      verify(() => repository.getAll(
            1,
            20,
            name: any(named: 'name'),
          )).called(1);
    });
  });
}
