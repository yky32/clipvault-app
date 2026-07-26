import 'package:flutter/material.dart';

import 'brand_palette.dart';
import 'palette_controller.dart';

/// Dynamic colors from the active [BrandPaletteTokens] (Higgs 01 / 02 / 05 / 06).
///
/// Widgets that read these should rebuild when [PaletteController] notifies
/// (see [ClipVaultApp] ListenableBuilder).
class AppColors {
  AppColors._();

  static BrandPaletteTokens get _t =>
      PaletteControllerHolder.instance?.tokens ?? BrandPalettes.warmGrey;

  // Brand
  static Color get primary => _t.primary;
  static Color get primaryLight => _t.primaryLight;
  static Color get primaryDark => _t.primaryDark;
  static Color get primaryMuted => _t.primaryMuted;
  static Color get accent => _t.accent10;
  static Color get accentLight => _t.accentLight;
  static Color get accentDark => _t.accentDark;
  static Color get accentMuted => _t.accentMuted;

  // Named light bases (for theme builders)
  static Color get warmGrey => _t.appPageLight;
  static Color get warmWhite => _t.appCardLight;

  // Surfaces
  static Color get surface => _t.appCardLight;
  static Color get surfaceDim => _t.appPageLight;
  static Color get surfaceCard => _t.appCardLight;
  static Color get surfaceElevated => _t.appCardLight;
  static Color get surfaceDark => _t.surfaceDark;
  static Color get surfaceDimDark => _t.surfaceDimDark;
  static Color get surfaceCardDark => _t.surfaceCardDark;
  static Color get surfaceElevatedDark => _t.surfaceElevatedDark;

  // Text
  static Color get textPrimary => _t.textPrimary;
  static Color get textSecondary => _t.textSecondary;
  static Color get textTertiary => _t.textSecondary;
  static Color get textPrimaryDark => _t.textPrimaryDark;
  static Color get textSecondaryDark => _t.textSecondaryDark;
  static Color get textTertiaryDark => _t.textSecondaryDark;

  // Borders
  static Color get separator => _t.separator;
  static Color get separatorDark => _t.separatorDark;
  static Color get border => _t.separator;
  static Color get borderDark => _t.separatorDark;

  // Status
  static Color get success => _t.success;
  static Color get warning => _t.warning;
  static Color get error => _t.error;

  // Settings icons
  static Color get iconSecurity => _t.iconSecurity;
  static Color get iconTheme => _t.iconTheme;
  static Color get iconView => _t.iconView;
  static Color get iconClipboard => _t.iconClipboard;
  static Color get iconExport => _t.iconExport;

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

  static Color groupedBackground(BuildContext context) =>
      pageBackground(context);

  static Color hairline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? separatorDark.withValues(alpha: 0.7)
        : separator.withValues(alpha: 0.85);
  }

  static Color searchFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _t.searchFillDark : _t.searchFillLight;
  }
}

/// Holds the live [PaletteController] for static [AppColors] lookups.
class PaletteControllerHolder {
  static PaletteController? instance;
}
