import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/lock/presentation/pages/lock_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/vault/bloc/vault_bloc.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../bootstrap/app_bootstrap.dart';
import '../services/settings_service.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();

  static String get initialLocation {
    if (!SettingsService.instance.onboardingDone) return '/onboarding';
    if (AppBootstrap.authService.requiresUnlock) return '/lock';
    return '/vault';
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
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
