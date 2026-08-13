import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E293B); // Slate 800
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color accent = Color(0xFF10B981); // Emerald 500
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color cardColor = Colors.white;
  static const Color textMain = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textMain,
        displayColor: primaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryDark),
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: textMuted, fontWeight: FontWeight.normal, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent);
          }
          return const IconThemeData(color: textMuted);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      useMaterial3: true,
    );
  }
}
