import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/lock/presentation/pages/lock_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/vault/bloc/vault_bloc.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../../features/widget_copy/presentation/pages/widget_copy_flash_page.dart';
import '../bootstrap/app_bootstrap.dart';
import '../constants/app_constants.dart';
import '../services/share_intake_service.dart';
import '../services/widget_deep_link.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();

  /// Welcome explainer is a bottom sheet on Vault (version-gated), not a route.
  /// Legacy `/onboarding` remains for deep links / older installs mid-flow.
  static String get initialLocation {
    if (AppBootstrap.authService.requiresUnlock) return '/lock';
    return '/vault';
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    // Widget opens clipval://copy?id=… — flash page, not vault.
    redirect: (context, state) {
      final uri = state.uri;
      if (ShareIntakeService.isShareUri(uri)) {
        ShareIntakeService.consumePending();
        return WidgetDeepLink.vaultLandingLocation;
      }
      if (uri.scheme == AppConstants.urlScheme ||
          WidgetDeepLink.isWidgetCopyUri(uri)) {
        // Fire-and-forget copy; do not await inside redirect.
        WidgetDeepLink.handle(uri);
        return WidgetDeepLink.copyFlashLocation;
      }
      // go_router sometimes passes full custom-scheme URI as the location.
      final loc = state.matchedLocation;
      if (loc.startsWith('${AppConstants.urlScheme}:')) {
        final parsed = Uri.tryParse(loc);
        if (parsed != null) {
          if (ShareIntakeService.isShareUri(parsed)) {
            ShareIntakeService.consumePending();
            return WidgetDeepLink.vaultLandingLocation;
          }
          if (WidgetDeepLink.isWidgetCopyUri(parsed)) {
            WidgetDeepLink.handle(parsed);
            return WidgetDeepLink.copyFlashLocation;
          }
        }
        return WidgetDeepLink.copyFlashLocation;
      }
      // Re-open after bounce: do not trap on Copied flash.
      if (loc == WidgetDeepLink.copyFlashLocation &&
          !WidgetDeepLink.isFreshFlash) {
        return WidgetDeepLink.vaultLandingLocation;
      }
      return null;
    },
    onException: (context, state, router) {
      final uri = state.uri;
      if (ShareIntakeService.isShareUri(uri)) {
        ShareIntakeService.consumePending();
        router.go(WidgetDeepLink.vaultLandingLocation);
        return;
      }
      if (WidgetDeepLink.isWidgetCopyUri(uri) ||
          uri.scheme == AppConstants.urlScheme) {
        WidgetDeepLink.handle(uri);
        router.go(WidgetDeepLink.copyFlashLocation);
        return;
      }
      // Fallback: unknown routes → vault
      router.go(initialLocation);
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (_, __) => const LockPage(),
      ),
      // Widget copy flash — outside vault shell (no list chrome).
      GoRoute(
        path: WidgetDeepLink.copyFlashLocation,
        name: 'widget-copy-flash',
        builder: (_, __) => const WidgetCopyFlashPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider(
            create: (_) => VaultBloc(
              itemRepository: AppBootstrap.clipItemRepository,
              categoryRepository: AppBootstrap.categoryRepository,
              clipboardService: AppBootstrap.clipboardService,
            )..add(const VaultStarted()),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/vault',
            name: 'vault',
            builder: (_, __) => const VaultPage(),
            routes: [
              // User input (add/edit item) → bottom sheet, not a route page
              // (Triftly pattern via ItemEditorBottomSheet.show)
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
