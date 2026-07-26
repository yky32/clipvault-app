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

/// Manage custom categories; product defaults are read-only.
/// Reused from Settings and from the category picker.
class CategoryManageBottomSheet extends StatefulWidget {
  const CategoryManageBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return ClipVaultBottomSheet.show<void>(
      context,
      child: const CategoryManageBottomSheet(),
    );
  }

  @override
  State<CategoryManageBottomSheet> createState() =>
      _CategoryManageBottomSheetState();
}

class _CategoryManageBottomSheetState extends State<CategoryManageBottomSheet> {
  List<Category> _system = const [];
  List<Category> _custom = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = AppBootstrap.categoryRepository;
    setState(() {
      _system = repo.systemCategories;
      _custom = repo.customCategories;
    });
  }

  Future<void> _add() async {
    final created = await CategoryEditorBottomSheet.show(context);
    if (created != null && mounted) _reload();
  }

  Future<void> _edit(Category category) async {
    if (category.isSystem) return;
    final updated = await CategoryEditorBottomSheet.show(
      context,
      category: category,
    );
    if (updated != null && mounted) _reload();
  }

  Future<void> _delete(Category category) async {
    if (category.isSystem) return;
    final l10n = AppLocalizations.of(context);
    final label = categoryDisplayName(category, l10n);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.categoryDeleteTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.categoryDeleteBody(label)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.mediumImpact();
    await AppBootstrap.categoryRepository.delete(category.id);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SheetScaffold(
      title: l10n.categoryManageTitle,
      subtitle: l10n.categoryManageSubtitle,
      showCloseButton: false,
      compactBody: false,
      footer: FilledButton(
        onPressed: _add,
        child: Text(l10n.categoryAdd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.categoryDefaultsSection.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryLabel(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._system.map(
            (c) => _ManageRow(
              label: categoryDisplayName(c, l10n),
              badge: l10n.categoryDefaultBadge,
              onTap: null,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.categoryCustomSection.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryLabel(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_custom.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.categoryEmptyCustom,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryLabel(context),
                ),
              ),
            )
          else
            ..._custom.map(
              (c) => _ManageRow(
                label: categoryDisplayName(c, l10n),
                onTap: () => _edit(c),
                onDelete: () => _delete(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.label,
    this.badge,
    this.onTap,
    this.onDelete,
  });

  final String label;
  final String? badge;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editable = onTap != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyLarge,
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
                if (editable) ...[
                  if (onDelete != null)
                    CupertinoButton(
                      padding: const EdgeInsets.only(right: 4),
                      minimumSize: Size.zero,
                      onPressed: onDelete,
                      child: Icon(
                        CupertinoIcons.delete,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  Icon(
                    CupertinoIcons.pencil,
                    size: 18,
                    color: AppColors.secondaryLabel(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
