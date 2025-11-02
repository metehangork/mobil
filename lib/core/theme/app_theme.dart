import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana renkler - Üniversite teması
  static const Color primaryBlue = Color(0xFF2E86AB);
  static const Color secondaryOrange = Color(0xFFF24236);
  static const Color accentGreen = Color(0xFF54C6EB);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGrey = Color(0xFF718096);
  static const Color borderGrey = Color(0xFFE2E8F0);

  static ThemeData lightTheme = _baseLight.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: textDark,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: textGrey,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surfaceWhite,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
  );

  static ThemeData darkTheme = _baseDark;

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: primaryBlue,
    brightness: Brightness.light,
    primary: primaryBlue,
    secondary: secondaryOrange,
    tertiary: accentGreen,
    surface: surfaceWhite,
  ).copyWith(
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    onSurface: textDark,
    outline: borderGrey,
  );

  static final ThemeData _baseLight = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightScheme,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: primaryBlue,
    brightness: Brightness.dark,
    primary: primaryBlue,
    secondary: secondaryOrange,
    tertiary: accentGreen,
  ).copyWith(
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
  );

  static final ThemeData _baseDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
  );
}
