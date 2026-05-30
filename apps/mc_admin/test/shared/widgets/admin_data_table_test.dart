import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/shared/widgets/admin_data_table.dart';

void main() {
  final columns = [
    AdminColumn<Map<String, String>>(
      label: 'Nombre',
      builder: (item) => Text(item['name'] ?? ''),
    ),
    AdminColumn<Map<String, String>>(
      label: 'Estado',
      builder: (item) => Text(item['status'] ?? ''),
    ),
  ];

  Widget buildTable({
    List<Map<String, String>> items = const [],
    bool isLoading = false,
    String? error,
    int currentPage = 1,
    int pageSize = 20,
    int totalItems = 0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AdminDataTable<Map<String, String>>(
          items: items,
          columns: columns,
          isLoading: isLoading,
          error: error,
          currentPage: currentPage,
          pageSize: pageSize,
          totalItems: totalItems,
          onPageChanged: (_) {},
        ),
      ),
    );
  }

  group('AdminDataTable', () {
    testWidgets('muestra LoadingWidget cuando isLoading=true', (tester) async {
      await tester.pumpWidget(buildTable(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra EmptyState cuando items vacíos', (tester) async {
      await tester.pumpWidget(buildTable(items: []));
      expect(find.text('No hay resultados'), findsOneWidget);
    });

    testWidgets('muestra ErrorWidget cuando hay error', (tester) async {
      await tester.pumpWidget(
        buildTable(error: 'Error de conexión'),
      );
      expect(find.text('Error de conexión'), findsOneWidget);
    });

    testWidgets('renderiza filas de datos', (tester) async {
      final items = [
        {'name': 'Coca-Cola', 'status': 'Activo'},
        {'name': 'Pepsi', 'status': 'Inactivo'},
      ];
      await tester.pumpWidget(buildTable(
        items: items,
        totalItems: 2,
      ));
      expect(find.text('Coca-Cola'), findsOneWidget);
      expect(find.text('Pepsi'), findsOneWidget);
    });

    testWidgets('muestra cabeceras de columna', (tester) async {
      await tester.pumpWidget(buildTable(
        items: [{'name': 'Test', 'status': 'OK'}],
        totalItems: 1,
      ));
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
    });

    testWidgets('muestra paginación cuando hay items', (tester) async {
      await tester.pumpWidget(buildTable(
        items: List.generate(20, (i) => {'name': 'Item $i', 'status': 'OK'}),
        currentPage: 1,
        pageSize: 20,
        totalItems: 50,
      ));
      expect(find.text('1–20 de 50'), findsOneWidget);
    });

    testWidgets('muestra botón crear si se provee createLabel', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminDataTable<Map<String, String>>(
            items: const [],
            columns: columns,
            currentPage: 1,
            pageSize: 20,
            totalItems: 0,
            onPageChanged: (_) {},
            createLabel: 'Nueva Marca',
            onCreateTap: () {},
          ),
        ),
      ));
      expect(find.text('Nueva Marca'), findsOneWidget);
    });

    testWidgets('llama onSort al hacer tap en columna sortable', (tester) async {
      int? sortedIndex;
      bool? sortedAscending;

      final sortableColumns = [
        AdminColumn<Map<String, String>>(
          label: 'Nombre',
          sortable: true,
          builder: (item) => Text(item['name'] ?? ''),
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminDataTable<Map<String, String>>(
            items: [{'name': 'Test'}],
            columns: sortableColumns,
            currentPage: 1,
            pageSize: 20,
            totalItems: 1,
            onPageChanged: (_) {},
            onSort: (index, ascending) {
              sortedIndex = index;
              sortedAscending = ascending;
            },
          ),
        ),
      ));

      await tester.tap(find.text('Nombre'));
      await tester.pump();

      expect(sortedIndex, equals(0));
      expect(sortedAscending, isNotNull);
    });
  });
}
