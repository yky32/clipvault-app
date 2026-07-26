import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Shown only when Settings → App lock is ON.
/// Never appears by default.
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsService.instance.biometricLockEnabled) {
        if (mounted) context.go('/vault');
        return;
      }
      // Prompt once when lock is intentionally enabled.
      _unlock();
    });
  }

  Future<void> _unlock() async {
    if (_busy) return;
    if (!SettingsService.instance.biometricLockEnabled) {
      if (mounted) context.go('/vault');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context);
    final ok = await AppBootstrap.authService.authenticate(
      reason: l10n.unlockSubtitle,
    );

    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      context.go('/vault');
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _busy = false;
        _error = l10n.unlockFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.unlockTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.unlockSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryLabel(context),
                    fontSize: 16,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                if (_busy)
                  const CupertinoActivityIndicator()
                else
                  CupertinoButton.filled(
                    onPressed: _unlock,
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.lock_open_fill, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.unlockButton),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
