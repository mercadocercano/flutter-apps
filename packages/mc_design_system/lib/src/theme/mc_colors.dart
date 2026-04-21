import 'package:flutter/material.dart';

/// Paleta de colores de Mercado Cercano.
/// Fuente: MANUAL_MARCA.md + globals.css del frontend actual.
abstract final class McColors {
  // ─── Primarios ───
  /// Cobalto — color dominante en interfaces y materiales.
  static const primary = Color(0xFF0A21C0);

  /// Púrpura — acento para CTAs, badges, highlights.
  static const secondary = Color(0xFF9333EA);

  // ─── Semánticos ───
  static const error = Color(0xFFE74C3C);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2563EB);

  // ─── Neutros (Light) ───
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const foregroundLight = Color(0xFF0F172A);
  static const mutedLight = Color(0xFFF1F5F9);
  static const borderLight = Color(0xFFE2E8F0);
  static const textSecondaryLight = Color(0xFFAAB7B8);

  // ─── Neutros (Dark) ───
  static const backgroundDark = Color(0xFF050C40);
  static const surfaceDark = Color(0xFF0A1157);
  static const foregroundDark = Color(0xFFE2E8F0);
  static const mutedDark = Color(0xFF1E2A5E);
  static const borderDark = Color(0xFF2E3A6E);

  // ─── Primary variants ───
  static const primaryLight = Color(0xFF2E45D4);
  static const primaryDark = Color(0xFF0818A0);
  static const secondaryLight = Color(0xFFAB5CF0);
  static const secondaryDark = Color(0xFF7C22D0);
}
