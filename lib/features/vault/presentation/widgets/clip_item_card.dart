import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/category_icons.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/theme/app_colors.dart';
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
    final subtitle = categoryName ?? l10n.tapToCopy;
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
          children: [
            _GlassIconWell(icon: icon, size: 34, iconSize: 17),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: categoryName != null
                          ? AppColors.secondaryLabel(context)
                          : AppColors.primary.withValues(alpha: 0.85),
                      fontWeight: categoryName == null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: -0.08,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _GlassIconWell(
              icon: CupertinoIcons.doc_on_clipboard,
              size: 30,
              iconSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact grid cell as a floating glass island.
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Title type size ≈ 30% of tile height (square grid cell).
            final titleSize =
                (constraints.maxHeight * 0.30).clamp(18.0, 42.0);
            final metaSize = (titleSize * 0.38).clamp(10.0, 14.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassIconWell(icon: icon, size: 30, iconSize: 15),
                    const Spacer(),
                    if (item.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          CupertinoIcons.pin_fill,
                          size: 12,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    _GlassIconWell(
                      icon: CupertinoIcons.doc_on_clipboard,
                      size: 28,
                      iconSize: 14,
                    ),
                  ],
                ),
                const Spacer(),
                // Title band ~30% of tile height
                SizedBox(
                  height: constraints.maxHeight * 0.30,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoryName ?? l10n.tapToCopy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: metaSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.08,
                    height: 1.15,
                    color: categoryName != null
                        ? AppColors.secondaryLabel(context)
                        : AppColors.primary.withValues(alpha: 0.85),
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
