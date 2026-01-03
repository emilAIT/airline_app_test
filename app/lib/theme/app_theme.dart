import 'package:flutter/material.dart';

class AppTheme {
  // Pink color palette inspired by shadcn
  static const Color pink50 = Color(0xFFFDF2F8);
  static const Color pink100 = Color(0xFFFCE7F3);
  static const Color pink200 = Color(0xFFFBCFE8);
  static const Color pink300 = Color(0xFFF9A8D4);
  static const Color pink400 = Color(0xFFF472B6);
  static const Color pink500 = Color(0xFFEC4899);
  static const Color pink600 = Color(0xFFDB2777);
  static const Color pink700 = Color(0xFFBE185D);
  static const Color pink800 = Color(0xFF9F1239);
  static const Color pink900 = Color(0xFF831843);
  static const Color pink950 = Color(0xFF500724);

  // Dark theme colors (Netflix-inspired)
  static const Color dark900 = Color(0xFF0A0A0A);
  static const Color dark800 = Color(0xFF141414);
  static const Color dark700 = Color(0xFF1A1A1A);
  static const Color dark600 = Color(0xFF2A2A2A);
  static const Color dark500 = Color(0xFF3A3A3A);
  static const Color dark400 = Color(0xFF4A4A4A);

  // Neutral colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  static const Color neutral950 = Color(0xFF0A0A0A);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Netflix uses dark theme
      colorScheme: ColorScheme.dark(
        primary: pink600,
        onPrimary: Colors.white,
        primaryContainer: pink900,
        onPrimaryContainer: pink100,
        secondary: pink400,
        onSecondary: Colors.white,
        secondaryContainer: pink800,
        onSecondaryContainer: pink200,
        tertiary: pink300,
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFE5E5),
        onErrorContainer: Color(0xFF7F1D1D),
        surface: dark800,
        onSurface: Colors.white,
        surfaceContainerHighest: dark600,
        onSurfaceVariant: neutral400,
        outline: dark500,
        outlineVariant: dark600,
        shadow: Colors.black.withOpacity(0.5),
        scrim: Colors.black.withOpacity(0.8),
        inverseSurface: neutral100,
        onInverseSurface: dark900,
        inversePrimary: pink400,
      ),
      scaffoldBackgroundColor: dark900,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: dark700,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: dark900,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: pink600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return dark500;
            }
            if (states.contains(MaterialState.pressed)) {
              return pink700;
            }
            return pink600;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: pink600,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: pink600, width: 2),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pink600,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark700,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark500, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark500, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pink600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: TextStyle(
          color: neutral400,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: neutral500,
          fontSize: 16,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark700,
        deleteIconColor: pink400,
        disabledColor: dark600,
        selectedColor: pink600,
        secondarySelectedColor: pink900,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        brightness: Brightness.dark,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dark600,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: dark700,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: dark800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        contentTextStyle: TextStyle(
          color: neutral300,
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark700,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pink600,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: dark800,
        selectedItemColor: pink600,
        unselectedItemColor: neutral500,
        selectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: dark800,
        elevation: 0,
        shape: Border(
          right: BorderSide(color: dark600, width: 1),
        ),
      ),
    );
  }

  // Helper method to get status colors
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'CONFIRMED':
      case 'SCHEDULED':
        return success;
      case 'PENDING':
      case 'CREATED':
        return warning;
      case 'FAILED':
      case 'CANCELLED':
        return error;
      case 'DELAYED':
        return info;
      default:
        return neutral500;
    }
  }

  // Helper method to get badge style
  static BoxDecoration getBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
    );
  }

  // Netflix-style gradient overlay
  static BoxDecoration getGradientOverlay() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          dark900.withOpacity(0.7),
          dark900,
        ],
        stops: [0.0, 0.7, 1.0],
      ),
    );
  }

  // Pink gradient for hero sections
  static LinearGradient getPinkGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [pink600, pink800],
    );
  }
}
