import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_design_system/mc_design_system.dart';
import 'auth_cubit.dart';

/// Pantalla de auth — login y registro en tabs.
/// El tenant se obtiene del JWT, no hay selector.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.cobaltTint,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(McSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header visual
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: McColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(McSpacing.radiusLg),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 48,
                      color: McColors.primary,
                    ),
                  ),
                  const SizedBox(height: McSpacing.md),
                  Text(
                    'Mercado Cercano',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: McColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'POS — Punto de Venta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: McColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: McSpacing.xl),
                  // Card contenedor del form
                  Expanded(
                    child: McCard(
                      padding: const EdgeInsets.all(McSpacing.lg),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Iniciar sesión'),
                              Tab(text: 'Crear cuenta'),
                            ],
                          ),
                          const SizedBox(height: McSpacing.lg),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                const _LoginForm(),
                                _RegisterForm(
                                  onSwitchToLogin: () =>
                                      _tabController.animateTo(0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    debugPrint('[AuthScreen] _login() llamado con email=$email');

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Completá email y contraseña');
      return;
    }

    setState(() => _localError = null);
    context.read<AuthCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final error = state is AuthError ? state.message : _localError;

          return SingleChildScrollView(
            child: Column(
              children: [
                McTextField(
                  label: 'Email',
                  hint: 'tu@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: McSpacing.base),
                McTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  onSubmitted: _login,
                ),
                if (error != null) ...[
                  const SizedBox(height: McSpacing.sm),
                  Text(error, style: TextStyle(color: McColors.error)),
                ],
                const SizedBox(height: McSpacing.lg),
                McButton(
                  label: 'Iniciar sesión',
                  expand: true,
                  size: McButtonSize.lg,
                  isLoading: isLoading,
                  onPressed: _login,
                ),
              ],
            ),
          );
        },
      );
  }
}

class _RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _RegisterForm({required this.onSwitchToLogin});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  void _register() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final storeName = _storeNameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || storeName.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() => _error = null);

    context.read<AuthCubit>().register(
      name: name,
      email: email,
      password: password,
      storeName: storeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _error = state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final displayError = _error;

        return SingleChildScrollView(
          child: Column(
            children: [
              McTextField(
                label: 'Tu nombre',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: McSpacing.md),
              McTextField(
                label: 'Email',
                hint: 'tu@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: McSpacing.md),
              McTextField(
                label: 'Contraseña',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: McSpacing.md),
              McTextField(
                label: 'Nombre de tu comercio',
                hint: 'Ej: Almacén Don Pedro',
                controller: _storeNameController,
                prefixIcon: Icons.store_outlined,
              ),
              if (displayError != null) ...[
                const SizedBox(height: McSpacing.sm),
                Text(displayError, style: TextStyle(color: McColors.error)),
              ],
              const SizedBox(height: McSpacing.lg),
              McButton(
                label: 'Crear cuenta',
                expand: true,
                size: McButtonSize.lg,
                isLoading: isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: McSpacing.md),
              TextButton(
                onPressed: widget.onSwitchToLogin,
                child: const Text('¿Ya tenés cuenta? Iniciá sesión'),
              ),
            ],
          ),
        );
      },
    );
  }
}
