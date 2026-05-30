import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/shared/widgets/admin_pagination.dart';

void main() {
  group('AdminPagination', () {
    Widget buildPagination({
      int currentPage = 1,
      int pageSize = 20,
      int totalItems = 50,
      void Function(int)? onPageChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AdminPagination(
            currentPage: currentPage,
            pageSize: pageSize,
            totalItems: totalItems,
            onPageChanged: onPageChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('muestra rango de items correcto página 1', (tester) async {
      await tester.pumpWidget(buildPagination(
        currentPage: 1,
        pageSize: 20,
        totalItems: 50,
      ));
      expect(find.text('1–20 de 50'), findsOneWidget);
    });

    testWidgets('muestra rango de items correcto página 2', (tester) async {
      await tester.pumpWidget(buildPagination(
        currentPage: 2,
        pageSize: 20,
        totalItems: 50,
      ));
      expect(find.text('21–40 de 50'), findsOneWidget);
    });

    testWidgets('muestra rango de items correcto página 3 (última)', (tester) async {
      await tester.pumpWidget(buildPagination(
        currentPage: 3,
        pageSize: 20,
        totalItems: 50,
      ));
      expect(find.text('41–50 de 50'), findsOneWidget);
    });

    testWidgets('botón anterior deshabilitado en página 1', (tester) async {
      await tester.pumpWidget(buildPagination(currentPage: 1));
      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('botón siguiente deshabilitado en última página', (tester) async {
      await tester.pumpWidget(buildPagination(
        currentPage: 3,
        pageSize: 20,
        totalItems: 50,
      ));
      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('llama onPageChanged al navegar', (tester) async {
      int? changedTo;
      await tester.pumpWidget(buildPagination(
        currentPage: 1,
        totalItems: 50,
        onPageChanged: (p) => changedTo = p,
      ));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
      await tester.pump();
      expect(changedTo, 2);
    });

    testWidgets('muestra indicador de páginas', (tester) async {
      await tester.pumpWidget(buildPagination(
        currentPage: 2,
        pageSize: 20,
        totalItems: 60,
      ));
      expect(find.text('2 / 3'), findsOneWidget);
    });
  });
}
