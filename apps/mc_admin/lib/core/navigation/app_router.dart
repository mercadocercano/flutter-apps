import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_helper.dart';
import 'admin_shell.dart';

// Screens existentes
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/business_types/presentation/screens/business_types_list_screen.dart';
// Legacy global_products screens removed — replaced by pim/global_catalog (S010)
import '../../features/dev_metrics/presentation/screens/dev_metrics_screen.dart';

// PIM Taxonomy screens (S009)
import '../../features/pim/taxonomy/taxonomy_screen.dart';
import '../../features/pim/taxonomy/category_form_screen.dart';
import '../../features/pim/taxonomy/blocs/taxonomy_bloc.dart';
import '../../features/pim/taxonomy/blocs/category_form_bloc.dart';

// PIM Brands screens (S008)
import '../../features/pim/brands/brands_screen.dart';
import '../../features/pim/brands/brand_form_screen.dart';
import '../../features/pim/brands/brand_detail_screen.dart';
import '../../features/pim/brands/blocs/brands_bloc.dart';
import '../../features/pim/brands/blocs/brand_form_bloc.dart';

// PIM Global Catalog BLoCs + Screens (S010)
import '../../features/pim/global_catalog/blocs/global_catalog_bloc.dart';
import '../../features/pim/global_catalog/blocs/product_form_bloc.dart';
import '../../features/pim/global_catalog/blocs/bulk_import_bloc.dart';
import '../../features/pim/global_catalog/global_catalog_screen.dart';
import '../../features/pim/global_catalog/product_form_screen.dart';
import '../../features/pim/global_catalog/product_detail_screen.dart';
import '../../features/pim/global_catalog/bulk_import_screen.dart';

// PIM Attributes BLoCs + Screens (S011)
import '../../features/pim/attributes/blocs/attribute_list_bloc.dart';
import '../../features/pim/attributes/blocs/attribute_form_bloc.dart';
import '../../features/pim/attributes/blocs/attribute_values_bloc.dart';
import '../../features/pim/attributes/attribute_list_screen.dart';
import '../../features/pim/attributes/attribute_form_screen.dart';
import '../../features/pim/attributes/attribute_detail_screen.dart';

// PIM Quickstart BLoCs (S012-T004)
import '../../features/pim/quickstart/blocs/business_types_bloc.dart';
import '../../features/pim/quickstart/blocs/templates_bloc.dart';
import '../../features/pim/quickstart/blocs/template_form_bloc.dart';
import '../../features/pim/quickstart/blocs/template_analytics_bloc.dart';

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
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => TaxonomyBloc(
                      getTree: GetCategoryTreeUseCase(
                        MarketplaceCategoryRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadTaxonomyEvent()),
                  ),
                  BlocProvider(
                    create: (_) => CategoryFormBloc(
                      create: CreateCategoryUseCase(
                        MarketplaceCategoryRepositoryImpl(KongClient()),
                      ),
                      update: UpdateCategoryUseCase(
                        MarketplaceCategoryRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteCategoryUseCase(
                        MarketplaceCategoryRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const TaxonomyScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-taxonomy-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final parentId = state.uri.queryParameters['parentId'];
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => TaxonomyBloc(
                          getTree: GetCategoryTreeUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadTaxonomyEvent()),
                      ),
                      BlocProvider(
                        create: (_) => CategoryFormBloc(
                          create: CreateCategoryUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                          update: UpdateCategoryUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteCategoryUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: CategoryFormScreen(initialParentId: parentId),
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-taxonomy-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => TaxonomyBloc(
                          getTree: GetCategoryTreeUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadTaxonomyEvent()),
                      ),
                      BlocProvider(
                        create: (_) => CategoryFormBloc(
                          create: CreateCategoryUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                          update: UpdateCategoryUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteCategoryUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: CategoryFormScreen(categoryId: id),
                  );
                },
              ),
            ],
          ),

          // --- PIM: Brands (S008) ---
          GoRoute(
            path: '/pim/brands',
            name: 'pim-brands',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => BrandsBloc(
                      getAll: GetBrandsUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadBrandsEvent()),
                  ),
                  BlocProvider(
                    create: (_) => BrandFormBloc(
                      create: CreateBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      update: UpdateBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      verify: VerifyBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      unverify: UnverifyBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      validateName: ValidateBrandNameUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const BrandsScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-brand-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BlocProvider(
                  create: (_) => BrandFormBloc(
                    create: CreateBrandUseCase(
                      MarketplaceBrandRepositoryImpl(KongClient()),
                    ),
                    update: UpdateBrandUseCase(
                      MarketplaceBrandRepositoryImpl(KongClient()),
                    ),
                    delete: DeleteBrandUseCase(
                      MarketplaceBrandRepositoryImpl(KongClient()),
                    ),
                    verify: VerifyBrandUseCase(
                      MarketplaceBrandRepositoryImpl(KongClient()),
                    ),
                    unverify: UnverifyBrandUseCase(
                      MarketplaceBrandRepositoryImpl(KongClient()),
                    ),
                  ),
                  child: const BrandFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'pim-brand-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => BrandsBloc(
                          getAll: GetBrandsUseCase(
                            MarketplaceBrandRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                      BlocProvider(
                        create: (_) => BrandFormBloc(
                          create: CreateBrandUseCase(
                            MarketplaceBrandRepositoryImpl(KongClient()),
                          ),
                          update: UpdateBrandUseCase(
                            MarketplaceBrandRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteBrandUseCase(
                            MarketplaceBrandRepositoryImpl(KongClient()),
                          ),
                          verify: VerifyBrandUseCase(
                            MarketplaceBrandRepositoryImpl(KongClient()),
                          ),
                          unverify: UnverifyBrandUseCase(
                            MarketplaceBrandRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: BrandDetailScreen(
                      brandId: id,
                      getBrand: GetBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                    ),
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-brand-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return BlocProvider(
                    create: (_) => BrandFormBloc(
                      create: CreateBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      update: UpdateBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      verify: VerifyBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      unverify: UnverifyBrandUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                      validateName: ValidateBrandNameUseCase(
                        MarketplaceBrandRepositoryImpl(KongClient()),
                      ),
                    ),
                    child: BrandFormScreen(brandId: id),
                  );
                },
              ),
            ],
          ),

          // --- PIM: Global Catalog (S010) ---
          GoRoute(
            path: '/pim/global-catalog',
            name: 'pim-global-catalog',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => GlobalCatalogBloc(
                      list: ListGlobalProductsUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadGlobalCatalogEvent()),
                  ),
                  BlocProvider(
                    create: (_) => ProductFormBloc(
                      get: GetGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      create: CreateGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      update: UpdateGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      verify: VerifyGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      unverify: UnverifyGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                  BlocProvider(
                    create: (_) => BulkImportBloc(
                      bulkImport: BulkImportGlobalProductsUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const GlobalCatalogScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-global-catalog-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => ProductFormBloc(
                        get: GetGlobalProductUseCase(
                          GlobalProductRepositoryImpl(KongClient()),
                        ),
                        create: CreateGlobalProductUseCase(
                          GlobalProductRepositoryImpl(KongClient()),
                        ),
                        update: UpdateGlobalProductUseCase(
                          GlobalProductRepositoryImpl(KongClient()),
                        ),
                        delete: DeleteGlobalProductUseCase(
                          GlobalProductRepositoryImpl(KongClient()),
                        ),
                        verify: VerifyGlobalProductUseCase(
                          GlobalProductRepositoryImpl(KongClient()),
                        ),
                        unverify: UnverifyGlobalProductUseCase(
                          GlobalProductRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                    BlocProvider(
                      create: (_) => TaxonomyBloc(
                        getTree: GetCategoryTreeUseCase(
                          MarketplaceCategoryRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                  ],
                  child: const ProductFormScreen(),
                ),
              ),
              GoRoute(
                path: 'import',
                name: 'pim-global-catalog-import',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BlocProvider(
                  create: (_) => BulkImportBloc(
                    bulkImport: BulkImportGlobalProductsUseCase(
                      GlobalProductRepositoryImpl(KongClient()),
                    ),
                  ),
                  child: const BulkImportScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'pim-global-catalog-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return BlocProvider(
                    create: (_) => ProductFormBloc(
                      get: GetGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      create: CreateGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      update: UpdateGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      verify: VerifyGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                      unverify: UnverifyGlobalProductUseCase(
                        GlobalProductRepositoryImpl(KongClient()),
                      ),
                    ),
                    child: ProductDetailScreen(productId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-global-catalog-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => ProductFormBloc(
                          get: GetGlobalProductUseCase(
                            GlobalProductRepositoryImpl(KongClient()),
                          ),
                          create: CreateGlobalProductUseCase(
                            GlobalProductRepositoryImpl(KongClient()),
                          ),
                          update: UpdateGlobalProductUseCase(
                            GlobalProductRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteGlobalProductUseCase(
                            GlobalProductRepositoryImpl(KongClient()),
                          ),
                          verify: VerifyGlobalProductUseCase(
                            GlobalProductRepositoryImpl(KongClient()),
                          ),
                          unverify: UnverifyGlobalProductUseCase(
                            GlobalProductRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                      BlocProvider(
                        create: (_) => TaxonomyBloc(
                          getTree: GetCategoryTreeUseCase(
                            MarketplaceCategoryRepositoryImpl(KongClient()),
                          ),
                        ),
                      ),
                    ],
                    child: ProductFormScreen(productId: id),
                  );
                },
              ),
            ],
          ),

          // --- PIM: Attributes (S011) ---
          GoRoute(
            path: '/pim/attributes',
            name: 'pim-attributes',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => AttributeListBloc(
                      list: ListMarketplaceAttributesUseCase(
                        MarketplaceAttributeRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteMarketplaceAttributeUseCase(
                        MarketplaceAttributeRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadAttributesEvent()),
                  ),
                  BlocProvider(
                    create: (_) => AttributeFormBloc(
                      get: GetMarketplaceAttributeUseCase(
                        MarketplaceAttributeRepositoryImpl(KongClient()),
                      ),
                      create: CreateMarketplaceAttributeUseCase(
                        MarketplaceAttributeRepositoryImpl(KongClient()),
                      ),
                      update: UpdateMarketplaceAttributeUseCase(
                        MarketplaceAttributeRepositoryImpl(KongClient()),
                      ),
                    ),
                  ),
                ],
                child: const AttributeListScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pim-attribute-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BlocProvider(
                  create: (_) => AttributeFormBloc(
                    get: GetMarketplaceAttributeUseCase(
                      MarketplaceAttributeRepositoryImpl(KongClient()),
                    ),
                    create: CreateMarketplaceAttributeUseCase(
                      MarketplaceAttributeRepositoryImpl(KongClient()),
                    ),
                    update: UpdateMarketplaceAttributeUseCase(
                      MarketplaceAttributeRepositoryImpl(KongClient()),
                    ),
                  ),
                  child: const AttributeFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'pim-attribute-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => AttributeFormBloc(
                          get: GetMarketplaceAttributeUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          create: CreateMarketplaceAttributeUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          update: UpdateMarketplaceAttributeUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadAttributeEvent(id)),
                      ),
                      BlocProvider(
                        create: (_) => AttributeValuesBloc(
                          list: ListAttributeValuesUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          create: CreateAttributeValueUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          update: UpdateAttributeValueUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteAttributeValueUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadAttributeValuesEvent(id)),
                      ),
                    ],
                    child: AttributeDetailScreen(attributeId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'pim-attribute-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => AttributeFormBloc(
                          get: GetMarketplaceAttributeUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          create: CreateMarketplaceAttributeUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          update: UpdateMarketplaceAttributeUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadAttributeEvent(id)),
                      ),
                      BlocProvider(
                        create: (_) => AttributeValuesBloc(
                          list: ListAttributeValuesUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          create: CreateAttributeValueUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          update: UpdateAttributeValueUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                          delete: DeleteAttributeValueUseCase(
                            MarketplaceAttributeRepositoryImpl(KongClient()),
                          ),
                        )..add(LoadAttributeValuesEvent(id)),
                      ),
                    ],
                    child: AttributeFormScreen(attributeId: id),
                  );
                },
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

          // --- Quickstart Dinámico (S012-T004) ---
          GoRoute(
            path: '/quickstart/business-types',
            name: 'quickstart-business-types',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => BusinessTypesBloc(
                      list: ListBusinessTypesUseCase(
                        QuickstartRepositoryImpl(KongClient()),
                      ),
                      activate: ActivateBusinessTypeUseCase(
                        QuickstartRepositoryImpl(KongClient()),
                      ),
                      deactivate: DeactivateBusinessTypeUseCase(
                        QuickstartRepositoryImpl(KongClient()),
                      ),
                      delete: DeleteBusinessTypeUseCase(
                        QuickstartRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadBusinessTypesEvent()),
                  ),
                ],
                child: const BusinessTypesListScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/quickstart/templates/:businessTypeId',
            name: 'quickstart-templates',
            pageBuilder: (context, state) {
              final businessTypeId =
                  state.pathParameters['businessTypeId']!;
              return NoTransitionPage(
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => TemplatesBloc(
                        list: ListTemplatesUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                        delete: DeleteTemplateUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                        duplicate: DuplicateTemplateUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                      )..add(LoadTemplatesEvent(businessTypeId)),
                    ),
                    BlocProvider(
                      create: (_) => TemplateFormBloc(
                        get: GetTemplateUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                        create: CreateTemplateUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                        update: UpdateTemplateUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                        generateAI: GenerateTemplateWithAIUseCase(
                          QuickstartRepositoryImpl(KongClient()),
                        ),
                      ),
                    ),
                  ],
                  child: PlaceholderScreen(
                    title: 'Templates',
                    spec: 'S012-T005',
                  ),
                ),
              );
            },
            routes: [
              GoRoute(
                path: ':templateId/analytics',
                name: 'quickstart-template-analytics',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final templateId = state.pathParameters['templateId']!;
                  return BlocProvider(
                    create: (_) => TemplateAnalyticsBloc(
                      getAnalytics: GetTemplateAnalyticsUseCase(
                        QuickstartRepositoryImpl(KongClient()),
                      ),
                    )..add(LoadTemplateAnalyticsEvent(templateId)),
                    child: PlaceholderScreen(
                      title: 'Analytics de Template',
                      spec: 'S012-T005',
                    ),
                  );
                },
              ),
            ],
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
