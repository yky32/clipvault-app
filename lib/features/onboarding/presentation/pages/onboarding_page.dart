import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  /// Finish onboarding and go straight to the vault.
  /// App lock is never forced here — only via Settings toggle.
  Future<void> _finish() async {
    await SettingsService.instance.setOnboardingDone(true);
    if (!mounted) return;
    context.go('/vault');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      _OnboardSlide(
        icon: CupertinoIcons.doc_on_clipboard_fill,
        color: AppColors.primary,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      _OnboardSlide(
        icon: CupertinoIcons.lock_shield_fill,
        color: AppColors.accentDark,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
      ),
      _OnboardSlide(
        icon: CupertinoIcons.hand_raised_fill,
        color: AppColors.iconView,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _finish();
                },
                child: Text(
                  l10n.skip,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  width: _index == i ? 8 : 7,
                  height: _index == i ? 8 : 7,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? AppColors.primary
                        : AppColors.tertiaryLabel(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (_index < pages.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    _finish();
                  }
                },
                child: Text(
                  _index < pages.length - 1 ? l10n.next : l10n.getStarted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 44, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.secondaryLabel(context),
              height: 1.45,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
