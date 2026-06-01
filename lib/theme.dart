import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Romantic Theme Palette Colors
  static const Color primary = Color(0xFFF05053);      // Sweet Crimson Rose (F05053)
  static const Color primaryDark = Color(0xFFD03B3E);  // Rich Crimson
  static const Color accent = Color(0xFFFF8FA2);       // Sweet Blush Pink
  static const Color backgroundStart = Color(0xFFFFEAEE); // Soft Sunset Pink
  static const Color backgroundEnd = Color(0xFFF5E4FF);   // Lavender Dream
  static const Color cardBg = Color(0xFFFFFFFF);        // Pure White
  static const Color textDark = Color(0xFF2C2525);      // Deep Espresso
  static const Color textLight = Color(0xFF7A6E70);     // Muted Taupe
  static const Color success = Color(0xFF34C759);       // Active Green
  
  // Dark Romantic Theme (optional / premium support)
  static const Color primaryDarkTheme = Color(0xFFFA586A);
  static const Color bgDarkStart = Color(0xFF1F1218);
  static const Color bgDarkEnd = Color(0xFF120D1A);
  static const Color cardBgDark = Color(0xFF291B24);
  static const Color textLightDark = Color(0xFFE5D5DA);

  // Dynamic Background Gradient matching Image 2
  static BoxDecoration romanticGradient({bool isDark = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
          ? [bgDarkStart, bgDarkEnd] 
          : [
              const Color(0xFFFFD5D5), // Top-left soft salmon-pink
              const Color(0xFFFFF9FA), // Creamy clean white middle
              const Color(0xFFE8DBFF), // Top-right gentle lavender
            ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.45, 1.0],
      ),
    );
  }

  // Visual card shadow
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: const Color(0xFFF05053).withValues(alpha: 0.06),
      spreadRadius: 2,
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF2C2525).withValues(alpha: 0.03),
      spreadRadius: 1,
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: const Color(0xFFF05053).withValues(alpha: 0.3),
      spreadRadius: 1,
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // Primary MaterialApp Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: cardBg,
        error: Colors.redAccent,
      ),
      fontFamily: GoogleFonts.quicksand().fontFamily,
      scaffoldBackgroundColor: const Color(0xFFFFF9FA),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.quicksand(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.quicksand(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displaySmall: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
        labelLarge: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x4DF05053),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        hintStyle: const TextStyle(
          color: Color(0x99796E70),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.pink.withValues(alpha: 0.08), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
