import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/shared/widgets/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    Future<bool?> showAndReturn(
      WidgetTester tester, {
      bool isDangerous = false,
      String confirmLabel = 'Confirmar',
    }) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmDialog.show(
                    ctx,
                    title: '¿Eliminar?',
                    message: 'Esta acción no se puede deshacer.',
                    confirmLabel: confirmLabel,
                    isDangerous: isDangerous,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('muestra title y message', (tester) async {
      await showAndReturn(tester);
      expect(find.text('¿Eliminar?'), findsOneWidget);
      expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);
    });

    testWidgets('retorna true al confirmar', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmDialog.show(
                    ctx,
                    title: 'Test',
                    message: 'Mensaje',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('retorna false al cancelar', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmDialog.show(
                    ctx,
                    title: 'Test',
                    message: 'Mensaje',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('confirmLabel customizable', (tester) async {
      await showAndReturn(tester, confirmLabel: 'Eliminar', isDangerous: true);
      expect(find.text('Eliminar'), findsOneWidget);
    });
  });
}
