import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Dual-typeface system: Manrope (display/headline) + Inter (body/label).
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme({required Color bodyColor, required bool isDark}) {
    final manrope = GoogleFonts.manropeTextTheme();
    final inter = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: manrope.displayLarge?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: manrope.displayMedium?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displaySmall: manrope.displaySmall?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
      ),
      headlineLarge: manrope.headlineLarge?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: manrope.headlineMedium?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: manrope.headlineSmall?.copyWith(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: manrope.titleLarge?.copyWith(
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
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      letterSpacing: -1,
    );
  }
}
