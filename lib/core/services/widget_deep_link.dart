import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bootstrap/app_bootstrap.dart';
import '../constants/app_constants.dart';
import '../navigation/app_router.dart';
import '../widgets/copied_hud.dart';
import '../../l10n/app_localizations.dart';

/// Handles `clipval://copy?id=<uuid>` from the Home Screen widget.
///
/// Must not be treated as a GoRouter path — see [AppRouter] redirect.
abstract final class WidgetDeepLink {
  static String? _lastHandledId;
  static DateTime? _lastHandledAt;

  /// Returns true if [uri] is a ClipVal widget deep link we recognize.
  static bool isWidgetCopyUri(Uri uri) {
    if (uri.scheme != AppConstants.urlScheme) return false;
    // clipval://copy?id=…  or  clipval://copy/?id=…
    if (uri.host == 'copy') return true;
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'copy') {
      return true;
    }
    return false;
  }

  /// Copy the item and show HUD. Safe to call from redirect / HomeWidget / onException.
  static Future<void> handle(Uri? uri) async {
    if (uri == null || !isWidgetCopyUri(uri)) return;

    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return;

    // Debounce double delivery (GoRouter + HomeWidget can both fire).
    final now = DateTime.now();
    if (_lastHandledId == id &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastHandledId = id;
    _lastHandledAt = now;

    final item = AppBootstrap.clipItemRepository.getById(id);
    if (item == null) return;

    await AppBootstrap.clipboardService.copy(item.value);
    await AppBootstrap.clipItemRepository.markCopied(item.id);
    await AppBootstrap.widgetSnapshotService.sync();

    void showHud() {
      final ctx = AppRouter.rootKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      HapticFeedback.lightImpact();
      final l10n = AppLocalizations.of(ctx);
      CopiedHud.show(ctx, message: l10n.copied(item.title));
    }

    // Navigator may not be ready on cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showHud();
      // One more frame if first context was null (common on cold open).
      if (AppRouter.rootKey.currentContext == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => showHud());
      }
    });
  }

  /// Where to land after handling a widget deep link.
  static String get landingLocation {
    if (AppBootstrap.authService.requiresUnlock) return '/lock';
    return '/vault';
  }
}
