/// Spacing tokens de Mercado Cercano.
/// Fuente: tailwind.config.ts del frontend actual.
abstract final class McSpacing {
  // ─── Spacing ───
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ─── Border Radius ───
  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 12;
  static const double radiusFull = 9999;

  // ─── Touch targets ───
  /// Mínimo para POS (cajero apurado, una mano).
  static const double touchTargetMin = 48;

  /// Ideal para POS.
  static const double touchTargetIdeal = 56;

  // ─── Breakpoints ───
  static const double breakpointMobile = 375;
  static const double breakpointTablet = 640;
  static const double breakpointDesktop = 1400;
}
