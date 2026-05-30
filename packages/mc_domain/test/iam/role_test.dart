import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2024, 1, 15, 10, 0);

  Role buildRole({
    String id = 'role-1',
    String name = 'Admin',
    RoleType type = RoleType.system,
    RoleStatus status = RoleStatus.active,
    List<String> permissions = const ['iam.read', 'iam.write'],
    String? tenantId,
  }) {
    return Role(
      id: id,
      name: name,
      type: type,
      status: status,
      permissions: permissions,
      createdAt: now,
      updatedAt: now,
      tenantId: tenantId,
    );
  }

  group('Role entity', () {
    test('construye correctamente', () {
      final r = buildRole();
      expect(r.id, 'role-1');
      expect(r.name, 'Admin');
      expect(r.type, RoleType.system);
      expect(r.status, RoleStatus.active);
      expect(r.permissions, ['iam.read', 'iam.write']);
      expect(r.description, isNull);
      expect(r.tenantId, isNull);
    });

    test('igualdad por valor', () {
      final r1 = buildRole();
      final r2 = buildRole();
      expect(r1, equals(r2));
    });

    test('distintos ids son distintos', () {
      final r1 = buildRole(id: 'role-1');
      final r2 = buildRole(id: 'role-2');
      expect(r1, isNot(equals(r2)));
    });

    test('todos los RoleType existen', () {
      expect(RoleType.values.length, 2);
      expect(RoleType.values, containsAll([RoleType.system, RoleType.tenant]));
    });

    test('todos los RoleStatus existen', () {
      expect(RoleStatus.values.length, 2);
      expect(RoleStatus.values, containsAll([RoleStatus.active, RoleStatus.inactive]));
    });

    test('role de tenant tiene tenantId', () {
      final r = buildRole(type: RoleType.tenant, tenantId: 'tenant-abc');
      expect(r.tenantId, 'tenant-abc');
      expect(r.type, RoleType.tenant);
    });

    test('lista de permisos vacia es valida', () {
      final r = buildRole(permissions: const []);
      expect(r.permissions, isEmpty);
    });

    test('permisos multiples se almacenan correctamente', () {
      const perms = ['sales.read', 'sales.write', 'stock.read'];
      final r = buildRole(permissions: perms);
      expect(r.permissions.length, 3);
      expect(r.permissions, contains('stock.read'));
    });
  });

  group('UpsertRoleParams', () {
    test('construye correctamente', () {
      const params = UpsertRoleParams(
        name: 'Vendedor',
        type: RoleType.tenant,
        permissions: ['sales.read'],
        status: RoleStatus.active,
        tenantId: 'tenant-xyz',
      );
      expect(params.name, 'Vendedor');
      expect(params.type, RoleType.tenant);
      expect(params.permissions, ['sales.read']);
      expect(params.status, RoleStatus.active);
      expect(params.tenantId, 'tenant-xyz');
      expect(params.description, isNull);
    });
  });
}
