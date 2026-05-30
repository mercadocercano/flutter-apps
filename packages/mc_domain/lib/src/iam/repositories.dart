import 'paginated_result.dart';
import 'tenant.dart';
import 'role.dart';
import 'plan.dart';

/// Puerto de repositorio para tenants.
abstract interface class TenantRepository {
  Future<PaginatedResult<Tenant>> getAll(
    int page,
    int pageSize, {
    String? name,
    TenantStatus? status,
    TenantType? type,
  });

  Future<Tenant> getById(String id);

  Future<Tenant> create(CreateTenantParams params);

  Future<Tenant> update(String id, UpdateTenantParams params);

  Future<Tenant> toggleStatus(String id, TenantStatus newStatus);

  Future<void> delete(String id);
}

/// Puerto de repositorio para roles.
abstract interface class RoleRepository {
  Future<PaginatedResult<Role>> getAll(
    int page,
    int pageSize, {
    RoleType? type,
    String? name,
    RoleStatus? status,
  });

  Future<Role> getById(String id);

  Future<Role> create(UpsertRoleParams params);

  Future<Role> update(String id, UpsertRoleParams params);

  Future<void> delete(String id);
}

/// Puerto de repositorio para planes.
abstract interface class PlanRepository {
  Future<PaginatedResult<Plan>> getAll(
    int page,
    int pageSize, {
    PlanType? type,
    String? name,
    PlanStatus? status,
  });

  Future<Plan> getById(String id);

  Future<Plan> create(UpsertPlanParams params);

  Future<Plan> update(String id, UpsertPlanParams params);

  Future<void> delete(String id);
}
