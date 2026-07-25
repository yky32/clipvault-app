import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/theme_controller.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometrics / device lock not available'),
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
    setState(() => _biometric = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeController = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(l10n.settingsSecurity),
          SwitchListTile.adaptive(
            title: Text(l10n.biometricLock),
            subtitle: Text(l10n.biometricLockSubtitle),
            value: _biometric,
            onChanged: _toggleBiometric,
          ),
          const Divider(height: 24),
          _SectionHeader(l10n.settingsAppearance),
          ListTile(
            title: Text(l10n.themeMode),
            subtitle: Text(
              switch (themeController.themeMode) {
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
                ThemeMode.system => l10n.themeSystem,
              },
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final mode = await showModalBottomSheet<ThemeMode>(
                context: context,
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(l10n.themeSystem),
                        onTap: () => Navigator.pop(ctx, ThemeMode.system),
                      ),
                      ListTile(
                        title: Text(l10n.themeLight),
                        onTap: () => Navigator.pop(ctx, ThemeMode.light),
                      ),
                      ListTile(
                        title: Text(l10n.themeDark),
                        onTap: () => Navigator.pop(ctx, ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              );
              if (mode != null) await themeController.setThemeMode(mode);
              setState(() {});
            },
          ),
          ListTile(
            title: Text(l10n.defaultView),
            subtitle: Text(
              _viewMode == VaultViewMode.grid
                  ? l10n.viewGrid
                  : l10n.viewList,
            ),
            trailing: SegmentedButton<VaultViewMode>(
              segments: [
                ButtonSegment(
                  value: VaultViewMode.list,
                  icon: const Icon(Icons.view_list_rounded, size: 18),
                  label: Text(l10n.viewList),
                ),
                ButtonSegment(
                  value: VaultViewMode.grid,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(l10n.viewGrid),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (set) async {
                final mode = set.first;
                await SettingsService.instance.setDefaultViewMode(mode);
                setState(() => _viewMode = mode);
              },
            ),
          ),
          const Divider(height: 24),
          _SectionHeader(l10n.settingsClipboard),
          ListTile(
            title: Text(l10n.clipboardAutoClear),
            subtitle: Text(l10n.clipboardAutoClearSubtitle),
            trailing: DropdownButton<int>(
              value: _clipboardSeconds,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.clipboardNever)),
                const DropdownMenuItem(value: 15, child: Text('15s')),
                const DropdownMenuItem(value: 30, child: Text('30s')),
                const DropdownMenuItem(value: 60, child: Text('60s')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await SettingsService.instance.setClipboardClearSeconds(v);
                setState(() => _clipboardSeconds = v);
              },
            ),
          ),
          const Divider(height: 24),
          _SectionHeader(l10n.settingsData),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(l10n.exportPlain),
            onTap: () async {
              final text =
                  await AppBootstrap.clipItemRepository.exportPlainText();
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.copied('export'))),
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ClipVault v1.0.0 · Local-only · AES-256',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
