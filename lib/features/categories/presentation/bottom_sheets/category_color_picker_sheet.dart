import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/l10n/category_colors.dart';
import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// Pick a color tag for any category (system or custom).
class CategoryColorPickerSheet extends StatelessWidget {
  const CategoryColorPickerSheet({required this.category, super.key});

  final Category category;

  static Future<bool> show(BuildContext context, Category category) async {
    final changed = await ClipVaultBottomSheet.show<bool>(
      context,
      child: CategoryColorPickerSheet(category: category),
    );
    return changed == true;
  }

  Future<void> _apply(BuildContext context, int? index) async {
    HapticFeedback.selectionClick();
    await AppBootstrap.categoryRepository.setColorIndex(category.id, index);
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = categoryDisplayName(category, l10n);
    final current = CategoryColors.forCategory(category);
    final selectedIndex = category.colorIndex;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLabel(context).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CategoryLeadingIcon(category: category, size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.categoryColorTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryLabel(context),
                        ),
                      ),
                    ],
                  ),
                ),
                CategoryColorDot(color: current, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.categoryColorSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.tertiaryLabel(context),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < CategoryColors.palette.length; i++)
                  _PaletteSwatch(
                    color: CategoryColors.palette[i],
                    selected: selectedIndex == i ||
                        (selectedIndex == null &&
                            CategoryColors.palette[i].toARGB32() ==
                                current.toARGB32()),
                    onTap: () => _apply(context, i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _apply(context, null),
              child: Text(l10n.categoryColorReset),
            ),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: selected ? 8 : 3,
              offset: const Offset(0, 1),
            ),
            if (selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 0,
                spreadRadius: 1.5,
              ),
          ],
        ),
        child: selected
            ? const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
