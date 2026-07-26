import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen lock — modern brand gate. System Face ID / passcode is only
/// invoked after this UI paints (we cannot restyle the system sheet).
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!SettingsService.instance.biometricLockEnabled) {
        if (mounted) context.go('/vault');
        return;
      }
      // Let the brand screen settle before the system prompt.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) _unlock(auto: true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _unlock({bool auto = false}) async {
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
      reason: l10n.unlockAuthReason,
    );

    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      context.go('/vault');
    } else {
      if (!auto) HapticFeedback.heavyImpact();
      setState(() {
        _busy = false;
        _error = auto ? null : l10n.unlockFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = AppColors.pageBackground(context);
    final accent = AppColors.primary;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft atmospheric background
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        page,
                        accent.withValues(alpha: 0.12),
                        page,
                      ]
                    : [
                        page,
                        Color.lerp(page, accent, 0.06)!,
                        page,
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // Ambient glow
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final t = 0.55 + (_pulse.value * 0.45);
                  return Container(
                    width: 220 * t,
                    height: 220 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: isDark ? 0.18 : 0.14),
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Brand monogram glass
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.7),
                            width: 0.6,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.white.withValues(alpha: 0.12),
                                    Colors.white.withValues(alpha: 0.04),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.55),
                                  ],
                          ),
                          boxShadow: AppShadows.island(context),
                        ),
                        child: Icon(
                          CupertinoIcons.lock_fill,
                          size: 36,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.label(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.unlockSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: AppColors.secondaryLabel(context),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                  // Primary unlock control
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _busy ? null : () => _unlock(auto: false),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            accent.withValues(alpha: 0.45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.lock_open_fill,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.unlockButton,
                                  style: const TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.unlockHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: AppColors.tertiaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
