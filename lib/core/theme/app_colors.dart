import 'package:flutter/material.dart';

/// Apple-inspired system palette with a calm teal accent (trustworthy vault).
class AppColors {
  AppColors._();

  // Brand — soft system teal (iOS-adjacent, not generic Material purple)
  static const primary = Color(0xFF0A7C72);
  static const primaryLight = Color(0xFF14A89A);
  static const primaryDark = Color(0xFF06665E);
  static const primaryMuted = Color(0xFFE6F6F4);

  // Light — systemGroupedBackground / systemBackground
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF2F2F7); // systemGroupedBackground
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const fill = Color(0xFF787880); // systemFill base
  static const fillTertiary = Color(0x1F767680); // ~12% systemFill

  // Dark — elevated system greys
  static const surfaceDark = Color(0xFF000000);
  static const surfaceDimDark = Color(0xFF1C1C1E); // secondarySystemBackground
  static const surfaceCardDark = Color(0xFF2C2C2E); // secondarySystemGrouped
  static const surfaceElevatedDark = Color(0xFF3A3A3C);
  static const fillDark = Color(0xFF8E8E93);

  // Label colors (iOS hierarchy)
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF3C3C43); // secondaryLabel ~60%
  static const textTertiary = Color(0xFF3C3C43); // tertiary via alpha
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFEBEBF5);
  static const textTertiaryDark = Color(0xFFEBEBF5);

  // Separators
  static const separator = Color(0xFFC6C6C8);
  static const separatorDark = Color(0xFF38383A);
  static const border = Color(0xFFD1D1D6);
  static const borderDark = Color(0xFF38383A);

  // Status
  static const success = Color(0xFF34C759); // systemGreen
  static const warning = Color(0xFFFF9500); // systemOrange
  static const error = Color(0xFFFF3B30); // systemRed

  static Color label(BuildContext context, {double opacity = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? textPrimaryDark : textPrimary;
    return base.withValues(alpha: opacity);
  }

  static Color secondaryLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? textSecondaryDark.withValues(alpha: 0.6)
        : textSecondary.withValues(alpha: 0.6);
  }

  static Color tertiaryLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? textTertiaryDark.withValues(alpha: 0.3)
        : textTertiary.withValues(alpha: 0.3);
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceCardDark
        : surfaceCard;
  }

  static Color pageBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceDim;
  }

  static Color groupedBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceDim;
  }

  static Color hairline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? separatorDark.withValues(alpha: 0.65)
        : separator.withValues(alpha: 0.65);
  }

  static Color searchFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFE3E3E8);
  }
}
