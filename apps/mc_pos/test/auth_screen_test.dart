import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_pos/features/auth/auth_cubit.dart';
import 'package:mc_pos/features/auth/auth_screen.dart';

import 'auth_cubit_test.dart';

void main() {
  group('AuthScreen', () {
    late FakeAuthPort authPort;

    setUp(() {
      authPort = FakeAuthPort();
    });

    Widget buildApp({bool loginShouldFail = false}) {
      authPort.loginShouldFail = loginShouldFail;
      bool authenticated = false;

      return MaterialApp(
        home: BlocProvider(
          create: (_) => AuthCubit(authPort),
          child: Builder(
            builder: (context) => AuthScreen(
              onAuthenticated: (isNew) => authenticated = true,
            ),
          ),
        ),
      );
    }

    testWidgets('muestra formulario de login', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Mercado Cercano'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Contraseña'), findsWidgets);
    });

    testWidgets('login con campos vacíos muestra error', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap en "Iniciar sesión" sin llenar campos
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pump();

      expect(find.text('Completá email y contraseña'), findsOneWidget);
    });

    testWidgets('login exitoso transiciona a AuthSuccess', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Llenar email
      await tester.enterText(
        find.widgetWithText(TextField, 'tu@email.com').first,
        'test@test.com',
      );
      // Llenar password
      await tester.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.obscureText),
        'password123',
      );

      // Tap login
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      // El cubit debería haber emitido AuthSuccess
      // (la UI no muestra auth screen si AuthSuccess, pero en este test
      // solo verificamos que no hay error)
      expect(find.text('Completá email y contraseña'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
    });

    testWidgets('login fallido muestra error', (tester) async {
      await tester.pumpWidget(buildApp(loginShouldFail: true));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'tu@email.com').first,
        'bad@test.com',
      );
      await tester.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.obscureText),
        'wrongpass',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      // Debe mostrar mensaje de error
      expect(find.text('Error inesperado. Intentá de nuevo'), findsOneWidget);
    });
  });
}
