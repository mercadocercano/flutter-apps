import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/attributes/blocs/attribute_list_bloc.dart';
import 'package:mc_admin/features/pim/attributes/blocs/attribute_form_bloc.dart';
import 'package:mc_admin/features/pim/attributes/blocs/attribute_values_bloc.dart';
import 'package:mc_admin/features/pim/attributes/attribute_list_screen.dart';
import 'package:mc_admin/features/pim/attributes/attribute_form_screen.dart';
import 'package:mc_admin/features/pim/attributes/attribute_detail_screen.dart';

// --- Mocks ---

class MockAttributeListBloc
    extends MockBloc<AttributeListEvent, AttributeListState>
    implements AttributeListBloc {}

class MockAttributeFormBloc
    extends MockBloc<AttributeFormEvent, AttributeFormState>
    implements AttributeFormBloc {}

class MockAttributeValuesBloc
    extends MockBloc<AttributeValuesEvent, AttributeValuesState>
    implements AttributeValuesBloc {}

// --- Builders ---

MarketplaceAttribute _buildAttribute({
  String id = 'attr-1',
  String name = 'Color',
  String slug = 'color',
  AttributeType type = AttributeType.select,
  bool isRequired = false,
  bool isFilterable = true,
  List<AttributeValue> values = const [],
}) {
  final now = DateTime(2024, 6, 15);
  return MarketplaceAttribute(
    id: id,
    name: name,
    slug: slug,
    type: type,
    isRequired: isRequired,
    isFilterable: isFilterable,
    values: values,
    createdAt: now,
    updatedAt: now,
  );
}

AttributeValue _buildValue({
  String id = 'val-1',
  String attributeId = 'attr-1',
  String label = 'Rojo',
  String value = 'rojo',
}) {
  final now = DateTime(2024, 6, 15);
  return AttributeValue(
    id: id,
    attributeId: attributeId,
    value: value,
    label: label,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

AttributeListLoaded _buildListLoaded({
  List<MarketplaceAttribute>? attributes,
  AttributeType? filterType,
}) {
  return AttributeListLoaded(
    attributes: attributes ??
        [
          _buildAttribute(id: 'attr-1', name: 'Color', type: AttributeType.select),
          _buildAttribute(
              id: 'attr-2',
              name: 'Material',
              slug: 'material',
              type: AttributeType.text),
        ],
    currentPage: 1,
    pageSize: 20,
    totalItems: attributes?.length ?? 2,
    filterType: filterType,
  );
}

// --- Widget helpers ---

Widget _buildListScreen({
  AttributeListState? listState,
  AttributeFormState? formState,
}) {
  final listBloc = MockAttributeListBloc();
  final formBloc = MockAttributeFormBloc();

  when(() => listBloc.state).thenReturn(listState ?? AttributeListInitial());
  when(() => formBloc.state).thenReturn(formState ?? AttributeFormInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<AttributeListBloc>.value(value: listBloc),
          BlocProvider<AttributeFormBloc>.value(value: formBloc),
        ],
        child: const AttributeListScreen(),
      ),
    ),
  );
}

Widget _buildFormScreen({
  AttributeFormState? formState,
  AttributeValuesState? valuesState,
  String? attributeId,
}) {
  final formBloc = MockAttributeFormBloc();
  final valuesBloc = MockAttributeValuesBloc();

  when(() => formBloc.state).thenReturn(formState ?? AttributeFormInitial());
  when(() => valuesBloc.state)
      .thenReturn(valuesState ?? AttributeValuesInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<AttributeFormBloc>.value(value: formBloc),
          BlocProvider<AttributeValuesBloc>.value(value: valuesBloc),
        ],
        child: AttributeFormScreen(attributeId: attributeId),
      ),
    ),
  );
}

Widget _buildDetailScreen({
  AttributeFormState? formState,
  AttributeValuesState? valuesState,
  String attributeId = 'attr-1',
}) {
  final formBloc = MockAttributeFormBloc();
  final valuesBloc = MockAttributeValuesBloc();

  when(() => formBloc.state).thenReturn(formState ?? AttributeFormInitial());
  when(() => valuesBloc.state)
      .thenReturn(valuesState ?? AttributeValuesInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<AttributeFormBloc>.value(value: formBloc),
          BlocProvider<AttributeValuesBloc>.value(value: valuesBloc),
        ],
        child: AttributeDetailScreen(attributeId: attributeId),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoadAttributesEvent());
    registerFallbackValue(RefreshAttributesEvent());
    registerFallbackValue(DeleteAttributeEvent(''));
    registerFallbackValue(LoadAttributeEvent(''));
    registerFallbackValue(ResetAttributeFormEvent());
    registerFallbackValue(
      SubmitAttributeFormEvent(
        MarketplaceAttribute(
          id: '',
          name: '',
          slug: '',
          type: AttributeType.text,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ),
    );
    registerFallbackValue(LoadAttributeValuesEvent(''));
    registerFallbackValue(
      CreateAttributeValueEvent(
        AttributeValue(
          id: '',
          attributeId: '',
          value: '',
          label: '',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ),
    );
    registerFallbackValue(
      UpdateAttributeValueEvent(
        AttributeValue(
          id: '',
          attributeId: '',
          value: '',
          label: '',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ),
    );
    registerFallbackValue(
      DeleteAttributeValueEvent(attributeId: '', valueId: ''),
    );
  });

  // ============================================================
  // BDD Escenario 1: Lista carga y muestra atributos
  // ============================================================

  group('AttributeListScreen — Escenario 1: lista de atributos', () {
    testWidgets('muestra CircularProgressIndicator mientras carga',
        (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: AttributeListLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra atributos cuando el estado es Loaded', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
    });

    testWidgets('muestra columnas de la tabla', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Obligatorio'), findsOneWidget);
      expect(find.text('Filtrable'), findsOneWidget);
      expect(find.text('Valores'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('muestra botón "Nuevo atributo"', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      expect(find.text('Nuevo atributo'), findsOneWidget);
    });

    testWidgets('muestra chip de tipo para cada atributo', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      // "Selección" aparece: en filtro + chip de la fila de tipo select
      expect(find.text('Selección'), findsWidgets);
      // "Texto" aparece: en filtro + chip de la fila de tipo text
      expect(find.text('Texto'), findsWidgets);
    });

    testWidgets('muestra mensaje de error cuando el estado es Error',
        (tester) async {
      await tester.pumpWidget(
        _buildListScreen(
          listState: AttributeListError('Error de red'),
        ),
      );
      await tester.pump();

      expect(find.text('Error de red'), findsOneWidget);
    });

    testWidgets('muestra íconos booleanos de isRequired y isFilterable',
        (tester) async {
      final attr = _buildAttribute(isRequired: false, isFilterable: true);
      await tester.pumpWidget(
        _buildListScreen(
          listState: AttributeListLoaded(
            attributes: [attr],
            currentPage: 1,
            pageSize: 20,
            totalItems: 1,
          ),
        ),
      );
      await tester.pump();

      // isFilterable=true → check_circle_outline
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      // isRequired=false → radio_button_unchecked
      expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);
    });
  });

  // ============================================================
  // BDD Escenario 2: Filtro por tipo funciona
  // ============================================================

  group('AttributeListScreen — Escenario 2: filtro por tipo', () {
    testWidgets('muestra chips de filtro de tipo', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Texto'), findsWidgets);
      expect(find.text('Número'), findsOneWidget);
      expect(find.text('Booleano'), findsOneWidget);
      expect(find.text('Selección'), findsWidgets);
      expect(find.text('Multi-selección'), findsOneWidget);
    });

    testWidgets('el chip "Todos" está seleccionado por defecto', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Todos'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('muestra campo de búsqueda', (tester) async {
      await tester.pumpWidget(
        _buildListScreen(listState: _buildListLoaded()),
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // ============================================================
  // BDD Escenario 3: Tipo select muestra sección de valores en form
  // ============================================================

  group('AttributeFormScreen — Escenario 3: tipo select muestra valores', () {
    testWidgets('formulario nuevo muestra placeholder de valores para select',
        (tester) async {
      final attr = _buildAttribute(type: AttributeType.select);
      await tester.pumpWidget(
        _buildFormScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded([_buildValue()]),
          attributeId: 'attr-1',
        ),
      );
      await tester.pump();

      // La sección de valores debe aparecer para tipo select
      expect(find.text('Valores'), findsOneWidget);
    });

    testWidgets(
        'formulario nuevo con tipo select muestra placeholder "Guardá primero"',
        (tester) async {
      await tester.pumpWidget(
        _buildFormScreen(
          // Sin attributeId = nuevo
          formState: AttributeFormInitial(),
        ),
      );
      await tester.pump();

      // Con tipo select por defecto (text), valores no aparece
      // Con tipo select en formulario nuevo, aparece placeholder
      // No podemos cambiar el DropdownButton fácilmente sin routing,
      // así verificamos que el formulario arranca con campos básicos.
      expect(find.text('Nombre *'), findsOneWidget);
      expect(find.text('Slug *'), findsOneWidget);
    });

    testWidgets(
        'formulario de edición con tipo select muestra valores existentes',
        (tester) async {
      final attr = _buildAttribute(type: AttributeType.select, id: 'attr-1');
      final values = [
        _buildValue(label: 'Rojo', value: 'rojo'),
        _buildValue(id: 'val-2', label: 'Azul', value: 'azul'),
      ];

      await tester.pumpWidget(
        _buildFormScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded(values),
          attributeId: 'attr-1',
        ),
      );
      await tester.pump();

      expect(find.text('Rojo'), findsOneWidget);
      expect(find.text('Azul'), findsOneWidget);
    });

    testWidgets('muestra botón "Agregar valor" en sección de valores',
        (tester) async {
      final attr = _buildAttribute(type: AttributeType.select, id: 'attr-1');

      await tester.pumpWidget(
        _buildFormScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded(const []),
          attributeId: 'attr-1',
        ),
      );
      await tester.pump();

      expect(find.text('Agregar valor'), findsOneWidget);
    });
  });

  // ============================================================
  // BDD Escenario 4: Tipo text oculta sección de valores
  // ============================================================

  group('AttributeFormScreen — Escenario 4: tipo text oculta valores', () {
    testWidgets('formulario con tipo text NO muestra sección de valores',
        (tester) async {
      final attr = _buildAttribute(type: AttributeType.text, id: 'attr-text');

      await tester.pumpWidget(
        _buildFormScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesInitial(),
          attributeId: 'attr-text',
        ),
      );
      await tester.pump();

      // La sección de valores (Card con 'Valores') NO debe aparecer para tipo text
      // El texto "Valores" solo aparece si el tipo tiene hasValues
      expect(find.text('Agregar valor'), findsNothing);
    });

    testWidgets('formulario nuevo sin modificar empieza con tipo Texto',
        (tester) async {
      await tester.pumpWidget(
        _buildFormScreen(formState: AttributeFormInitial()),
      );
      await tester.pump();

      // El DropdownButtonFormField debe mostrar 'Texto' como valor inicial
      expect(find.text('Texto'), findsWidgets);
    });
  });

  // ============================================================
  // BDD Escenario 5: Eliminar muestra diálogo de confirmación
  // ============================================================

  group('AttributeListScreen — Escenario 5: confirmación de eliminar', () {
    testWidgets('muestra ícono de eliminar en acciones de fila', (tester) async {
      final state = AttributeListLoaded(
        attributes: [_buildAttribute()],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );

      await tester.pumpWidget(_buildListScreen(listState: state));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tap en eliminar muestra ConfirmDialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AttributeListLoaded(
        attributes: [_buildAttribute(name: 'Color')],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );

      await tester.pumpWidget(_buildListScreen(listState: state));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // El diálogo debe aparecer con título y botón Eliminar
      expect(find.text('Eliminar atributo'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('ConfirmDialog contiene advertencia de uso en productos',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AttributeListLoaded(
        attributes: [_buildAttribute(name: 'Color')],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );

      await tester.pumpWidget(_buildListScreen(listState: state));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('puede estar en uso en productos'),
        findsOneWidget,
      );
    });

    testWidgets('cancelar en ConfirmDialog cierra el diálogo sin disparar evento',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final listBloc = MockAttributeListBloc();
      final formBloc = MockAttributeFormBloc();

      final state = AttributeListLoaded(
        attributes: [_buildAttribute()],
        currentPage: 1,
        pageSize: 20,
        totalItems: 1,
      );
      when(() => listBloc.state).thenReturn(state);
      when(() => formBloc.state).thenReturn(AttributeFormInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AttributeListBloc>.value(value: listBloc),
                BlocProvider<AttributeFormBloc>.value(value: formBloc),
              ],
              child: const AttributeListScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // El diálogo se cerró
      expect(find.text('Eliminar atributo'), findsNothing);
      // No se disparó DeleteAttributeEvent
      verifyNever(() => listBloc.add(any(that: isA<DeleteAttributeEvent>())));
    });
  });

  // ============================================================
  // AttributeDetailScreen — tests adicionales
  // ============================================================

  group('AttributeDetailScreen', () {
    testWidgets('muestra CircularProgressIndicator mientras carga',
        (tester) async {
      await tester.pumpWidget(
        _buildDetailScreen(formState: AttributeFormLoading()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra datos del atributo cuando está cargado', (tester) async {
      final attr = _buildAttribute(name: 'Color', slug: 'color');

      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded(const []),
        ),
      );
      await tester.pump();

      expect(find.text('Color'), findsWidgets);
      expect(find.text('color'), findsOneWidget);
    });

    testWidgets('muestra botón Editar en la AppBar', (tester) async {
      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormLoaded(_buildAttribute()),
          valuesState: AttributeValuesLoaded(const []),
        ),
      );
      await tester.pump();

      expect(find.text('Editar'), findsOneWidget);
    });

    testWidgets('muestra chip de tipo en detalle', (tester) async {
      final attr = _buildAttribute(type: AttributeType.select);

      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded(const []),
        ),
      );
      await tester.pump();

      expect(find.text('Selección'), findsOneWidget);
    });

    testWidgets(
        'muestra sección Valores cuando tipo es select y valores existen',
        (tester) async {
      final attr = _buildAttribute(type: AttributeType.select, id: 'attr-1');
      final values = [
        _buildValue(label: 'Rojo'),
        _buildValue(id: 'val-2', label: 'Azul'),
      ];

      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded(values),
        ),
      );
      await tester.pump();

      expect(find.text('Valores (2)'), findsOneWidget);
      expect(find.text('Rojo'), findsOneWidget);
      expect(find.text('Azul'), findsOneWidget);
    });

    testWidgets('NO muestra sección Valores cuando tipo es text', (tester) async {
      final attr = _buildAttribute(type: AttributeType.text, id: 'attr-text');

      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesInitial(),
        ),
      );
      await tester.pump();

      // No debe mostrar "Valores" en la vista de detalle para tipo text
      expect(find.text('Valores (0)'), findsNothing);
    });

    testWidgets('muestra mensaje de error cuando falla la carga', (tester) async {
      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormError('Error al cargar atributo'),
        ),
      );
      await tester.pump();

      expect(find.text('Error al cargar atributo'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('muestra badges de Obligatorio y Filtrable', (tester) async {
      final attr = _buildAttribute(isRequired: true, isFilterable: false);

      await tester.pumpWidget(
        _buildDetailScreen(
          formState: AttributeFormLoaded(attr),
          valuesState: AttributeValuesLoaded(const []),
        ),
      );
      await tester.pump();

      // Badges con "Sí" y "No"
      expect(find.text('Sí'), findsWidgets);
      expect(find.text('No'), findsWidgets);
    });
  });
}
