import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

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
              child: const Icon(
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
