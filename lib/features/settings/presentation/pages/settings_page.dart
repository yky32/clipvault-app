import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _biometric;
  late VaultViewMode _viewMode;
  late int _clipboardSeconds;

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _biometric = s.biometricLockEnabled;
    _viewMode = s.defaultViewMode;
    _clipboardSeconds = s.clipboardClearSeconds;
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final can = await AppBootstrap.authService.canCheckBiometrics();
      if (!can) {
        if (!mounted) return;
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Unavailable'),
            content: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Biometrics / device lock is not available.'),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      final ok = await AppBootstrap.authService.authenticate(
        reason: 'Enable app lock for ClipVault',
      );
      if (!ok) return;
    }
    await SettingsService.instance.setBiometricLockEnabled(value);
    HapticFeedback.selectionClick();
    setState(() => _biometric = value);
  }

  Future<void> _pickTheme(ThemeController controller) async {
    final l10n = AppLocalizations.of(context);
    final mode = await showCupertinoModalPopup<ThemeMode>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.themeMode),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ThemeMode.system),
            child: Text(l10n.themeSystem),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ThemeMode.light),
            child: Text(l10n.themeLight),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ThemeMode.dark),
            child: Text(l10n.themeDark),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (mode != null) {
      await controller.setThemeMode(mode);
      setState(() {});
    }
  }

  Future<void> _pickClipboardTimeout() async {
    final l10n = AppLocalizations.of(context);
    final value = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.clipboardAutoClear),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(l10n.clipboardNever),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 15),
            child: const Text('15 seconds'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 30),
            child: const Text('30 seconds'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 60),
            child: const Text('60 seconds'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (value != null) {
      await SettingsService.instance.setClipboardClearSeconds(value);
      setState(() => _clipboardSeconds = value);
    }
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };
  }

  String _clipboardLabel(AppLocalizations l10n) {
    if (_clipboardSeconds == 0) return l10n.clipboardNever;
    return '${_clipboardSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeController = ThemeScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor:
                AppColors.groupedBackground(context).withValues(alpha: 0.92),
            border: null,
            largeTitle: Text(l10n.settingsTitle),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => context.pop(),
              child: const Icon(
                CupertinoIcons.back,
                color: AppColors.primary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                IosGroup(
                  header: l10n.settingsSecurity,
                  footer: l10n.biometricLockSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.biometricLock,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.lock_shield_fill,
                        color: const Color(0xFF007AFF),
                      ),
                      trailing: CupertinoSwitch(
                        value: _biometric,
                        activeTrackColor: AppColors.success,
                        onChanged: _toggleBiometric,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsAppearance,
                  children: [
                    IosGroupTile(
                      title: l10n.themeMode,
                      leading: const _LeadingIcon(
                        icon: CupertinoIcons.moon_stars_fill,
                        color: Color(0xFF5856D6),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _themeLabel(themeController.themeMode, l10n),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 17,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                          const IosChevron(),
                        ],
                      ),
                      onTap: () => _pickTheme(themeController),
                    ),
                    IosGroupTile(
                      title: l10n.defaultView,
                      leading: const _LeadingIcon(
                        icon: CupertinoIcons.rectangle_grid_2x2_fill,
                        color: Color(0xFFAF52DE),
                      ),
                      trailing: CupertinoSlidingSegmentedControl<VaultViewMode>(
                        groupValue: _viewMode,
                        children: {
                          VaultViewMode.list: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              l10n.viewList,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          VaultViewMode.grid: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              l10n.viewGrid,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        },
                        onValueChanged: (mode) async {
                          if (mode == null) return;
                          HapticFeedback.selectionClick();
                          await SettingsService.instance
                              .setDefaultViewMode(mode);
                          setState(() => _viewMode = mode);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsClipboard,
                  footer: l10n.clipboardAutoClearSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.clipboardAutoClear,
                      leading: const _LeadingIcon(
                        icon: CupertinoIcons.doc_on_clipboard_fill,
                        color: Color(0xFFFF9500),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _clipboardLabel(l10n),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 17,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                          const IosChevron(),
                        ],
                      ),
                      onTap: _pickClipboardTimeout,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsData,
                  children: [
                    IosGroupTile(
                      title: l10n.exportPlain,
                      leading: const _LeadingIcon(
                        icon: CupertinoIcons.share_solid,
                        color: Color(0xFF34C759),
                      ),
                      trailing: const IosChevron(),
                      onTap: () async {
                        final text = await AppBootstrap.clipItemRepository
                            .exportPlainText();
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        HapticFeedback.lightImpact();
                        CopiedHud.show(
                          context,
                          message: l10n.copied('export'),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  'ClipVault',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0 · Local-only · AES-256',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: AppColors.tertiaryLabel(context),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: Colors.white),
    );
  }
}
