import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/auth_screen.dart';
import 'features/quickstart/quickstart_cubit.dart';
import 'features/quickstart/quickstart_screen.dart';
import 'app/pos_shell.dart';
import 'app/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storage = SecureSessionStorage();
  final authAdapter = AuthHttpAdapter(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
    storage: storage,
  );

  runApp(McPosApp(authPort: authAdapter, prefs: prefs));
}

class McPosApp extends StatelessWidget {
  final AuthPort authPort;
  final SharedPreferences prefs;

  const McPosApp({super.key, required this.authPort, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authPort)..checkSession()),
        BlocProvider(create: (_) => ThemeCubit(prefs)),
      ],
      child: const _McPosRoot(),
    );
  }
}

/// Raíz de la app — escucha AuthCubit y provee repositorios cuando está autenticado.
/// MultiRepositoryProvider envuelve MaterialApp para que todas las rutas lo hereden.
class _McPosRoot extends StatefulWidget {
  const _McPosRoot();

  @override
  State<_McPosRoot> createState() => _McPosRootState();
}

class _McPosRootState extends State<_McPosRoot> {
  McHttpClient? _httpClient;
  CatalogHttpAdapter? _catalogAdapter;

  void _ensureClient(AuthCubit authCubit) {
    if (_httpClient != null) return;
    _httpClient = McHttpClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
      sessionProvider: authCubit,
    );
    _catalogAdapter = CatalogHttpAdapter(_httpClient!);
  }

  void _disposeClient() {
    _httpClient = null;
    _catalogAdapter = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          (prev is AuthSuccess) != (curr is AuthSuccess),
      listener: (context, state) {
        if (state is! AuthSuccess) setState(_disposeClient);
      },
      builder: (context, state) {
        final themeMode = context.watch<ThemeCubit>().state;
        if (state is! AuthSuccess) {
          return MaterialApp(
            title: 'MC POS',
            debugShowCheckedModeBanner: false,
            theme: McTheme.light,
            darkTheme: McTheme.dark,
            themeMode: themeMode,
            home: const AuthScreen(),
          );
        }

        _ensureClient(context.read<AuthCubit>());
        final httpClient = _httpClient!;
        final catalogAdapter = _catalogAdapter!;

        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CatalogPort>(
              create: (_) => catalogAdapter,
            ),
            RepositoryProvider<CategoryPort>(
              create: (_) => CategoryHttpAdapter(httpClient),
            ),
            RepositoryProvider<BrandPort>(
              create: (_) => BrandHttpAdapter(httpClient),
            ),
            RepositoryProvider<SalePort>(
              create: (_) => SaleHttpAdapter(httpClient),
            ),
            RepositoryProvider<StockPort>(
              create: (_) => StockHttpAdapter(httpClient),
            ),
            RepositoryProvider<QuickstartPort>(
              create: (_) => QuickstartHttpAdapter(httpClient),
            ),
            RepositoryProvider<PaymentMethodPort>(
              create: (_) => PaymentMethodHttpAdapter(httpClient),
            ),
            RepositoryProvider<TenantConfigPort>(
              create: (_) => TenantConfigHttpAdapter(httpClient),
            ),
            // ─── Impresora térmica (opcional, según dispositivo) ───
            // El POS elige el formato del comprobante según haya o no un
            // PrinterPort registrado: si existe → botón "Ticket" (ESC/POS);
            // si no → "Imprimir PDF A4" (ReceiptDetailScreen lo resuelve con
            // un try/catch sobre context.read<PrinterPort>()).
            //
            // TODO(E18-TramoC): registrar BluetoothThermalPrinterAdapter cuando
            // exista la pantalla de emparejamiento (discoverDevices + connect)
            // y la preferencia de ancho (58/80mm) en settings del tenant.
            // Ejemplo de activación:
            //   RepositoryProvider<PrinterPort>(
            //     create: (_) => BluetoothThermalPrinterAdapter(
            //       storeName: 'Mi Comercio',
            //       paperWidth: ThermalPaperWidth.mm58,
            //     ),
            //   ),
          ],
          child: BlocProvider(
            create: (_) => QuickstartCubit(catalogAdapter)..checkIfNeeded(),
            child: MaterialApp(
              title: 'MC POS',
              debugShowCheckedModeBanner: false,
              theme: McTheme.light,
              darkTheme: McTheme.dark,
              themeMode: themeMode,
              home: const _QuickstartGate(),
            ),
          ),
        );
      },
    );
  }
}

/// Decide: si necesita quickstart, mostrar QuickstartScreen; si no, PosShell.
class _QuickstartGate extends StatelessWidget {
  const _QuickstartGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuickstartCubit, QuickstartState>(
      builder: (context, state) {
        if (state is QuickstartNeeded) {
          return QuickstartScreen(
            onCompleted: () {
              context.read<QuickstartCubit>().complete();
            },
            quickstartPort: context.read<QuickstartPort>(),
            stockPort: context.read<StockPort>(),
          );
        }
        // QuickstartComplete, Initial, Loading, Error → mostrar POS
        return const PosShell();
      },
    );
  }
}
