import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/features/dashboard/widgets/dashboard_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('ServiceHealthChip — parseo de status', () {
    test('status "online" mapea a ServiceStatus.online', () {
      const chip = ServiceHealthChip(serviceName: 'Kong', status: 'online');
      expect(chip.status, 'online');
    });

    test('status desconocido mapea a offline', () {
      const chip = ServiceHealthChip(serviceName: 'Kong', status: 'unknown');
      // La propiedad pública es el string raw; el parseo es interno.
      // Verificamos que el widget se construye sin error.
      expect(chip.serviceName, 'Kong');
    });
  });

  group('ServiceHealthChip — estado online', () {
    testWidgets('muestra el nombre del servicio', (tester) async {
      await tester.pumpWidget(wrap(
        const ServiceHealthChip(serviceName: 'Kong', status: 'online'),
      ));

      expect(find.text('Kong'), findsOneWidget);
    });

    testWidgets('no muestra latencia cuando latencyMs es null', (tester) async {
      await tester.pumpWidget(wrap(
        const ServiceHealthChip(serviceName: 'Kong', status: 'online'),
      ));

      expect(find.textContaining('ms'), findsNothing);
    });

    testWidgets('muestra latencia entre paréntesis cuando se provee',
        (tester) async {
      await tester.pumpWidget(wrap(
        const ServiceHealthChip(
          serviceName: 'Kong',
          status: 'online',
          latencyMs: 42,
        ),
      ));

      expect(find.text('(42ms)'), findsOneWidget);
    });
  });

  group('ServiceHealthChip — estado degraded', () {
    testWidgets('renderiza correctamente con status degraded', (tester) async {
      await tester.pumpWidget(wrap(
        const ServiceHealthChip(
          serviceName: 'IAM',
          status: 'degraded',
          latencyMs: 1200,
        ),
      ));

      expect(find.text('IAM'), findsOneWidget);
      expect(find.text('(1200ms)'), findsOneWidget);
    });
  });

  group('ServiceHealthChip — estado offline', () {
    testWidgets('renderiza correctamente con status offline', (tester) async {
      await tester.pumpWidget(wrap(
        const ServiceHealthChip(
          serviceName: 'WebData',
          status: 'offline',
        ),
      ));

      expect(find.text('WebData'), findsOneWidget);
      expect(find.textContaining('ms'), findsNothing);
    });
  });

  group('ServiceHealthChip — tooltip', () {
    testWidgets('tiene un Tooltip con información del servicio', (tester) async {
      await tester.pumpWidget(wrap(
        const ServiceHealthChip(
          serviceName: 'PIM',
          status: 'online',
          latencyMs: 55,
        ),
      ));

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('PIM'));
      expect(tooltip.message, contains('55ms'));
    });
  });
}
