import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2024, 1, 15, 10, 0);

  Plan buildPlan({
    String id = 'plan-1',
    String name = 'Professional',
    PlanType type = PlanType.professional,
    PlanStatus status = PlanStatus.active,
    double price = 9999.0,
    String currency = 'ARS',
    List<String> features = const ['feature_a', 'feature_b'],
    Map<String, dynamic> limits = const {'max_products': 500},
  }) {
    return Plan(
      id: id,
      name: name,
      type: type,
      status: status,
      price: price,
      currency: currency,
      features: features,
      limits: limits,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('Plan entity', () {
    test('construye correctamente', () {
      final p = buildPlan();
      expect(p.id, 'plan-1');
      expect(p.name, 'Professional');
      expect(p.type, PlanType.professional);
      expect(p.status, PlanStatus.active);
      expect(p.price, 9999.0);
      expect(p.currency, 'ARS');
      expect(p.features, ['feature_a', 'feature_b']);
      expect(p.limits['max_products'], 500);
      expect(p.description, isNull);
    });

    test('igualdad por valor', () {
      final p1 = buildPlan();
      final p2 = buildPlan();
      expect(p1, equals(p2));
    });

    test('distintos ids son distintos', () {
      final p1 = buildPlan(id: 'plan-1');
      final p2 = buildPlan(id: 'plan-2');
      expect(p1, isNot(equals(p2)));
    });

    test('todos los PlanType existen', () {
      expect(PlanType.values.length, 4);
      expect(PlanType.values, containsAll([
        PlanType.free,
        PlanType.starter,
        PlanType.professional,
        PlanType.enterprise,
      ]));
    });

    test('todos los PlanStatus existen', () {
      expect(PlanStatus.values.length, 2);
      expect(PlanStatus.values, containsAll([PlanStatus.active, PlanStatus.inactive]));
    });

    test('plan free con precio 0', () {
      final p = buildPlan(type: PlanType.free, price: 0.0);
      expect(p.price, 0.0);
      expect(p.type, PlanType.free);
    });

    test('features vacia es valido', () {
      final p = buildPlan(features: const []);
      expect(p.features, isEmpty);
    });

    test('limits vacio es valido', () {
      final p = buildPlan(limits: const {});
      expect(p.limits, isEmpty);
    });

    test('plan con descripcion', () {
      final p = Plan(
        id: 'plan-full',
        name: 'Enterprise',
        description: 'Plan para grandes empresas',
        type: PlanType.enterprise,
        price: 49999.0,
        currency: 'ARS',
        features: const ['all'],
        limits: const {'unlimited': true},
        status: PlanStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      expect(p.description, 'Plan para grandes empresas');
    });
  });

  group('PaginatedResult', () {
    test('construye correctamente', () {
      final result = PaginatedResult<Plan>(
        items: [buildPlan()],
        totalCount: 10,
        page: 1,
        pageSize: 5,
        totalPages: 2,
      );
      expect(result.items.length, 1);
      expect(result.totalCount, 10);
      expect(result.page, 1);
      expect(result.pageSize, 5);
      expect(result.totalPages, 2);
    });

    test('hasNextPage es true cuando hay mas paginas', () {
      final result = PaginatedResult<Plan>(
        items: const [],
        totalCount: 10,
        page: 1,
        pageSize: 5,
        totalPages: 2,
      );
      expect(result.hasNextPage, isTrue);
    });

    test('hasNextPage es false en la ultima pagina', () {
      final result = PaginatedResult<Plan>(
        items: const [],
        totalCount: 10,
        page: 2,
        pageSize: 5,
        totalPages: 2,
      );
      expect(result.hasNextPage, isFalse);
    });

    test('hasPreviousPage es false en la primera pagina', () {
      final result = PaginatedResult<Plan>(
        items: const [],
        totalCount: 10,
        page: 1,
        pageSize: 5,
        totalPages: 2,
      );
      expect(result.hasPreviousPage, isFalse);
    });

    test('hasPreviousPage es true despues de la primera pagina', () {
      final result = PaginatedResult<Plan>(
        items: const [],
        totalCount: 10,
        page: 2,
        pageSize: 5,
        totalPages: 2,
      );
      expect(result.hasPreviousPage, isTrue);
    });

    test('isEmpty cuando no hay items', () {
      final result = PaginatedResult<Plan>(
        items: const [],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
      expect(result.isEmpty, isTrue);
    });

    test('igualdad por valor', () {
      final r1 = PaginatedResult<int>(
        items: const [1, 2],
        totalCount: 2,
        page: 1,
        pageSize: 10,
        totalPages: 1,
      );
      final r2 = PaginatedResult<int>(
        items: const [1, 2],
        totalCount: 2,
        page: 1,
        pageSize: 10,
        totalPages: 1,
      );
      expect(r1, equals(r2));
    });
  });

  group('UpsertPlanParams', () {
    test('construye correctamente', () {
      const params = UpsertPlanParams(
        name: 'Starter',
        type: PlanType.starter,
        price: 2999.0,
        currency: 'ARS',
        features: ['feature_1'],
        limits: {'max_users': 5},
        status: PlanStatus.active,
      );
      expect(params.name, 'Starter');
      expect(params.price, 2999.0);
      expect(params.currency, 'ARS');
      expect(params.description, isNull);
    });
  });
}
