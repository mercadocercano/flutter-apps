import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_helper.dart';
import 'admin_shell.dart';

// Screens existentes
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/brands/presentation/screens/brands_list_screen.dart';
import '../../features/brands/presentation/screens/brand_form_screen.dart';
import '../../features/categories/presentation/screens/categories_tree_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/business_types/presentation/screens/business_types_list_screen.dart';
import '../../features/global_products/presentation/screens/global_products_screen.dart';
import '../../features/global_products/presentation/screens/global_product_detail_screen.dart';
import '../../features/dev_metrics/presentation/screens/dev_metrics_screen.dart';

// IAM screens (S007)
import '../../features/iam/tenants/tenants_screen.dart';
import '../../features/iam/tenants/tenant_form_screen.dart';
import '../../features/iam/tenants/tenant_detail_screen.dart';
import '../../features/iam/tenants/tenants_bloc.dart';
import '../../features/iam/tenants/tenant_form_bloc.dart';
import '../../features/iam/roles/roles_screen.dart';
import '../../features/iam/roles/role_form_screen.dart';
import '../../features/iam/roles/roles_bloc.dart';
import '../../features/iam/roles/role_form_bloc.dart';
import '../../features/iam/plans/plans_screen.dart';
import '../../features/iam/plans/plan_form_screen.dart';
import '../../features/iam/plans/plans_bloc.dart';
import '../../features/iam/plans/plan_form_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';

// Placeholder screens para S008-S014 (se reemplazan cuando se implementen)
import '../placeholders/placeholder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login';
      final isAuthenticated = AuthHelper.isAuthenticated();
      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Ruta no encontrada: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Ir al Dashboard'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DevMetricsScreen()),
          ),

          // --- IAM (S007) ---
          GoRoute(
            path: '/iam/tenants',
            name: 'iam-tenants',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => TenantsBloc(
                      getAll: GetTenantsUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadTenantsEvent()),
                  ),
                  BlocProvider(
                    create: (_) => TenantFormBloc(
                      create: CreateTenantUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                      update: UpdateTenantUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteTenantUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const TenantsScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'iam-tenant-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BlocProvider(
                  create: (_) => TenantFormBloc(
                    create: CreateTenantUseCase(
                      TenantRepositoryImpl(KongClient()),
                    ),
                    update: UpdateTenantUseCase(
                      TenantRepositoryImpl(KongClient()),
                    ),
                    delete: DeleteTenantUseCase(
                      TenantRepositoryImpl(KongClient()),
                    ),
                  ),
                  child: const TenantFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'iam-tenant-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => TenantsBloc(
                          getAll: GetTenantsUseCase(
                            TenantRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadTenantsEvent()),
                      ),
                      BlocProvider(
                        create: (_) => TenantFormBloc(
                          create: CreateTenantUseCase(
                            TenantRepositoryImpl(KongClient()),
                          ),
                          update: UpdateTenantUseCase(
                            TenantRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteTenantUseCase(
                            TenantRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: TenantDetailScreen(tenantId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'iam-tenant-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return BlocProvider(
                    create: (_) => TenantFormBloc(
                      create: CreateTenantUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                      update: UpdateTenantUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteTenantUseCase(
                        TenantRepositoryImpl(KongClient()),
                      ),
                    ),
                    child: TenantFormScreen(tenantId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/iam/roles',
            name: 'iam-roles',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => RolesBloc(
                      getAll: GetRolesUseCase(
                        RoleRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadRolesEvent()),
                  ),
                  BlocProvider(
                    create: (_) => RoleFormBloc(
                      create: CreateRoleUseCase(
                        RoleRepositoryImpl(KongClient()),
                      ),
                      update: UpdateRoleUseCase(
                        RoleRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteRoleUseCase(
                        RoleRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const RolesScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'iam-role-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => RolesBloc(
                        getAll: GetRolesUseCase(
                          RoleRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                    BlocProvider(
                      create: (_) => RoleFormBloc(
                        create: CreateRoleUseCase(
                          RoleRepositoryImpl(KongClient()),
                        ),
                        update: UpdateRoleUseCase(
                          RoleRepositoryImpl(KongClient()),
                        ),
                        delete: DeleteRoleUseCase(
                          RoleRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                  ],
                  child: const RoleFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'iam-role-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => RolesBloc(
                          getAll: GetRolesUseCase(
                            RoleRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadRolesEvent()),
                      ),
                      BlocProvider(
                        create: (_) => RoleFormBloc(
                          create: CreateRoleUseCase(
                            RoleRepositoryImpl(KongClient()),
                          ),
                          update: UpdateRoleUseCase(
                            RoleRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteRoleUseCase(
                            RoleRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: RoleFormScreen(roleId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/iam/plans',
            name: 'iam-plans',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => PlansBloc(
                      getAll: GetPlansUseCase(
                        PlanRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadPlansEvent()),
                  ),
                  BlocProvider(
                    create: (_) => PlanFormBloc(
                      create: CreatePlanUseCase(
                        PlanRepositoryImpl(KongClient()),
                      ),
                      update: UpdatePlanUseCase(
                        PlanRepositoryImpl(KongClient()),
                      ),
                      delete: DeletePlanUseCase(
                        PlanRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const PlansScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'iam-plan-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => PlansBloc(
                        getAll: GetPlansUseCase(
                          PlanRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                    BlocProvider(
                      create: (_) => PlanFormBloc(
                        create: CreatePlanUseCase(
                          PlanRepositoryImpl(KongClient()),
                        ),
                        update: UpdatePlanUseCase(
                          PlanRepositoryImpl(KongClient()),
                        ),
                        delete: DeletePlanUseCase(
                          PlanRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                  ],
                  child: const PlanFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'iam-plan-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => PlansBloc(
                          getAll: GetPlansUseCase(
                            PlanRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadPlansEvent()),
                      ),
                      BlocProvider(
                        create: (_) => PlanFormBloc(
                          create: CreatePlanUseCase(
                            PlanRepositoryImpl(KongClient()),
                          ),
                          update: UpdatePlanUseCase(
                            PlanRepositoryImpl(KongClient()),
                          ),
                          delete: DeletePlanUseCase(
                            PlanRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: PlanFormScreen(planId: id),
                  );
                },
              ),
            ],
          ),

          // --- PIM: Taxonomy (S009) ---
          GoRoute(
            path: '/pim/taxonomy',
            name: 'pim-taxonomy',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CategoriesTreeScreen()),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-taxonomy-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final parentId = state.uri.queryParameters['parentId'];
                  return CategoryFormScreen(initialParentId: parentId);
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-taxonomy-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => CategoryFormScreen(
                  categoryId: state.pathParameters['id'],
                ),
              ),
            ],
          ),

          // --- PIM: Brands (S008) ---
          GoRoute(
            path: '/pim/brands',
            name: 'pim-brands',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BrandsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-brand-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const BrandFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-brand-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BrandFormScreen(
                  brandId: state.pathParameters['id'],
                ),
              ),
            ],
          ),

          // --- PIM: Global Catalog (S010) ---
          GoRoute(
            path: '/pim/global-catalog',
            name: 'pim-global-catalog',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GlobalProductsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'pim-global-catalog-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => GlobalProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // --- PIM: Attributes (S011) ---
          GoRoute(
            path: '/pim/attributes',
            name: 'pim-attributes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Atributos', spec: 'S011'),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-attribute-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Nuevo Atributo',
                  spec: 'S011',
                ),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-attribute-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => PlaceholderScreen(
                  title: 'Editar Atributo',
                  spec: 'S011',
                ),
              ),
            ],
          ),

          // --- Web Data (S013) ---
          GoRoute(
            path: '/web-data/dashboard',
            name: 'webdata-dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Web Data Dashboard', spec: 'S013'),
            ),
          ),
          GoRoute(
            path: '/web-data/sources',
            name: 'webdata-sources',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Fuentes', spec: 'S013'),
            ),
          ),
          GoRoute(
            path: '/web-data/jobs',
            name: 'webdata-jobs',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Jobs', spec: 'S013'),
            ),
          ),
          GoRoute(
            path: '/web-data/products',
            name: 'webdata-products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Productos Web', spec: 'S013'),
            ),
          ),

          // --- Quickstart Dinámico (S012) ---
          GoRoute(
            path: '/quickstart/business-types',
            name: 'quickstart-business-types',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BusinessTypesListScreen()),
          ),
          GoRoute(
            path: '/quickstart/templates',
            name: 'quickstart-templates',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(title: 'Templates', spec: 'S012'),
            ),
          ),

          // Compat: rutas legacy que redirigen a las nuevas
          GoRoute(
            path: '/brands',
            redirect: (context, state) => '/pim/brands',
          ),
          GoRoute(
            path: '/categories',
            redirect: (context, state) => '/pim/taxonomy',
          ),
          GoRoute(
            path: '/global-products',
            redirect: (context, state) => '/pim/global-catalog',
          ),
          GoRoute(
            path: '/business-types',
            redirect: (context, state) => '/quickstart/business-types',
          ),
          GoRoute(
            path: '/dev-metrics',
            redirect: (context, state) => '/dashboard',
          ),
        ],
      ),
    ],
  );
}
