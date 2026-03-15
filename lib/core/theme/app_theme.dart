import 'package:flutter/material.dart';

class AppTheme {
  // Brand gradient (applied at layout level)
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF000000),
      Color(0xFF6A5AE0),
    ],
  );

  static const Color primary = Color(0xFF6A5AE0);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F1F7);
  static const Color textPrimary = Color(0xFF1E1E2C);
  static const Color textSecondary = Color(0xFF6E6E80);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primary,
      surface: surface,
      surfaceContainerHighest: surfaceVariant,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),

    // ❌ NO scaffoldBackgroundColor
    // Gradient is handled by AppScaffold

    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      foregroundColor: textPrimary,
    ),

cardTheme: CardThemeData(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
),


    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
  );
}
