import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/attributes/blocs/attribute_list_bloc.dart';
import 'package:mc_admin/features/pim/attributes/blocs/attribute_form_bloc.dart';
import 'package:mc_admin/features/pim/attributes/blocs/attribute_values_bloc.dart';

// --- Mocks ---

class MockListMarketplaceAttributesUseCase extends Mock
    implements ListMarketplaceAttributesUseCase {}

class MockGetMarketplaceAttributeUseCase extends Mock
    implements GetMarketplaceAttributeUseCase {}

class MockCreateMarketplaceAttributeUseCase extends Mock
    implements CreateMarketplaceAttributeUseCase {}

class MockUpdateMarketplaceAttributeUseCase extends Mock
    implements UpdateMarketplaceAttributeUseCase {}

class MockDeleteMarketplaceAttributeUseCase extends Mock
    implements DeleteMarketplaceAttributeUseCase {}

class MockListAttributeValuesUseCase extends Mock
    implements ListAttributeValuesUseCase {}

class MockCreateAttributeValueUseCase extends Mock
    implements CreateAttributeValueUseCase {}

class MockUpdateAttributeValueUseCase extends Mock
    implements UpdateAttributeValueUseCase {}

class MockDeleteAttributeValueUseCase extends Mock
    implements DeleteAttributeValueUseCase {}

// --- Builders ---

MarketplaceAttribute _buildAttribute({
  String id = 'attr-1',
  AttributeType type = AttributeType.select,
}) {
  final now = DateTime(2024, 6, 15);
  return MarketplaceAttribute(
    id: id,
    name: 'Color',
    slug: 'color',
    type: type,
    isRequired: false,
    isFilterable: true,
    createdAt: now,
    updatedAt: now,
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

AttributeValue _buildValue({String id = 'val-1'}) {
  final now = DateTime(2024, 6, 15);
  return AttributeValue(
    id: id,
    attributeId: 'attr-1',
    value: 'rojo',
    label: 'Rojo',
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
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
  // -----------------------------------------------------------------------
  // AttributeListBloc
  // -----------------------------------------------------------------------

  group('AttributeListBloc', () {
    late MockListMarketplaceAttributesUseCase listUseCase;
    late MockDeleteMarketplaceAttributeUseCase deleteUseCase;

    setUp(() {
      listUseCase = MockListMarketplaceAttributesUseCase();
      deleteUseCase = MockDeleteMarketplaceAttributeUseCase();
    });

    AttributeListBloc buildBloc() => AttributeListBloc(
          list: listUseCase,
          delete: deleteUseCase,
        );

    blocTest<AttributeListBloc, AttributeListState>(
      'LoadAttributesEvent emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => listUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributesEvent()),
      expect: () => [
        isA<AttributeListLoading>(),
        isA<AttributeListLoaded>(),
      ],
    );

    blocTest<AttributeListBloc, AttributeListState>(
      'LoadAttributesEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => listUseCase.execute(1, 20))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributesEvent()),
      expect: () => [
        isA<AttributeListLoading>(),
        isA<AttributeListError>(),
      ],
    );

    blocTest<AttributeListBloc, AttributeListState>(
      'AttributeListLoaded contiene los atributos correctos',
      build: () {
        when(() => listUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(3));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributesEvent()),
      expect: () => [
        isA<AttributeListLoading>(),
        isA<AttributeListLoaded>()
            .having((s) => s.attributes.length, 'attributes count', 3),
      ],
    );

    blocTest<AttributeListBloc, AttributeListState>(
      'pasa filtros search y type al use case',
      build: () {
        when(() => listUseCase.execute(
              1,
              20,
              search: 'color',
              type: AttributeType.select,
            )).thenAnswer((_) async => _buildPage(1));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributesEvent(
        search: 'color',
        type: AttributeType.select,
      )),
      verify: (_) {
        verify(() => listUseCase.execute(
              1,
              20,
              search: 'color',
              type: AttributeType.select,
            )).called(1);
      },
    );

    blocTest<AttributeListBloc, AttributeListState>(
      'RefreshAttributesEvent recarga con los mismos filtros',
      build: () {
        when(() => listUseCase.execute(1, 20, search: 'color'))
            .thenAnswer((_) async => _buildPage(1));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadAttributesEvent(search: 'color'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(RefreshAttributesEvent());
      },
      skip: 2,
      verify: (_) {
        verify(() => listUseCase.execute(1, 20, search: 'color')).called(2);
      },
    );

    blocTest<AttributeListBloc, AttributeListState>(
      'DeleteAttributeEvent refresca la lista al eliminar exitosamente',
      build: () {
        when(() => deleteUseCase.execute('attr-1'))
            .thenAnswer((_) async {});
        when(() => listUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(1));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadAttributesEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(DeleteAttributeEvent('attr-1'));
      },
      skip: 2,
      expect: () => [
        isA<AttributeListLoading>(),
        isA<AttributeListLoaded>(),
      ],
    );

    blocTest<AttributeListBloc, AttributeListState>(
      'DeleteAttributeEvent emite Error con 409',
      build: () {
        when(() => deleteUseCase.execute(any()))
            .thenThrow(_buildDioException(statusCode: 409));
        return buildBloc();
      },
      seed: () => AttributeListLoaded(
        attributes: const [],
        currentPage: 1,
        pageSize: 20,
        totalItems: 0,
      ),
      act: (bloc) => bloc.add(DeleteAttributeEvent('attr-used')),
      expect: () => [
        isA<AttributeListError>().having(
          (s) => s.message,
          'message',
          contains('en uso'),
        ),
      ],
    );

    test('AttributeListLoaded.totalPages calcula correctamente', () {
      final state = AttributeListLoaded(
        attributes: const [],
        currentPage: 1,
        pageSize: 10,
        totalItems: 25,
      );
      expect(state.totalPages, 3);
    });

    test('AttributeListLoaded.totalPages con pageSize 0 retorna 1', () {
      final state = AttributeListLoaded(
        attributes: const [],
        currentPage: 1,
        pageSize: 0,
        totalItems: 10,
      );
      expect(state.totalPages, 1);
    });
  });

  // -----------------------------------------------------------------------
  // AttributeFormBloc
  // -----------------------------------------------------------------------

  group('AttributeFormBloc', () {
    late MockGetMarketplaceAttributeUseCase getUseCase;
    late MockCreateMarketplaceAttributeUseCase createUseCase;
    late MockUpdateMarketplaceAttributeUseCase updateUseCase;

    setUp(() {
      getUseCase = MockGetMarketplaceAttributeUseCase();
      createUseCase = MockCreateMarketplaceAttributeUseCase();
      updateUseCase = MockUpdateMarketplaceAttributeUseCase();
      registerFallbackValue(_buildAttribute());
    });

    AttributeFormBloc buildBloc() => AttributeFormBloc(
          get: getUseCase,
          create: createUseCase,
          update: updateUseCase,
        );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'LoadAttributeEvent emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => getUseCase.execute('attr-1'))
            .thenAnswer((_) async => _buildAttribute());
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributeEvent('attr-1')),
      expect: () => [
        isA<AttributeFormLoading>(),
        isA<AttributeFormLoaded>(),
      ],
    );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'LoadAttributeEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => getUseCase.execute(any()))
            .thenThrow(Exception('Not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributeEvent('missing')),
      expect: () => [
        isA<AttributeFormLoading>(),
        isA<AttributeFormError>(),
      ],
    );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'SubmitAttributeFormEvent con id vacío crea nuevo atributo',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildAttribute());
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        SubmitAttributeFormEvent(_buildAttribute(id: '')),
      ),
      expect: () => [
        isA<AttributeFormSubmitting>(),
        isA<AttributeFormSuccess>(),
      ],
    );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'SubmitAttributeFormEvent con id existente actualiza atributo',
      build: () {
        when(() => updateUseCase.execute(any()))
            .thenAnswer((_) async => _buildAttribute());
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        SubmitAttributeFormEvent(_buildAttribute(id: 'attr-existing')),
      ),
      expect: () => [
        isA<AttributeFormSubmitting>(),
        isA<AttributeFormSuccess>(),
      ],
    );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'SubmitAttributeFormEvent emite Error con 409 en conflicto de slug',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenThrow(_buildDioException(statusCode: 409));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(SubmitAttributeFormEvent(_buildAttribute(id: ''))),
      expect: () => [
        isA<AttributeFormSubmitting>(),
        isA<AttributeFormError>().having(
          (s) => s.message,
          'message',
          contains('slug'),
        ),
      ],
    );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'SubmitAttributeFormEvent emite Error cuando falla con excepción genérica',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenThrow(Exception('Server error'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(SubmitAttributeFormEvent(_buildAttribute(id: ''))),
      expect: () => [
        isA<AttributeFormSubmitting>(),
        isA<AttributeFormError>(),
      ],
    );

    blocTest<AttributeFormBloc, AttributeFormState>(
      'ResetAttributeFormEvent regresa a AttributeFormInitial',
      build: () => buildBloc(),
      seed: () => AttributeFormError('prev error'),
      act: (bloc) => bloc.add(ResetAttributeFormEvent()),
      expect: () => [isA<AttributeFormInitial>()],
    );

    test('AttributeFormSuccess contiene el atributo', () {
      final attr = _buildAttribute();
      final state = AttributeFormSuccess(attr);
      expect(state.attribute.id, 'attr-1');
    });
  });

  // -----------------------------------------------------------------------
  // AttributeValuesBloc
  // -----------------------------------------------------------------------

  group('AttributeValuesBloc', () {
    late MockListAttributeValuesUseCase listUseCase;
    late MockCreateAttributeValueUseCase createUseCase;
    late MockUpdateAttributeValueUseCase updateUseCase;
    late MockDeleteAttributeValueUseCase deleteUseCase;

    setUp(() {
      listUseCase = MockListAttributeValuesUseCase();
      createUseCase = MockCreateAttributeValueUseCase();
      updateUseCase = MockUpdateAttributeValueUseCase();
      deleteUseCase = MockDeleteAttributeValueUseCase();
      registerFallbackValue(_buildValue());
    });

    AttributeValuesBloc buildBloc() => AttributeValuesBloc(
          list: listUseCase,
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
        );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'LoadAttributeValuesEvent emite [Loading, Loaded] exitosamente',
      build: () {
        when(() => listUseCase.execute('attr-1'))
            .thenAnswer((_) async => [_buildValue(), _buildValue(id: 'val-2')]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributeValuesEvent('attr-1')),
      expect: () => [
        isA<AttributeValuesLoading>(),
        isA<AttributeValuesLoaded>()
            .having((s) => s.values.length, 'values count', 2),
      ],
    );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'LoadAttributeValuesEvent emite [Loading, Error] cuando falla',
      build: () {
        when(() => listUseCase.execute(any()))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadAttributeValuesEvent('attr-1')),
      expect: () => [
        isA<AttributeValuesLoading>(),
        isA<AttributeValuesError>(),
      ],
    );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'CreateAttributeValueEvent crea y recarga los valores',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildValue());
        when(() => listUseCase.execute('attr-1'))
            .thenAnswer((_) async => [_buildValue()]);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadAttributeValuesEvent('attr-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(CreateAttributeValueEvent(_buildValue()));
      },
      skip: 2,
      expect: () => [
        isA<AttributeValuesLoading>(),
        isA<AttributeValuesLoaded>(),
      ],
    );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'CreateAttributeValueEvent emite Error cuando falla',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenThrow(Exception('Server error'));
        return buildBloc();
      },
      seed: () => AttributeValuesLoaded(const []),
      act: (bloc) => bloc.add(CreateAttributeValueEvent(_buildValue())),
      expect: () => [isA<AttributeValuesError>()],
    );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'UpdateAttributeValueEvent actualiza y recarga los valores',
      build: () {
        when(() => updateUseCase.execute(any()))
            .thenAnswer((_) async => _buildValue());
        when(() => listUseCase.execute('attr-1'))
            .thenAnswer((_) async => [_buildValue()]);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadAttributeValuesEvent('attr-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(UpdateAttributeValueEvent(_buildValue()));
      },
      skip: 2,
      expect: () => [
        isA<AttributeValuesLoading>(),
        isA<AttributeValuesLoaded>(),
      ],
    );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'DeleteAttributeValueEvent elimina y recarga los valores',
      build: () {
        when(() => deleteUseCase.execute('attr-1', 'val-1'))
            .thenAnswer((_) async {});
        when(() => listUseCase.execute('attr-1'))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadAttributeValuesEvent('attr-1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(DeleteAttributeValueEvent(
          attributeId: 'attr-1',
          valueId: 'val-1',
        ));
      },
      skip: 2,
      expect: () => [
        isA<AttributeValuesLoading>(),
        isA<AttributeValuesLoaded>().having(
          (s) => s.values,
          'values empty',
          isEmpty,
        ),
      ],
    );

    blocTest<AttributeValuesBloc, AttributeValuesState>(
      'DeleteAttributeValueEvent emite Error con 409',
      build: () {
        when(() => deleteUseCase.execute(any(), any()))
            .thenThrow(_buildDioException(statusCode: 409));
        return buildBloc();
      },
      seed: () => AttributeValuesLoaded(const []),
      act: (bloc) => bloc.add(DeleteAttributeValueEvent(
        attributeId: 'attr-1',
        valueId: 'val-used',
      )),
      expect: () => [
        isA<AttributeValuesError>().having(
          (s) => s.message,
          'message',
          contains('en uso'),
        ),
      ],
    );

    test('AttributeValuesLoaded contiene los valores', () {
      final values = [_buildValue(), _buildValue(id: 'val-2')];
      final state = AttributeValuesLoaded(values);
      expect(state.values.length, 2);
    });
  });
}
