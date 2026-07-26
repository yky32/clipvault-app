import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.compact = false,
    this.showDivider = false,
    super.key,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final bool compact;

  /// When true, renders as an iOS grouped list row (no outer card chrome).
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _GridTile(
        item: item,
        categoryName: categoryName,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }
    return _ListRow(
      item: item,
      categoryName: categoryName,
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
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final subtitle = categoryName ?? l10n.tapToCopy;

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
              child: Icon(
                item.isPinned
                    ? CupertinoIcons.pin_fill
                    : CupertinoIcons.doc_on_clipboard,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
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

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.categoryName,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: AppRadii.group,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.isPinned
                      ? CupertinoIcons.pin_fill
                      : CupertinoIcons.lock_fill,
                  size: 14,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.doc_on_doc,
                  size: 16,
                  color: AppColors.tertiaryLabel(context),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (categoryName != null) ...[
              const SizedBox(height: 4),
              Text(
                categoryName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryLabel(context),
                ),
              ),
            ],
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
    super.key,
  });

  final List<ClipItem> items;
  final String? Function(ClipItem) categoryNameOf;
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
