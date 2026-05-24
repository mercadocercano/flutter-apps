import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_design_system/mc_design_system.dart';

void main() {
  group('ProductCategoryIcon', () {
    test('TestProductCategoryIcon_Beverage_ReturnsDrinkIcon', () {
      final icon = ProductCategoryIcon.iconFor(category: 'Gaseosas');
      expect(icon, equals(Icons.local_drink_outlined));
    });

    test('TestProductCategoryIcon_Lacteo_ReturnsEggIcon', () {
      final icon = ProductCategoryIcon.iconFor(category: 'Lácteos');
      expect(icon, equals(Icons.egg_alt_outlined));
    });

    test('TestProductCategoryIcon_Alcohol_ReturnsWineIcon', () {
      final icon = ProductCategoryIcon.iconFor(category: 'Vinos');
      expect(icon, equals(Icons.wine_bar_outlined));
    });

    test('TestProductCategoryIcon_UnknownCategory_ReturnsInventoryIcon', () {
      final icon = ProductCategoryIcon.iconFor(category: 'CategoriaDesconocida999');
      expect(icon, equals(Icons.inventory_2_outlined));
    });

    test('TestProductCategoryIcon_NullCategory_UsesBusinessTypeFallback', () {
      final icon = ProductCategoryIcon.iconFor(
        category: null,
        businessType: 'Panadería',
      );
      expect(icon, equals(Icons.bakery_dining_outlined));
    });

    test('TestProductCategoryIcon_BothNull_ReturnsInventoryFallback', () {
      final icon = ProductCategoryIcon.iconFor(category: null, businessType: null);
      expect(icon, equals(Icons.inventory_2_outlined));
    });

    test('TestProductCategoryIcon_AccentedInput_NormalizesAndMatches', () {
      final icon = ProductCategoryIcon.iconFor(category: 'Lácteos');
      expect(icon, equals(Icons.egg_alt_outlined));
    });
  });

  group('McColors', () {
    test('TestMcColors_Primary_IsCobalt', () {
      expect(McColors.primary, equals(const Color(0xFF0A21C0)));
    });

    test('TestMcColors_Secondary_IsPurple', () {
      expect(McColors.secondary, equals(const Color(0xFF9333EA)));
    });

    test('TestMcColors_SemanticTokens_AreCorrect', () {
      expect(McColors.error, equals(const Color(0xFFE74C3C)));
      expect(McColors.success, equals(const Color(0xFF16A34A)));
      expect(McColors.warning, equals(const Color(0xFFF59E0B)));
      expect(McColors.info, equals(const Color(0xFF2563EB)));
    });

    test('TestMcColors_LightNeutrals_AreCorrect', () {
      expect(McColors.backgroundLight, equals(const Color(0xFFF8FAFC)));
      expect(McColors.surfaceLight, equals(const Color(0xFFFFFFFF)));
      expect(McColors.foregroundLight, equals(const Color(0xFF0F172A)));
    });

    test('TestMcColors_DarkNeutrals_AreCorrect', () {
      expect(McColors.backgroundDark, equals(const Color(0xFF050C40)));
      expect(McColors.surfaceDark, equals(const Color(0xFF0A1157)));
      expect(McColors.foregroundDark, equals(const Color(0xFFE2E8F0)));
    });
  });

  group('McSpacing', () {
    test('TestMcSpacing_Tokens_AreCorrect', () {
      expect(McSpacing.xs, equals(4));
      expect(McSpacing.sm, equals(8));
      expect(McSpacing.md, equals(12));
      expect(McSpacing.base, equals(16));
      expect(McSpacing.lg, equals(24));
      expect(McSpacing.xl, equals(32));
      expect(McSpacing.xxl, equals(48));
    });

    test('TestMcSpacing_BorderRadius_AreCorrect', () {
      expect(McSpacing.radiusSm, equals(8));
      expect(McSpacing.radiusMd, equals(10));
      expect(McSpacing.radiusLg, equals(12));
      expect(McSpacing.radiusFull, equals(9999));
    });

    test('TestMcSpacing_TouchTargets_AreCorrect', () {
      expect(McSpacing.touchTargetMin, equals(48));
      expect(McSpacing.touchTargetIdeal, equals(56));
    });

    test('TestMcSpacing_Breakpoints_AreCorrect', () {
      expect(McSpacing.breakpointMobile, equals(375));
      expect(McSpacing.breakpointTablet, equals(640));
      expect(McSpacing.breakpointDesktop, equals(1400));
    });
  });
}
