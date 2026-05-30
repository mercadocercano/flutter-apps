import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/iam/plans/plans_bloc.dart';
import 'package:mc_admin/features/iam/plans/plan_form_bloc.dart';

class MockGetPlansUseCase extends Mock implements GetPlansUseCase {}
class MockCreatePlanUseCase extends Mock implements CreatePlanUseCase {}
class MockUpdatePlanUseCase extends Mock implements UpdatePlanUseCase {}
class MockDeletePlanUseCase extends Mock implements DeletePlanUseCase {}

Plan _buildPlan({String id = 'plan-1'}) {
  final now = DateTime(2024, 1, 15);
  return Plan(
    id: id,
    name: 'Professional',
    type: PlanType.professional,
    price: 9999.0,
    currency: 'ARS',
    features: const ['feature_a'],
    limits: const {'max_products': 500},
    status: PlanStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

PaginatedResult<Plan> _buildPage([int count = 2]) {
  return PaginatedResult<Plan>(
    items: List.generate(count, (i) => _buildPlan(id: 'plan-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

void main() {
  late MockGetPlansUseCase getPlansUseCase;

  setUp(() {
    getPlansUseCase = MockGetPlansUseCase();
    registerFallbackValue(
      const UpsertPlanParams(
        name: 'x',
        type: PlanType.free,
        price: 0,
        currency: 'ARS',
        features: [],
        limits: {},
        status: PlanStatus.active,
      ),
    );
  });

  group('PlansBloc', () {
    blocTest<PlansBloc, PlansState>(
      'emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => getPlansUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage());
        return PlansBloc(getAll: getPlansUseCase);
      },
      act: (bloc) => bloc.add(LoadPlansEvent()),
      expect: () => [
        isA<PlansLoading>(),
        isA<PlansLoaded>(),
      ],
    );

    blocTest<PlansBloc, PlansState>(
      'emite [Loading, Error] cuando falla',
      build: () {
        when(() => getPlansUseCase.execute(1, 20))
            .thenThrow(Exception('Error'));
        return PlansBloc(getAll: getPlansUseCase);
      },
      act: (bloc) => bloc.add(LoadPlansEvent()),
      expect: () => [
        isA<PlansLoading>(),
        isA<PlansError>(),
      ],
    );

    blocTest<PlansBloc, PlansState>(
      'PlansLoaded contiene planes correctos',
      build: () {
        when(() => getPlansUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(3));
        return PlansBloc(getAll: getPlansUseCase);
      },
      act: (bloc) => bloc.add(LoadPlansEvent()),
      expect: () => [
        isA<PlansLoading>(),
        isA<PlansLoaded>().having((s) => s.plans.length, 'plans count', 3),
      ],
    );

    test('PlansLoaded.totalPages calcula correctamente', () {
      final state = PlansLoaded(
        plans: const [],
        currentPage: 1,
        pageSize: 5,
        totalItems: 12,
      );
      expect(state.totalPages, 3);
    });
  });

  group('PlanFormBloc', () {
    late MockCreatePlanUseCase createUseCase;
    late MockUpdatePlanUseCase updateUseCase;
    late MockDeletePlanUseCase deleteUseCase;

    setUp(() {
      createUseCase = MockCreatePlanUseCase();
      updateUseCase = MockUpdatePlanUseCase();
      deleteUseCase = MockDeletePlanUseCase();
    });

    blocTest<PlanFormBloc, PlanFormState>(
      'emite [Submitting, Success] al crear exitosamente',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildPlan());
        return PlanFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitCreatePlanEvent(
        const UpsertPlanParams(
          name: 'Starter',
          type: PlanType.starter,
          price: 2999.0,
          currency: 'ARS',
          features: ['f1'],
          limits: {},
          status: PlanStatus.active,
        ),
      )),
      expect: () => [
        isA<PlanFormSubmitting>(),
        isA<PlanFormSuccess>(),
      ],
    );

    blocTest<PlanFormBloc, PlanFormState>(
      'emite [Submitting, Error] cuando crear falla',
      build: () {
        when(() => createUseCase.execute(any())).thenThrow(Exception('Error'));
        return PlanFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitCreatePlanEvent(
        const UpsertPlanParams(
          name: 'x',
          type: PlanType.free,
          price: 0,
          currency: 'ARS',
          features: [],
          limits: {},
          status: PlanStatus.active,
        ),
      )),
      expect: () => [
        isA<PlanFormSubmitting>(),
        isA<PlanFormError>(),
      ],
    );

    blocTest<PlanFormBloc, PlanFormState>(
      'emite [Submitting, Success] al actualizar',
      build: () {
        when(() => updateUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildPlan());
        return PlanFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(SubmitUpdatePlanEvent(
        id: 'plan-1',
        params: const UpsertPlanParams(
          name: 'Pro V2',
          type: PlanType.professional,
          price: 12999.0,
          currency: 'ARS',
          features: ['f1'],
          limits: {},
          status: PlanStatus.active,
        ),
      )),
      expect: () => [
        isA<PlanFormSubmitting>(),
        isA<PlanFormSuccess>(),
      ],
    );

    blocTest<PlanFormBloc, PlanFormState>(
      'emite [Submitting, Deleted] al eliminar',
      build: () {
        when(() => deleteUseCase.execute(any())).thenAnswer((_) async {});
        return PlanFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );
      },
      act: (bloc) => bloc.add(DeletePlanFormEvent('plan-1')),
      expect: () => [
        isA<PlanFormSubmitting>(),
        isA<PlanFormDeleted>(),
      ],
    );
  });
}
