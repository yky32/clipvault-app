import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/address_languages.dart';
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
    this.selectionMode = false,
    this.selected = false,
    this.gridColumns = 2,
    super.key,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final IconData? categoryIconData;
  final bool compact;
  final bool selectionMode;
  final bool selected;

  /// Cross-axis count when [compact] (2 or 3). Drives title/meta scale.
  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _GridTile(
        item: item,
        categoryName: categoryName,
        categoryIconData: categoryIconData,
        onTap: onTap,
        onLongPress: onLongPress,
        selectionMode: selectionMode,
        selected: selected,
        gridColumns: gridColumns,
      );
    }
    return _ListRow(
      item: item,
      categoryName: categoryName,
      categoryIconData: categoryIconData,
      onTap: onTap,
      onLongPress: onLongPress,
      selectionMode: selectionMode,
      selected: selected,
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
    this.selectionMode = false,
    this.selected = false,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final IconData? categoryIconData;
  final bool selectionMode;
  final bool selected;

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
            if (selectionMode) ...[
              _SelectionCheck(selected: selected, size: 22),
              const SizedBox(width: 12),
            ] else
              CategoryLeadingIcon(
                categoryId: item.categoryId,
                size: 34,
                iconSize: 17,
              ),
            if (!selectionMode) const SizedBox(width: 12),
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
                      if (item.isSensitive) ...[
                        Icon(
                          CupertinoIcons.eye_slash_fill,
                          size: 12,
                          color: AppColors.secondaryLabel(context),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.displayTitle,
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
    this.selectionMode = false,
    this.selected = false,
    this.gridColumns = 2,
  });

  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? categoryName;
  final IconData? categoryIconData;
  final bool selectionMode;
  final bool selected;
  final int gridColumns;

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
    final radius = BorderRadius.circular(18);

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: selected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: GlassIsland(
          borderRadius: radius,
          blur: 16,
          padding: const EdgeInsets.fromLTRB(12, 11, 11, 11),
          // Title size is a Settings preference — never auto-shrinks.
          child: ValueListenableBuilder<GridTitleSize>(
            valueListenable: SettingsService.instance.gridTitleSizeListenable,
            builder: (context, titleSizePref, _) {
              final cols = gridColumns.clamp(2, 3);
              final titleSize = titleSizePref.titleFontSizeForColumns(cols);
              final metaSize = titleSizePref.metaFontSizeForColumns(cols);
              final titleHeight =
                  titleSizePref.titleLineHeightForColumns(cols);
              final isDense = cols >= 3;
              final iconSize = isDense ? 26.0 : 30.0;
              final iconGlyph = isDense ? 13.0 : 15.0;
              final padTop = isDense ? 2.0 : 4.0;
              final gapTitleMeta = isDense ? 2.0 : 3.0;

              // Keep icon fixed; flex title into remaining space so 3-col
              // never overflows when titles wrap to two lines.
              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // —— Top: category icon (left) | language + pin (right) ——
                      SizedBox(
                        height: iconSize,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CategoryLeadingIcon(
                              categoryId: item.categoryId,
                              size: iconSize,
                              iconSize: iconGlyph,
                            ),
                            const Spacer(),
                            if (!selectionMode)
                              _StatusCluster(
                                languageTag: item.languageTag,
                                isPinned: item.isPinned,
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: padTop),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Tooltip(
                                      message: item.displayTitle,
                                      waitDuration:
                                          const Duration(milliseconds: 400),
                                      child: Text(
                                        item.displayTitle,
                                        maxLines: 2,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing:
                                              isDense ? -0.28 : -0.35,
                                          height: titleHeight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: gapTitleMeta),
                              Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: metaSize,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.08,
                                  height: 1.12,
                                  color: AppColors.secondaryLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectionMode)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _SelectionCheck(
                        selected: selected,
                        size: isDense ? 20 : 24,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Circle checkmark used in list/grid selection mode.
class _SelectionCheck extends StatelessWidget {
  const _SelectionCheck({required this.selected, this.size = 22});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.secondaryLabel(context).withValues(alpha: 0.45),
          width: 1.6,
        ),
      ),
      child: selected
          ? Icon(
              CupertinoIcons.checkmark,
              size: size * 0.55,
              color: Colors.white,
            )
          : null,
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

    final short = AddressLanguages.shortBadge(tag);

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

/// Grouped list as one soft glass island (Apple inset list feel).
class ClipItemGroupedList extends StatelessWidget {
  const ClipItemGroupedList({
    required this.items,
    required this.categoryNameOf,
    required this.onTap,
    required this.onLongPress,
    this.categoryIconOf,
    this.selectionMode = false,
    this.isSelected,
    super.key,
  });

  final List<ClipItem> items;
  final String? Function(ClipItem) categoryNameOf;
  final IconData? Function(ClipItem)? categoryIconOf;
  final void Function(ClipItem) onTap;
  final void Function(ClipItem) onLongPress;
  final bool selectionMode;
  final bool Function(ClipItem)? isSelected;

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
              selectionMode: selectionMode,
              selected: isSelected?.call(items[i]) ?? false,
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
