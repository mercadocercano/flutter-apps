import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/auth_helper.dart';
import 'core/api/kong_client.dart';
import 'core/navigation/app_router.dart';
import 'core/themes/app_theme.dart';
import 'features/brands/data/brands_repository.dart';
import 'features/brands/presentation/bloc/brands_bloc.dart';
import 'features/categories/data/categories_repository.dart';
import 'features/categories/presentation/bloc/categories_bloc.dart';
import 'features/business_types/data/business_types_repository.dart';
import 'features/business_types/presentation/bloc/business_types_bloc.dart';
import 'features/global_products/data/global_products_repository.dart';
import 'features/global_products/presentation/bloc/global_products_bloc.dart';
import 'features/dev_metrics/data/dev_metrics_repository.dart';
import 'features/dev_metrics/presentation/bloc/dev_metrics_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restaura sesión persistida antes de renderizar la UI
  await AuthHelper.init();
  runApp(const McAdminApp());
}

class McAdminApp extends StatelessWidget {
  const McAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final kong = KongClient();
    final brandsRepo = BrandsRepository(kong);
    final categoriesRepo = CategoriesRepository(kong);
    final businessTypesRepo = BusinessTypesRepository(kong);
    final globalProductsRepo = GlobalProductsRepository(kong);
    final devMetricsRepo = DevMetricsRepository(kong);

    return MultiBlocProvider(
      providers: [
        RepositoryProvider<BrandsRepository>.value(value: brandsRepo),
        RepositoryProvider<CategoriesRepository>.value(value: categoriesRepo),
        RepositoryProvider<BusinessTypesRepository>.value(
            value: businessTypesRepo),
        RepositoryProvider<GlobalProductsRepository>.value(
            value: globalProductsRepo),
        RepositoryProvider<DevMetricsRepository>.value(value: devMetricsRepo),
        BlocProvider<BrandsBloc>(
          create: (_) => BrandsBloc(repository: brandsRepo),
        ),
        BlocProvider<CategoriesBloc>(
          create: (_) => CategoriesBloc(repository: categoriesRepo),
        ),
        BlocProvider<BusinessTypesBloc>(
          create: (_) => BusinessTypesBloc(repository: businessTypesRepo),
        ),
        BlocProvider<GlobalProductsBloc>(
          create: (_) => GlobalProductsBloc(repository: globalProductsRepo),
        ),
        BlocProvider<DevMetricsBloc>(
          create: (_) => DevMetricsBloc(repository: devMetricsRepo),
        ),
      ],
      child: MaterialApp.router(
        title: 'MC Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
