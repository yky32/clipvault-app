import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Apple-style floating island — soft elevation, frosted fill, no hard stroke.
///
/// Inspired by iOS continuous corners + light liquid-glass (Triftly GlassSurface,
/// toned down for content cards: blur lighter, no opaque border ring).
class GlassIsland extends StatelessWidget {
  const GlassIsland({
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 18,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blur;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.xl);

    // Frosted fill — slightly translucent over grouped background
    final fill = isDark
        ? AppColors.surfaceCardDark.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.72);

    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.92);

    final island = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.island(context),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              // Ultra-soft edge (not a full “border” stroke)
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.55),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  highlight,
                  fill,
                  fill.withValues(alpha: isDark ? 0.65 : 0.58),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      ),
    );

    if (onTap == null && onLongPress == null) return island;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: island,
      ),
    );
  }
}
