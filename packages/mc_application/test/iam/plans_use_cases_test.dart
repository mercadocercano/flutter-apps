import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

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
    pageSize: 10,
    totalPages: 1,
  );
}

void main() {
  late MockPlanRepository repository;

  setUp(() {
    repository = MockPlanRepository();
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

  group('GetPlansUseCase', () {
    test('delega a repository.getAll', () async {
      when(() => repository.getAll(1, 10)).thenAnswer((_) async => _buildPage());
      final useCase = GetPlansUseCase(repository);

      final result = await useCase.execute(1, 10);

      expect(result.items.length, 2);
      verify(() => repository.getAll(1, 10)).called(1);
    });

    test('pasa filtros opcionales', () async {
      when(() => repository.getAll(
            1,
            10,
            type: PlanType.professional,
            name: 'pro',
            status: PlanStatus.active,
          )).thenAnswer((_) async => _buildPage());
      final useCase = GetPlansUseCase(repository);

      await useCase.execute(1, 10,
          type: PlanType.professional, name: 'pro', status: PlanStatus.active);

      verify(() => repository.getAll(
            1,
            10,
            type: PlanType.professional,
            name: 'pro',
            status: PlanStatus.active,
          )).called(1);
    });

    test('propaga excepcion', () async {
      when(() => repository.getAll(any(), any())).thenThrow(Exception('Error'));
      final useCase = GetPlansUseCase(repository);

      expect(() => useCase.execute(1, 10), throwsException);
    });
  });

  group('GetPlanUseCase', () {
    test('retorna el plan correcto', () async {
      final plan = _buildPlan(id: 'plan-abc');
      when(() => repository.getById('plan-abc'))
          .thenAnswer((_) async => plan);
      final useCase = GetPlanUseCase(repository);

      final result = await useCase.execute('plan-abc');

      expect(result.id, 'plan-abc');
    });
  });

  group('CreatePlanUseCase', () {
    test('crea plan y retorna entidad', () async {
      const params = UpsertPlanParams(
        name: 'Starter',
        type: PlanType.starter,
        price: 2999.0,
        currency: 'ARS',
        features: ['feature_1'],
        limits: {'max_users': 5},
        status: PlanStatus.active,
      );
      final created = _buildPlan(id: 'new-plan');
      when(() => repository.create(params)).thenAnswer((_) async => created);
      final useCase = CreatePlanUseCase(repository);

      final result = await useCase.execute(params);

      expect(result.id, 'new-plan');
      verify(() => repository.create(params)).called(1);
    });
  });

  group('UpdatePlanUseCase', () {
    test('actualiza plan correctamente', () async {
      const params = UpsertPlanParams(
        name: 'Pro V2',
        type: PlanType.professional,
        price: 12999.0,
        currency: 'ARS',
        features: ['feature_a', 'feature_b'],
        limits: {'max_products': 1000},
        status: PlanStatus.active,
      );
      final updated = _buildPlan(id: 'plan-1');
      when(() => repository.update('plan-1', params))
          .thenAnswer((_) async => updated);
      final useCase = UpdatePlanUseCase(repository);

      final result = await useCase.execute('plan-1', params);

      expect(result.id, 'plan-1');
    });
  });

  group('DeletePlanUseCase', () {
    test('elimina plan correctamente', () async {
      when(() => repository.delete('plan-1')).thenAnswer((_) async {});
      final useCase = DeletePlanUseCase(repository);

      await useCase.execute('plan-1');

      verify(() => repository.delete('plan-1')).called(1);
    });

    test('propaga excepcion', () async {
      when(() => repository.delete(any())).thenThrow(Exception('Not found'));
      final useCase = DeletePlanUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });
}
