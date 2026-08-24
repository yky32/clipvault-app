import 'dart:async';

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
  static const _channel = MethodChannel('com.clipval/widget');

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

    String? value;
    String title = 'ClipVal';

    final item = AppBootstrap.clipItemRepository.getById(id);
    if (item != null && item.value.trim().isNotEmpty) {
      value = item.value;
      title = item.title.trim().isEmpty ? title : item.title;
      await AppBootstrap.clipboardService.copy(value);
      await _forceNativePasteboard(value);
      unawaited(AppBootstrap.clipItemRepository.markCopied(item.id));
      unawaited(AppBootstrap.widgetSnapshotService.sync());
    } else {
      // Vault locked / not ready — AppDelegate should have written from App Group.
      // Reinforce via native id lookup.
      try {
        final res = await _channel.invokeMethod<dynamic>(
          'forcePasteboardById',
          {'id': id},
        );
        if (res is Map && res['chars'] is int) {
          final chars = res['chars'] as int;
          if (chars <= 0) {
            _showHud('Copy failed — open vault once');
            return;
          }
          title = 'Copied ($chars chars)';
        }
      } catch (_) {
        try {
          await _channel.invokeMethod<void>('rehydratePaste');
        } catch (_) {}
      }
    }

    // Re-write after Flutter settle, then request bounce (native times it).
    if (value != null && value.trim().isNotEmpty) {
      final v = value;
      await _forceNativePasteboard(v);
      _showHud(
        '${title.length > 28 ? '${title.substring(0, 28)}…' : title} · ${value.length} chars',
      );
      unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () async {
        await _forceNativePasteboard(v);
      }));
      unawaited(Future<void>.delayed(const Duration(milliseconds: 800), () async {
        await _forceNativePasteboard(v);
        try {
          await _channel.invokeMethod<void>('bounceIfWidgetCopy');
        } catch (_) {}
      }));
    } else {
      // Native should still have written from App Group — reinforce + bounce
      try {
        await _channel.invokeMethod<void>(
          'forcePasteboardById',
          {'id': id},
        );
      } catch (_) {
        try {
          await _channel.invokeMethod<void>('rehydratePaste');
        } catch (_) {}
      }
      _showHud(title.startsWith('Copied') ? title : 'Copied');
      unawaited(Future<void>.delayed(const Duration(milliseconds: 800), () async {
        try {
          await _channel.invokeMethod<void>('bounceIfWidgetCopy');
        } catch (_) {}
      }));
    }
  }

  static Future<void> _forceNativePasteboard(String value) async {
    final t = value.trim();
    if (t.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('forcePasteboard', {'value': t});
    } catch (_) {}
  }

  static void _showHud(String message) {
    void show() {
      final ctx = AppRouter.rootKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      HapticFeedback.mediumImpact();
      // Prefer l10n when simple copied; otherwise show diagnostic message.
      try {
        final l10n = AppLocalizations.of(ctx);
        if (message.startsWith('Copied') || message.contains('chars')) {
          CopiedHud.show(ctx, message: message);
        } else {
          CopiedHud.show(ctx, message: l10n.copied(message));
        }
      } catch (_) {
        CopiedHud.show(ctx, message: message);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      show();
      if (AppRouter.rootKey.currentContext == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => show());
      }
    });
  }

  /// Where to land after handling a widget deep link.
  static String get landingLocation {
    if (AppBootstrap.authService.requiresUnlock) return '/lock';
    return '/vault';
  }
}
