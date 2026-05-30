import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/iam/tenants/tenants_bloc.dart';
import 'package:mc_admin/features/iam/tenants/tenant_form_bloc.dart';

class MockGetTenantsUseCase extends Mock implements GetTenantsUseCase {}
class MockCreateTenantUseCase extends Mock implements CreateTenantUseCase {}
class MockUpdateTenantUseCase extends Mock implements UpdateTenantUseCase {}
class MockDeleteTenantUseCase extends Mock implements DeleteTenantUseCase {}

Tenant _buildTenant({String id = 'tid-1'}) {
  final now = DateTime(2024, 1, 15);
  return Tenant(
    id: id,
    name: 'Test',
    slug: 'test',
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
    pageSize: 20,
    totalPages: 1,
  );
}

void main() {
  late MockGetTenantsUseCase getTenantsUseCase;

  setUp(() {
    getTenantsUseCase = MockGetTenantsUseCase();
    registerFallbackValue(
      const CreateTenantParams(
        name: 'x', slug: 'x', type: TenantType.business, ownerId: 'o',
      ),
    );
    registerFallbackValue(const UpdateTenantParams());
  });

  group('TenantsBloc', () {
    blocTest<TenantsBloc, TenantsState>(
      'emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => getTenantsUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage());
        return TenantsBloc(getAll: getTenantsUseCase);
      },
      act: (bloc) => bloc.add(LoadTenantsEvent()),
      expect: () => [
        isA<TenantsLoading>(),
        isA<TenantsLoaded>(),
      ],
    );

    blocTest<TenantsBloc, TenantsState>(
      'emite [Loading, Error] cuando el use case falla',
      build: () {
        when(() => getTenantsUseCase.execute(1, 20))
            .thenThrow(Exception('Network error'));
        return TenantsBloc(getAll: getTenantsUseCase);
      },
      act: (bloc) => bloc.add(LoadTenantsEvent()),
      expect: () => [
        isA<TenantsLoading>(),
        isA<TenantsError>(),
      ],
    );

    blocTest<TenantsBloc, TenantsState>(
      'TenantsLoaded contiene los tenants correctos',
      build: () {
        when(() => getTenantsUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(3));
        return TenantsBloc(getAll: getTenantsUseCase);
      },
      act: (bloc) => bloc.add(LoadTenantsEvent()),
      expect: () => [
        isA<TenantsLoading>(),
        isA<TenantsLoaded>().having((s) => s.tenants.length, 'tenants count', 3),
      ],
    );

    blocTest<TenantsBloc, TenantsState>(
      'pasa filtros al use case',
      build: () {
        when(() => getTenantsUseCase.execute(
              1,
              20,
              status: TenantStatus.active,
              type: TenantType.business,
            )).thenAnswer((_) async => _buildPage());
        return TenantsBloc(getAll: getTenantsUseCase);
      },
      act: (bloc) => bloc.add(LoadTenantsEvent(
        status: TenantStatus.active,
        type: TenantType.business,
      )),
      verify: (_) {
        verify(() => getTenantsUseCase.execute(
              1,
              20,
              status: TenantStatus.active,
              type: TenantType.business,
            )).called(1);
      },
    );

    blocTest<TenantsBloc, TenantsState>(
      'ChangeTenantsPageEvent carga la pagina correcta',
      build: () {
        when(() => getTenantsUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildPage());
        return TenantsBloc(getAll: getTenantsUseCase);
      },
      act: (bloc) async {
        bloc.add(LoadTenantsEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ChangeTenantsPageEvent(2));
      },
      skip: 2,
      expect: () => [
        isA<TenantsLoading>(),
        isA<TenantsLoaded>(),
      ],
    );

    test('TenantsLoaded.totalPages calcula correctamente', () {
      final state = TenantsLoaded(
        tenants: const [],
        currentPage: 1,
        pageSize: 10,
        totalItems: 25,
      );
      expect(state.totalPages, 3);
    });
  });

  group('TenantFormBloc', () {
    late MockCreateTenantUseCase createUseCase;
    late MockUpdateTenantUseCase updateUseCase;
    late MockDeleteTenantUseCase deleteUseCase;

    setUp(() {
      createUseCase = MockCreateTenantUseCase();
      updateUseCase = MockUpdateTenantUseCase();
      deleteUseCase = MockDeleteTenantUseCase();
    });

    blocTest<TenantFormBloc, TenantFormState>(
      'emite [Submitting, Success] al crear exitosamente',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildTenant());
        return TenantFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitCreateTenantEvent(
        const CreateTenantParams(
          name: 'Test',
          slug: 'test',
          type: TenantType.business,
          ownerId: 'owner-1',
        ),
      )),
      expect: () => [
        isA<TenantFormSubmitting>(),
        isA<TenantFormSuccess>(),
      ],
    );

    blocTest<TenantFormBloc, TenantFormState>(
      'emite [Submitting, Error] cuando crear falla',
      build: () {
        when(() => createUseCase.execute(any())).thenThrow(Exception('Error'));
        return TenantFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitCreateTenantEvent(
        const CreateTenantParams(
          name: 'Test',
          slug: 'test',
          type: TenantType.business,
          ownerId: 'owner-1',
        ),
      )),
      expect: () => [
        isA<TenantFormSubmitting>(),
        isA<TenantFormError>(),
      ],
    );

    blocTest<TenantFormBloc, TenantFormState>(
      'emite [Submitting, Success] al actualizar exitosamente',
      build: () {
        when(() => updateUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildTenant());
        return TenantFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitUpdateTenantEvent(
        id: 'tid-1',
        params: const UpdateTenantParams(name: 'Updated'),
      )),
      expect: () => [
        isA<TenantFormSubmitting>(),
        isA<TenantFormSuccess>(),
      ],
    );

    blocTest<TenantFormBloc, TenantFormState>(
      'emite [Submitting, Deleted] al eliminar exitosamente',
      build: () {
        when(() => deleteUseCase.execute(any())).thenAnswer((_) async {});
        return TenantFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(DeleteTenantFormEvent('tid-1')),
      expect: () => [
        isA<TenantFormSubmitting>(),
        isA<TenantFormDeleted>(),
      ],
    );

    blocTest<TenantFormBloc, TenantFormState>(
      'emite [Submitting, Error] cuando eliminar falla',
      build: () {
        when(() => deleteUseCase.execute(any())).thenThrow(Exception('Forbidden'));
        return TenantFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(DeleteTenantFormEvent('tid-1')),
      expect: () => [
        isA<TenantFormSubmitting>(),
        isA<TenantFormError>(),
      ],
    );
  });
}
