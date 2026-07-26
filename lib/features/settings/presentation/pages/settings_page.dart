import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_palette.dart';
import '../../../../core/theme/palette_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/bottom_sheets/category_manage_bottom_sheet.dart';
import '../../../vault/bloc/vault_bloc.dart';

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
        reason: 'Enable app lock for clipVauLt',
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
    final paletteController = PaletteScope.of(context);

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
              child: Icon(
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
                        color: AppColors.iconSecurity,
                      ),
                      trailing: CupertinoSwitch(
                        value: _biometric,
                        activeTrackColor: AppColors.primary,
                        onChanged: _toggleBiometric,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsAppearance,
                  footer: l10n.colorPaletteSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.themeMode,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.moon_stars_fill,
                        color: AppColors.iconTheme,
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
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.rectangle_grid_2x2_fill,
                        color: AppColors.iconView,
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
                    // Single row · 4-way palette switch (like Default view)
                    IosGroupTile(
                      title: l10n.colorPalette,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.paintbrush_fill,
                        color: AppColors.primary,
                      ),
                      trailing: _PaletteSegmentControl(
                        selected: paletteController.id,
                        onChanged: (id) async {
                          HapticFeedback.selectionClick();
                          await paletteController.setPalette(id);
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
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.doc_on_clipboard_fill,
                        color: AppColors.iconClipboard,
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
                  header: l10n.categoryManageTitle,
                  footer: l10n.categoryManageSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.categoryManageTitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.tag_fill,
                        color: AppColors.iconView,
                      ),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await CategoryManageBottomSheet.show(context);
                        if (!context.mounted) return;
                        // Refresh vault chips if shell has VaultBloc.
                        try {
                          context
                              .read<VaultBloc>()
                              .add(const VaultRefreshed());
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsData,
                  children: [
                    IosGroupTile(
                      title: l10n.exportPlain,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.share_solid,
                        color: AppColors.iconExport,
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
                  AppConstants.appName,
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

/// 4-button palette switch — same row pattern as List / Grid.
class _PaletteSegmentControl extends StatelessWidget {
  const _PaletteSegmentControl({
    required this.selected,
    required this.onChanged,
  });

  final BrandPaletteId selected;
  final ValueChanged<BrandPaletteId> onChanged;

  static const _labels = {
    BrandPaletteId.deepBrown: '01',
    BrandPaletteId.warmGrey: '02',
    BrandPaletteId.woodBlue: '05',
    BrandPaletteId.inkBlue: '06',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark
        ? AppColors.surfaceElevatedDark
        : const Color(0xFFE8E5DF);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in BrandPalettes.all)
            _PaletteSegmentButton(
              id: id,
              label: _labels[id]!,
              selected: selected == id,
              onTap: () => onChanged(id),
            ),
        ],
      ),
    );
  }
}

class _PaletteSegmentButton extends StatelessWidget {
  const _PaletteSegmentButton({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BrandPaletteId id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = BrandPalettes.of(id);
    final accent = tokens.accent10;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 40,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardBackground(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.secondaryLabel(context),
              ),
            ),
          ],
        ),
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
