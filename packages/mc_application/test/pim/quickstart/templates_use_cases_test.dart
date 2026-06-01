import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockQuickstartRepository extends Mock implements QuickstartRepository {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

final _now = DateTime(2024, 6, 15);

BusinessTypeTemplate _buildTemplate({
  String id = 'tmpl-1',
  String businessTypeId = 'bt-1',
  String name = 'Ferretería Básica',
  List<String> categoryIds = const ['cat-1', 'cat-2'],
  List<String> baseProductIds = const ['prod-1'],
  bool isDuplicate = false,
}) {
  return BusinessTypeTemplate(
    id: id,
    businessTypeId: businessTypeId,
    name: name,
    categoryIds: categoryIds,
    baseProductIds: baseProductIds,
    isDuplicate: isDuplicate,
    createdAt: _now,
    updatedAt: _now,
  );
}

TemplateAnalytics _buildAnalytics({
  String templateId = 'tmpl-1',
  int tenantsCount = 5,
  double completionRate = 0.75,
}) {
  return TemplateAnalytics(
    templateId: templateId,
    tenantsCount: tenantsCount,
    lastActivatedAt: _now,
    completionRate: completionRate,
  );
}

// ---------------------------------------------------------------------------

void main() {
  late MockQuickstartRepository repository;

  setUp(() {
    repository = MockQuickstartRepository();
    registerFallbackValue(_buildTemplate());
  });

  // -------------------------------------------------------------------------
  group('ListTemplatesUseCase', () {
    test('retorna lista de templates para el businessTypeId dado', () async {
      final templates = [
        _buildTemplate(id: 'tmpl-1'),
        _buildTemplate(id: 'tmpl-2'),
      ];
      when(() => repository.listTemplates('bt-1'))
          .thenAnswer((_) async => templates);
      final useCase = ListTemplatesUseCase(repository);

      final result = await useCase.execute('bt-1');

      expect(result.length, 2);
      verify(() => repository.listTemplates('bt-1')).called(1);
    });

    test('retorna lista vacía cuando el businessType no tiene templates',
        () async {
      when(() => repository.listTemplates('bt-empty'))
          .thenAnswer((_) async => []);
      final useCase = ListTemplatesUseCase(repository);

      final result = await useCase.execute('bt-empty');

      expect(result, isEmpty);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.listTemplates(any()))
          .thenThrow(Exception('Not found'));
      final useCase = ListTemplatesUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('GetTemplateUseCase', () {
    test('retorna el template correcto por id', () async {
      final template = _buildTemplate(id: 'tmpl-specific');
      when(() => repository.getTemplate('tmpl-specific'))
          .thenAnswer((_) async => template);
      final useCase = GetTemplateUseCase(repository);

      final result = await useCase.execute('tmpl-specific');

      expect(result.id, 'tmpl-specific');
      verify(() => repository.getTemplate('tmpl-specific')).called(1);
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.getTemplate('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetTemplateUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('CreateTemplateUseCase', () {
    test('crea template y retorna entidad con id asignado', () async {
      final input = _buildTemplate(id: '');
      final created = _buildTemplate(id: 'new-tmpl-id');
      when(() => repository.createTemplate(any()))
          .thenAnswer((_) async => created);
      final useCase = CreateTemplateUseCase(repository);

      final result = await useCase.execute(input);

      expect(result.id, 'new-tmpl-id');
      verify(() => repository.createTemplate(input)).called(1);
    });

    test('propaga error de conflicto del repositorio', () async {
      when(() => repository.createTemplate(any()))
          .thenThrow(Exception('Conflict: name already exists'));
      final useCase = CreateTemplateUseCase(repository);

      expect(() => useCase.execute(_buildTemplate()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('UpdateTemplateUseCase', () {
    test('actualiza template y retorna entidad actualizada', () async {
      final updated = _buildTemplate(id: 'tmpl-1', name: 'Ferretería Avanzada');
      when(() => repository.updateTemplate(any()))
          .thenAnswer((_) async => updated);
      final useCase = UpdateTemplateUseCase(repository);

      final result = await useCase.execute(_buildTemplate(id: 'tmpl-1'));

      expect(result.name, 'Ferretería Avanzada');
      verify(() => repository.updateTemplate(any())).called(1);
    });

    test('propaga error not found del repositorio', () async {
      when(() => repository.updateTemplate(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UpdateTemplateUseCase(repository);

      expect(() => useCase.execute(_buildTemplate()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('DeleteTemplateUseCase', () {
    test('elimina template correctamente', () async {
      when(() => repository.deleteTemplate('tmpl-1'))
          .thenAnswer((_) async {});
      final useCase = DeleteTemplateUseCase(repository);

      await useCase.execute('tmpl-1');

      verify(() => repository.deleteTemplate('tmpl-1')).called(1);
    });

    test('propaga error cuando el template no existe', () async {
      when(() => repository.deleteTemplate(any()))
          .thenThrow(Exception('Not found'));
      final useCase = DeleteTemplateUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('DuplicateTemplateUseCase', () {
    test('retorna copia del template con isDuplicate=true', () async {
      final copy = _buildTemplate(
        id: 'tmpl-copy',
        name: 'Ferretería Básica (copia)',
        isDuplicate: true,
      );
      when(() => repository.duplicateTemplate('tmpl-1'))
          .thenAnswer((_) async => copy);
      final useCase = DuplicateTemplateUseCase(repository);

      final result = await useCase.execute('tmpl-1');

      expect(result.id, 'tmpl-copy');
      expect(result.isDuplicate, isTrue);
      verify(() => repository.duplicateTemplate('tmpl-1')).called(1);
    });

    test('propaga error cuando el template origen no existe', () async {
      when(() => repository.duplicateTemplate(any()))
          .thenThrow(Exception('Not found'));
      final useCase = DuplicateTemplateUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('GetTemplateAnalyticsUseCase', () {
    test('retorna analytics del template con métricas correctas', () async {
      final analytics = _buildAnalytics(templateId: 'tmpl-1', tenantsCount: 12);
      when(() => repository.getTemplateAnalytics('tmpl-1'))
          .thenAnswer((_) async => analytics);
      final useCase = GetTemplateAnalyticsUseCase(repository);

      final result = await useCase.execute('tmpl-1');

      expect(result.templateId, 'tmpl-1');
      expect(result.tenantsCount, 12);
      expect(result.hasBeenUsed, isTrue);
      verify(() => repository.getTemplateAnalytics('tmpl-1')).called(1);
    });

    test('retorna analytics con tenantsCount=0 cuando no fue usado', () async {
      final analytics = _buildAnalytics(tenantsCount: 0, completionRate: 0.0);
      when(() => repository.getTemplateAnalytics('tmpl-unused'))
          .thenAnswer((_) async => analytics);
      final useCase = GetTemplateAnalyticsUseCase(repository);

      final result = await useCase.execute('tmpl-unused');

      expect(result.hasBeenUsed, isFalse);
      expect(result.isCompletionAcceptable, isFalse);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.getTemplateAnalytics(any()))
          .thenThrow(Exception('Not found'));
      final useCase = GetTemplateAnalyticsUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('GenerateTemplateWithAIUseCase', () {
    test('genera template a partir de descripción y businessTypeId', () async {
      final generated = _buildTemplate(
        id: 'ai-tmpl-1',
        name: 'Ferretería Urbana (IA)',
        categoryIds: ['cat-tornillos', 'cat-herramientas', 'cat-electrico'],
      );
      when(() => repository.generateTemplateWithAI(any(), any()))
          .thenAnswer((_) async => generated);
      final useCase = GenerateTemplateWithAIUseCase(repository);

      final result = await useCase.execute(
        'Ferretería mediana en zona urbana, principalmente tornillos y herramientas',
        'bt-1',
      );

      expect(result.id, 'ai-tmpl-1');
      expect(result.categoryIds.length, 3);
      verify(() => repository.generateTemplateWithAI(
            'Ferretería mediana en zona urbana, principalmente tornillos y herramientas',
            'bt-1',
          )).called(1);
    });

    test('lanza AIGenerationTimeoutException cuando la IA supera el timeout',
        () async {
      // Usamos timeout de 50ms para no bloquear el test suite.
      // El repositorio responde en 200ms → simula latencia real alta.
      when(() => repository.generateTemplateWithAI(any(), any()))
          .thenAnswer((_) => Future.delayed(
                const Duration(milliseconds: 200),
                () => _buildTemplate(),
              ));
      final useCase = GenerateTemplateWithAIUseCase(
        repository,
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        () => useCase.execute('descripción', 'bt-1'),
        throwsA(isA<AIGenerationTimeoutException>()),
      );
    });

    test('propaga error del repositorio sin modificarlo', () async {
      when(() => repository.generateTemplateWithAI(any(), any()))
          .thenThrow(Exception('AI gateway unavailable'));
      final useCase = GenerateTemplateWithAIUseCase(repository);

      expect(
        () => useCase.execute('descripción', 'bt-1'),
        throwsException,
      );
    });

    test('AIGenerationTimeoutException tiene mensaje descriptivo', () {
      const exception = AIGenerationTimeoutException();
      expect(exception.message, isNotEmpty);
      expect(exception.toString(), contains('AIGenerationTimeoutException'));
    });
  });
}
