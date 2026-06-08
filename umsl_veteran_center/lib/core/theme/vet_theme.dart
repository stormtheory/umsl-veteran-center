// lib/core/theme/vet_theme.dart
//
// Semantic color tokens for the UMSL Vet Center app.
// Every widget reads colors from here via context.vetTheme — never hardcoded.
// Adding a new color: add the field here, set values in _light and _dark below.
//
// Usage in any widget:
//   final t = context.vetTheme;
//   color: t.textPrimary
//   color: t.cardBackground
//   color: t.textOnDark  // always white — for use on colored buttons/bars

import 'package:flutter/material.dart';

@immutable
class VetTheme extends ThemeExtension<VetTheme> {
  // Page backgrounds
  final Color pageBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputBorderFocused;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnDark;    // white — use on colored surfaces only

  // Accent — these stay the same in both modes
  final Color primaryRed;
  final Color deepRed;
  final Color accentGold;

  // Status
  final Color statusGreen;
  final Color statusRed;
  final Color statusAmber;

  // Divider / separator
  final Color divider;

  // Tag / badge backgrounds
  final Color tagBackground;
  final Color tagBorder;

  // Selected pill / segment background (buttons, benefit selectors)
  final Color selectedBackground;
  final Color selectedBorder;
  final Color unselectedBackground;

  const VetTheme({
    required this.pageBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputBorderFocused,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnDark,
    required this.primaryRed,
    required this.deepRed,
    required this.accentGold,
    required this.statusGreen,
    required this.statusRed,
    required this.statusAmber,
    required this.divider,
    required this.tagBackground,
    required this.tagBorder,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.unselectedBackground,
  });

  // ---- Dark theme (default) ------------------------------------------------
  static const dark = VetTheme(
    pageBackground:    Color(0xFF0D0D14),
    cardBackground:    Color(0xFF13131F),
    cardBorder:        Color(0x14FFFFFF), // white 8%
    inputBackground:   Color(0xFF16161F),
    inputBorder:       Color(0xFF2A2A3A),
    inputBorderFocused: Color(0xFFC0A060),
    textPrimary:       Colors.white,
    textSecondary:     Color(0x99FFFFFF), // white 60%
    textTertiary:      Color(0x61FFFFFF), // white 38%
    textOnDark:        Colors.white,
    primaryRed:        Color(0xFFB22222),
    deepRed:           Color(0xFF8B0000),
    accentGold:        Color(0xFFC0A060),
    statusGreen:       Color(0xFF4CAF50),
    statusRed:         Color(0xFFE53935),
    statusAmber:       Color(0xFFEF9F27),
    divider:           Color(0x1AFFFFFF), // white 10%
    tagBackground:       Color(0x1FC0A060),
    tagBorder:           Color(0x33C0A060),
    selectedBackground:  Color(0x47B22222), // red 28% tint
    selectedBorder:      Color(0x80B22222), // red 50%
    unselectedBackground: Color(0x0AFFFFFF), // white 4%
  );

  // ---- Light theme ---------------------------------------------------------
  static const light = VetTheme(
    pageBackground:    Color(0xFFF2F2F7),
    cardBackground:    Color(0xFFFFFFFF),
    cardBorder:        Color(0xFFCCCCCC),
    inputBackground:   Color(0xFFF5F5F5),
    inputBorder:       Color(0xFFDDDDDD),
    inputBorderFocused: Color(0xFF8B0000),
    textPrimary:       Color(0xFF0D0D14),
    textSecondary:     Color(0xFF555560),
    textTertiary:      Color(0xFF999999),
    textOnDark:        Colors.white,
    primaryRed:        Color(0xFFB22222),
    deepRed:           Color(0xFF8B0000),
    accentGold:        Color(0xFF8B6914), // darker gold for light bg legibility
    statusGreen:       Color(0xFF2E7D32),
    statusRed:         Color(0xFFC62828),
    statusAmber:       Color(0xFFE65100),
    divider:           Color(0xFFE8E8E8),
    tagBackground:       Color(0xFFFFF8E1),
    tagBorder:           Color(0xFFFFE082),
    selectedBackground:  Color(0xFFC8102E), // full UMSL red — crisp on white
    selectedBorder:      Color(0x4DC8102E),  // red 30% border
    unselectedBackground: Color(0xFFEEEEEE),
  );

  // ---- ThemeExtension boilerplate ------------------------------------------
  @override
  VetTheme copyWith({
    Color? pageBackground, Color? cardBackground, Color? cardBorder,
    Color? inputBackground, Color? inputBorder, Color? inputBorderFocused,
    Color? textPrimary, Color? textSecondary, Color? textTertiary,
    Color? textOnDark, Color? primaryRed, Color? deepRed, Color? accentGold,
    Color? statusGreen, Color? statusRed, Color? statusAmber,
    Color? divider, Color? tagBackground, Color? tagBorder,
    Color? selectedBackground, Color? selectedBorder, Color? unselectedBackground,
  }) => VetTheme(
    pageBackground:    pageBackground    ?? this.pageBackground,
    cardBackground:    cardBackground    ?? this.cardBackground,
    cardBorder:        cardBorder        ?? this.cardBorder,
    inputBackground:   inputBackground   ?? this.inputBackground,
    inputBorder:       inputBorder       ?? this.inputBorder,
    inputBorderFocused: inputBorderFocused ?? this.inputBorderFocused,
    textPrimary:       textPrimary       ?? this.textPrimary,
    textSecondary:     textSecondary     ?? this.textSecondary,
    textTertiary:      textTertiary      ?? this.textTertiary,
    textOnDark:        textOnDark        ?? this.textOnDark,
    primaryRed:        primaryRed        ?? this.primaryRed,
    deepRed:           deepRed           ?? this.deepRed,
    accentGold:        accentGold        ?? this.accentGold,
    statusGreen:       statusGreen       ?? this.statusGreen,
    statusRed:         statusRed         ?? this.statusRed,
    statusAmber:       statusAmber       ?? this.statusAmber,
    divider:           divider           ?? this.divider,
    tagBackground:       tagBackground       ?? this.tagBackground,
    tagBorder:           tagBorder           ?? this.tagBorder,
    selectedBackground:  selectedBackground  ?? this.selectedBackground,
    selectedBorder:      selectedBorder      ?? this.selectedBorder,
    unselectedBackground: unselectedBackground ?? this.unselectedBackground,
  );

  @override
  VetTheme lerp(VetTheme? other, double t) {
    if (other == null) return this;
    return VetTheme(
      pageBackground:    Color.lerp(pageBackground,    other.pageBackground,    t)!,
      cardBackground:    Color.lerp(cardBackground,    other.cardBackground,    t)!,
      cardBorder:        Color.lerp(cardBorder,        other.cardBorder,        t)!,
      inputBackground:   Color.lerp(inputBackground,   other.inputBackground,   t)!,
      inputBorder:       Color.lerp(inputBorder,       other.inputBorder,       t)!,
      inputBorderFocused: Color.lerp(inputBorderFocused, other.inputBorderFocused, t)!,
      textPrimary:       Color.lerp(textPrimary,       other.textPrimary,       t)!,
      textSecondary:     Color.lerp(textSecondary,     other.textSecondary,     t)!,
      textTertiary:      Color.lerp(textTertiary,      other.textTertiary,      t)!,
      textOnDark:        Color.lerp(textOnDark,        other.textOnDark,        t)!,
      primaryRed:        Color.lerp(primaryRed,        other.primaryRed,        t)!,
      deepRed:           Color.lerp(deepRed,           other.deepRed,           t)!,
      accentGold:        Color.lerp(accentGold,        other.accentGold,        t)!,
      statusGreen:       Color.lerp(statusGreen,       other.statusGreen,       t)!,
      statusRed:         Color.lerp(statusRed,         other.statusRed,         t)!,
      statusAmber:       Color.lerp(statusAmber,       other.statusAmber,       t)!,
      divider:           Color.lerp(divider,           other.divider,           t)!,
      tagBackground:       Color.lerp(tagBackground,       other.tagBackground,       t)!,
      tagBorder:           Color.lerp(tagBorder,           other.tagBorder,           t)!,
      selectedBackground:  Color.lerp(selectedBackground,  other.selectedBackground,  t)!,
      selectedBorder:      Color.lerp(selectedBorder,      other.selectedBorder,      t)!,
      unselectedBackground: Color.lerp(unselectedBackground, other.unselectedBackground, t)!,
    );
  }
}

// Convenience extension so any widget can do: context.vetTheme
extension VetThemeContext on BuildContext {
  VetTheme get vetTheme =>
      Theme.of(this).extension<VetTheme>() ?? VetTheme.dark;
}
