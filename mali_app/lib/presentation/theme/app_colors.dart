import 'package:flutter/material.dart';

/// Sovereign Ledger design tokens — "The Sovereign Ledger" palette.
class AppColors {
  const AppColors._();

  // Primary — Wealth Green
  static const Color primary = Color(0xFF00450D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B5E20);
  static const Color onPrimaryContainer = Color(0xFF90D689);
  static const Color primaryFixed = Color(0xFFACF4A4);
  static const Color primaryFixedDim = Color(0xFF91D78A);
  static const Color onPrimaryFixed = Color(0xFF002203);

  // Secondary — Secure Navy
  static const Color secondary = Color(0xFF4C56AF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF959EFD);
  static const Color onSecondaryContainer = Color(0xFF27308A);
  static const Color secondaryFixed = Color(0xFFE0E0FF);
  static const Color secondaryFixedDim = Color(0xFFBDC2FF);

  // Tertiary — Warm Amber
  static const Color tertiary = Color(0xFF553300);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF754700);
  static const Color onTertiaryContainer = Color(0xFFFFB65E);
  static const Color tertiaryFixed = Color(0xFFFFDDBA);
  static const Color tertiaryFixedDim = Color(0xFFFFB865);

  // Surfaces — tonal layering
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF41493E);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color surfaceTint = Color(0xFF2A6B2C);

  // Outline
  static const Color outline = Color(0xFF717A6D);
  static const Color outlineVariant = Color(0xFFC0C9BB);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // Inverse
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color onInverseSurface = Color(0xFFF1F1F1);
  static const Color inversePrimary = Color(0xFF91D78A);

  // Dark mode surfaces
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkOnSurface = Color(0xFFE5E7EB);

  // Legacy aliases (used across existing widgets/tests)
  static const Color tealPrimary = primaryFixedDim;
  static const Color tealPrimaryDark = primaryContainer;
  static const Color tealPrimaryLight = primaryFixed;
  static const Color lightBackground = background;
  static const Color lightSurface = surfaceContainerLowest;
  static const Color lightOnSurface = onSurface;
  static const Color darkOnSurfaceLegacy = darkOnSurface;
}
