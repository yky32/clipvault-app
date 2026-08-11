import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/default_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Prefill payload when user taps an empty-state starter chip.
class VaultStarter {
  const VaultStarter({
    required this.title,
    required this.systemKey,
  });

  final String title;
  final String systemKey;

  String get categoryId => DefaultCategories.boxId(systemKey);
}

/// Truly empty vault — CTA + starter chips for first 60s activation (P0).
class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({
    this.onAdd,
    this.onStarter,
    super.key,
  });

  final VoidCallback? onAdd;
  final void Function(VaultStarter starter)? onStarter;

  static List<VaultStarter> startersFor(AppLocalizations l10n) => [
        VaultStarter(
          title: l10n.starterWifiTitle,
          systemKey: DefaultCategories.wifi,
        ),
        VaultStarter(
          title: l10n.starterFpsTitle,
          systemKey: DefaultCategories.banking,
        ),
        VaultStarter(
          title: l10n.starterAddressTitle,
          systemKey: DefaultCategories.addresses,
        ),
        VaultStarter(
          title: l10n.starterApiTitle,
          systemKey: DefaultCategories.developer,
        ),
        VaultStarter(
          title: l10n.starterPromoTitle,
          systemKey: DefaultCategories.codes,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final starters = startersFor(l10n);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.lock_shield_fill,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.emptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryLabel(context),
                height: 1.4,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onAdd!();
                  },
                  icon: const Icon(CupertinoIcons.add, size: 18),
                  label: Text(l10n.emptyAddFirst),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            if (onStarter != null) ...[
              const SizedBox(height: 28),
              Text(
                l10n.emptyStartersLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.tertiaryLabel(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: starters.map((s) {
                  return ActionChip(
                    label: Text(s.title),
                    avatar: Icon(
                      _iconFor(s.systemKey),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onStarter!(s);
                    },
                    backgroundColor: AppColors.cardBackground(context),
                    side: BorderSide(color: AppColors.hairline(context)),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.emptyShareHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.tertiaryLabel(context),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String systemKey) {
    return switch (systemKey) {
      DefaultCategories.wifi => CupertinoIcons.wifi,
      DefaultCategories.banking => CupertinoIcons.creditcard,
      DefaultCategories.addresses => CupertinoIcons.location,
      DefaultCategories.developer => CupertinoIcons.chevron_left_slash_chevron_right,
      DefaultCategories.codes => CupertinoIcons.tag,
      _ => CupertinoIcons.doc_on_clipboard,
    };
  }
}

/// Search / category filter returned zero rows — keep it clean (header + still works).
class VaultFilterEmptyState extends StatelessWidget {
  const VaultFilterEmptyState({
    required this.searchQuery,
    required this.categoryName,
    required this.onClearSearch,
    required this.onShowAll,
    super.key,
  });

  final String searchQuery;
  final String? categoryName;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasSearch = searchQuery.trim().isNotEmpty;
    final hasCategory = categoryName != null && categoryName!.isNotEmpty;

    final String message;
    if (hasSearch) {
      message = l10n.noMatchesSearch(searchQuery.trim());
    } else if (hasCategory) {
      message = l10n.noMatchesCategory(categoryName!);
    } else {
      message = l10n.noMatchesTitle;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? CupertinoIcons.search : CupertinoIcons.folder,
              size: 40,
              color: AppColors.tertiaryLabel(context),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noMatchesTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryLabel(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (hasSearch)
              CupertinoButton(
                onPressed: onClearSearch,
                child: Text(l10n.clearSearch),
              ),
            if (hasCategory)
              CupertinoButton(
                onPressed: onShowAll,
                child: Text(l10n.showAllItems),
              ),
          ],
        ),
      ),
    );
  }
}
