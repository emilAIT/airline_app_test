import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    // Premium Airline Palette
    const primaryNavy = Color(0xFF0A1E3C);
    const accentGold = Color(0xFFD4AF37); // Metadata Gold
    const background = Color(0xFFF5F7FA);
    const surface = Colors.white;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryNavy,
      
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: accentGold,
        surface: surface,
        error: Color(0xFFE53935),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),

      // ───────────────── AppBar ─────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Glass/Clean look
        foregroundColor: primaryNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primaryNavy,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primaryNavy),
      ),

      // ───────────────── Text ─────────────────
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: primaryNavy,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primaryNavy,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryNavy,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
        ),
      ),

      // ───────────────── Inputs ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        floatingLabelStyle: const TextStyle(color: primaryNavy),
      ),

      // ───────────────── ELEVATED BUTTON ─────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryNavy.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ───────────────── CARDS ─────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // ───────────────── ICON BUTTON ─────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryNavy,
        ),
      ),
    );
  }
}
