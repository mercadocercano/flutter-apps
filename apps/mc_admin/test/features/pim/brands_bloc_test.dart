import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mc_admin/features/pim/brands/blocs/brands_bloc.dart';
import 'package:mc_admin/features/pim/brands/blocs/brand_form_bloc.dart';

class MockGetBrandsUseCase extends Mock implements GetBrandsUseCase {}
class MockCreateBrandUseCase extends Mock implements CreateBrandUseCase {}
class MockUpdateBrandUseCase extends Mock implements UpdateBrandUseCase {}
class MockDeleteBrandUseCase extends Mock implements DeleteBrandUseCase {}
class MockVerifyBrandUseCase extends Mock implements VerifyBrandUseCase {}
class MockUnverifyBrandUseCase extends Mock implements UnverifyBrandUseCase {}

MarketplaceBrand _buildBrand({String id = 'brand-1'}) {
  final now = DateTime(2024, 6, 15);
  return MarketplaceBrand(
    id: id,
    name: 'Nike',
    slug: 'nike',
    createdAt: now,
    updatedAt: now,
  );
}

PaginatedResult<MarketplaceBrand> _buildPage([int count = 2]) {
  return PaginatedResult<MarketplaceBrand>(
    items: List.generate(count, (i) => _buildBrand(id: 'brand-$i')),
    totalCount: count,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );
}

void main() {
  late MockGetBrandsUseCase getBrandsUseCase;

  setUp(() {
    getBrandsUseCase = MockGetBrandsUseCase();
    registerFallbackValue(BrandVerificationStatus.unverified);
    registerFallbackValue(const CreateBrandParams(name: 'x'));
    registerFallbackValue(const UpdateBrandParams());
  });

  group('BrandsBloc', () {
    blocTest<BrandsBloc, BrandsState>(
      'emite [Loading, Loaded] al cargar exitosamente',
      build: () {
        when(() => getBrandsUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage());
        return BrandsBloc(getAll: getBrandsUseCase);
      },
      act: (bloc) => bloc.add(LoadBrandsEvent()),
      expect: () => [
        isA<BrandsLoading>(),
        isA<BrandsLoaded>(),
      ],
    );

    blocTest<BrandsBloc, BrandsState>(
      'emite [Loading, Error] cuando el use case falla',
      build: () {
        when(() => getBrandsUseCase.execute(1, 20))
            .thenThrow(Exception('Network error'));
        return BrandsBloc(getAll: getBrandsUseCase);
      },
      act: (bloc) => bloc.add(LoadBrandsEvent()),
      expect: () => [
        isA<BrandsLoading>(),
        isA<BrandsError>(),
      ],
    );

    blocTest<BrandsBloc, BrandsState>(
      'BrandsLoaded contiene las marcas correctas',
      build: () {
        when(() => getBrandsUseCase.execute(1, 20))
            .thenAnswer((_) async => _buildPage(3));
        return BrandsBloc(getAll: getBrandsUseCase);
      },
      act: (bloc) => bloc.add(LoadBrandsEvent()),
      expect: () => [
        isA<BrandsLoading>(),
        isA<BrandsLoaded>().having((s) => s.brands.length, 'brands count', 3),
      ],
    );

    blocTest<BrandsBloc, BrandsState>(
      'pasa filtros verificationStatus e isActive al use case',
      build: () {
        when(() => getBrandsUseCase.execute(
              1,
              20,
              verificationStatus: BrandVerificationStatus.verified,
              isActive: true,
            )).thenAnswer((_) async => _buildPage());
        return BrandsBloc(getAll: getBrandsUseCase);
      },
      act: (bloc) => bloc.add(LoadBrandsEvent(
        verificationStatus: BrandVerificationStatus.verified,
        isActive: true,
      )),
      verify: (_) {
        verify(() => getBrandsUseCase.execute(
              1,
              20,
              verificationStatus: BrandVerificationStatus.verified,
              isActive: true,
            )).called(1);
      },
    );

    blocTest<BrandsBloc, BrandsState>(
      'pasa searchQuery al use case como name',
      build: () {
        when(() => getBrandsUseCase.execute(1, 20, name: 'nike'))
            .thenAnswer((_) async => _buildPage(1));
        return BrandsBloc(getAll: getBrandsUseCase);
      },
      act: (bloc) => bloc.add(LoadBrandsEvent(searchQuery: 'nike')),
      verify: (_) {
        verify(() => getBrandsUseCase.execute(1, 20, name: 'nike')).called(1);
      },
    );

    blocTest<BrandsBloc, BrandsState>(
      'ChangeBrandsPageEvent carga la página correcta',
      build: () {
        when(() => getBrandsUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildPage());
        return BrandsBloc(getAll: getBrandsUseCase);
      },
      act: (bloc) async {
        bloc.add(LoadBrandsEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ChangeBrandsPageEvent(2));
      },
      skip: 2,
      expect: () => [
        isA<BrandsLoading>(),
        isA<BrandsLoaded>(),
      ],
    );

    test('BrandsLoaded.totalPages calcula correctamente', () {
      final state = BrandsLoaded(
        brands: const [],
        currentPage: 1,
        pageSize: 10,
        totalItems: 25,
      );
      expect(state.totalPages, 3);
    });

    test('BrandsError guarda el mensaje', () {
      final state = BrandsError('Error de red');
      expect(state.message, 'Error de red');
    });
  });

  group('BrandFormBloc', () {
    late MockCreateBrandUseCase createUseCase;
    late MockUpdateBrandUseCase updateUseCase;
    late MockDeleteBrandUseCase deleteUseCase;
    late MockVerifyBrandUseCase verifyUseCase;
    late MockUnverifyBrandUseCase unverifyUseCase;

    setUp(() {
      createUseCase = MockCreateBrandUseCase();
      updateUseCase = MockUpdateBrandUseCase();
      deleteUseCase = MockDeleteBrandUseCase();
      verifyUseCase = MockVerifyBrandUseCase();
      unverifyUseCase = MockUnverifyBrandUseCase();
    });

    BrandFormBloc buildBloc() => BrandFormBloc(
          create: createUseCase,
          update: updateUseCase,
          delete: deleteUseCase,
          verify: verifyUseCase,
          unverify: unverifyUseCase,
        );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Success] al crear exitosamente',
      build: () {
        when(() => createUseCase.execute(any()))
            .thenAnswer((_) async => _buildBrand());
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitCreateBrandEvent(
        const CreateBrandParams(name: 'Nike'),
      )),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormSuccess>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Error] cuando crear falla',
      build: () {
        when(() => createUseCase.execute(any())).thenThrow(Exception('Error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitCreateBrandEvent(
        const CreateBrandParams(name: 'Nike'),
      )),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormError>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Success] al actualizar exitosamente',
      build: () {
        when(() => updateUseCase.execute(any(), any()))
            .thenAnswer((_) async => _buildBrand());
        return buildBloc();
      },
      act: (bloc) => bloc.add(SubmitUpdateBrandEvent(
        id: 'brand-1',
        params: const UpdateBrandParams(name: 'Actualizado'),
      )),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormSuccess>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Deleted] al eliminar exitosamente',
      build: () {
        when(() => deleteUseCase.execute(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteBrandFormEvent('brand-1')),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormDeleted>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Error] cuando eliminar falla',
      build: () {
        when(() => deleteUseCase.execute(any()))
            .thenThrow(Exception('Forbidden'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteBrandFormEvent('brand-1')),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormError>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Success] al verificar exitosamente',
      build: () {
        when(() => verifyUseCase.execute('brand-1'))
            .thenAnswer((_) async => _buildBrand());
        return buildBloc();
      },
      act: (bloc) => bloc.add(VerifyBrandFormEvent('brand-1')),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormSuccess>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Success] al desverificar exitosamente',
      build: () {
        when(() => unverifyUseCase.execute('brand-1'))
            .thenAnswer((_) async => _buildBrand());
        return buildBloc();
      },
      act: (bloc) => bloc.add(UnverifyBrandFormEvent('brand-1')),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormSuccess>(),
      ],
    );

    blocTest<BrandFormBloc, BrandFormState>(
      'emite [Submitting, Error] cuando verificar falla',
      build: () {
        when(() => verifyUseCase.execute(any()))
            .thenThrow(Exception('Not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(VerifyBrandFormEvent('missing')),
      expect: () => [
        isA<BrandFormSubmitting>(),
        isA<BrandFormError>(),
      ],
    );
  });
}
