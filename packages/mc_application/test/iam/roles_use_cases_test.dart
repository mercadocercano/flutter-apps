import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRoleRepository extends Mock implements RoleRepository {}

Role _buildRole({String id = 'role-1'}) {
  final now = DateTime(2024, 1, 15);
  return Role(
    id: id,
    name: 'Admin',
    type: RoleType.system,
    permissions: const ['iam.read'],
    status: RoleStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

PaginatedResult<Role> _buildPage([int count = 2]) {
  return PaginatedResult<Role>(
    items: List.generate(count, (i) => _buildRole(id: 'role-$i')),
    totalCount: count,
    page: 1,
    pageSize: 10,
    totalPages: 1,
  );
}

void main() {
  late MockRoleRepository repository;

  setUp(() {
    repository = MockRoleRepository();
    registerFallbackValue(
      const UpsertRoleParams(
        name: 'x',
        type: RoleType.system,
        permissions: [],
        status: RoleStatus.active,
      ),
    );
  });

  group('GetRolesUseCase', () {
    test('delega a repository.getAll', () async {
      when(() => repository.getAll(1, 10)).thenAnswer((_) async => _buildPage());
      final useCase = GetRolesUseCase(repository);

      final result = await useCase.execute(1, 10);

      expect(result.items.length, 2);
      verify(() => repository.getAll(1, 10)).called(1);
    });

    test('pasa filtros opcionales', () async {
      when(() => repository.getAll(
            1,
            10,
            type: RoleType.system,
            name: 'admin',
            status: RoleStatus.active,
          )).thenAnswer((_) async => _buildPage());
      final useCase = GetRolesUseCase(repository);

      await useCase.execute(1, 10,
          type: RoleType.system, name: 'admin', status: RoleStatus.active);

      verify(() => repository.getAll(
            1,
            10,
            type: RoleType.system,
            name: 'admin',
            status: RoleStatus.active,
          )).called(1);
    });

    test('propaga excepcion', () async {
      when(() => repository.getAll(any(), any())).thenThrow(Exception('Error'));
      final useCase = GetRolesUseCase(repository);

      expect(() => useCase.execute(1, 10), throwsException);
    });
  });

  group('GetRoleUseCase', () {
    test('retorna el role correcto', () async {
      final role = _buildRole(id: 'role-abc');
      when(() => repository.getById('role-abc')).thenAnswer((_) async => role);
      final useCase = GetRoleUseCase(repository);

      final result = await useCase.execute('role-abc');

      expect(result.id, 'role-abc');
    });
  });

  group('CreateRoleUseCase', () {
    test('crea rol y retorna entidad', () async {
      const params = UpsertRoleParams(
        name: 'Vendedor',
        type: RoleType.tenant,
        permissions: ['sales.read'],
        status: RoleStatus.active,
      );
      final created = _buildRole(id: 'new-role');
      when(() => repository.create(params)).thenAnswer((_) async => created);
      final useCase = CreateRoleUseCase(repository);

      final result = await useCase.execute(params);

      expect(result.id, 'new-role');
      verify(() => repository.create(params)).called(1);
    });
  });

  group('UpdateRoleUseCase', () {
    test('actualiza rol correctamente', () async {
      const params = UpsertRoleParams(
        name: 'Admin V2',
        type: RoleType.system,
        permissions: ['iam.read', 'iam.write'],
        status: RoleStatus.active,
      );
      final updated = _buildRole(id: 'role-1');
      when(() => repository.update('role-1', params))
          .thenAnswer((_) async => updated);
      final useCase = UpdateRoleUseCase(repository);

      final result = await useCase.execute('role-1', params);

      expect(result.id, 'role-1');
    });
  });

  group('DeleteRoleUseCase', () {
    test('elimina rol correctamente', () async {
      when(() => repository.delete('role-1')).thenAnswer((_) async {});
      final useCase = DeleteRoleUseCase(repository);

      await useCase.execute('role-1');

      verify(() => repository.delete('role-1')).called(1);
    });

    test('propaga excepcion', () async {
      when(() => repository.delete(any())).thenThrow(Exception('Not found'));
      final useCase = DeleteRoleUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });
}
