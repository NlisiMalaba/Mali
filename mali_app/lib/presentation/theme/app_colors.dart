import 'package:flutter/material.dart';

/// Master of Coin design tokens — "Navy & Silver".
///
/// Navy carries the brand (hero cards, the bottom bar, primary buttons) and
/// silver is the accent on navy. Green, amber and red are reserved for meaning:
/// money in / on track, close to a limit, and over a limit or errors.
class AppColors {
  const AppColors._();

  // Brand — Navy & Silver
  static const Color navy = Color(0xFF0B1B3F);
  static const Color navyRaised = Color(0xFF16295A);
  static const Color navyBorder = Color(0xFF2B4580);
  static const Color navyDeep = Color(0xFF070F24);
  static const Color silver = Color(0xFFE6EAF2);
  static const Color silverDim = Color(0xFFC8CFDD);

  /// Muted text and icons placed on navy surfaces.
  static const Color onNavyMuted = Color(0xFFB8C4E0);
  static const Color navInactive = Color(0xFFA3B1D1);

  /// Text links and small interactive accents on light surfaces.
  static const Color link = Color(0xFF2F5BEA);

  // Primary — Navy
  static const Color primary = navy;
  static const Color onPrimary = Color(0xFFF4F6FB);
  static const Color primaryContainer = navyRaised;
  static const Color onPrimaryContainer = onNavyMuted;
  static const Color primaryFixed = silver;
  static const Color primaryFixedDim = silverDim;
  static const Color onPrimaryFixed = navy;

  // Secondary — Link blue
  static const Color secondary = link;
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDCE4FB);
  static const Color onSecondaryContainer = Color(0xFF1E3A8A);
  static const Color secondaryFixed = Color(0xFFE3E8F2);
  static const Color secondaryFixedDim = silverDim;

  // Tertiary — Amber (warnings, "close to limit")
  static const Color tertiary = Color(0xFF8F4A00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF754700);
  static const Color onTertiaryContainer = Color(0xFFFFB65E);
  static const Color tertiaryFixed = Color(0xFFFFE9D1);
  static const Color tertiaryFixedDim = Color(0xFFE8890C);

  // Surfaces — cool grey-blue layering
  static const Color background = Color(0xFFF4F6FB);
  static const Color onBackground = Color(0xFF0F172A);
  static const Color surface = Color(0xFFF4F6FB);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF556079);
  static const Color surfaceBright = Color(0xFFF8F9FC);
  static const Color surfaceDim = Color(0xFFD4DAE6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F9FC);
  static const Color surfaceContainer = Color(0xFFECEFF5);
  static const Color surfaceContainerHigh = Color(0xFFE3E8F2);
  static const Color surfaceContainerHighest = Color(0xFFDCE1EC);
  static const Color surfaceVariant = Color(0xFFE3E8F2);
  static const Color surfaceTint = navy;

  // Outline
  static const Color outline = Color(0xFF8590A6);
  static const Color outlineVariant = Color(0xFFD4DAE6);

  // Semantic
  static const Color error = Color(0xFFB42318);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFDE4E1);
  static const Color onErrorContainer = Color(0xFF7A1A10);
  static const Color success = Color(0xFF0F7A3D);
  /// Soft green chip used on Settings / transaction avatars in the redesign.
  static const Color successContainer = Color(0xFFE6F2DA);
  static const Color warning = Color(0xFFE8890C);

  /// Money leaving the user's wallets in charts ("out" bars and legends).
  static const Color moneyOut = Color(0xFFB85C00);
  static const Color warningText = Color(0xFF8F4A00);
  static const Color warningContainer = Color(0xFFFFE9D1);

  /// Notification bell badge on Home.
  static const Color notificationOrange = Color(0xFFE8590C);

  /// Hairline divider inside settings cards.
  static const Color settingsDivider = Color(0xFFEDF0F6);

  /// Soft blue chip (sync / currency / income).
  static const Color infoContainer = Color(0xFFE3E9FF);
  static const Color info = Color(0xFF3B5BDB);

  /// Budget / amber chip on Settings.
  static const Color budgetChip = Color(0xFFFFF4CC);
  static const Color budgetChipInk = Color(0xFF8A6100);

  /// Exchange-rates purple chip.
  static const Color ratesChip = Color(0xFFF1E4F8);
  static const Color ratesChipInk = Color(0xFF7B3BA3);

  /// Neutral export chip ink.
  static const Color exportInk = Color(0xFF3A4560);

  // Inverse
  static const Color inverseSurface = navy;
  static const Color onInverseSurface = Color(0xFFF4F6FB);
  static const Color inversePrimary = silver;

  // Dark mode surfaces
  static const Color darkBackground = navyDeep;
  static const Color darkSurface = navy;
  static const Color darkOnSurface = silver;

  // Legacy aliases (used across existing widgets/tests)
  static const Color tealPrimary = link;
  static const Color tealPrimaryDark = navy;
  static const Color tealPrimaryLight = silver;
  static const Color lightBackground = background;
  static const Color lightSurface = surfaceContainerLowest;
  static const Color lightOnSurface = onSurface;
  static const Color darkOnSurfaceLegacy = darkOnSurface;
}
