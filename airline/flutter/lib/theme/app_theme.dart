import 'package:flutter/material.dart';

class EldiyarTheme {
  // Color Palette
  // Neo-Aviation Color Palette
  static const Color primaryBlue = Color(0xFF3DF2E1); // Neon Cyan
  static const Color secondaryPurple = Color(0xFF0E1624); // Dark Blue Gradient Base
  static const Color accentTeal = Color(0xFF3DF2E1); // Same as primary
  static const Color accentAmber = Color(0xFFFFB703); // Aviation Amber
  static const Color darkBackground = Color(0xFF0B0F14); // Deep Graphite Black
  static const Color darkerBackground = Color(0xFF05070A); // Almost Black
  static const Color cardBackground = Color(0xFF131820); // Darker Card
  static const Color textPrimary = Color(0xFFE8E8E8); // Soft white
  static const Color textSecondary = Color(0xFF9CA3AF); // Light grey
  static const Color errorRed = Color(0xFFFF3B30); // Emergency Red
  static const Color successGreen = Color(0xFF34C759); // Success Green

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkerBackground,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryPurple,
        tertiary: accentTeal,
        error: errorRed,
        surface: cardBackground,
        onPrimary: darkerBackground,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryBlue.withOpacity(0.3), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue.withOpacity(0.2),
          foregroundColor: primaryBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primaryBlue.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
    );
  }

  // Glow effect decoration
  static BoxDecoration glowDecoration({
    Color color = primaryBlue,
    double blurRadius = 20,
    double spreadRadius = 0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.5),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }

  // Glassmorphism decoration
  static BoxDecoration glassDecoration() {
    return BoxDecoration(
      color: cardBackground.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
