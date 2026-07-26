import 'package:flutter/material.dart';

/// Higgs Brand palettes available in Settings (60 / 30 / 10).
enum BrandPaletteId {
  /// 01 深啡 + 焦糖
  deepBrown,

  /// 02 灰白 + 橘红 (default)
  warmGrey,

  /// 05 木色 + 湖蓝
  woodBlue,

  /// 06 黑白 + 亮蓝
  inkBlue,
}

/// Resolved color tokens for one Higgs palette.
class BrandPaletteTokens {
  const BrandPaletteTokens({
    required this.id,
    required this.base60,
    required this.surface30,
    required this.accent10,
    required this.accentLight,
    required this.accentDark,
    required this.accentMuted,
    required this.surfaceDark,
    required this.surfaceDimDark,
    required this.surfaceCardDark,
    required this.surfaceElevatedDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textPrimaryDark,
    required this.textSecondaryDark,
    required this.separator,
    required this.separatorDark,
    required this.searchFillLight,
    required this.searchFillDark,
    required this.success,
    required this.warning,
    required this.error,
    required this.iconSecurity,
    required this.iconTheme,
    required this.iconView,
    required this.iconClipboard,
    required this.iconExport,
  });

  final BrandPaletteId id;

  /// 60% — page / large surfaces (light)
  final Color base60;

  /// 30% — cards / elevated panels (light)
  final Color surface30;

  /// 10% — accent / CTA
  final Color accent10;
  final Color accentLight;
  final Color accentDark;
  final Color accentMuted;

  final Color surfaceDark;
  final Color surfaceDimDark;
  final Color surfaceCardDark;
  final Color surfaceElevatedDark;

  final Color textPrimary;
  final Color textSecondary;
  final Color textPrimaryDark;
  final Color textSecondaryDark;

  final Color separator;
  final Color separatorDark;

  final Color searchFillLight;
  final Color searchFillDark;

  final Color success;
  final Color warning;
  final Color error;

  final Color iconSecurity;
  final Color iconTheme;
  final Color iconView;
  final Color iconClipboard;
  final Color iconExport;

  // Aliases used by AppColors / Theme
  Color get primary => accent10;
  Color get primaryLight => accentLight;
  Color get primaryDark => accentDark;
  Color get primaryMuted => accentMuted;
  Color get surface => surface30;
  Color get surfaceDim => base60;
  Color get surfaceCard => surface30;
  Color get surfaceElevated => surface30;
  Color get border => separator;
  Color get borderDark => separatorDark;
}

/// All selectable Higgs palettes for clipVAuLt.
abstract final class BrandPalettes {
  static const BrandPaletteId defaultId = BrandPaletteId.warmGrey;

  static BrandPaletteTokens of(BrandPaletteId id) => switch (id) {
        BrandPaletteId.deepBrown => deepBrown,
        BrandPaletteId.warmGrey => warmGrey,
        BrandPaletteId.woodBlue => woodBlue,
        BrandPaletteId.inkBlue => inkBlue,
      };

  static const List<BrandPaletteId> all = BrandPaletteId.values;

  /// 01 — 深啡 + 焦糖 + 奶油白
  static const deepBrown = BrandPaletteTokens(
    id: BrandPaletteId.deepBrown,
    base60: Color(0xFF2B1F1A), // deep brown as immersive page in light too
    surface30: Color(0xFFB9824A), // caramel panels — too strong for cards
    // Re-map for app UX: cream page, cream cards, caramel accent on deep text
    // Override via specialized layout: use cream as surfaces, brown as text, caramel accent
    accent10: Color(0xFFB9824A),
    accentLight: Color(0xFFC99A68),
    accentDark: Color(0xFF9A6A38),
    accentMuted: Color(0xFFF0E6D8),
    surfaceDark: Color(0xFF1A1411),
    surfaceDimDark: Color(0xFF241C17),
    surfaceCardDark: Color(0xFF322820),
    surfaceElevatedDark: Color(0xFF3D3228),
    textPrimary: Color(0xFF2B1F1A),
    textSecondary: Color(0xFF6B5344),
    textPrimaryDark: Color(0xFFF4EFE7),
    textSecondaryDark: Color(0xFFE0D4C4),
    separator: Color(0xFFD9CFC2),
    separatorDark: Color(0xFF4A3B30),
    searchFillLight: Color(0xFFE8DFD4),
    searchFillDark: Color(0xFF322820),
    success: Color(0xFF6B8F5A),
    warning: Color(0xFFC99A68),
    error: Color(0xFFB84A3D),
    iconSecurity: Color(0xFFB9824A),
    iconTheme: Color(0xFF2B1F1A),
    iconView: Color(0xFF8A6A4A),
    iconClipboard: Color(0xFF9A6A38),
    iconExport: Color(0xFF6B8F5A),
  );

  /// 02 — 暖灰 + 暖白 + 橘红 (current default)
  static const warmGrey = BrandPaletteTokens(
    id: BrandPaletteId.warmGrey,
    base60: Color(0xFFE4E2DD),
    surface30: Color(0xFFF8F6F0),
    accent10: Color(0xFFC85F42),
    accentLight: Color(0xFFD97A60),
    accentDark: Color(0xFFA84A32),
    accentMuted: Color(0xFFF3E4DF),
    surfaceDark: Color(0xFF141311),
    surfaceDimDark: Color(0xFF1C1B19),
    surfaceCardDark: Color(0xFF2A2825),
    surfaceElevatedDark: Color(0xFF35322E),
    textPrimary: Color(0xFF1A1816),
    textSecondary: Color(0xFF5C574F),
    textPrimaryDark: Color(0xFFF8F6F0),
    textSecondaryDark: Color(0xFFE8E4DC),
    separator: Color(0xFFD0CDC6),
    separatorDark: Color(0xFF3D3A35),
    searchFillLight: Color(0xFFD9D6D0),
    searchFillDark: Color(0xFF2A2825),
    success: Color(0xFF5A8F62),
    warning: Color(0xFFC8893A),
    error: Color(0xFFC44B3C),
    iconSecurity: Color(0xFFC85F42),
    iconTheme: Color(0xFF6B6560),
    iconView: Color(0xFF8A7568),
    iconClipboard: Color(0xFFA84A32),
    iconExport: Color(0xFF5A8F62),
  );

  /// 05 — 橡木 + 湖蓝 + 米白
  static const woodBlue = BrandPaletteTokens(
    id: BrandPaletteId.woodBlue,
    base60: Color(0xFFF4EFE7), // 米白 as page (app-friendly 60%)
    surface30: Color(0xFFFFFFFF),
    accent10: Color(0xFF315D72), // 湖蓝 as focal
    accentLight: Color(0xFF3F7390),
    accentDark: Color(0xFF274A5A),
    accentMuted: Color(0xFFD9E6EC),
    surfaceDark: Color(0xFF12181C),
    surfaceDimDark: Color(0xFF1A2228),
    surfaceCardDark: Color(0xFF253038),
    surfaceElevatedDark: Color(0xFF2F3C46),
    textPrimary: Color(0xFF1C2428),
    textSecondary: Color(0xFF5A656C),
    textPrimaryDark: Color(0xFFF4EFE7),
    textSecondaryDark: Color(0xFFD0D8DC),
    separator: Color(0xFFDDD6CA),
    separatorDark: Color(0xFF3A4650),
    searchFillLight: Color(0xFFE8E0D4),
    searchFillDark: Color(0xFF253038),
    success: Color(0xFF5A8F6A),
    warning: Color(0xFFB99168),
    error: Color(0xFFB84A3D),
    iconSecurity: Color(0xFF315D72),
    iconTheme: Color(0xFFB99168),
    iconView: Color(0xFF315D72),
    iconClipboard: Color(0xFFB99168),
    iconExport: Color(0xFF5A8F6A),
  );

  /// 06 — 黑 + 暖白 + 亮蓝
  static const inkBlue = BrandPaletteTokens(
    id: BrandPaletteId.inkBlue,
    base60: Color(0xFFF5F3ED), // 暖白 page
    surface30: Color(0xFFFFFFFF),
    accent10: Color(0xFF2A67FF), // 亮蓝 focal only
    accentLight: Color(0xFF4B80FF),
    accentDark: Color(0xFF1A4FD6),
    accentMuted: Color(0xFFDCE6FF),
    surfaceDark: Color(0xFF111111),
    surfaceDimDark: Color(0xFF111111),
    surfaceCardDark: Color(0xFF1C1C1E),
    surfaceElevatedDark: Color(0xFF2C2C2E),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF5C5C5C),
    textPrimaryDark: Color(0xFFF5F3ED),
    textSecondaryDark: Color(0xFFB0B0B0),
    separator: Color(0xFFD8D5CE),
    separatorDark: Color(0xFF2C2C2E),
    searchFillLight: Color(0xFFE8E6E0),
    searchFillDark: Color(0xFF1C1C1E),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    error: Color(0xFFFF3B30),
    iconSecurity: Color(0xFF2A67FF),
    iconTheme: Color(0xFF111111),
    iconView: Color(0xFF2A67FF),
    iconClipboard: Color(0xFF555555),
    iconExport: Color(0xFF34C759),
  );
}

/// App-friendly light surfaces for palette 01 (deep brown as text/page tint,
/// cream cards, caramel accent) — PDF uses deep brown as 60% field which is
/// too heavy for a full app scaffold, so we invert to cream field + caramel CTA.
extension BrandPaletteAppSurfaces on BrandPaletteTokens {
  Color get appPageLight {
    if (id == BrandPaletteId.deepBrown) {
      return const Color(0xFFF4EFE7); // 奶油白
    }
    return base60;
  }

  Color get appCardLight {
    if (id == BrandPaletteId.deepBrown) {
      return const Color(0xFFFAF6F0);
    }
    if (id == BrandPaletteId.woodBlue) {
      return const Color(0xFFFFFFFF);
    }
    return surface30;
  }

  Color get appAccentSecondary {
    // Extra material color used for wood chips etc.
    if (id == BrandPaletteId.woodBlue) {
      return const Color(0xFFB99168); // oak
    }
    if (id == BrandPaletteId.deepBrown) {
      return const Color(0xFF2B1F1A);
    }
    return accentDark;
  }
}
