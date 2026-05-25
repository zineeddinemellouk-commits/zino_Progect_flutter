import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ========================================
// App Theme
// Centralizes the visual palette, spacing,
// and typography for the whole application.
// ========================================

/// Comprehensive app theme configuration for light and dark modes
/// Includes Material 3 design with proper color schemes and component styling
class AppTheme {
  // ── Font Configuration ─────────────────────────────────────────
  static const String poppinsFont = 'Poppins';
  static const String cairnFont = 'Cairo';
  // ── Light Theme Colors ─────────────────────────────────────────
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightPrimaryDark = Color(0xFF004AC6);
  static const Color lightSecondary = Color(0xFF06B6D4);
  static const Color lightAccent = Color(0xFF8B5CF6);
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFD1D5DB);

  // ── Dark Theme Colors ──────────────────────────────────────────
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkPrimaryDark = Color(0xFF1E40AF);
  static const Color darkSecondary = Color(0xFF22D3EE);
  static const Color darkAccent = Color(0xFFA78BFA);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkDivider = Color(0xFF64748B);

  // ── Light Theme ────────────────────────────────────────────────
  static ThemeData lightTheme() {
    final textTheme = GoogleFonts.poppinsTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: poppinsFont,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        onSurface: lightOnSurface,
        error: lightError,
        background: lightBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: lightPrimary.withOpacity(0.05),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackground,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        labelStyle: const TextStyle(color: lightOnSurface),
        prefixIconColor: lightPrimary,
        suffixIconColor: lightPrimary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightError, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: lightSurface,
        textColor: lightOnSurface,
        iconColor: lightPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 16,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Color(0xFF9CA3AF),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightOnSurface,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: lightBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      // FIXED: Use GoogleFonts.poppinsTextTheme for consistent Poppins font
      textTheme: textTheme.apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────
  static ThemeData darkTheme() {
    final textTheme = GoogleFonts.poppinsTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: poppinsFont,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Color(0xFF0F172A),
        secondary: darkSecondary,
        surface: darkSurface,
        onSurface: darkOnSurface,
        error: darkError,
        background: darkBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: darkPrimary.withOpacity(0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Color(0xFF0F172A),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        labelStyle: const TextStyle(color: darkOnSurface),
        prefixIconColor: darkPrimary,
        suffixIconColor: darkPrimary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkError, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: darkSurface,
        textColor: darkOnSurface,
        iconColor: darkPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 16,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: Color(0xFF94A3B8),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: darkOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: darkBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      // FIXED: Use GoogleFonts.poppinsTextTheme for consistent Poppins font
      textTheme: textTheme.apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      ),
    );
  }
}
