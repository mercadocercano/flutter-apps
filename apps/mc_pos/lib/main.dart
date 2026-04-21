import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/auth_screen.dart';
import 'features/quickstart/quickstart_screen.dart';
import 'app/pos_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureSessionStorage();
  final authAdapter = AuthHttpAdapter(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8001',
    ),
    storage: storage,
  );

  runApp(McPosApp(authPort: authAdapter));
}

class McPosApp extends StatelessWidget {
  final AuthPort authPort;

  const McPosApp({super.key, required this.authPort});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authPort)..checkSession(),
      child: const _McPosRoot(),
    );
  }
}

class _McPosRoot extends StatefulWidget {
  const _McPosRoot();

  @override
  State<_McPosRoot> createState() => _McPosRootState();
}

class _McPosRootState extends State<_McPosRoot> {
  bool _showQuickstart = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MC POS',
      debugShowCheckedModeBanner: false,
      theme: McTheme.light,
      darkTheme: McTheme.dark,
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            if (_showQuickstart) {
              return QuickstartScreen(
                onCompleted: () => setState(() => _showQuickstart = false),
              );
            }
            return _AuthenticatedShell(session: state.session);
          }
          return AuthScreen(
            onAuthenticated: (isNew) {
              if (isNew) {
                setState(() => _showQuickstart = true);
              }
            },
          );
        },
      ),
    );
  }
}

/// Shell autenticado — inyecta McHttpClient y adapters HTTP.
class _AuthenticatedShell extends StatelessWidget {
  final AuthSession session;

  const _AuthenticatedShell({required this.session});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    final httpClient = McHttpClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8001',
      ),
      sessionProvider: authCubit,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogPort>(
          create: (_) => CatalogHttpAdapter(httpClient),
        ),
        RepositoryProvider<SalePort>(
          create: (_) => SaleHttpAdapter(httpClient),
        ),
        RepositoryProvider<StockPort>(
          create: (_) => StockHttpAdapter(httpClient),
        ),
      ],
      child: const PosShell(),
    );
  }
}
