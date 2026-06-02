import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/quickstart/blocs/business_types_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/blocs/templates_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/blocs/template_form_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/blocs/template_analytics_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/business_types_screen.dart';
import 'package:mc_admin/features/pim/quickstart/templates_screen.dart';
import 'package:mc_admin/features/pim/quickstart/template_analytics_screen.dart';
import 'package:mc_admin/features/pim/quickstart/widgets/ai_generation_sheet.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockBusinessTypesBloc
    extends MockBloc<BusinessTypesEvent, BusinessTypesState>
    implements BusinessTypesBloc {}

class MockTemplatesBloc extends MockBloc<TemplatesEvent, TemplatesState>
    implements TemplatesBloc {}

class MockTemplateFormBloc
    extends MockBloc<TemplateFormEvent, TemplateFormState>
    implements TemplateFormBloc {}

class MockTemplateAnalyticsBloc
    extends MockBloc<TemplateAnalyticsEvent, TemplateAnalyticsState>
    implements TemplateAnalyticsBloc {}

// ---------------------------------------------------------------------------
// Builders de objetos de prueba (Object Mother)
// ---------------------------------------------------------------------------

BusinessType _buildBusinessType({
  String id = 'bt-1',
  String name = 'Ferretería',
  String slug = 'ferreteria',
  String icon = '🔧',
  bool isActive = true,
  int templateCount = 3,
}) {
  final now = DateTime(2024, 6, 15);
  return BusinessType(
    id: id,
    name: name,
    slug: slug,
    icon: icon,
    isActive: isActive,
    templateCount: templateCount,
    createdAt: now,
    updatedAt: now,
  );
}

BusinessTypeTemplate _buildTemplate({
  String id = 'tpl-1',
  String businessTypeId = 'bt-1',
  String name = 'Ferretería Básica',
  String? description = 'Template básico de ferretería',
  List<String> categoryIds = const ['cat-1', 'cat-2'],
  List<String> baseProductIds = const ['prod-1'],
  bool isDuplicate = false,
}) {
  final now = DateTime(2024, 6, 15);
  return BusinessTypeTemplate(
    id: id,
    businessTypeId: businessTypeId,
    name: name,
    description: description,
    categoryIds: categoryIds,
    baseProductIds: baseProductIds,
    isDuplicate: isDuplicate,
    createdAt: now,
    updatedAt: now,
  );
}

TemplateAnalytics _buildAnalytics({
  String templateId = 'tpl-1',
  int tenantsCount = 12,
  DateTime? lastActivatedAt,
  double completionRate = 0.78,
}) {
  return TemplateAnalytics(
    templateId: templateId,
    tenantsCount: tenantsCount,
    lastActivatedAt: lastActivatedAt ?? DateTime(2024, 6, 15, 10, 30),
    completionRate: completionRate,
  );
}

// ---------------------------------------------------------------------------
// Helpers de widgets
// ---------------------------------------------------------------------------

Widget _buildBusinessTypesScreen({
  required BusinessTypesState state,
}) {
  final bloc = MockBusinessTypesBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<BusinessTypesBloc>.value(
        value: bloc,
        child: const BusinessTypesScreen(),
      ),
    ),
  );
}

Widget _buildTemplatesScreen({
  required TemplatesState templatesState,
  TemplateFormState? formState,
  String businessTypeId = 'bt-1',
}) {
  final templatesBloc = MockTemplatesBloc();
  final formBloc = MockTemplateFormBloc();

  when(() => templatesBloc.state).thenReturn(templatesState);
  when(() => formBloc.state)
      .thenReturn(formState ?? TemplateFormInitial());

  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<TemplatesBloc>.value(value: templatesBloc),
          BlocProvider<TemplateFormBloc>.value(value: formBloc),
        ],
        child: TemplatesScreen(businessTypeId: businessTypeId),
      ),
    ),
  );
}

Widget _buildAnalyticsScreen({
  required TemplateAnalyticsState state,
  String templateId = 'tpl-1',
}) {
  final bloc = MockTemplateAnalyticsBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<TemplateAnalyticsBloc>.value(
        value: bloc,
        child: TemplateAnalyticsScreen(templateId: templateId),
      ),
    ),
  );
}

Widget _buildAISheet({required TemplateFormState state}) {
  final bloc = MockTemplateFormBloc();
  when(() => bloc.state).thenReturn(state);

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<TemplateFormBloc>.value(
        value: bloc,
        child: const AIGenerationSheet(businessTypeId: 'bt-1'),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(LoadBusinessTypesEvent());
    registerFallbackValue(RefreshBusinessTypesEvent());
    registerFallbackValue(ActivateBusinessTypeEvent(''));
    registerFallbackValue(DeactivateBusinessTypeEvent(''));
    registerFallbackValue(DeleteBusinessTypeEvent(''));
    registerFallbackValue(LoadTemplatesEvent(''));
    registerFallbackValue(RefreshTemplatesEvent());
    registerFallbackValue(DeleteTemplateEvent(''));
    registerFallbackValue(DuplicateTemplateEvent(''));
    registerFallbackValue(LoadTemplateAnalyticsEvent(''));
    registerFallbackValue(
      GenerateWithAIEvent(description: '', businessTypeId: ''),
    );
    registerFallbackValue(
      SubmitTemplateFormEvent(
        BusinessTypeTemplate(
          id: '',
          businessTypeId: '',
          name: '',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ),
    );
  });

  // ==========================================================================
  // BDD Escenario 1: Lista de tipos de negocio con badges activo/inactivo
  // ==========================================================================

  group('BusinessTypesScreen — Escenario 1: lista con badges activo/inactivo', () {
    testWidgets('muestra spinner mientras carga', (tester) async {
      await tester.pumpWidget(
        _buildBusinessTypesScreen(state: BusinessTypesLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra tipos cuando el estado es Loaded', (tester) async {
      final state = BusinessTypesLoaded(
        types: [
          _buildBusinessType(name: 'Ferretería', isActive: true),
          _buildBusinessType(
              id: 'bt-2',
              name: 'Panadería',
              slug: 'panaderia',
              isActive: false),
        ],
      );

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('Ferretería'), findsOneWidget);
      expect(find.text('Panadería'), findsOneWidget);
    });

    testWidgets('muestra badge "Activo" para tipo activo', (tester) async {
      final state = BusinessTypesLoaded(
        types: [_buildBusinessType(isActive: true)],
      );

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('muestra badge "Inactivo" para tipo inactivo', (tester) async {
      final state = BusinessTypesLoaded(
        types: [_buildBusinessType(isActive: false)],
      );

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('muestra columnas correctas en la tabla', (tester) async {
      final state = BusinessTypesLoaded(types: [_buildBusinessType()]);

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('Icono'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('muestra botón "Nuevo tipo"', (tester) async {
      final state = BusinessTypesLoaded(types: []);

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('Nuevo tipo'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla la carga', (tester) async {
      await tester.pumpWidget(
        _buildBusinessTypesScreen(
          state: BusinessTypesError('Error de conexión'),
        ),
      );
      await tester.pump();

      expect(find.text('Error de conexión'), findsOneWidget);
    });

    testWidgets('muestra icono del tipo de negocio', (tester) async {
      final state = BusinessTypesLoaded(
        types: [_buildBusinessType(icon: '🔧')],
      );

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('🔧'), findsOneWidget);
    });

    testWidgets('muestra slug bajo el nombre', (tester) async {
      final state = BusinessTypesLoaded(
        types: [_buildBusinessType(name: 'Ferretería', slug: 'ferreteria')],
      );

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('ferreteria'), findsOneWidget);
    });

    testWidgets('muestra contador de templates', (tester) async {
      final state = BusinessTypesLoaded(
        types: [_buildBusinessType(templateCount: 5)],
      );

      await tester.pumpWidget(_buildBusinessTypesScreen(state: state));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
    });
  });

  // ==========================================================================
  // BDD Escenario 2: Activar/desactivar cambia badge
  // ==========================================================================

  group('BusinessTypesScreen — Escenario 2: activar/desactivar', () {
    testWidgets('tipo activo muestra ícono toggle_on para desactivar',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = MockBusinessTypesBloc();
      when(() => bloc.state).thenReturn(
        BusinessTypesLoaded(types: [_buildBusinessType(isActive: true)]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<BusinessTypesBloc>.value(
              value: bloc,
              child: const BusinessTypesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.toggle_on_outlined), findsOneWidget);
    });

    testWidgets('tipo inactivo muestra ícono toggle_off para activar',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = MockBusinessTypesBloc();
      when(() => bloc.state).thenReturn(
        BusinessTypesLoaded(types: [_buildBusinessType(isActive: false)]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<BusinessTypesBloc>.value(
              value: bloc,
              child: const BusinessTypesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.toggle_off_outlined), findsOneWidget);
    });

    testWidgets(
        'tap en toggle de tipo activo dispara DeactivateBusinessTypeEvent',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = MockBusinessTypesBloc();
      when(() => bloc.state).thenReturn(
        BusinessTypesLoaded(
            types: [_buildBusinessType(id: 'bt-1', isActive: true)]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<BusinessTypesBloc>.value(
              value: bloc,
              child: const BusinessTypesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.toggle_on_outlined));
      await tester.pump();

      verify(
        () => bloc.add(any(that: isA<DeactivateBusinessTypeEvent>())),
      ).called(1);
    });

    testWidgets(
        'tap en toggle de tipo inactivo dispara ActivateBusinessTypeEvent',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = MockBusinessTypesBloc();
      when(() => bloc.state).thenReturn(
        BusinessTypesLoaded(
            types: [_buildBusinessType(id: 'bt-1', isActive: false)]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<BusinessTypesBloc>.value(
              value: bloc,
              child: const BusinessTypesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.toggle_off_outlined));
      await tester.pump();

      verify(
        () => bloc.add(any(that: isA<ActivateBusinessTypeEvent>())),
      ).called(1);
    });

    testWidgets('filtros activo/inactivo/todos están presentes', (tester) async {
      await tester.pumpWidget(
        _buildBusinessTypesScreen(
          state: BusinessTypesLoaded(types: []),
        ),
      );
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Activos'), findsOneWidget);
      expect(find.text('Inactivos'), findsOneWidget);
    });
  });

  // ==========================================================================
  // BDD Escenario 3: Lista de templates para un tipo de negocio
  // ==========================================================================

  group('TemplatesScreen — Escenario 3: lista de templates por tipo', () {
    testWidgets('muestra spinner mientras carga', (tester) async {
      await tester.pumpWidget(
        _buildTemplatesScreen(templatesState: TemplatesLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra templates cuando el estado es Loaded', (tester) async {
      final state = TemplatesLoaded(
        templates: [
          _buildTemplate(name: 'Ferretería Básica'),
          _buildTemplate(id: 'tpl-2', name: 'Ferretería Completa'),
        ],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      expect(find.text('Ferretería Básica'), findsOneWidget);
      expect(find.text('Ferretería Completa'), findsOneWidget);
    });

    testWidgets('muestra columnas correctas', (tester) async {
      final state = TemplatesLoaded(
        templates: [_buildTemplate()],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Productos base'), findsOneWidget);
      expect(find.text('Copia'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('muestra botón "Nueva plantilla"', (tester) async {
      await tester.pumpWidget(
        _buildTemplatesScreen(
          templatesState: TemplatesLoaded(
            templates: [],
            businessTypeId: 'bt-1',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nueva plantilla'), findsOneWidget);
    });

    testWidgets('muestra badge "Copia" para template duplicado',
        (tester) async {
      final state = TemplatesLoaded(
        templates: [_buildTemplate(isDuplicate: true)],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      // "Copia" del encabezado de columna y del badge
      expect(find.text('Copia'), findsWidgets);
    });

    testWidgets('muestra contador de categorías e IDs de productos',
        (tester) async {
      final state = TemplatesLoaded(
        templates: [
          _buildTemplate(
            categoryIds: ['cat-1', 'cat-2', 'cat-3'],
            baseProductIds: ['prod-1', 'prod-2'],
          ),
        ],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      expect(find.text('3'), findsOneWidget); // categorías
      expect(find.text('2'), findsOneWidget); // productos
    });

    testWidgets('muestra mensaje de error cuando falla la carga', (tester) async {
      await tester.pumpWidget(
        _buildTemplatesScreen(
          templatesState: TemplatesError('Error al cargar templates'),
        ),
      );
      await tester.pump();

      expect(find.text('Error al cargar templates'), findsOneWidget);
    });

    testWidgets('muestra descripción del template cuando existe', (tester) async {
      final state = TemplatesLoaded(
        templates: [
          _buildTemplate(description: 'Template para ferreterías urbanas'),
        ],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      expect(find.text('Template para ferreterías urbanas'), findsOneWidget);
    });
  });

  // ==========================================================================
  // BDD Escenario 4: Sheet de IA muestra spinner durante generación
  // ==========================================================================

  group('AIGenerationSheet — Escenario 4: spinner durante generación', () {
    testWidgets('muestra campo de descripción y botón Generar',
        (tester) async {
      await tester.pumpWidget(
        _buildAISheet(state: TemplateFormInitial()),
      );
      await tester.pump();

      expect(find.text('Generar plantilla con IA'), findsOneWidget);
      expect(find.text('Generar'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('muestra spinner cuando el estado es AIGenerating',
        (tester) async {
      await tester.pumpWidget(
        _buildAISheet(state: TemplateFormAIGenerating()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('La IA está generando tu plantilla...'), findsOneWidget);
    });

    testWidgets('botón Generar NO aparece durante generación', (tester) async {
      await tester.pumpWidget(
        _buildAISheet(state: TemplateFormAIGenerating()),
      );
      await tester.pump();

      expect(find.text('Generar'), findsNothing);
    });

    testWidgets('validación rechaza descripción menor a 20 caracteres',
        (tester) async {
      await tester.pumpWidget(
        _buildAISheet(state: TemplateFormInitial()),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Corto');
      await tester.pump();

      await tester.tap(find.text('Generar'));
      await tester.pump();

      expect(
        find.textContaining('al menos 20 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('muestra ícono de cerrar el sheet', (tester) async {
      await tester.pumpWidget(
        _buildAISheet(state: TemplateFormInitial()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets(
        'dispara GenerateWithAIEvent cuando la descripción es suficientemente larga',
        (tester) async {
      final bloc = MockTemplateFormBloc();
      when(() => bloc.state).thenReturn(TemplateFormInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TemplateFormBloc>.value(
              value: bloc,
              child: const AIGenerationSheet(businessTypeId: 'bt-1'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField),
        'Ferretería mediana en zona urbana con más de 20 caracteres',
      );
      await tester.pump();

      await tester.tap(find.text('Generar'));
      await tester.pump();

      verify(
        () => bloc.add(any(that: isA<GenerateWithAIEvent>())),
      ).called(1);
    });
  });

  // ==========================================================================
  // BDD Escenario 5: Duplicar crea copia con "(copia)" en la lista
  // ==========================================================================

  group('TemplatesScreen — Escenario 5: duplicar template', () {
    testWidgets('muestra ícono de duplicar en acciones de fila', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = TemplatesLoaded(
        templates: [_buildTemplate(name: 'Ferretería Básica')],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('tap en duplicar muestra ConfirmDialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = TemplatesLoaded(
        templates: [_buildTemplate(name: 'Ferretería Básica')],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Duplicar plantilla'), findsOneWidget);
      expect(find.text('Duplicar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('ConfirmDialog menciona el nombre con "(copia)"',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = TemplatesLoaded(
        templates: [_buildTemplate(name: 'Ferretería Básica')],
        businessTypeId: 'bt-1',
      );

      await tester.pumpWidget(_buildTemplatesScreen(templatesState: state));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ferretería Básica (copia)'),
        findsOneWidget,
      );
    });

    testWidgets(
        'confirmar duplicar dispara DuplicateTemplateEvent',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final templatesBloc = MockTemplatesBloc();
      final formBloc = MockTemplateFormBloc();

      when(() => templatesBloc.state).thenReturn(
        TemplatesLoaded(
          templates: [_buildTemplate(id: 'tpl-1', name: 'Ferretería Básica')],
          businessTypeId: 'bt-1',
        ),
      );
      when(() => formBloc.state).thenReturn(TemplateFormInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<TemplatesBloc>.value(value: templatesBloc),
                BlocProvider<TemplateFormBloc>.value(value: formBloc),
              ],
              child: const TemplatesScreen(businessTypeId: 'bt-1'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicar'));
      await tester.pumpAndSettle();

      verify(
        () => templatesBloc.add(any(that: isA<DuplicateTemplateEvent>())),
      ).called(1);
    });
  });

  // ==========================================================================
  // TemplateAnalyticsScreen — tests adicionales
  // ==========================================================================

  group('TemplateAnalyticsScreen', () {
    testWidgets('muestra spinner mientras carga', (tester) async {
      await tester.pumpWidget(
        _buildAnalyticsScreen(state: TemplateAnalyticsLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra métricas cuando el estado es Loaded', (tester) async {
      final analytics = _buildAnalytics(
        tenantsCount: 12,
        completionRate: 0.78,
      );

      await tester.pumpWidget(
        _buildAnalyticsScreen(
          state: TemplateAnalyticsLoaded(analytics),
        ),
      );
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
    });

    testWidgets('muestra "Nunca" cuando no hay fecha de última activación',
        (tester) async {
      final analytics = TemplateAnalytics(
        templateId: 'tpl-1',
        tenantsCount: 0,
        lastActivatedAt: null,
        completionRate: 0.0,
      );

      await tester.pumpWidget(
        _buildAnalyticsScreen(
          state: TemplateAnalyticsLoaded(analytics),
        ),
      );
      await tester.pump();

      expect(find.text('Nunca'), findsOneWidget);
    });

    testWidgets('muestra barra de progreso de completitud', (tester) async {
      await tester.pumpWidget(
        _buildAnalyticsScreen(
          state: TemplateAnalyticsLoaded(_buildAnalytics()),
        ),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra error y botón Reintentar cuando falla', (tester) async {
      await tester.pumpWidget(
        _buildAnalyticsScreen(
          state: TemplateAnalyticsError('Error al cargar analytics'),
        ),
      );
      await tester.pump();

      expect(find.text('Error al cargar analytics'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('muestra labels de las métricas', (tester) async {
      await tester.pumpWidget(
        _buildAnalyticsScreen(
          state: TemplateAnalyticsLoaded(_buildAnalytics()),
        ),
      );
      await tester.pump();

      expect(find.text('Comercios que lo usaron'), findsOneWidget);
      expect(find.text('Última activación'), findsOneWidget);
      expect(find.text('Tasa de completitud'), findsOneWidget);
    });

    testWidgets('la AppBar tiene título "Analytics de plantilla"', (tester) async {
      await tester.pumpWidget(
        _buildAnalyticsScreen(
          state: TemplateAnalyticsLoaded(_buildAnalytics()),
        ),
      );
      await tester.pump();

      expect(find.text('Analytics de plantilla'), findsOneWidget);
    });
  });
}
