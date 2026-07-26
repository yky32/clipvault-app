import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_router.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette_controller.dart';
import 'core/theme/theme_controller.dart';
import 'l10n/app_localizations.dart';

class ClipVaultApp extends StatefulWidget {
  const ClipVaultApp({
    required this.themeController,
    required this.paletteController,
    super.key,
  });

  final ThemeController themeController;
  final PaletteController paletteController;

  @override
  State<ClipVaultApp> createState() => _ClipVaultAppState();
}

class _ClipVaultAppState extends State<ClipVaultApp>
    with WidgetsBindingObserver {
  /// True after the app was fully backgrounded (not just inactive for Face ID).
  bool _needsRelock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use paused/hidden so OS auth sheets (inactive) do not false-trigger.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (SettingsService.instance.biometricLockEnabled) {
        _needsRelock = true;
      }
      return;
    }

    if (state == AppLifecycleState.resumed && _needsRelock) {
      _needsRelock = false;
      _relockIfNeeded();
    }
  }

  void _relockIfNeeded() {
    if (!SettingsService.instance.biometricLockEnabled) return;

    final location =
        AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (location == '/lock' || location == '/onboarding') return;

    AppRouter.router.go('/lock');
  }

  @override
  Widget build(BuildContext context) {
    PaletteControllerHolder.instance = widget.paletteController;

    return ThemeScope(
      controller: widget.themeController,
      child: PaletteScope(
        controller: widget.paletteController,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            widget.themeController,
            widget.paletteController,
          ]),
          builder: (context, _) {
            // Keep static AppColors in sync for this rebuild.
            PaletteControllerHolder.instance = widget.paletteController;
            final tokens = widget.paletteController.tokens;

            return MaterialApp.router(
              title: 'clipVAuLt',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(tokens),
              darkTheme: AppTheme.dark(tokens),
              themeMode: widget.themeController.themeMode,
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
              ),
              localeResolutionCallback: (deviceLocale, supported) {
                if (deviceLocale != null &&
                    deviceLocale.languageCode == 'zh') {
                  return const Locale('zh');
                }
                return const Locale('en');
              },
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}
