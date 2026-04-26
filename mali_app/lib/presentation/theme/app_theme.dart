import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.tealPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.tealPrimaryLight,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.tealPrimaryLight,
      onPrimary: Colors.black,
      secondary: AppColors.tealPrimary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color bodyColor) {
    return TextTheme(
      displayLarge: TextStyle(color: bodyColor, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(color: bodyColor, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(color: bodyColor, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: bodyColor, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: bodyColor, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: bodyColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: bodyColor, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: bodyColor),
      bodyMedium: TextStyle(color: bodyColor),
      bodySmall: TextStyle(color: bodyColor.withValues(alpha: 0.8)),
      labelLarge: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: bodyColor.withValues(alpha: 0.9)),
      labelSmall: TextStyle(color: bodyColor.withValues(alpha: 0.8)),
    );
  }
}
