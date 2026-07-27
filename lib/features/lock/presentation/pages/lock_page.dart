import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen lock — brand gate with app icon.
/// System Face ID / passcode sheet is invoked automatically (and via the
/// biometric control). We cannot restyle the OS auth UI.
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  UnlockBiometricKind _kind = UnlockBiometricKind.devicePasscode;
  late final AnimationController _pulse;

  static const _appIconAsset =
      'assets/icon/app-icons/source/app-icon-1024.png';

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
      final kind = await AppBootstrap.authService.preferredUnlockKind();
      if (mounted) setState(() => _kind = kind);
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

  IconData get _unlockIcon {
    return switch (_kind) {
      UnlockBiometricKind.faceId => Icons.face_outlined,
      UnlockBiometricKind.touchId ||
      UnlockBiometricKind.fingerprint =>
        Icons.fingerprint,
      UnlockBiometricKind.strongBiometric => Icons.fingerprint,
      UnlockBiometricKind.devicePasscode => CupertinoIcons.lock_fill,
    };
  }

  String _unlockLabel(AppLocalizations l10n) {
    return switch (_kind) {
      UnlockBiometricKind.faceId => l10n.unlockWithFaceId,
      UnlockBiometricKind.touchId ||
      UnlockBiometricKind.fingerprint =>
        l10n.unlockWithTouchId,
      UnlockBiometricKind.strongBiometric => l10n.unlockWithBiometrics,
      UnlockBiometricKind.devicePasscode => l10n.unlockWithPasscode,
    };
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
                  // App icon — mask white marketing fringes (flattened 1024 PNG).
                  _LockAppIcon(
                    asset: _appIconAsset,
                    size: 96,
                    accent: accent,
                    isDark: isDark,
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
                  // Device-aware unlock control (no full-width button)
                  Opacity(
                    opacity: _busy ? 0.45 : 1,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      onPressed: _busy ? null : () => _unlock(auto: false),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_busy)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CupertinoActivityIndicator(
                                color: accent,
                              ),
                            )
                          else
                            Icon(
                              _unlockIcon,
                              size: 40,
                              color: accent,
                            ),
                          const SizedBox(height: 10),
                          Text(
                            _unlockLabel(l10n),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded brand mark without white edge cracks from marketing assets.
class _LockAppIcon extends StatelessWidget {
  const _LockAppIcon({
    required this.asset,
    required this.size,
    required this.accent,
    required this.isDark,
  });

  final String asset;
  final double size;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // iOS-like continuous corner (~22% of side).
    final radius = BorderRadius.circular(size * 0.223);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        // Match lock atmosphere so any residual fringe is invisible.
        color: isDark ? const Color(0xFF152038) : const Color(0xFFE8E4DC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scale past 1.0 crops baked-in white corner padding from App Store PNG.
            Transform.scale(
              scale: 1.08,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: accent.withValues(alpha: 0.15),
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    size: size * 0.38,
                    color: accent,
                  ),
                ),
              ),
            ),
            // Hairline inner ring softens the mask edge (no white crack).
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
