import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette_controller.dart';
import 'core/theme/theme_controller.dart';
import 'l10n/app_localizations.dart';

class ClipVaultApp extends StatelessWidget {
  const ClipVaultApp({
    required this.themeController,
    required this.paletteController,
    super.key,
  });

  final ThemeController themeController;
  final PaletteController paletteController;

  @override
  Widget build(BuildContext context) {
    PaletteControllerHolder.instance = paletteController;

    return ThemeScope(
      controller: themeController,
      child: PaletteScope(
        controller: paletteController,
        child: ListenableBuilder(
          listenable: Listenable.merge([themeController, paletteController]),
          builder: (context, _) {
            // Keep static AppColors in sync for this rebuild.
            PaletteControllerHolder.instance = paletteController;
            final tokens = paletteController.tokens;

            return MaterialApp.router(
              title: 'clipVAuLt',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(tokens),
              darkTheme: AppTheme.dark(tokens),
              themeMode: themeController.themeMode,
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
