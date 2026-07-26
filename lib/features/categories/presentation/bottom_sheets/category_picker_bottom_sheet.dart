import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import 'category_editor_bottom_sheet.dart';
import 'category_manage_bottom_sheet.dart';

/// Result of a category pick. [category] null means “None”.
class CategoryPickResult {
  const CategoryPickResult(this.category);
  final Category? category;
}

/// Select a category for an item (Triftly-style nested bottom sheet).
class CategoryPickerBottomSheet extends StatefulWidget {
  const CategoryPickerBottomSheet({
    this.selectedId,
    this.allowManage = true,
    super.key,
  });

  final String? selectedId;
  final bool allowManage;

  /// Returns selected [Category], or `null` if user picked None.
  /// Returns unchanged (don’t update) if sheet is dismissed without selection
  /// via drag — use a wrapper sentinel? Simpler: return Category? where
  /// dismissing without tap returns nothing useful.
  ///
  /// We use a private sentinel via Optional-like: pop with CategoryPickResult.
  static Future<CategoryPickResult?> show(
    BuildContext context, {
    String? selectedId,
    bool allowManage = true,
  }) {
    return ClipVaultBottomSheet.show<CategoryPickResult>(
      context,
      child: CategoryPickerBottomSheet(
        selectedId: selectedId,
        allowManage: allowManage,
      ),
    );
  }

  @override
  State<CategoryPickerBottomSheet> createState() =>
      _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState extends State<CategoryPickerBottomSheet> {
  late List<Category> _categories;
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _reload();
  }

  void _reload() {
    _categories = AppBootstrap.categoryRepository.getAll();
  }

  void _pick(Category? category) {
    HapticFeedback.selectionClick();
    Navigator.pop(context, CategoryPickResult(category));
  }

  Future<void> _addCustom() async {
    final created = await CategoryEditorBottomSheet.show(context);
    if (!mounted) return;
    if (created != null) {
      setState(_reload);
      _pick(created);
    }
  }

  Future<void> _openManage() async {
    await CategoryManageBottomSheet.show(context);
    if (!mounted) return;
    setState(_reload);
    // Clear selection if deleted
    if (_selectedId != null &&
        AppBootstrap.categoryRepository.getById(_selectedId!) == null) {
      setState(() => _selectedId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SheetScaffold(
      title: l10n.categorySelectTitle,
      showCloseButton: false,
      compactBody: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PickRow(
            label: l10n.categoryNone,
            selected: _selectedId == null,
            onTap: () => _pick(null),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _PickRow(
                label: categoryDisplayName(c, l10n),
                badge: c.isSystem ? l10n.categoryDefaultBadge : null,
                selected: _selectedId == c.id,
                onTap: () => _pick(c),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: _addCustom,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Text(l10n.categoryAdd),
          ),
          if (widget.allowManage) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openManage,
              child: Text(l10n.categoryManageTitle),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.categoryManageSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.cardBackground(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 22,
                color: selected
                    ? AppColors.primary
                    : AppColors.tertiaryLabel(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
