import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Dual-typeface system: Space Grotesk (numbers, display, headlines) + Inter
/// (body and labels).
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme({required Color bodyColor, required bool isDark}) {
    final grotesk = GoogleFonts.spaceGroteskTextTheme();
    final inter = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: grotesk.displayLarge?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: grotesk.displayMedium?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displaySmall: grotesk.displaySmall?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineLarge: grotesk.headlineLarge?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: grotesk.headlineMedium?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: grotesk.headlineSmall?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: grotesk.titleLarge?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(color: bodyColor),
      bodyMedium: inter.bodyMedium?.copyWith(color: bodyColor),
      bodySmall: inter.bodySmall?.copyWith(
        color: bodyColor.withValues(alpha: 0.8),
      ),
      labelLarge: inter.labelLarge?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        color: bodyColor.withValues(alpha: 0.9),
        fontWeight: FontWeight.w500,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontSize: 10,
        letterSpacing: 0.8,
      ),
    );
  }

  static TextStyle sectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: AppColors.onSurfaceVariant,
    );
  }

  static TextStyle currencyHero(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      letterSpacing: -1.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Money figures anywhere in the app: Space Grotesk with tabular digits so
  /// amounts don't jitter while counting up.
  static TextStyle money({
    required double fontSize,
    Color color = AppColors.onSurface,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: fontSize >= 28 ? -1.2 : -0.3,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
