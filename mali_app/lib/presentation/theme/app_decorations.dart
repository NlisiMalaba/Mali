import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Shared visual primitives for the Sovereign Ledger design system.
class AppDecorations {
  const AppDecorations._();

  static const double radiusMd = 12;
  static const double radiusXl = 24;
  static const double radiusHero = 32;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      AppColors.primaryContainer,
      AppColors.secondary,
    ],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      AppColors.primaryContainer,
    ],
  );

  static BoxDecoration heroCard({double radius = radiusHero}) {
    return BoxDecoration(
      gradient: heroGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: ambientShadow(),
    );
  }

  static BoxDecoration surfaceCard({
    Color? color,
    double radius = radiusXl,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: withShadow ? softCardShadow() : null,
    );
  }

  static BoxDecoration ghostBorderCard({
    double radius = radiusXl,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.15),
      ),
      boxShadow: softCardShadow(),
    );
  }

  static List<BoxShadow> ambientShadow() {
    return [
      BoxShadow(
        color: AppColors.onSurface.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> softCardShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> bottomNavShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, -12),
      ),
    ];
  }

  /// Glassmorphism surface for floating bars.
  static Widget glassBar({
    required Widget child,
    required Color backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.8),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
