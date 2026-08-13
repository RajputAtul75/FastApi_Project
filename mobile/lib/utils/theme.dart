/// Shared UI constants and theme utilities for NyayaAI.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette - deep civic navy
  static const Color primary = Color(0xFF0C2340);
  static const Color primaryLight = Color(0xFF153A66);
  static const Color primaryDark = Color(0xFF061120);

  // Accent - warm saffron for action
  static const Color accent = Color(0xFFE1650E);
  static const Color accentLight = Color(0xFFFCE4D0);

  // Status colors
  static const Color submitted = Color(0xFF5C6BC0);   // Indigo
  static const Color assigned = Color(0xFFFF9800);     // Orange
  static const Color inProgress = Color(0xFF29B6F6);   // Light Blue
  static const Color resolved = Color(0xFF0B7A3C);     // Green (Tricolor match)

  // Priority colors
  static const Color low = Color(0xFF81C784);
  static const Color medium = Color(0xFFFFCA28);
  static const Color high = Color(0xFFFF7043);
  static const Color critical = Color(0xFFEF5350);

  // Background
  static const Color background = Color(0xFFFBF9F4);   // Paper
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1B1F27);  // Ink
  static const Color textSecondary = Color(0xFF5B6472); // Slate
  static const Color textLight = Color(0xFF8C95A5);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.ibmPlexSansTextTheme().copyWith(
      displayLarge: GoogleFonts.fraunces(fontWeight: FontWeight.w600, color: AppColors.primary),
      displayMedium: GoogleFonts.fraunces(fontWeight: FontWeight.w600, color: AppColors.primary),
      displaySmall: GoogleFonts.fraunces(fontWeight: FontWeight.w600, color: AppColors.primary),
      headlineLarge: GoogleFonts.fraunces(fontWeight: FontWeight.w600, color: AppColors.primary),
      headlineMedium: GoogleFonts.fraunces(fontWeight: FontWeight.w600, color: AppColors.primary),
      headlineSmall: GoogleFonts.fraunces(fontWeight: FontWeight.w500, color: AppColors.primary),
      titleLarge: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, color: AppColors.primary),
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBg,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

// Utility methods
Color getStatusColor(String status) {
  switch (status) {
    case 'Submitted':
      return AppColors.submitted;
    case 'Assigned':
      return AppColors.assigned;
    case 'In Progress':
      return AppColors.inProgress;
    case 'Resolved':
      return AppColors.resolved;
    default:
      return Colors.grey;
  }
}

Color getPriorityColor(String priority) {
  switch (priority) {
    case 'Low':
      return AppColors.low;
    case 'Medium':
      return AppColors.medium;
    case 'High':
      return AppColors.high;
    case 'Critical':
      return AppColors.critical;
    default:
      return Colors.grey;
  }
}

IconData getStatusIcon(String status) {
  switch (status) {
    case 'Submitted':
      return Icons.inbox_rounded;
    case 'Assigned':
      return Icons.assignment_ind_rounded;
    case 'In Progress':
      return Icons.autorenew_rounded;
    case 'Resolved':
      return Icons.check_circle_rounded;
    default:
      return Icons.help_outline;
  }
}
