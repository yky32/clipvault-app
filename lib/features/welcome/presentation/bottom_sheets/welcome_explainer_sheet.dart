import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// ~90% height welcome / what's-new explainer.
/// Shown once per marketing version (first install + App Store upgrades).
class WelcomeExplainerSheet extends StatelessWidget {
  const WelcomeExplainerSheet({
    required this.version,
    required this.isUpgrade,
    super.key,
  });

  final String version;
  final bool isUpgrade;

  /// Presents the sheet and marks [version] as seen when dismissed.
  static Future<void> show(
    BuildContext context, {
    required String version,
  }) {
    final isUpgrade = SettingsService.instance.welcomeSeenVersion != null &&
        SettingsService.instance.welcomeSeenVersion!.isNotEmpty;

    return ClipVaultBottomSheet.show<void>(
      context,
      child: WelcomeExplainerSheet(
        version: version,
        isUpgrade: isUpgrade,
      ),
    ).whenComplete(() async {
      // Swipe-down or CTA — always count as seen so it does not loop.
      await SettingsService.instance.markWelcomeSeen(version);
    });
  }

  Future<void> _dismiss(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = isUpgrade ? l10n.welcomeTitleUpgrade : l10n.welcomeTitle;
    final subtitle = isUpgrade
        ? l10n.welcomeSubtitleUpgrade(version)
        : l10n.welcomeSubtitle;
    final cta = isUpgrade ? l10n.welcomeCtaContinue : l10n.welcomeCta;

    // Cap height using the *available* modal height (after keyboard/safe area),
    // never a rigid fraction of the full physical screen.
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.sizeOf(context).height;
        final viewPad = MediaQuery.viewPaddingOf(context).bottom;
        final viewInset = MediaQuery.viewInsetsOf(context).bottom;
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (screenH - viewPad - viewInset);
        // Leave a little headroom so chrome + CTA never overflow.
        final sheetHeight = (available * 0.92).clamp(320.0, available);

        return SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: SheetScaffold(
            title: title,
            subtitle: subtitle,
            compactBody: false,
            centerTitle: true,
            showCloseButton: false,
            footer: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => _dismiss(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  cta,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WelcomeSection(
                  emoji: '🚀',
                  icon: CupertinoIcons.bolt_fill,
                  iconColor: AppColors.primary,
                  title: l10n.welcomeWhyTitle,
                  body: l10n.welcomeWhyBody,
                ),
                const _WelcomeDivider(),
                _WelcomeSection(
                  emoji: '🔒',
                  icon: CupertinoIcons.lock_shield_fill,
                  iconColor: AppColors.iconSecurity,
                  title: l10n.welcomeLocalTitle,
                  body: l10n.welcomeLocalBody,
                ),
                const _WelcomeDivider(),
                _WelcomeSection(
                  emoji: '☁️',
                  icon: CupertinoIcons.cloud,
                  iconColor: AppColors.primary,
                  title: l10n.welcomeIcloudTitle,
                  body: l10n.welcomeIcloudBody,
                ),
                const _WelcomeDivider(),
                _WelcomeSection(
                  emoji: '✨',
                  icon: CupertinoIcons.hand_point_right_fill,
                  iconColor: AppColors.iconView,
                  title: l10n.welcomeHowTitle,
                  body: l10n.welcomeHowBody,
                ),
                const _WelcomeDivider(),
                _WelcomeSection(
                  emoji: '💎',
                  icon: CupertinoIcons.star_fill,
                  iconColor: AppColors.iconExport,
                  title: l10n.welcomePromoTitle,
                  body: l10n.welcomePromoBody,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeDivider extends StatelessWidget {
  const _WelcomeDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.hairline(context),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({
    required this.emoji,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final String emoji;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$emoji  $title',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.35,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Satoshi',
            fontSize: 15,
            height: 1.45,
            letterSpacing: -0.15,
            color: AppColors.secondaryLabel(context),
          ),
        ),
      ],
    );
  }
}
