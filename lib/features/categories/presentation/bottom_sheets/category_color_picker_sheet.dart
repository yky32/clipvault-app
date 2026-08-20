import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/l10n/category_colors.dart';
import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Color palette body — embed inside [CategoryManageBottomSheet] (no nested modal).
class CategoryColorPickerBody extends StatelessWidget {
  const CategoryColorPickerBody({
    required this.category,
    required this.onApplied,
    super.key,
  });

  final Category category;
  final Future<void> Function(int? colorIndex) onApplied;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = categoryDisplayName(category, l10n);
    final current = CategoryColors.forCategory(category);
    final selectedIndex = category.colorIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CategoryLeadingIcon(category: category, size: 40, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.categoryColorSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryLabel(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            CategoryColorDot(color: current, size: 18),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.start,
          children: [
            for (var i = 0; i < CategoryColors.palette.length; i++)
              _PaletteSwatch(
                color: CategoryColors.palette[i],
                selected: selectedIndex == i ||
                    (selectedIndex == null &&
                        CategoryColors.palette[i].toARGB32() ==
                            current.toARGB32()),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await onApplied(i);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: selected ? 2.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: selected ? 8 : 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: selected
              ? const Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 20,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

/// Fallback modal (opaque). Prefer embedded [CategoryColorPickerBody].
class CategoryColorPickerSheet extends StatelessWidget {
  const CategoryColorPickerSheet({required this.category, super.key});
  final Category category;

  static Future<bool> show(BuildContext context, Category category) async {
    // Fallback: opaque material dialog (never transparent nested sheet).
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDimDark
          : AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryColorPickerBody(
                  category: category,
                  onApplied: (index) async {
                    await AppBootstrap.categoryRepository
                        .setColorIndex(category.id, index);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await AppBootstrap.categoryRepository
                          .setColorIndex(category.id, null);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    child: Text(AppLocalizations.of(ctx).categoryColorReset),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return changed == true;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
