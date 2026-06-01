import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockQuickstartRepository extends Mock implements QuickstartRepository {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

final _now = DateTime(2024, 10, 1);

BusinessType _buildBusinessType({
  String id = 'bt-1',
  String name = 'Ferretería',
  String slug = 'ferreteria',
  String? description = 'Comercio de herramientas y materiales',
  String icon = 'hardware',
  bool isActive = true,
  int templateCount = 3,
}) {
  return BusinessType(
    id: id,
    name: name,
    slug: slug,
    description: description,
    icon: icon,
    isActive: isActive,
    templateCount: templateCount,
    createdAt: _now,
    updatedAt: _now,
  );
}

PaginatedResult<BusinessType> _buildPage([int count = 2]) {
  return PaginatedResult<BusinessType>(
    items: List.generate(count, (i) => _buildBusinessType(id: 'bt-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

// ---------------------------------------------------------------------------

void main() {
  late MockQuickstartRepository repository;

  setUp(() {
    repository = MockQuickstartRepository();
    registerFallbackValue(_buildBusinessType());
  });

  // -------------------------------------------------------------------------
  group('ListBusinessTypesUseCase', () {
    test('delega a repository.listBusinessTypes con page y pageSize', () async {
      when(() => repository.listBusinessTypes(page: 1, pageSize: 20))
          .thenAnswer((_) async => _buildPage());
      final useCase = ListBusinessTypesUseCase(repository);

      final result = await useCase.execute(page: 1, pageSize: 20);

      expect(result.items.length, 2);
      verify(() => repository.listBusinessTypes(page: 1, pageSize: 20))
          .called(1);
    });

    test('pasa filtro isActive=true al repositorio', () async {
      when(() => repository.listBusinessTypes(
            isActive: true,
            page: 1,
            pageSize: 20,
          )).thenAnswer((_) async => _buildPage(1));
      final useCase = ListBusinessTypesUseCase(repository);

      await useCase.execute(isActive: true, page: 1, pageSize: 20);

      verify(() => repository.listBusinessTypes(
            isActive: true,
            page: 1,
            pageSize: 20,
          )).called(1);
    });

    test('pasa filtro isActive=false al repositorio', () async {
      when(() => repository.listBusinessTypes(
            isActive: false,
            page: 2,
            pageSize: 10,
          )).thenAnswer((_) async => _buildPage(0));
      final useCase = ListBusinessTypesUseCase(repository);

      await useCase.execute(isActive: false, page: 2, pageSize: 10);

      verify(() => repository.listBusinessTypes(
            isActive: false,
            page: 2,
            pageSize: 10,
          )).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.listBusinessTypes(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenThrow(Exception('Network error'));
      final useCase = ListBusinessTypesUseCase(repository);

      expect(() => useCase.execute(), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('GetBusinessTypeUseCase', () {
    test('retorna el tipo de negocio correcto por id', () async {
      final bt = _buildBusinessType(id: 'bt-specific');
      when(() => repository.getBusinessType('bt-specific'))
          .thenAnswer((_) async => bt);
      final useCase = GetBusinessTypeUseCase(repository);

      final result = await useCase.execute('bt-specific');

      expect(result.id, 'bt-specific');
      expect(result.name, 'Ferretería');
      verify(() => repository.getBusinessType('bt-specific')).called(1);
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.getBusinessType('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetBusinessTypeUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('CreateBusinessTypeUseCase', () {
    test('crea tipo de negocio y retorna entidad con id asignado', () async {
      final input = _buildBusinessType(id: '');
      final created = _buildBusinessType(id: 'new-bt-id');
      when(() => repository.createBusinessType(any()))
          .thenAnswer((_) async => created);
      final useCase = CreateBusinessTypeUseCase(repository);

      final result = await useCase.execute(input);

      expect(result.id, 'new-bt-id');
      verify(() => repository.createBusinessType(input)).called(1);
    });

    test('propaga error de conflicto cuando el slug ya existe', () async {
      when(() => repository.createBusinessType(any()))
          .thenThrow(Exception('Conflict: slug already exists'));
      final useCase = CreateBusinessTypeUseCase(repository);

      expect(() => useCase.execute(_buildBusinessType()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('UpdateBusinessTypeUseCase', () {
    test('actualiza tipo de negocio y retorna entidad actualizada', () async {
      final updated = _buildBusinessType(id: 'bt-1', name: 'Ferretería Pro');
      when(() => repository.updateBusinessType(any()))
          .thenAnswer((_) async => updated);
      final useCase = UpdateBusinessTypeUseCase(repository);

      final result = await useCase.execute(_buildBusinessType(id: 'bt-1'));

      expect(result.id, 'bt-1');
      expect(result.name, 'Ferretería Pro');
      verify(() => repository.updateBusinessType(any())).called(1);
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.updateBusinessType(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UpdateBusinessTypeUseCase(repository);

      expect(() => useCase.execute(_buildBusinessType()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('DeleteBusinessTypeUseCase', () {
    test('elimina tipo de negocio correctamente', () async {
      when(() => repository.deleteBusinessType('bt-1'))
          .thenAnswer((_) async {});
      final useCase = DeleteBusinessTypeUseCase(repository);

      await useCase.execute('bt-1');

      verify(() => repository.deleteBusinessType('bt-1')).called(1);
    });

    test('propaga error 409 cuando el tipo tiene templates asociados', () async {
      when(() => repository.deleteBusinessType(any()))
          .thenThrow(Exception('Cannot delete: business type has templates'));
      final useCase = DeleteBusinessTypeUseCase(repository);

      expect(() => useCase.execute('bt-with-templates'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('ActivateBusinessTypeUseCase', () {
    test('activa el tipo de negocio y retorna entidad con isActive=true',
        () async {
      final activated = _buildBusinessType(id: 'bt-1', isActive: true);
      when(() => repository.activateBusinessType('bt-1'))
          .thenAnswer((_) async => activated);
      final useCase = ActivateBusinessTypeUseCase(repository);

      final result = await useCase.execute('bt-1');

      expect(result.isActive, isTrue);
      verify(() => repository.activateBusinessType('bt-1')).called(1);
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.activateBusinessType('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = ActivateBusinessTypeUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('DeactivateBusinessTypeUseCase', () {
    test('desactiva el tipo de negocio y retorna entidad con isActive=false',
        () async {
      final deactivated = _buildBusinessType(id: 'bt-1', isActive: false);
      when(() => repository.deactivateBusinessType('bt-1'))
          .thenAnswer((_) async => deactivated);
      final useCase = DeactivateBusinessTypeUseCase(repository);

      final result = await useCase.execute('bt-1');

      expect(result.isActive, isFalse);
      verify(() => repository.deactivateBusinessType('bt-1')).called(1);
    });

    test('badge cambia a Inactivo — tipo no aparece en selector de inicio',
        () async {
      final deactivated = _buildBusinessType(
        id: 'bt-ferreteria',
        isActive: false,
      );
      when(() => repository.deactivateBusinessType('bt-ferreteria'))
          .thenAnswer((_) async => deactivated);
      final useCase = DeactivateBusinessTypeUseCase(repository);

      final result = await useCase.execute('bt-ferreteria');

      expect(result.isActive, isFalse);
      expect(result.id, 'bt-ferreteria');
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.deactivateBusinessType('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = DeactivateBusinessTypeUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });
}
