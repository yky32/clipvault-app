import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import 'category_editor_bottom_sheet.dart';
import 'category_manage_bottom_sheet.dart';

/// Result of a category pick. [category] null means “None”.
class CategoryPickResult {
  const CategoryPickResult(this.category);
  final Category? category;
}

/// Select a category for an item (nested bottom sheet).
class CategoryPickerBottomSheet extends StatefulWidget {
  const CategoryPickerBottomSheet({
    this.selectedId,
    this.allowManage = true,
    super.key,
  });

  final String? selectedId;
  final bool allowManage;

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
    if (_selectedId != null &&
        AppBootstrap.categoryRepository.getById(_selectedId!) == null) {
      setState(() => _selectedId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SheetScaffold(
      title: l10n.categorySelectTitle,
      showCloseButton: false,
      compactBody: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosGroup(
            inset: false,
            children: [
              _PickTile(
                icon: CupertinoIcons.minus_circle,
                label: l10n.categoryNone,
                selected: _selectedId == null,
                onTap: () => _pick(null),
              ),
              for (final c in _categories)
                _PickTile(
                  icon: categoryIcon(c),
                  label: categoryDisplayName(c, l10n),
                  selected: _selectedId == c.id,
                  onTap: () => _pick(c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _addCustom,
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: Text(l10n.categoryAdd),
          ),
          if (widget.allowManage) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _openManage,
              child: Text(l10n.categoryManageTitle),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
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
