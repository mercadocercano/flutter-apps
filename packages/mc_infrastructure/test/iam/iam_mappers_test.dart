import 'package:mc_domain/mc_domain.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  final baseJson = {
    'id': 'tenant-1',
    'name': 'Comercio Test',
    'slug': 'comercio-test',
    'type': 'BUSINESS',
    'status': 'ACTIVE',
    'owner_id': 'owner-1',
    'settings': <String, dynamic>{},
    'created_at': '2024-01-15T10:00:00Z',
    'updated_at': '2024-01-15T10:00:00Z',
    'is_active': true,
    'user_count': 5,
    'max_users': 50,
  };

  group('tenantStatusFromString', () {
    test('ACTIVE mapea a TenantStatus.active', () {
      expect(tenantStatusFromString('ACTIVE'), TenantStatus.active);
    });
    test('INACTIVE mapea a TenantStatus.inactive', () {
      expect(tenantStatusFromString('INACTIVE'), TenantStatus.inactive);
    });
    test('SUSPENDED mapea a TenantStatus.suspended', () {
      expect(tenantStatusFromString('SUSPENDED'), TenantStatus.suspended);
    });
    test('DELETED mapea a TenantStatus.deleted', () {
      expect(tenantStatusFromString('DELETED'), TenantStatus.deleted);
    });
    test('null mapea a inactive por defecto', () {
      expect(tenantStatusFromString(null), TenantStatus.inactive);
    });
    test('valor desconocido mapea a inactive', () {
      expect(tenantStatusFromString('UNKNOWN'), TenantStatus.inactive);
    });
  });

  group('tenantTypeFromString', () {
    test('PERSONAL → TenantType.personal', () {
      expect(tenantTypeFromString('PERSONAL'), TenantType.personal);
    });
    test('STARTUP → TenantType.startup', () {
      expect(tenantTypeFromString('STARTUP'), TenantType.startup);
    });
    test('BUSINESS → TenantType.business', () {
      expect(tenantTypeFromString('BUSINESS'), TenantType.business);
    });
    test('ENTERPRISE → TenantType.enterprise', () {
      expect(tenantTypeFromString('ENTERPRISE'), TenantType.enterprise);
    });
    test('null → personal por defecto', () {
      expect(tenantTypeFromString(null), TenantType.personal);
    });
  });

  group('tenantFromJson', () {
    test('mapea campos obligatorios correctamente', () {
      final tenant = tenantFromJson(baseJson);
      expect(tenant.id, 'tenant-1');
      expect(tenant.name, 'Comercio Test');
      expect(tenant.slug, 'comercio-test');
      expect(tenant.type, TenantType.business);
      expect(tenant.status, TenantStatus.active);
      expect(tenant.ownerId, 'owner-1');
      expect(tenant.isActive, isTrue);
      expect(tenant.userCount, 5);
      expect(tenant.maxUsers, 50);
    });

    test('campos opcionales null cuando no estan presentes', () {
      final tenant = tenantFromJson(baseJson);
      expect(tenant.description, isNull);
      expect(tenant.domain, isNull);
      expect(tenant.planId, isNull);
      expect(tenant.expiresAt, isNull);
    });

    test('mapea expires_at cuando esta presente', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['expires_at'] = '2025-12-31T00:00:00Z';
      final tenant = tenantFromJson(json);
      expect(tenant.expiresAt, isNotNull);
    });

    test('mapea settings como mapa', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['settings'] = {'feature_x': true};
      final tenant = tenantFromJson(json);
      expect(tenant.settings['feature_x'], isTrue);
    });
  });

  group('roleFromJson', () {
    final roleJson = {
      'id': 'role-1',
      'name': 'Admin',
      'type': 'SYSTEM',
      'status': 'active',
      'permissions': ['iam.read', 'iam.write'],
      'created_at': '2024-01-15T10:00:00Z',
      'updated_at': '2024-01-15T10:00:00Z',
    };

    test('mapea campos correctamente', () {
      final role = roleFromJson(roleJson);
      expect(role.id, 'role-1');
      expect(role.name, 'Admin');
      expect(role.type, RoleType.system);
      expect(role.status, RoleStatus.active);
      expect(role.permissions, ['iam.read', 'iam.write']);
      expect(role.tenantId, isNull);
    });

    test('mapea tenant role con tenant_id', () {
      final json = Map<String, dynamic>.from(roleJson)
        ..['type'] = 'TENANT'
        ..['tenant_id'] = 'tenant-abc';
      final role = roleFromJson(json);
      expect(role.type, RoleType.tenant);
      expect(role.tenantId, 'tenant-abc');
    });

    test('permissions null resulta en lista vacia', () {
      final json = Map<String, dynamic>.from(roleJson)
        ..remove('permissions');
      final role = roleFromJson(json);
      expect(role.permissions, isEmpty);
    });
  });

  group('planFromJson', () {
    final planJson = {
      'id': 'plan-1',
      'name': 'Professional',
      'type': 'PROFESSIONAL',
      'status': 'active',
      'price': 9999.0,
      'currency': 'ARS',
      'features': ['feature_a', 'feature_b'],
      'limits': {'max_products': 500},
      'created_at': '2024-01-15T10:00:00Z',
      'updated_at': '2024-01-15T10:00:00Z',
    };

    test('mapea campos correctamente', () {
      final plan = planFromJson(planJson);
      expect(plan.id, 'plan-1');
      expect(plan.name, 'Professional');
      expect(plan.type, PlanType.professional);
      expect(plan.status, PlanStatus.active);
      expect(plan.price, 9999.0);
      expect(plan.currency, 'ARS');
      expect(plan.features, ['feature_a', 'feature_b']);
      expect(plan.limits['max_products'], 500);
    });

    test('features null resulta en lista vacia', () {
      final json = Map<String, dynamic>.from(planJson)
        ..remove('features');
      final plan = planFromJson(json);
      expect(plan.features, isEmpty);
    });

    test('price como entero se convierte a double', () {
      final json = Map<String, dynamic>.from(planJson)
        ..['price'] = 5000;
      final plan = planFromJson(json);
      expect(plan.price, 5000.0);
    });
  });

  group('paginatedFromJson', () {
    test('mapea campos de paginacion correctamente', () {
      final json = {
        'items': [
          {
            'id': 'plan-1',
            'name': 'Pro',
            'type': 'PROFESSIONAL',
            'status': 'active',
            'price': 999.0,
            'currency': 'ARS',
            'features': <String>[],
            'limits': <String, dynamic>{},
            'created_at': '2024-01-15T10:00:00Z',
            'updated_at': '2024-01-15T10:00:00Z',
          }
        ],
        'total_count': 20,
        'page': 2,
        'page_size': 10,
        'total_pages': 2,
      };

      final result = paginatedFromJson<Plan>(json, planFromJson);
      expect(result.items.length, 1);
      expect(result.totalCount, 20);
      expect(result.page, 2);
      expect(result.pageSize, 10);
      expect(result.totalPages, 2);
    });

    test('items null resulta en lista vacia', () {
      final json = {
        'total_count': 0,
        'page': 1,
        'page_size': 10,
        'total_pages': 0,
      };
      final result = paginatedFromJson<Plan>(json, planFromJson);
      expect(result.items, isEmpty);
    });
  });
}
