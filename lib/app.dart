import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';

import 'core/navigation/app_router.dart';
import 'core/services/settings_service.dart';
import 'core/services/share_intake_service.dart';
import 'core/services/widget_deep_link.dart';
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
  /// When we entered paused/hidden — used for auto-lock timeout (Phase D).
  DateTime? _backgroundedAt;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Backup delivery path; GoRouter redirect also handles clipval://copy.
    _widgetClickSub = HomeWidget.widgetClicked.listen(WidgetDeepLink.handle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeWidget.initiallyLaunchedFromHomeWidget()
          .then(WidgetDeepLink.handle);
      // Share Extension may have written App Group before cold start.
      ShareIntakeService.consumePending();
    });
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
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
        _backgroundedAt ??= DateTime.now();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // Share Extension opens host while we were backgrounded.
      ShareIntakeService.consumePending();
      if (_needsRelock) {
        _needsRelock = false;
        final started = _backgroundedAt;
        _backgroundedAt = null;
        _relockIfNeeded(backgroundedAt: started);
      }
    }
  }

  void _relockIfNeeded({DateTime? backgroundedAt}) {
    if (!SettingsService.instance.biometricLockEnabled) return;

    final timeout = SettingsService.instance.autoLockTimeoutSeconds;
    if (timeout > 0 && backgroundedAt != null) {
      final elapsed = DateTime.now().difference(backgroundedAt);
      if (elapsed < Duration(seconds: timeout)) {
        // Still within grace window — stay unlocked.
        return;
      }
    }

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
            SettingsService.instance.localePreferenceListenable,
          ]),
          builder: (context, _) {
            // Keep static AppColors in sync for this rebuild.
            PaletteControllerHolder.instance = widget.paletteController;
            final tokens = widget.paletteController.tokens;
            final localePref =
                SettingsService.instance.localePreferenceListenable.value;

            // Explicit override, or null → resolve from device below.
            final Locale? forcedLocale = switch (localePref) {
              AppLocalePreference.en => const Locale('en'),
              AppLocalePreference.zh => const Locale('zh'),
              AppLocalePreference.system => null,
            };

            return MaterialApp.router(
              title: 'ClipVal',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(tokens),
              darkTheme: AppTheme.dark(tokens),
              themeMode: widget.themeController.themeMode,
              locale: forcedLocale,
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
              ),
              localeResolutionCallback: (deviceLocale, supported) {
                // Settings override wins when set.
                if (forcedLocale != null) return forcedLocale;
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
