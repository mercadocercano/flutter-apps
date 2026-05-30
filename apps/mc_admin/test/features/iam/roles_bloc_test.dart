import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/iam/roles/roles_bloc.dart';
import 'package:mc_admin/features/iam/roles/role_form_bloc.dart';

class MockGetRolesUseCase extends Mock implements GetRolesUseCase {}
class MockCreateRoleUseCase extends Mock implements CreateRoleUseCase {}
class MockUpdateRoleUseCase extends Mock implements UpdateRoleUseCase {}
class MockDeleteRoleUseCase extends Mock implements DeleteRoleUseCase {}

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
    pageSize: 20,
    totalPages: 1,
  );
}

void main() {
  late MockGetRolesUseCase getRolesUseCase;

  setUp(() {
    getRolesUseCase = MockGetRolesUseCase();
    registerFallbackValue(
      const UpsertRoleParams(
        name: 'x',
        type: RoleType.system,
        permissions: [],
        status: RoleStatus.active,
      ),
    );
  });

  group('RolesBloc', () {
    blocTest<RolesBloc, RolesState>(
      'emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => getRolesUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage());
        return RolesBloc(getAll: getRolesUseCase);
      },
      act: (bloc) => bloc.add(LoadRolesEvent()),
      expect: () => [
        isA<RolesLoading>(),
        isA<RolesLoaded>(),
      ],
    );

    blocTest<RolesBloc, RolesState>(
      'emite [Loading, Error] cuando falla',
      build: () {
        when(() => getRolesUseCase.execute(1, 20))
            .thenThrow(Exception('Error'));
        return RolesBloc(getAll: getRolesUseCase);
      },
      act: (bloc) => bloc.add(LoadRolesEvent()),
      expect: () => [
        isA<RolesLoading>(),
        isA<RolesError>(),
      ],
    );

    blocTest<RolesBloc, RolesState>(
      'RolesLoaded contiene roles correctos',
      build: () {
        when(() => getRolesUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(3));
        return RolesBloc(getAll: getRolesUseCase);
      },
      act: (bloc) => bloc.add(LoadRolesEvent()),
      expect: () => [
        isA<RolesLoading>(),
        isA<RolesLoaded>().having((s) => s.roles.length, 'roles count', 3),
      ],
    );

    test('RolesLoaded.totalPages calcula correctamente', () {
      final state = RolesLoaded(
        roles: const [],
        currentPage: 1,
        pageSize: 10,
        totalItems: 25,
      );
      expect(state.totalPages, 3);
    });
  });

  group('RoleFormBloc', () {
    late MockCreateRoleUseCase createUseCase;
    late MockUpdateRoleUseCase updateUseCase;
    late MockDeleteRoleUseCase deleteUseCase;

    setUp(() {
      createUseCase = MockCreateRoleUseCase();
      updateUseCase = MockUpdateRoleUseCase();
      deleteUseCase = MockDeleteRoleUseCase();
    });

    blocTest<RoleFormBloc, RoleFormState>(
      'emite [Submitting, Success] al crear exitosamente',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildRole());
        return RoleFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitCreateRoleEvent(
        const UpsertRoleParams(
          name: 'Vendedor',
          type: RoleType.tenant,
          permissions: ['sales.read'],
          status: RoleStatus.active,
        ),
      )),
      expect: () => [
        isA<RoleFormSubmitting>(),
        isA<RoleFormSuccess>(),
      ],
    );

    blocTest<RoleFormBloc, RoleFormState>(
      'emite [Submitting, Error] cuando crear falla',
      build: () {
        when(() => createUseCase.execute(any())).thenThrow(Exception('Error'));
        return RoleFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitCreateRoleEvent(
        const UpsertRoleParams(
          name: 'x',
          type: RoleType.system,
          permissions: [],
          status: RoleStatus.active,
        ),
      )),
      expect: () => [
        isA<RoleFormSubmitting>(),
        isA<RoleFormError>(),
      ],
    );

    blocTest<RoleFormBloc, RoleFormState>(
      'emite [Submitting, Success] al actualizar',
      build: () {
        when(() => updateUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildRole());
        return RoleFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitUpdateRoleEvent(
        id: 'role-1',
        params: const UpsertRoleParams(
          name: 'Admin V2',
          type: RoleType.system,
          permissions: ['iam.read'],
          status: RoleStatus.active,
        ),
      )),
      expect: () => [
        isA<RoleFormSubmitting>(),
        isA<RoleFormSuccess>(),
      ],
    );

    blocTest<RoleFormBloc, RoleFormState>(
      'emite [Submitting, Deleted] al eliminar',
      build: () {
        when(() => deleteUseCase.execute(any())).thenAnswer((_) async {});
        return RoleFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(DeleteRoleFormEvent('role-1')),
      expect: () => [
        isA<RoleFormSubmitting>(),
        isA<RoleFormDeleted>(),
      ],
    );
  });
}
