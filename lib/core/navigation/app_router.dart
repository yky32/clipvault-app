import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/lock/presentation/pages/lock_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/vault/bloc/vault_bloc.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../bootstrap/app_bootstrap.dart';
import '../constants/app_constants.dart';
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
    // Widget opens clipval://copy?id=… — treat as action, not a page route.
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == AppConstants.urlScheme ||
          WidgetDeepLink.isWidgetCopyUri(uri)) {
        // Fire-and-forget copy; do not await inside redirect.
        WidgetDeepLink.handle(uri);
        return WidgetDeepLink.landingLocation;
      }
      // go_router sometimes passes full custom-scheme URI as the location.
      final loc = state.matchedLocation;
      if (loc.startsWith('${AppConstants.urlScheme}:')) {
        final parsed = Uri.tryParse(loc);
        if (parsed != null && WidgetDeepLink.isWidgetCopyUri(parsed)) {
          WidgetDeepLink.handle(parsed);
          return WidgetDeepLink.landingLocation;
        }
        return WidgetDeepLink.landingLocation;
      }
      return null;
    },
    onException: (context, state, router) {
      final uri = state.uri;
      if (WidgetDeepLink.isWidgetCopyUri(uri) ||
          uri.scheme == AppConstants.urlScheme) {
        WidgetDeepLink.handle(uri);
        router.go(WidgetDeepLink.landingLocation);
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
