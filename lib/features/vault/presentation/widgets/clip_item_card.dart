import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/category_icons.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../core/widgets/glass_island.dart';
import '../../../../l10n/app_localizations.dart';

class ClipItemCard extends StatelessWidget {
  const ClipItemCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.categoryName,
    this.categoryIconData,
    this.compact = false,
    super.key,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final IconData? categoryIconData;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _GridTile(
        item: item,
        categoryName: categoryName,
        categoryIconData: categoryIconData,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }
    return _ListRow(
      item: item,
      categoryName: categoryName,
      categoryIconData: categoryIconData,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.categoryName,
    this.categoryIconData,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final IconData? categoryIconData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    // Language sits on the trailing edge — not in the meta line.
    final subtitle = vaultItemMetaLine(
      l10n: l10n,
      categoryName: categoryName,
      lastUsedAt: item.lastCopiedAt,
      locale: locale,
    );
    final icon = item.isPinned && item.categoryId == null
        ? CupertinoIcons.pin_fill
        : (categoryIconData ?? categoryIconForId(item.categoryId));

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GlassIconWell(icon: icon, size: 34, iconSize: 17),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (item.isPinned && item.categoryId != null) ...[
                        Icon(
                          CupertinoIcons.pin_fill,
                          size: 11,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.secondaryLabel(context),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.08,
                    ),
                  ),
                ],
              ),
            ),
            if (item.languageTag != null) ...[
              const SizedBox(width: 10),
              _LanguageCornerBadge(tag: item.languageTag!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact grid cell as a floating glass island.
///
/// Layout:
/// ```
/// [icon]                  [EN] 📌   ← category icon top-left
/// Office WiFi
/// Wi-Fi · Just now
/// ```
class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.categoryName,
    this.categoryIconData,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final IconData? categoryIconData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    // Language lives top-right — keep meta short.
    final meta = vaultItemMetaLine(
      l10n: l10n,
      categoryName: categoryName,
      lastUsedAt: item.lastCopiedAt,
      locale: locale,
    );
    final icon = item.isPinned && item.categoryId == null
        ? CupertinoIcons.pin_fill
        : (categoryIconData ?? categoryIconForId(item.categoryId));

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: GlassIsland(
        borderRadius: BorderRadius.circular(18),
        blur: 16,
        padding: const EdgeInsets.fromLTRB(12, 11, 11, 11),
        // Title size is a Settings preference — never auto-shrinks.
        child: ValueListenableBuilder<GridTitleSize>(
          valueListenable: SettingsService.instance.gridTitleSizeListenable,
          builder: (context, titleSizePref, _) {
            final titleSize = titleSizePref.titleFontSize;
            final metaSize = titleSizePref.metaFontSize;
            const iconSize = 30.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // —— Top: category icon (left) | language + pin (right) ——
                SizedBox(
                  height: iconSize,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _GlassIconWell(
                        icon: icon,
                        size: iconSize,
                        iconSize: 15,
                      ),
                      const Spacer(),
                      _StatusCluster(
                        languageTag: item.languageTag,
                        isPinned: item.isPinned,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // —— Title ——
                Tooltip(
                  message: item.title,
                  waitDuration: const Duration(milliseconds: 400),
                  child: Text(
                    item.title,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.35,
                      height: 1.12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // —— Meta: Wi-Fi · Just now (no icon) ——
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: metaSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.08,
                    height: 1.15,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Top-right status group: language pill, then pin — single alignment baseline.
class _StatusCluster extends StatelessWidget {
  const _StatusCluster({
    this.languageTag,
    this.isPinned = false,
  });

  final String? languageTag;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    if (languageTag == null && !isPinned) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (languageTag != null) _LanguageCornerBadge(tag: languageTag!),
        if (languageTag != null && isPinned) const SizedBox(width: 5),
        if (isPinned)
          Icon(
            CupertinoIcons.pin_fill,
            size: 12,
            color: AppColors.primary.withValues(alpha: 0.72),
          ),
      ],
    );
  }
}

/// Compact language tag for Addresses — top-right of grid / trailing on list.
class _LanguageCornerBadge extends StatelessWidget {
  const _LanguageCornerBadge({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final full = languageTagLabel(tag, l10n);
    if (full == null) return const SizedBox.shrink();

    final short = switch (tag) {
      ClipItem.languageZh => '中',
      ClipItem.languageEn => 'EN',
      _ => full,
    };

    return Tooltip(
      message: full,
      waitDuration: const Duration(milliseconds: 350),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          short,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
            height: 1.1,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Soft frosted icon chip — no hard ring.
class _GlassIconWell extends StatelessWidget {
  const _GlassIconWell({
    required this.icon,
    this.size = 30,
    this.iconSize = 15,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: iconSize, color: AppColors.primary),
    );
  }
}

/// Grouped list as one soft glass island (Apple inset list feel).
class ClipItemGroupedList extends StatelessWidget {
  const ClipItemGroupedList({
    required this.items,
    required this.categoryNameOf,
    required this.onTap,
    required this.onLongPress,
    this.categoryIconOf,
    super.key,
  });

  final List<ClipItem> items;
  final String? Function(ClipItem) categoryNameOf;
  final IconData? Function(ClipItem)? categoryIconOf;
  final void Function(ClipItem) onTap;
  final void Function(ClipItem) onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassIsland(
      borderRadius: BorderRadius.circular(18),
      blur: 14,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ClipItemCard(
              item: items[i],
              categoryName: categoryNameOf(items[i]),
              categoryIconData: categoryIconOf?.call(items[i]),
              onTap: () => onTap(items[i]),
              onLongPress: () => onLongPress(items[i]),
            ),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
