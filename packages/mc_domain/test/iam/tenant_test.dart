import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2024, 1, 15, 10, 0);

  Tenant buildTenant({
    String id = 'tid-1',
    String name = 'Comercio Test',
    String slug = 'comercio-test',
    TenantType type = TenantType.business,
    TenantStatus status = TenantStatus.active,
    String ownerId = 'owner-uuid',
    bool isActive = true,
  }) {
    return Tenant(
      id: id,
      name: name,
      slug: slug,
      type: type,
      status: status,
      ownerId: ownerId,
      settings: const {},
      createdAt: now,
      updatedAt: now,
      isActive: isActive,
    );
  }

  group('Tenant entity', () {
    test('construye correctamente con campos obligatorios', () {
      final t = buildTenant();
      expect(t.id, 'tid-1');
      expect(t.name, 'Comercio Test');
      expect(t.slug, 'comercio-test');
      expect(t.type, TenantType.business);
      expect(t.status, TenantStatus.active);
      expect(t.ownerId, 'owner-uuid');
      expect(t.isActive, isTrue);
      expect(t.userCount, 0);
      expect(t.maxUsers, 0);
      expect(t.settings, isEmpty);
    });

    test('campos opcionales son null por defecto', () {
      final t = buildTenant();
      expect(t.description, isNull);
      expect(t.domain, isNull);
      expect(t.planId, isNull);
      expect(t.expiresAt, isNull);
    });

    test('igualdad por valor (Equatable)', () {
      final t1 = buildTenant();
      final t2 = buildTenant();
      expect(t1, equals(t2));
    });

    test('distintos ids son distintos', () {
      final t1 = buildTenant(id: 'tid-1');
      final t2 = buildTenant(id: 'tid-2');
      expect(t1, isNot(equals(t2)));
    });

    test('distinto nombre genera distintos objetos', () {
      final t1 = buildTenant(name: 'A');
      final t2 = buildTenant(name: 'B');
      expect(t1, isNot(equals(t2)));
    });

    test('todos los TenantType existen', () {
      expect(TenantType.values.length, 4);
      expect(TenantType.values, containsAll([
        TenantType.personal,
        TenantType.startup,
        TenantType.business,
        TenantType.enterprise,
      ]));
    });

    test('todos los TenantStatus existen', () {
      expect(TenantStatus.values.length, 4);
      expect(TenantStatus.values, containsAll([
        TenantStatus.active,
        TenantStatus.inactive,
        TenantStatus.suspended,
        TenantStatus.deleted,
      ]));
    });

    test('isActive false cuando status es inactive', () {
      final t = buildTenant(status: TenantStatus.inactive, isActive: false);
      expect(t.isActive, isFalse);
    });

    test('tenant con todos los campos opcionales', () {
      final t = Tenant(
        id: 'full-id',
        name: 'Full Tenant',
        slug: 'full-tenant',
        description: 'Descripcion completa',
        type: TenantType.enterprise,
        status: TenantStatus.active,
        ownerId: 'owner-1',
        domain: 'full.example.com',
        planId: 'plan-pro',
        userCount: 50,
        maxUsers: 100,
        settings: {'feature_x': true},
        expiresAt: DateTime(2025, 12, 31),
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );
      expect(t.description, 'Descripcion completa');
      expect(t.domain, 'full.example.com');
      expect(t.planId, 'plan-pro');
      expect(t.userCount, 50);
      expect(t.maxUsers, 100);
      expect(t.settings['feature_x'], isTrue);
      expect(t.expiresAt, isNotNull);
    });
  });

  group('CreateTenantParams', () {
    test('construye con campos obligatorios', () {
      const params = CreateTenantParams(
        name: 'Nuevo Comercio',
        slug: 'nuevo-comercio',
        type: TenantType.startup,
        ownerId: 'owner-123',
      );
      expect(params.name, 'Nuevo Comercio');
      expect(params.slug, 'nuevo-comercio');
      expect(params.type, TenantType.startup);
      expect(params.ownerId, 'owner-123');
      expect(params.description, isNull);
      expect(params.domain, isNull);
    });

    test('construye con campos opcionales', () {
      const params = CreateTenantParams(
        name: 'Comercio',
        slug: 'comercio',
        type: TenantType.business,
        ownerId: 'owner-456',
        description: 'Mi comercio',
        domain: 'comercio.com',
      );
      expect(params.description, 'Mi comercio');
      expect(params.domain, 'comercio.com');
    });
  });

  group('UpdateTenantParams', () {
    test('construye con todos los campos nulos por defecto', () {
      const params = UpdateTenantParams();
      expect(params.name, isNull);
      expect(params.description, isNull);
      expect(params.domain, isNull);
      expect(params.status, isNull);
      expect(params.type, isNull);
      expect(params.settings, isNull);
    });

    test('construye con cambio de status', () {
      const params = UpdateTenantParams(status: TenantStatus.suspended);
      expect(params.status, TenantStatus.suspended);
    });
  });
}
