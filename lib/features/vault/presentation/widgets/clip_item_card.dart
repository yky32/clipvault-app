import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/category_icons.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/copied_hud.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
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
                          size: 12,
                          color: AppColors.primary.withValues(alpha: 0.85),
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
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: categoryName != null
                          ? AppColors.secondaryLabel(context)
                          : AppColors.primary.withValues(alpha: 0.8),
                      fontWeight: categoryName == null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      letterSpacing: -0.08,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.doc_on_clipboard,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact grid cell — dense, scannable, tap = copy.
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.primary),
                ),
                const Spacer(),
                if (item.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      CupertinoIcons.pin_fill,
                      size: 12,
                      color: AppColors.primary.withValues(alpha: 0.75),
                    ),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_on_clipboard,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              categoryName ?? l10n.tapToCopy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.08,
                height: 1.2,
                color: categoryName != null
                    ? AppColors.secondaryLabel(context)
                    : AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped list of vault items with iOS inset style + hairline separators.
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: AppRadii.group,
      ),
      clipBehavior: Clip.antiAlias,
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
                padding: const EdgeInsets.only(left: 64),
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppColors.hairline(context),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
