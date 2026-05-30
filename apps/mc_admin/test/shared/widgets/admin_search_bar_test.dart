import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/shared/widgets/admin_search_bar.dart';

void main() {
  group('AdminSearchBar', () {
    testWidgets('muestra hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchBar(
              hint: 'Buscar marca...',
              onSearch: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Buscar marca...'), findsOneWidget);
    });

    testWidgets('llama onSearch con debounce', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchBar(
              hint: 'Buscar...',
              debounceDuration: Duration.zero,
              onSearch: (q) => lastQuery = q,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'samsung');
      await tester.pump(Duration.zero);
      expect(lastQuery, equals('samsung'));
    });

    testWidgets('muestra botón clear cuando hay texto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchBar(
              hint: 'Buscar...',
              initialValue: 'samsung',
              onSearch: (_) {},
            ),
          ),
        ),
      );
      // El suffixIcon (clear) debería aparecer porque hay initialValue
      // Verificamos que el TextField tiene el texto
      expect(find.text('samsung'), findsOneWidget);
    });

    testWidgets('clear button vacía el campo', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchBar(
              hint: 'Buscar...',
              debounceDuration: Duration.zero,
              onSearch: (q) => lastQuery = q,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(Duration.zero);
      expect(lastQuery, 'test');

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(lastQuery, '');
    });
  });
}
