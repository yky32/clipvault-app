import 'package:flutter/material.dart';

/// Higgs Brand palette **02 — 灰白 + 橘红**
///
/// 60% 暖灰 · 30% 暖白 · 10% 橘红
/// Feel: 俐落、有力量、现代. Accent only on focal UI (CTA / FAB / copy).
class AppColors {
  AppColors._();

  // ── Palette 02 tokens ──────────────────────────────────────────
  /// 60% — 暖灰色 (page / large surfaces)
  static const warmGrey = Color(0xFFE4E2DD);

  /// 30% — 暖白色 (cards / elevated panels)
  static const warmWhite = Color(0xFFF8F6F0);

  /// 10% — 橘红色 (memory point / CTA)
  static const accent = Color(0xFFC85F42);

  static const accentLight = Color(0xFFD97A60);
  static const accentDark = Color(0xFFA84A32);
  static const accentMuted = Color(0xFFF3E4DF); // soft wash of 橘红

  // Brand aliases (used across the app)
  static const primary = accent;
  static const primaryLight = accentLight;
  static const primaryDark = accentDark;
  static const primaryMuted = accentMuted;

  // Surface — light (Higgs 02)
  static const surface = warmWhite; // cards, sheets
  static const surfaceDim = warmGrey; // page / grouped bg
  static const surfaceCard = warmWhite;
  static const surfaceElevated = Color(0xFFFAF8F4);
  static const fill = Color(0xFF78746E);
  static const fillTertiary = Color(0x1F78746E);

  // Surface — dark (warm charcoal counterpart)
  static const surfaceDark = Color(0xFF141311);
  static const surfaceDimDark = Color(0xFF1C1B19);
  static const surfaceCardDark = Color(0xFF2A2825);
  static const surfaceElevatedDark = Color(0xFF35322E);
  static const fillDark = Color(0xFFA39E96);

  // Labels — slightly warm neutrals
  static const textPrimary = Color(0xFF1A1816);
  static const textSecondary = Color(0xFF5C574F);
  static const textTertiary = Color(0xFF5C574F);
  static const textPrimaryDark = Color(0xFFF8F6F0);
  static const textSecondaryDark = Color(0xFFE8E4DC);
  static const textTertiaryDark = Color(0xFFE8E4DC);

  // Separators
  static const separator = Color(0xFFD0CDC6);
  static const separatorDark = Color(0xFF3D3A35);
  static const border = Color(0xFFD8D4CC);
  static const borderDark = Color(0xFF3D3A35);

  // Status (keep system-readable; warning/error near accent family)
  static const success = Color(0xFF5A8F62);
  static const warning = Color(0xFFC8893A);
  static const error = Color(0xFFC44B3C);

  // Settings leading icon tiles (harmonized with 02)
  static const iconSecurity = Color(0xFFC85F42);
  static const iconTheme = Color(0xFF6B6560);
  static const iconView = Color(0xFF8A7568);
  static const iconClipboard = Color(0xFFA84A32);
  static const iconExport = Color(0xFF5A8F62);

  static Color label(BuildContext context, {double opacity = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? textPrimaryDark : textPrimary;
    return base.withValues(alpha: opacity);
  }

  static Color secondaryLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? textSecondaryDark.withValues(alpha: 0.6)
        : textSecondary.withValues(alpha: 0.72);
  }

  static Color tertiaryLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? textTertiaryDark.withValues(alpha: 0.35)
        : textTertiary.withValues(alpha: 0.4);
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
    return pageBackground(context);
  }

  static Color hairline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? separatorDark.withValues(alpha: 0.7)
        : separator.withValues(alpha: 0.85);
  }

  static Color searchFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sit between 60% grey and 30% white — quiet, not cold system grey.
    return isDark ? const Color(0xFF2A2825) : const Color(0xFFD9D6D0);
  }
}
