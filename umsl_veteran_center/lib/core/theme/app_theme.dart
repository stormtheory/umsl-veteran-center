// lib/core/theme/app_theme.dart
//
// UMSL Veterans Center color palette and Material 3 theme definitions.
//
// Brand colors pulled from the UMSL Veterans Center logo:
//   Primary red:  #B22222 (firebrick — matches the logo's "Veterans Center" bar)
//   Deep red:     #8B0000 (darkred — used for borders, shadows, emphasis)
//   Gold:         #C0A060 (antique gold — star strip accent)
//   Dark bg:      #0D0D14 (near-black with a slight blue-navy tint)

import 'package:flutter/material.dart';
import 'vet_theme.dart';

class AppTheme {
  // ---- Brand color constants -----------------------------------------------

  /// Primary action color — UMSL Veterans Center red
  static const primaryRed = Color(0xFFB22222);

  /// Darker red for borders, glows, and emphasis
  static const deepRed = Color(0xFF8B0000);

  /// Antique gold — star strip / label accent in dark mode
  static const accentGold = Color(0xFFC0A060);

  /// Main dark scaffold background
  static const darkBackground = Color(0xFF0D0D14);

  /// Slightly lighter surface for cards in dark mode
  static const darkSurface = Color(0xFF1E1E2E);

  /// Card/input field background in dark mode
  static const darkInputBg = Color(0xFF16161F);

  /// Light theme scaffold background
  static const lightBackground = Color(0xFFF2F2F7);

  /// Light theme card/surface color
  static const lightSurface = Color(0xFFFFFFFF);

  /// Light theme card border color
  static const lightBorder = Color(0xFFE0E0E0);

  // ---- Dark theme ----------------------------------------------------------

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryRed,
      onPrimary: Colors.white,
      secondary: accentGold,
      onSecondary: Colors.black,
      surface: darkSurface,
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
    ),

    // Input field decoration applied globally
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputBg,
      hintStyle: const TextStyle(color: Color(0xFF444455)),
      labelStyle: const TextStyle(color: accentGold),
      errorStyle: const TextStyle(color: Color(0xFFCF6679), fontSize: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
      ),
    ),

    // Elevated button defaults — override per-button when needed
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    extensions: const [VetTheme.dark],

    // Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white60),
    ),
  );

  // ---- Light theme ---------------------------------------------------------

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: deepRed,
      onPrimary: Colors.white,
      secondary: accentGold,
      onSecondary: Colors.black,
      surface: Color(0xFFF8F8F8),
      onSurface: Color(0xFF0D0D14),
      error: Color(0xFFB00020),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      hintStyle: const TextStyle(color: Colors.black38),
      errorStyle: const TextStyle(color: Color(0xFFB00020), fontSize: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: deepRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB00020)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    extensions: const [VetTheme.light],

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0D0D14),
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0D0D14),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF0D0D14)),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
      bodySmall: TextStyle(fontSize: 12, color: Colors.black45),
    ),
  );
}
