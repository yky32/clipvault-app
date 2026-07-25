import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets groupInset = EdgeInsets.symmetric(horizontal: lg);
}

abstract final class AppRadii {
  /// Continuous-looking corners (Apple medium).
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get group => BorderRadius.circular(lg);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(xxl));
  static BorderRadius get control => BorderRadius.circular(md);
  static BorderRadius get search => BorderRadius.circular(12);
}

abstract final class AppShadows {
  static List<BoxShadow> subtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return const [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> fab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
