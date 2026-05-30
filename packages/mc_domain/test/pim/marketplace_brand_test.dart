import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

MarketplaceBrand buildBrand({
  String id = 'brand-1',
  String name = 'Nike',
  String slug = 'nike',
  BrandVerificationStatus verificationStatus = BrandVerificationStatus.unverified,
  bool isActive = true,
  int productCount = 0,
  double qualityScore = 0.0,
}) {
  final now = DateTime(2024, 6, 15);
  return MarketplaceBrand(
    id: id,
    name: name,
    slug: slug,
    verificationStatus: verificationStatus,
    isActive: isActive,
    productCount: productCount,
    qualityScore: qualityScore,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MarketplaceBrand entity', () {
    test('construye correctamente con campos obligatorios', () {
      final brand = buildBrand();
      expect(brand.id, 'brand-1');
      expect(brand.name, 'Nike');
      expect(brand.slug, 'nike');
      expect(brand.verificationStatus, BrandVerificationStatus.unverified);
      expect(brand.isActive, isTrue);
      expect(brand.productCount, 0);
      expect(brand.qualityScore, 0.0);
      expect(brand.categoryTags, isEmpty);
      expect(brand.aliases, isEmpty);
      expect(brand.sources, isEmpty);
    });

    test('campos opcionales son null por defecto', () {
      final brand = buildBrand();
      expect(brand.description, isNull);
      expect(brand.logoUrl, isNull);
      expect(brand.website, isNull);
      expect(brand.backgroundColor, isNull);
      expect(brand.textColor, isNull);
      expect(brand.typography, isNull);
      expect(brand.normalizedName, isNull);
    });

    test('igualdad por valor (Equatable)', () {
      final b1 = buildBrand();
      final b2 = buildBrand();
      expect(b1, equals(b2));
    });

    test('distintos ids generan entidades distintas', () {
      final b1 = buildBrand(id: 'brand-1');
      final b2 = buildBrand(id: 'brand-2');
      expect(b1, isNot(equals(b2)));
    });

    test('distinct name genera entidades distintas', () {
      final b1 = buildBrand(name: 'Nike');
      final b2 = buildBrand(name: 'Adidas');
      expect(b1, isNot(equals(b2)));
    });

    test('isVerified true cuando verificationStatus es verified', () {
      final brand = buildBrand(verificationStatus: BrandVerificationStatus.verified);
      expect(brand.isVerified, isTrue);
    });

    test('isVerified false cuando verificationStatus no es verified', () {
      final b1 = buildBrand(verificationStatus: BrandVerificationStatus.unverified);
      final b2 = buildBrand(verificationStatus: BrandVerificationStatus.pending);
      expect(b1.isVerified, isFalse);
      expect(b2.isVerified, isFalse);
    });

    test('copyWith cambia solo los campos indicados', () {
      final original = buildBrand(name: 'Nike');
      final updated = original.copyWith(name: 'Adidas', productCount: 10);
      expect(updated.name, 'Adidas');
      expect(updated.productCount, 10);
      expect(updated.id, original.id);
      expect(updated.slug, original.slug);
    });

    test('construye con todos los campos opcionales', () {
      final now = DateTime(2024, 6, 15);
      final brand = MarketplaceBrand(
        id: 'full-id',
        name: 'Full Brand',
        slug: 'full-brand',
        normalizedName: 'full brand',
        description: 'Descripcion completa',
        logoUrl: 'https://cdn.example.com/logo.png',
        website: 'https://fullbrand.com',
        verificationStatus: BrandVerificationStatus.verified,
        qualityScore: 9.5,
        productCount: 100,
        categoryTags: ['ropa', 'deportes'],
        aliases: ['Full', 'FB'],
        sources: ['scraped', 'manual'],
        isActive: true,
        backgroundColor: '#FFFFFF',
        textColor: '#000000',
        typography: 'Helvetica',
        createdAt: now,
        updatedAt: now,
      );
      expect(brand.normalizedName, 'full brand');
      expect(brand.description, 'Descripcion completa');
      expect(brand.logoUrl, 'https://cdn.example.com/logo.png');
      expect(brand.website, 'https://fullbrand.com');
      expect(brand.qualityScore, 9.5);
      expect(brand.productCount, 100);
      expect(brand.categoryTags, ['ropa', 'deportes']);
      expect(brand.aliases, ['Full', 'FB']);
      expect(brand.sources, ['scraped', 'manual']);
      expect(brand.backgroundColor, '#FFFFFF');
      expect(brand.textColor, '#000000');
      expect(brand.typography, 'Helvetica');
    });
  });

  group('BrandVerificationStatus enum', () {
    test('todos los valores existen', () {
      expect(BrandVerificationStatus.values.length, 3);
      expect(BrandVerificationStatus.values, containsAll([
        BrandVerificationStatus.verified,
        BrandVerificationStatus.unverified,
        BrandVerificationStatus.pending,
      ]));
    });

    test('fromString verified', () {
      expect(
        BrandVerificationStatus.fromString('verified'),
        BrandVerificationStatus.verified,
      );
    });

    test('fromString pending', () {
      expect(
        BrandVerificationStatus.fromString('pending'),
        BrandVerificationStatus.pending,
      );
    });

    test('fromString unverified', () {
      expect(
        BrandVerificationStatus.fromString('unverified'),
        BrandVerificationStatus.unverified,
      );
    });

    test('fromString null → unverified por defecto', () {
      expect(
        BrandVerificationStatus.fromString(null),
        BrandVerificationStatus.unverified,
      );
    });

    test('fromString valor desconocido → unverified', () {
      expect(
        BrandVerificationStatus.fromString('UNKNOWN'),
        BrandVerificationStatus.unverified,
      );
    });

    test('toApiString retorna el name del enum', () {
      expect(BrandVerificationStatus.verified.toApiString(), 'verified');
      expect(BrandVerificationStatus.unverified.toApiString(), 'unverified');
      expect(BrandVerificationStatus.pending.toApiString(), 'pending');
    });
  });

  group('CreateBrandParams', () {
    test('construye con nombre obligatorio', () {
      const params = CreateBrandParams(name: 'Nueva Marca');
      expect(params.name, 'Nueva Marca');
      expect(params.description, isNull);
      expect(params.logoUrl, isNull);
      expect(params.website, isNull);
      expect(params.backgroundColor, isNull);
      expect(params.textColor, isNull);
      expect(params.typography, isNull);
    });

    test('construye con todos los campos opcionales', () {
      const params = CreateBrandParams(
        name: 'Marca Completa',
        description: 'Descripcion',
        logoUrl: 'https://example.com/logo.png',
        website: 'https://example.com',
        backgroundColor: '#FF0000',
        textColor: '#FFFFFF',
        typography: 'Arial',
      );
      expect(params.description, 'Descripcion');
      expect(params.logoUrl, 'https://example.com/logo.png');
      expect(params.website, 'https://example.com');
      expect(params.backgroundColor, '#FF0000');
      expect(params.textColor, '#FFFFFF');
      expect(params.typography, 'Arial');
    });
  });

  group('UpdateBrandParams', () {
    test('todos los campos son null por defecto', () {
      const params = UpdateBrandParams();
      expect(params.name, isNull);
      expect(params.description, isNull);
      expect(params.logoUrl, isNull);
      expect(params.website, isNull);
      expect(params.backgroundColor, isNull);
      expect(params.textColor, isNull);
      expect(params.typography, isNull);
    });

    test('construye con un subset de campos', () {
      const params = UpdateBrandParams(name: 'Nuevo nombre', textColor: '#FF0000');
      expect(params.name, 'Nuevo nombre');
      expect(params.textColor, '#FF0000');
      expect(params.description, isNull);
    });
  });
}
