import 'package:flutter/material.dart';

/// Dark racing-inspired theme for the pilot dashboard.
///
/// Design rationale:
/// - Pure dark background (#0A0A0F) to maximize contrast under sunlight
/// - Neon accent colors (cyan, green, amber) for high visibility
/// - Rajdhani font: geometric, wide, designed for dashboards and speed
class AppTheme {
  AppTheme._();

  // --- Color Palette ---
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceVariant = Color(0xFF1A1A26);
  static const Color border = Color(0xFF2A2A3A);

  static const Color primary = Color(0xFF00E5FF);       // Cyan — speed
  static const Color secondary = Color(0xFF00E676);      // Green — energy
  static const Color warning = Color(0xFFFFAB00);        // Amber — alerts
  static const Color danger = Color(0xFFFF1744);         // Red — critical
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF888899);
  static const Color textMuted = Color(0xFF555566);

  // --- Font ---
  static const String fontFamily = 'Rajdhani';

  // --- Theme Data ---
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
        onPrimary: background,
        onSecondary: background,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 72,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.0,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.0,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 1.2,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      dividerColor: border,
    );
  }
}
