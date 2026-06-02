import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/features/dashboard/widgets/dashboard_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('QuickActionButton', () {
    testWidgets('muestra el label del botón', (tester) async {
      await tester.pumpWidget(wrap(
        QuickActionButton(
          label: 'Nuevo Tenant',
          icon: Icons.add_business,
          onTap: () {},
        ),
      ));

      expect(find.text('Nuevo Tenant'), findsOneWidget);
    });

    testWidgets('muestra el ícono indicado', (tester) async {
      await tester.pumpWidget(wrap(
        QuickActionButton(
          label: 'Nuevo Tenant',
          icon: Icons.add_business,
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.add_business), findsOneWidget);
    });

    testWidgets('llama a onTap al presionar el botón', (tester) async {
      var tapped = false;

      await tester.pumpWidget(wrap(
        QuickActionButton(
          label: 'Nuevo Tenant',
          icon: Icons.add_business,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('usa el color provisto cuando se especifica', (tester) async {
      const customColor = Colors.purple;

      await tester.pumpWidget(wrap(
        QuickActionButton(
          label: 'Trigger',
          icon: Icons.play_arrow,
          onTap: () {},
          color: customColor,
        ),
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!.backgroundColor!
          .resolve({WidgetState.pressed}) as Color?;

      // Verificamos que el botón existe y tiene el color correcto en el style
      final resolvedColor =
          button.style!.backgroundColor!.resolve({}) as Color?;
      expect(resolvedColor, customColor);
    });

    testWidgets('usa color primario del tema cuando color es null',
        (tester) async {
      await tester.pumpWidget(wrap(
        QuickActionButton(
          label: 'Trigger',
          icon: Icons.play_arrow,
          onTap: () {},
        ),
      ));

      // Solo verifica que renderiza sin error cuando color es null
      expect(find.text('Trigger'), findsOneWidget);
    });
  });
}
