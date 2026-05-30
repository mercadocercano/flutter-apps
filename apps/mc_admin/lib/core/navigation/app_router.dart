import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/auth_helper.dart';
import 'admin_shell.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/brands/presentation/screens/brands_list_screen.dart';
import '../../features/brands/presentation/screens/brand_form_screen.dart';
import '../../features/categories/presentation/screens/categories_tree_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/business_types/presentation/screens/business_types_list_screen.dart';
import '../../features/global_products/presentation/screens/global_products_screen.dart';
import '../../features/global_products/presentation/screens/global_product_detail_screen.dart';
import '../../features/dev_metrics/presentation/screens/dev_metrics_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/brands',
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login';
      final hasJwt = AuthHelper.getJwt() != null;
      if (!hasJwt && !isLoginRoute) return '/login';
      if (hasJwt && isLoginRoute) return '/brands';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error 404')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ruta no encontrada: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/brands'),
              child: const Text('Ir a Marcas'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Ruta pública — sin shell
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/brands',
      ),

      // Rutas autenticadas envueltas en AdminShell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/brands',
            name: 'brands',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BrandsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                name: 'brand-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const BrandFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'brand-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return BrandFormScreen(brandId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CategoriesTreeScreen()),
            routes: [
              GoRoute(
                path: 'new',
                name: 'category-new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final parentId = state.uri.queryParameters['parentId'];
                  return CategoryFormScreen(initialParentId: parentId);
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'category-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CategoryFormScreen(categoryId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/business-types',
            name: 'business-types',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BusinessTypesListScreen()),
          ),
          GoRoute(
            path: '/global-products',
            name: 'global-products',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GlobalProductsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'global-product-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return GlobalProductDetailScreen(productId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/dev-metrics',
            name: 'dev-metrics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DevMetricsScreen()),
          ),
        ],
      ),
    ],
  );
}
