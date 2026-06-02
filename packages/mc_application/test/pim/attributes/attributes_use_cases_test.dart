import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMarketplaceAttributeRepository extends Mock
    implements MarketplaceAttributeRepository {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

final _now = DateTime(2024, 6, 15);

MarketplaceAttribute _buildAttribute({
  String id = 'attr-1',
  AttributeType type = AttributeType.text,
  bool isRequired = false,
  bool isFilterable = false,
  List<AttributeValue> values = const [],
}) {
  return MarketplaceAttribute(
    id: id,
    name: 'Color',
    slug: 'color',
    type: type,
    description: 'Color del producto',
    isRequired: isRequired,
    isFilterable: isFilterable,
    values: values,
    createdAt: _now,
    updatedAt: _now,
  );
}

AttributeValue _buildValue({
  String id = 'val-1',
  String attributeId = 'attr-1',
  int sortOrder = 0,
}) {
  return AttributeValue(
    id: id,
    attributeId: attributeId,
    value: 'rojo',
    label: 'Rojo',
    sortOrder: sortOrder,
    createdAt: _now,
    updatedAt: _now,
  );
}

PaginatedResult<MarketplaceAttribute> _buildPage([int count = 2]) {
  return PaginatedResult<MarketplaceAttribute>(
    items: List.generate(count, (i) => _buildAttribute(id: 'attr-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

// ---------------------------------------------------------------------------

void main() {
  late MockMarketplaceAttributeRepository repository;

  setUp(() {
    repository = MockMarketplaceAttributeRepository();
    registerFallbackValue(_buildAttribute());
    registerFallbackValue(_buildValue());
  });

  // -------------------------------------------------------------------------
  group('ListMarketplaceAttributesUseCase', () {
    test('delega a repository.listAttributes con page y pageSize', () async {
      when(() => repository.listAttributes(page: 1, pageSize: 20))
          .thenAnswer((_) async => _buildPage());
      final useCase = ListMarketplaceAttributesUseCase(repository);

      final result = await useCase.execute(1, 20);

      expect(result.items.length, 2);
      verify(() => repository.listAttributes(page: 1, pageSize: 20)).called(1);
    });

    test('pasa filtros opcionales (search y type) al repositorio', () async {
      when(() => repository.listAttributes(
            search: 'color',
            type: AttributeType.select,
            page: 2,
            pageSize: 10,
          )).thenAnswer((_) async => _buildPage(1));
      final useCase = ListMarketplaceAttributesUseCase(repository);

      await useCase.execute(2, 10, search: 'color', type: AttributeType.select);

      verify(() => repository.listAttributes(
            search: 'color',
            type: AttributeType.select,
            page: 2,
            pageSize: 10,
          )).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.listAttributes(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenThrow(Exception('Network error'));
      final useCase = ListMarketplaceAttributesUseCase(repository);

      expect(() => useCase.execute(1, 20), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('GetMarketplaceAttributeUseCase', () {
    test('retorna el atributo correcto por id', () async {
      final attr = _buildAttribute(id: 'attr-specific');
      when(() => repository.getAttribute('attr-specific'))
          .thenAnswer((_) async => attr);
      final useCase = GetMarketplaceAttributeUseCase(repository);

      final result = await useCase.execute('attr-specific');

      expect(result.id, 'attr-specific');
      verify(() => repository.getAttribute('attr-specific')).called(1);
    });

    test('propaga not found del repositorio', () async {
      when(() => repository.getAttribute('missing'))
          .thenThrow(Exception('Not found'));
      final useCase = GetMarketplaceAttributeUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('CreateMarketplaceAttributeUseCase', () {
    test('crea atributo y retorna entidad con id asignado', () async {
      final input = _buildAttribute(id: '');
      final created = _buildAttribute(id: 'new-attr-id');
      when(() => repository.createAttribute(any()))
          .thenAnswer((_) async => created);
      final useCase = CreateMarketplaceAttributeUseCase(repository);

      final result = await useCase.execute(input);

      expect(result.id, 'new-attr-id');
      verify(() => repository.createAttribute(input)).called(1);
    });

    test('propaga error de conflicto del repositorio', () async {
      when(() => repository.createAttribute(any()))
          .thenThrow(Exception('Conflict: slug already exists'));
      final useCase = CreateMarketplaceAttributeUseCase(repository);

      expect(() => useCase.execute(_buildAttribute()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('UpdateMarketplaceAttributeUseCase', () {
    test('actualiza atributo y retorna entidad actualizada', () async {
      final updated = _buildAttribute(id: 'attr-1', isFilterable: true);
      when(() => repository.updateAttribute(any()))
          .thenAnswer((_) async => updated);
      final useCase = UpdateMarketplaceAttributeUseCase(repository);

      final result = await useCase.execute(_buildAttribute(id: 'attr-1'));

      expect(result.id, 'attr-1');
      verify(() => repository.updateAttribute(any())).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.updateAttribute(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UpdateMarketplaceAttributeUseCase(repository);

      expect(() => useCase.execute(_buildAttribute()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('DeleteMarketplaceAttributeUseCase', () {
    test('elimina atributo correctamente', () async {
      when(() => repository.deleteAttribute('attr-1'))
          .thenAnswer((_) async {});
      final useCase = DeleteMarketplaceAttributeUseCase(repository);

      await useCase.execute('attr-1');

      verify(() => repository.deleteAttribute('attr-1')).called(1);
    });

    test('propaga 409 cuando el atributo está en uso', () async {
      when(() => repository.deleteAttribute(any()))
          .thenThrow(Exception('Attribute in use by products'));
      final useCase = DeleteMarketplaceAttributeUseCase(repository);

      expect(() => useCase.execute('attr-in-use'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('ListAttributeValuesUseCase', () {
    test('retorna lista de valores para el atributo dado', () async {
      final values = [
        _buildValue(id: 'val-1', attributeId: 'attr-1'),
        _buildValue(id: 'val-2', attributeId: 'attr-1'),
      ];
      when(() => repository.listValues('attr-1'))
          .thenAnswer((_) async => values);
      final useCase = ListAttributeValuesUseCase(repository);

      final result = await useCase.execute('attr-1');

      expect(result.length, 2);
      verify(() => repository.listValues('attr-1')).called(1);
    });

    test('retorna lista vacía cuando el atributo no tiene valores', () async {
      when(() => repository.listValues('attr-text'))
          .thenAnswer((_) async => []);
      final useCase = ListAttributeValuesUseCase(repository);

      final result = await useCase.execute('attr-text');

      expect(result, isEmpty);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.listValues(any()))
          .thenThrow(Exception('Not found'));
      final useCase = ListAttributeValuesUseCase(repository);

      expect(() => useCase.execute('missing'), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('CreateAttributeValueUseCase', () {
    test('crea valor y retorna entidad con id asignado', () async {
      final input = _buildValue(id: '');
      final created = _buildValue(id: 'new-val-id');
      when(() => repository.createValue(any()))
          .thenAnswer((_) async => created);
      final useCase = CreateAttributeValueUseCase(repository);

      final result = await useCase.execute(input);

      expect(result.id, 'new-val-id');
      verify(() => repository.createValue(input)).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.createValue(any()))
          .thenThrow(Exception('Conflict: value already exists'));
      final useCase = CreateAttributeValueUseCase(repository);

      expect(() => useCase.execute(_buildValue()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('UpdateAttributeValueUseCase', () {
    test('actualiza valor y retorna entidad actualizada', () async {
      final updated = _buildValue(id: 'val-1', sortOrder: 2);
      when(() => repository.updateValue(any()))
          .thenAnswer((_) async => updated);
      final useCase = UpdateAttributeValueUseCase(repository);

      final result = await useCase.execute(_buildValue(id: 'val-1'));

      expect(result.id, 'val-1');
      verify(() => repository.updateValue(any())).called(1);
    });

    test('propaga error del repositorio', () async {
      when(() => repository.updateValue(any()))
          .thenThrow(Exception('Not found'));
      final useCase = UpdateAttributeValueUseCase(repository);

      expect(() => useCase.execute(_buildValue()), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  group('DeleteAttributeValueUseCase', () {
    test('elimina valor correctamente con attributeId y valueId', () async {
      when(() => repository.deleteValue('attr-1', 'val-1'))
          .thenAnswer((_) async {});
      final useCase = DeleteAttributeValueUseCase(repository);

      await useCase.execute('attr-1', 'val-1');

      verify(() => repository.deleteValue('attr-1', 'val-1')).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(() => repository.deleteValue(any(), any()))
          .thenThrow(Exception('Not found'));
      final useCase = DeleteAttributeValueUseCase(repository);

      expect(() => useCase.execute('attr-x', 'val-x'), throwsException);
    });
  });
}
