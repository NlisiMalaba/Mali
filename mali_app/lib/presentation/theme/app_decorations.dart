import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

/// Shared visual primitives for the Master of Coin "Navy & Silver" system.
class AppDecorations {
  const AppDecorations._();

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 22;
  static const double radiusHero = 28;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.navy,
      AppColors.navy,
    ],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.navy,
      AppColors.navy,
    ],
  );

  static BoxDecoration heroCard({double radius = radiusHero}) {
    return BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: navyShadow(),
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

  /// Deep, tinted shadow that makes navy cards feel lifted off the page.
  static List<BoxShadow> navyShadow() {
    return [
      BoxShadow(
        color: AppColors.navy.withValues(alpha: 0.45),
        blurRadius: 40,
        spreadRadius: -12,
        offset: const Offset(0, 24),
      ),
    ];
  }

  /// Small rounded square holding a category or setting icon.
  static BoxDecoration iconTile(Color tint, {double radius = radiusSm}) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static List<BoxShadow> softCardShadow() {
    return [
      BoxShadow(
        color: AppColors.navy.withValues(alpha: 0.05),
        blurRadius: 16,
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
