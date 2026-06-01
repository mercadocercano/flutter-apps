import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/quickstart/blocs/business_types_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/blocs/templates_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/blocs/template_form_bloc.dart';
import 'package:mc_admin/features/pim/quickstart/blocs/template_analytics_bloc.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockListBusinessTypesUseCase extends Mock
    implements ListBusinessTypesUseCase {}

class MockActivateBusinessTypeUseCase extends Mock
    implements ActivateBusinessTypeUseCase {}

class MockDeactivateBusinessTypeUseCase extends Mock
    implements DeactivateBusinessTypeUseCase {}

class MockDeleteBusinessTypeUseCase extends Mock
    implements DeleteBusinessTypeUseCase {}

class MockListTemplatesUseCase extends Mock implements ListTemplatesUseCase {}

class MockDeleteTemplateUseCase extends Mock implements DeleteTemplateUseCase {}

class MockDuplicateTemplateUseCase extends Mock
    implements DuplicateTemplateUseCase {}

class MockGetTemplateUseCase extends Mock implements GetTemplateUseCase {}

class MockCreateTemplateUseCase extends Mock implements CreateTemplateUseCase {}

class MockUpdateTemplateUseCase extends Mock implements UpdateTemplateUseCase {}

class MockGenerateTemplateWithAIUseCase extends Mock
    implements GenerateTemplateWithAIUseCase {}

class MockGetTemplateAnalyticsUseCase extends Mock
    implements GetTemplateAnalyticsUseCase {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

BusinessType _buildBT({String id = 'bt-1', bool isActive = true}) {
  final now = DateTime(2024, 6, 15);
  return BusinessType(
    id: id,
    name: 'Ferretería',
    slug: 'ferreteria',
    icon: 'hardware',
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

PaginatedResult<BusinessType> _buildBTPage([int count = 2]) {
  return PaginatedResult<BusinessType>(
    items: List.generate(count, (i) => _buildBT(id: 'bt-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

BusinessTypeTemplate _buildTemplate({String id = 'tpl-1'}) {
  final now = DateTime(2024, 6, 15);
  return BusinessTypeTemplate(
    id: id,
    businessTypeId: 'bt-1',
    name: 'Ferretería Básica',
    categoryIds: const ['cat-1'],
    baseProductIds: const ['prod-1'],
    createdAt: now,
    updatedAt: now,
  );
}

TemplateAnalytics _buildAnalytics() {
  return const TemplateAnalytics(
    templateId: 'tpl-1',
    tenantsCount: 10,
    completionRate: 0.75,
  );
}

DioException _buildDioException({int statusCode = 500}) {
  return DioException(
    requestOptions: RequestOptions(path: '/test'),
    response: Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: statusCode,
    ),
  );
}

void main() {
  // =========================================================================
  // BusinessTypesBloc
  // =========================================================================

  group('BusinessTypesBloc', () {
    late MockListBusinessTypesUseCase listUseCase;
    late MockActivateBusinessTypeUseCase activateUseCase;
    late MockDeactivateBusinessTypeUseCase deactivateUseCase;
    late MockDeleteBusinessTypeUseCase deleteUseCase;

    setUp(() {
      listUseCase = MockListBusinessTypesUseCase();
      activateUseCase = MockActivateBusinessTypeUseCase();
      deactivateUseCase = MockDeactivateBusinessTypeUseCase();
      deleteUseCase = MockDeleteBusinessTypeUseCase();
    });

    BusinessTypesBloc buildBloc() => BusinessTypesBloc(
          list: listUseCase,
          activate: activateUseCase,
          deactivate: deactivateUseCase,
          delete: deleteUseCase,
        );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'LoadBusinessTypesEvent emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => listUseCase.execute())
            .thenAnswer((_) async => _buildBTPage());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadBusinessTypesEvent()),
      expect: () => [
        isA<BusinessTypesLoading>(),
        isA<BusinessTypesLoaded>(),
      ],
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'LoadBusinessTypesEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => listUseCase.execute())
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadBusinessTypesEvent()),
      expect: () => [
        isA<BusinessTypesLoading>(),
        isA<BusinessTypesError>(),
      ],
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'Loaded contiene los tipos de negocio correctos',
      build: () {
        when(() => listUseCase.execute())
            .thenAnswer((_) async => _buildBTPage(3));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadBusinessTypesEvent()),
      expect: () => [
        isA<BusinessTypesLoading>(),
        isA<BusinessTypesLoaded>()
            .having((s) => s.types.length, 'types count', 3),
      ],
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'pasa filtro isActive=true al use case',
      build: () {
        when(() => listUseCase.execute(isActive: true))
            .thenAnswer((_) async => _buildBTPage(1));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadBusinessTypesEvent(isActive: true)),
      verify: (_) {
        verify(() => listUseCase.execute(isActive: true)).called(1);
      },
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'ActivateBusinessTypeEvent refresca la lista al activar exitosamente',
      build: () {
        when(() => activateUseCase.execute('bt-1'))
            .thenAnswer((_) async => _buildBT());
        when(() => listUseCase.execute())
            .thenAnswer((_) async => _buildBTPage());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadBusinessTypesEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ActivateBusinessTypeEvent('bt-1'));
      },
      skip: 2,
      expect: () => [
        isA<BusinessTypesLoading>(),
        isA<BusinessTypesLoaded>(),
      ],
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'DeactivateBusinessTypeEvent refresca la lista al desactivar exitosamente',
      build: () {
        when(() => deactivateUseCase.execute('bt-1'))
            .thenAnswer((_) async => _buildBT(isActive: false));
        when(() => listUseCase.execute())
            .thenAnswer((_) async => _buildBTPage());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadBusinessTypesEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(DeactivateBusinessTypeEvent('bt-1'));
      },
      skip: 2,
      expect: () => [
        isA<BusinessTypesLoading>(),
        isA<BusinessTypesLoaded>(),
      ],
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'DeleteBusinessTypeEvent emite Error con 409',
      build: () {
        when(() => deleteUseCase.execute(any()))
            .thenThrow(_buildDioException(statusCode: 409));
        return buildBloc();
      },
      seed: () => BusinessTypesLoaded(types: const []),
      act: (bloc) => bloc.add(DeleteBusinessTypeEvent('bt-used')),
      expect: () => [
        isA<BusinessTypesError>().having(
          (s) => s.message,
          'message',
          contains('en uso'),
        ),
      ],
    );

    blocTest<BusinessTypesBloc, BusinessTypesState>(
      'RefreshBusinessTypesEvent recarga con los mismos filtros',
      build: () {
        when(() => listUseCase.execute(isActive: true))
            .thenAnswer((_) async => _buildBTPage(1));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadBusinessTypesEvent(isActive: true));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(RefreshBusinessTypesEvent());
      },
      skip: 2,
      verify: (_) {
        verify(() => listUseCase.execute(isActive: true)).called(2);
      },
    );
  });

  // =========================================================================
  // TemplatesBloc
  // =========================================================================

  group('TemplatesBloc', () {
    late MockListTemplatesUseCase listUseCase;
    late MockDeleteTemplateUseCase deleteUseCase;
    late MockDuplicateTemplateUseCase duplicateUseCase;

    setUp(() {
      listUseCase = MockListTemplatesUseCase();
      deleteUseCase = MockDeleteTemplateUseCase();
      duplicateUseCase = MockDuplicateTemplateUseCase();
      registerFallbackValue(_buildTemplate());
    });

    TemplatesBloc buildBloc() => TemplatesBloc(
          list: listUseCase,
          delete: deleteUseCase,
          duplicate: duplicateUseCase,
        );

    blocTest<TemplatesBloc, TemplatesState>(
      'LoadTemplatesEvent emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => listUseCase.execute('bt-1'))
            .thenAnswer((_) async => [_buildTemplate(), _buildTemplate(id: 'tpl-2')]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTemplatesEvent('bt-1')),
      expect: () => [
        isA<TemplatesLoading>(),
        isA<TemplatesLoaded>()
            .having((s) => s.templates.length, 'templates count', 2)
            .having((s) => s.businessTypeId, 'businessTypeId', 'bt-1'),
      ],
    );

    blocTest<TemplatesBloc, TemplatesState>(
      'LoadTemplatesEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => listUseCase.execute(any()))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTemplatesEvent('bt-1')),
      expect: () => [
        isA<TemplatesLoading>(),
        isA<TemplatesError>(),
      ],
    );

    blocTest<TemplatesBloc, TemplatesState>(
      'DeleteTemplateEvent refresca la lista al eliminar exitosamente',
      build: () {
        when(() => deleteUseCase.execute('tpl-1'))
            .thenAnswer((_) async {});
        when(() => listUseCase.execute('bt-1'))
            .thenAnswer((_) async => [_buildTemplate()]);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTemplatesEvent('bt-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(DeleteTemplateEvent('tpl-1'));
      },
      skip: 2,
      expect: () => [
        isA<TemplatesLoading>(),
        isA<TemplatesLoaded>(),
      ],
    );

    blocTest<TemplatesBloc, TemplatesState>(
      'DeleteTemplateEvent emite Error con 409',
      build: () {
        when(() => deleteUseCase.execute(any()))
            .thenThrow(_buildDioException(statusCode: 409));
        return buildBloc();
      },
      seed: () => TemplatesLoaded(templates: const [], businessTypeId: 'bt-1'),
      act: (bloc) => bloc.add(DeleteTemplateEvent('tpl-used')),
      expect: () => [
        isA<TemplatesError>().having(
          (s) => s.message,
          'message',
          contains('en uso'),
        ),
      ],
    );

    blocTest<TemplatesBloc, TemplatesState>(
      'DuplicateTemplateEvent refresca la lista al duplicar exitosamente',
      build: () {
        when(() => duplicateUseCase.execute('tpl-1'))
            .thenAnswer((_) async => _buildTemplate(id: 'tpl-copy'));
        when(() => listUseCase.execute('bt-1'))
            .thenAnswer((_) async =>
                [_buildTemplate(), _buildTemplate(id: 'tpl-copy')]);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTemplatesEvent('bt-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(DuplicateTemplateEvent('tpl-1'));
      },
      skip: 2,
      expect: () => [
        isA<TemplatesLoading>(),
        isA<TemplatesLoaded>()
            .having((s) => s.templates.length, 'count after duplicate', 2),
      ],
    );

    blocTest<TemplatesBloc, TemplatesState>(
      'RefreshTemplatesEvent no hace nada si businessTypeId no se cargó',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(RefreshTemplatesEvent()),
      expect: () => [],
    );
  });

  // =========================================================================
  // TemplateFormBloc
  // =========================================================================

  group('TemplateFormBloc', () {
    late MockGetTemplateUseCase getUseCase;
    late MockCreateTemplateUseCase createUseCase;
    late MockUpdateTemplateUseCase updateUseCase;
    late MockGenerateTemplateWithAIUseCase generateAIUseCase;

    setUp(() {
      getUseCase = MockGetTemplateUseCase();
      createUseCase = MockCreateTemplateUseCase();
      updateUseCase = MockUpdateTemplateUseCase();
      generateAIUseCase = MockGenerateTemplateWithAIUseCase();
      registerFallbackValue(_buildTemplate());
    });

    TemplateFormBloc buildBloc() => TemplateFormBloc(
          get: getUseCase,
          create: createUseCase,
          update: updateUseCase,
          generateAI: generateAIUseCase,
        );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'LoadTemplateEvent emite [Loading, Success] al cargar exitosamente',
      build: () {
        when(() => getUseCase.execute('tpl-1'))
            .thenAnswer((_) async => _buildTemplate());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTemplateEvent('tpl-1')),
      expect: () => [
        isA<TemplateFormLoading>(),
        isA<TemplateFormSuccess>(),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'LoadTemplateEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => getUseCase.execute(any()))
            .thenThrow(Exception('Not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTemplateEvent('missing')),
      expect: () => [
        isA<TemplateFormLoading>(),
        isA<TemplateFormError>(),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'SubmitTemplateFormEvent con id vacío crea nuevo template',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildTemplate());
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        SubmitTemplateFormEvent(_buildTemplate(id: '')),
      ),
      expect: () => [
        isA<TemplateFormLoading>(),
        isA<TemplateFormSuccess>(),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'SubmitTemplateFormEvent con id existente actualiza template',
      build: () {
        when(() => updateUseCase.execute(any()))
            .thenAnswer((_) async => _buildTemplate());
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        SubmitTemplateFormEvent(_buildTemplate(id: 'tpl-existing')),
      ),
      expect: () => [
        isA<TemplateFormLoading>(),
        isA<TemplateFormSuccess>(),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'SubmitTemplateFormEvent emite Error con 409',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenThrow(_buildDioException(statusCode: 409));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(SubmitTemplateFormEvent(_buildTemplate(id: ''))),
      expect: () => [
        isA<TemplateFormLoading>(),
        isA<TemplateFormError>().having(
          (s) => s.message,
          'message',
          contains('nombre'),
        ),
      ],
    );

    // --- Flujo IA (clave de T004) ---

    blocTest<TemplateFormBloc, TemplateFormState>(
      'GenerateWithAIEvent emite [AIGenerating, AISuccess] al completar',
      build: () {
        when(() => generateAIUseCase.execute(
              'Ferretería mediana en zona urbana',
              'bt-1',
            )).thenAnswer((_) async => _buildTemplate());
        return buildBloc();
      },
      act: (bloc) => bloc.add(GenerateWithAIEvent(
        description: 'Ferretería mediana en zona urbana',
        businessTypeId: 'bt-1',
      )),
      expect: () => [
        isA<TemplateFormAIGenerating>(),
        isA<TemplateFormAISuccess>(),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'AISuccess contiene el template sugerido por la IA',
      build: () {
        when(() => generateAIUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildTemplate());
        return buildBloc();
      },
      act: (bloc) => bloc.add(GenerateWithAIEvent(
        description: 'Descripción de prueba',
        businessTypeId: 'bt-1',
      )),
      expect: () => [
        isA<TemplateFormAIGenerating>(),
        isA<TemplateFormAISuccess>()
            .having((s) => s.template.name, 'template name', 'Ferretería Básica'),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'GenerateWithAIEvent emite Error por timeout con mensaje claro',
      build: () {
        when(() => generateAIUseCase.execute(any(), any()))
            .thenThrow(const AIGenerationTimeoutException());
        return buildBloc();
      },
      act: (bloc) => bloc.add(GenerateWithAIEvent(
        description: 'Test',
        businessTypeId: 'bt-1',
      )),
      expect: () => [
        isA<TemplateFormAIGenerating>(),
        isA<TemplateFormError>().having(
          (s) => s.message,
          'timeout message',
          contains('tiempo de espera'),
        ),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'GenerateWithAIEvent emite Error por excepción genérica',
      build: () {
        when(() => generateAIUseCase.execute(any(), any()))
            .thenThrow(Exception('AI service unavailable'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(GenerateWithAIEvent(
        description: 'Test',
        businessTypeId: 'bt-1',
      )),
      expect: () => [
        isA<TemplateFormAIGenerating>(),
        isA<TemplateFormError>(),
      ],
    );

    blocTest<TemplateFormBloc, TemplateFormState>(
      'ResetTemplateFormEvent regresa a TemplateFormInitial',
      build: () => buildBloc(),
      seed: () => TemplateFormError('error previo'),
      act: (bloc) => bloc.add(ResetTemplateFormEvent()),
      expect: () => [isA<TemplateFormInitial>()],
    );

    test('TemplateFormSuccess contiene el template', () {
      final template = _buildTemplate();
      final state = TemplateFormSuccess(template);
      expect(state.template.id, 'tpl-1');
    });

    test('TemplateFormAISuccess contiene el template sugerido', () {
      final template = _buildTemplate();
      final state = TemplateFormAISuccess(template);
      expect(state.template.businessTypeId, 'bt-1');
    });
  });

  // =========================================================================
  // TemplateAnalyticsBloc
  // =========================================================================

  group('TemplateAnalyticsBloc', () {
    late MockGetTemplateAnalyticsUseCase analyticsUseCase;

    setUp(() {
      analyticsUseCase = MockGetTemplateAnalyticsUseCase();
    });

    TemplateAnalyticsBloc buildBloc() => TemplateAnalyticsBloc(
          getAnalytics: analyticsUseCase,
        );

    blocTest<TemplateAnalyticsBloc, TemplateAnalyticsState>(
      'LoadTemplateAnalyticsEvent emite [Loading, Loaded] exitosamente',
      build: () {
        when(() => analyticsUseCase.execute('tpl-1'))
            .thenAnswer((_) async => _buildAnalytics());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTemplateAnalyticsEvent('tpl-1')),
      expect: () => [
        isA<TemplateAnalyticsLoading>(),
        isA<TemplateAnalyticsLoaded>()
            .having(
              (s) => s.analytics.tenantsCount,
              'tenantsCount',
              10,
            )
            .having(
              (s) => s.analytics.completionRate,
              'completionRate',
              closeTo(0.75, 0.001),
            ),
      ],
    );

    blocTest<TemplateAnalyticsBloc, TemplateAnalyticsState>(
      'LoadTemplateAnalyticsEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => analyticsUseCase.execute(any()))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTemplateAnalyticsEvent('tpl-1')),
      expect: () => [
        isA<TemplateAnalyticsLoading>(),
        isA<TemplateAnalyticsError>(),
      ],
    );

    test('TemplateAnalyticsLoaded contiene los analytics', () {
      final analytics = _buildAnalytics();
      final state = TemplateAnalyticsLoaded(analytics);
      expect(state.analytics.hasBeenUsed, isTrue);
      expect(state.analytics.isCompletionAcceptable, isTrue);
    });
  });
}
