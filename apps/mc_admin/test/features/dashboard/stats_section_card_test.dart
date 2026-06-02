import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/features/dashboard/widgets/dashboard_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  final sampleItems = [
    const StatItem(label: 'Tenants', value: 42),
    const StatItem(label: 'Roles', value: 5, subtitle: '3 activos'),
  ];

  group('StatsSectionCard — estado loaded', () {
    testWidgets('muestra el título del encabezado', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: sampleItems,
        ),
      ));

      expect(find.text('IAM'), findsOneWidget);
    });

    testWidgets('muestra los valores numéricos de cada StatItem', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: sampleItems,
        ),
      ));

      expect(find.text('42'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('muestra las labels de cada StatItem', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: sampleItems,
        ),
      ));

      expect(find.text('Tenants'), findsOneWidget);
      expect(find.text('Roles'), findsOneWidget);
    });

    testWidgets('muestra el subtitle cuando está presente', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: sampleItems,
        ),
      ));

      expect(find.text('3 activos'), findsOneWidget);
    });

    testWidgets('no muestra "Datos no disponibles" en estado normal',
        (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: sampleItems,
        ),
      ));

      expect(find.text('Datos no disponibles'), findsNothing);
    });
  });

  group('StatsSectionCard — estado loading', () {
    testWidgets('muestra contenedores skeleton cuando isLoading=true',
        (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: const [],
          isLoading: true,
        ),
      ));

      // Los skeleton cells son Containers grises: verificamos que no hay valores
      expect(find.text('42'), findsNothing);
      expect(find.text('Datos no disponibles'), findsNothing);
    });

    testWidgets('sigue mostrando el título en estado loading', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'IAM',
          icon: Icons.people_outline,
          color: Colors.blue,
          items: const [],
          isLoading: true,
        ),
      ));

      expect(find.text('IAM'), findsOneWidget);
    });
  });

  group('StatsSectionCard — estado error', () {
    testWidgets('muestra "Datos no disponibles" cuando hasError=true',
        (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'Web Data',
          icon: Icons.cloud_outlined,
          color: Colors.orange,
          items: const [],
          hasError: true,
        ),
      ));

      expect(find.text('Datos no disponibles'), findsOneWidget);
    });

    testWidgets('muestra ícono cloud_off en estado error', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'Web Data',
          icon: Icons.cloud_outlined,
          color: Colors.orange,
          items: const [],
          hasError: true,
        ),
      ));

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('no muestra valores de items en estado error', (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'Web Data',
          icon: Icons.cloud_outlined,
          color: Colors.orange,
          items: sampleItems,
          hasError: true,
        ),
      ));

      expect(find.text('42'), findsNothing);
    });

    testWidgets('error tiene prioridad sobre loading cuando ambos son true',
        (tester) async {
      await tester.pumpWidget(wrap(
        StatsSectionCard(
          title: 'Web Data',
          icon: Icons.cloud_outlined,
          color: Colors.orange,
          items: const [],
          isLoading: true,
          hasError: true,
        ),
      ));

      // hasError se evalúa primero en _CardBody
      expect(find.text('Datos no disponibles'), findsOneWidget);
    });
  });
}
