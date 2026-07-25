import 'package:flutter/material.dart';

/// ClipVault palette — deep teal accent, trustworthy & minimal (PRD §9).
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const primaryDark = Color(0xFF115E59);
  static const primaryMuted = Color(0xFFCCFBF1);

  // Surface — light
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF4F7F7);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFAFCFC);

  // Surface — dark
  static const surfaceDark = Color(0xFF0B1214);
  static const surfaceDimDark = Color(0xFF121A1C);
  static const surfaceCardDark = Color(0xFF1A2326);
  static const surfaceElevatedDark = Color(0xFF243033);

  // Text — light
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  // Text — dark
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);

  // Border
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF2A363A);

  // Status
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);

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
}
