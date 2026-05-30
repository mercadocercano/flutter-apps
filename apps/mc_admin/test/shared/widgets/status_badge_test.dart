import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/shared/widgets/status_badge.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('StatusBadge', () {
    test('fromString mapea "active" → AdminStatus.active', () {
      final badge = StatusBadge.fromString('active');
      expect(badge.status, AdminStatus.active);
    });

    test('fromString mapea "verified" → AdminStatus.verified', () {
      final badge = StatusBadge.fromString('verified');
      expect(badge.status, AdminStatus.verified);
    });

    test('fromString mapea "failed" → AdminStatus.failed', () {
      final badge = StatusBadge.fromString('failed');
      expect(badge.status, AdminStatus.failed);
    });

    test('fromString mapea string desconocido → AdminStatus.pending', () {
      final badge = StatusBadge.fromString('desconocido');
      expect(badge.status, AdminStatus.pending);
    });

    testWidgets('renderiza label "Activo" para active', (tester) async {
      await tester.pumpWidget(wrap(
        const StatusBadge(status: AdminStatus.active),
      ));
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('renderiza label "Verificado" para verified', (tester) async {
      await tester.pumpWidget(wrap(
        const StatusBadge(status: AdminStatus.verified),
      ));
      expect(find.text('Verificado'), findsOneWidget);
    });

    testWidgets('usa customLabel cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(
        const StatusBadge(
          status: AdminStatus.active,
          customLabel: 'En línea',
        ),
      ));
      expect(find.text('En línea'), findsOneWidget);
      expect(find.text('Activo'), findsNothing);
    });

    testWidgets('fromString con customLabel usa el customLabel', (tester) async {
      await tester.pumpWidget(wrap(
        StatusBadge.fromString('active', customLabel: 'Operativo'),
      ));
      expect(find.text('Operativo'), findsOneWidget);
    });
  });
}
