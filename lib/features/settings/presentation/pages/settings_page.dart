import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/build_info.dart';
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
  late GridTitleSize _gridTitleSize;
  late AppLocalePreference _localePref;
  late int _clipboardSeconds;
  String _versionLabel = '1.0.0';

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _biometric = s.biometricLockEnabled;
    _viewMode = s.defaultViewMode;
    _gridTitleSize = s.gridTitleSize;
    _localePref = s.localePreference;
    _clipboardSeconds = s.clipboardClearSeconds;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _versionLabel = info.version);
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context);
    if (value) {
      final can = await AppBootstrap.authService.canCheckBiometrics();
      if (!mounted) return;
      if (!can) {
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
        // Short system prompt copy — keep it clean (OS owns the sheet UI)
        reason: l10n.enableLockAuthReason,
      );
      if (!ok || !mounted) return;
    }
    await SettingsService.instance.setBiometricLockEnabled(value);
    if (!mounted) return;
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

  /// High-impact safety: confirm + re-auth when app lock is on, then export.
  Future<void> _exportPlainText(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.exportConfirmTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.exportConfirmBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.exportConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (SettingsService.instance.biometricLockEnabled) {
      final ok = await AppBootstrap.authService.authenticate(
        reason: l10n.exportAuthReason,
      );
      if (!ok || !context.mounted) {
        if (context.mounted) {
          HapticFeedback.heavyImpact();
          CopiedHud.show(context, message: l10n.exportCancelled);
        }
        return;
      }
    }

    final text = await AppBootstrap.clipItemRepository.exportPlainText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    CopiedHud.show(context, message: l10n.copied('export'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeController = ThemeScope.of(context);
    final paletteController = PaletteScope.of(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Back + title on one row (same pattern as Vault header)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.pop();
                      },
                      child: Icon(
                        CupertinoIcons.back,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.settingsTitle,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.37,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
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
                  footer: l10n.gridTitleSizeSubtitle,
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
                      title: l10n.language,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.globe,
                        color: AppColors.iconTheme,
                      ),
                      below: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<
                            AppLocalePreference>(
                          groupValue: _localePref,
                          children: {
                            AppLocalePreference.system:
                                _SegmentLabel(l10n.languageSystem),
                            AppLocalePreference.en:
                                _SegmentLabel(l10n.languageEng),
                            AppLocalePreference.zh:
                                _SegmentLabel(l10n.languageZh),
                          },
                          onValueChanged: (pref) async {
                            if (pref == null) return;
                            HapticFeedback.selectionClick();
                            await SettingsService.instance
                                .setLocalePreference(pref);
                            setState(() => _localePref = pref);
                          },
                        ),
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.defaultView,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.rectangle_grid_2x2_fill,
                        color: AppColors.iconView,
                      ),
                      // Full-width under title so 3 segments stay aligned
                      below: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<VaultViewMode>(
                          groupValue: _viewMode,
                          children: {
                            VaultViewMode.list: _SegmentLabel(l10n.viewList),
                            VaultViewMode.grid2:
                                _SegmentLabel(l10n.viewGrid2Label),
                            VaultViewMode.grid3:
                                _SegmentLabel(l10n.viewGrid3Label),
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
                    ),
                    IosGroupTile(
                      title: l10n.gridTitleSize,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.textformat_size,
                        color: AppColors.iconTheme,
                      ),
                      below: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<GridTitleSize>(
                          groupValue: _gridTitleSize,
                          children: {
                            GridTitleSize.large:
                                _SegmentLabel(l10n.gridTitleSizeLarge),
                            GridTitleSize.medium:
                                _SegmentLabel(l10n.gridTitleSizeMedium),
                            GridTitleSize.small:
                                _SegmentLabel(l10n.gridTitleSizeSmall),
                          },
                          onValueChanged: (size) async {
                            if (size == null) return;
                            HapticFeedback.selectionClick();
                            await SettingsService.instance
                                .setGridTitleSize(size);
                            setState(() => _gridTitleSize = size);
                          },
                        ),
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.colorPalette,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.paintbrush_fill,
                        color: AppColors.primary,
                      ),
                      below: Align(
                        alignment: Alignment.centerLeft,
                        child: _PaletteSegmentControl(
                          selected: paletteController.id,
                          onChanged: (id) async {
                            HapticFeedback.selectionClick();
                            await paletteController.setPalette(id);
                          },
                        ),
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
                      onTap: () => _exportPlainText(context),
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
                  BuildInfo.hasCommit
                      ? l10n.settingsFooterVersionWithCommit(
                          _versionLabel,
                          BuildInfo.shortCommit,
                        )
                      : l10n.settingsFooterVersion(_versionLabel),
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
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 4-button palette switch — full-width under the title row.
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
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final id in BrandPalettes.all)
            Expanded(
              child: _PaletteSegmentButton(
                id: id,
                label: _labels[id]!,
                selected: selected == id,
                onTap: () => onChanged(id),
              ),
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
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.cardBackground(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
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
