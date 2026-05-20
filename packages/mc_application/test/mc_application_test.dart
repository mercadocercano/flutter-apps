import 'package:mc_application/mc_application.dart';
import 'package:test/test.dart';

void main() {
  group('AuthSession', () {
    AuthSession buildSession({required DateTime expiresAt}) => AuthSession(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          userId: 'user-123',
          tenantId: 'tenant-abc',
          email: 'comerciante@test.com',
          role: 'admin',
          expiresAt: expiresAt,
        );

    test('TestAuthSession_ExpiredToken_IsExpiredTrue', () {
      final session = buildSession(
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(session.isExpired, isTrue);
    });

    test('TestAuthSession_FutureToken_IsExpiredFalse', () {
      final session = buildSession(
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(session.isExpired, isFalse);
    });
  });

  group('BrandPage', () {
    test('TestBrandPage_MorePagesExist_HasMoreTrue', () {
      // page=1, pageSize=10, totalCount=25 → 10 < 25
      final page = BrandPage(items: const [], totalCount: 25, page: 1, pageSize: 10);
      expect(page.hasMore, isTrue);
    });

    test('TestBrandPage_LastPage_HasMoreFalse', () {
      // page=3, pageSize=10, totalCount=25 → 30 >= 25
      final page = BrandPage(items: const [], totalCount: 25, page: 3, pageSize: 10);
      expect(page.hasMore, isFalse);
    });

    test('TestBrandPage_ExactCount_HasMoreFalse', () {
      // page=2, pageSize=10, totalCount=20 → 20 not < 20
      final page = BrandPage(items: const [], totalCount: 20, page: 2, pageSize: 10);
      expect(page.hasMore, isFalse);
    });
  });

  group('ProductPage', () {
    test('TestProductPage_MorePagesExist_HasMoreTrue', () {
      final page = ProductPage(items: const [], totalCount: 100, page: 1, pageSize: 20);
      expect(page.hasMore, isTrue);
    });

    test('TestProductPage_LastPage_HasMoreFalse', () {
      // page=5, pageSize=20, totalCount=100 → 100 not < 100
      final page = ProductPage(items: const [], totalCount: 100, page: 5, pageSize: 20);
      expect(page.hasMore, isFalse);
    });
  });
}
