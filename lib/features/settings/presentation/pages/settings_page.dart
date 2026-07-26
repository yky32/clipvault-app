import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _paletteTitle(BrandPaletteId id, AppLocalizations l10n) {
    return switch (id) {
      BrandPaletteId.deepBrown => l10n.paletteDeepBrown,
      BrandPaletteId.warmGrey => l10n.paletteWarmGrey,
      BrandPaletteId.woodBlue => l10n.paletteWoodBlue,
      BrandPaletteId.inkBlue => l10n.paletteInkBlue,
    };
  }

  String _paletteCaption(BrandPaletteId id, AppLocalizations l10n) {
    return switch (id) {
      BrandPaletteId.deepBrown => l10n.paletteDeepBrownCaption,
      BrandPaletteId.warmGrey => l10n.paletteWarmGreyCaption,
      BrandPaletteId.woodBlue => l10n.paletteWoodBlueCaption,
      BrandPaletteId.inkBlue => l10n.paletteInkBlueCaption,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeController = ThemeScope.of(context);
    final paletteController = PaletteScope.of(context);
    final selectedPalette = paletteController.id;

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
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.colorPalette,
                  footer: l10n.colorPaletteSubtitle,
                  children: [
                    for (final id in BrandPalettes.all)
                      _PaletteOption(
                        id: id,
                        title: _paletteTitle(id, l10n),
                        caption: _paletteCaption(id, l10n),
                        selected: selectedPalette == id,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await paletteController.setPalette(id);
                        },
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

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.id,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final BrandPaletteId id;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = BrandPalettes.of(id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _PaletteSwatch(tokens: tokens),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryLabel(context),
                          ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 20,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.tokens});

  final BrandPaletteTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Preview: 60% / 30% / 10% strip (Higgs ratio)
    final page = tokens.appPageLight;
    final card = tokens.appCardLight;
    final accent = tokens.accent10;

    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(flex: 6, child: ColoredBox(color: page)),
          Expanded(flex: 3, child: ColoredBox(color: card)),
          Expanded(flex: 1, child: ColoredBox(color: accent)),
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
