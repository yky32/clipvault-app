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
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/bottom_sheets/address_language_settings_sheet.dart';
import 'category_editor_bottom_sheet.dart';

/// Manage custom categories; product defaults are read-only.
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

  Future<void> _cycleColor(Category category) async {
    if (category.isSystem) return;
    HapticFeedback.selectionClick();
    final next = CategoryColors.nextIndex(category.colorIndex);
    await AppBootstrap.categoryRepository.updateCustom(
      category.id,
      colorIndex: next,
    );
    if (mounted) _reload();
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

  /// Addresses is the only product default with extra setup (language tags).
  Future<void> _openAddressLanguages() async {
    HapticFeedback.selectionClick();
    await AddressLanguageSettingsSheet.show(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SheetScaffold(
      title: l10n.categoryManageTitle,
      subtitle: l10n.categoryManageSubtitle,
      showCloseButton: false,
      compactBody: false,
      footer: FilledButton.icon(
        onPressed: _add,
        icon: const Icon(CupertinoIcons.add, size: 18),
        label: Text(l10n.categoryAdd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosGroup(
            inset: false,
            header: l10n.categoryDefaultsSection,
            children: [
              for (final c in _system)
                _CategoryTile(
                  icon: categoryIcon(c),
                  label: categoryDisplayName(c, l10n),
                  color: CategoryColors.forCategory(c),
                  // Single-line rows so Default badges share one column.
                  // Language tags are configured by tapping Addresses.
                  onTap: c.supportsLanguageTag ? _openAddressLanguages : null,
                  trailing: _DefaultTrailing(
                    badgeLabel: l10n.categoryDefaultBadge,
                    showChevron: c.supportsLanguageTag,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          IosGroup(
            inset: false,
            header: l10n.categoryCustomSection,
            children: [
              if (_custom.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.tag,
                        size: 20,
                        color: AppColors.tertiaryLabel(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.categoryEmptyCustom,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryLabel(context),
                              ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final c in _custom)
                  _CategoryTile(
                    icon: categoryIcon(c),
                    label: categoryDisplayName(c, l10n),
                    color: CategoryColors.forCategory(c),
                    onTap: () => _edit(c),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          onPressed: () => _cycleColor(c),
                          child: CategoryColorDot(
                            color: CategoryColors.forCategory(c),
                            size: 14,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          onPressed: () => _delete(c),
                          child: Icon(
                            CupertinoIcons.trash,
                            size: 18,
                            color: AppColors.error.withValues(alpha: 0.9),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: AppColors.tertiaryLabel(context),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Default badge + optional chevron. Chevron slot is always reserved so
/// badges line up across product-default rows.
class _DefaultTrailing extends StatelessWidget {
  const _DefaultTrailing({
    required this.badgeLabel,
    this.showChevron = false,
  });

  final String badgeLabel;
  final bool showChevron;

  static const double _chevronSlot = 22;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DefaultBadge(badgeLabel),
        SizedBox(
          width: _chevronSlot,
          child: showChevron
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: AppColors.tertiaryLabel(context),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 16, color: c),
              ),
              const SizedBox(width: 10),
              CategoryColorDot(color: c, size: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: -0.1,
            ),
      ),
    );
  }
}
