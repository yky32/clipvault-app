import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Truly empty vault (no items at all).
class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 24, 40, 48),
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
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Text(l10n.addFirstItem),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search / category filter returned zero rows — offer a clear next step.
class VaultFilterEmptyState extends StatelessWidget {
  const VaultFilterEmptyState({
    required this.searchQuery,
    required this.categoryName,
    required this.onClearSearch,
    required this.onShowAll,
    required this.onAdd,
    super.key,
  });

  final String searchQuery;
  final String? categoryName;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;
  final VoidCallback onAdd;

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
              hasSearch
                  ? CupertinoIcons.search
                  : CupertinoIcons.folder,
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
            const SizedBox(height: 24),
            if (hasSearch)
              CupertinoButton(
                onPressed: onClearSearch,
                child: Text(l10n.clearSearch),
              ),
            if (hasCategory && !hasSearch) ...[
              FilledButton(
                onPressed: onAdd,
                child: Text(l10n.addToCategory),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: onShowAll,
                child: Text(l10n.showAllItems),
              ),
            ],
            if (hasSearch && hasCategory)
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
