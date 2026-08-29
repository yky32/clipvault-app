import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../bootstrap/app_bootstrap.dart';
import '../constants/app_constants.dart';

/// Handles `clipval://copy?id=<uuid>` from the Home Screen widget.
///
/// Must not be treated as a GoRouter path — see [AppRouter] redirect.
/// UX (option A): land on `/widget-copy` full-screen flash — not vault.
abstract final class WidgetDeepLink {
  static String? _lastHandledId;
  static DateTime? _lastHandledAt;
  static const _channel = MethodChannel('com.clipval/widget');

  /// Shown on WidgetCopyFlashPage after a widget copy.
  static String? lastFlashTitle;
  static int? lastFlashChars;

  /// Increments on every widget copy so flash page can refresh (2nd tap).
  static final ValueNotifier<int> flashTick = ValueNotifier<int>(0);

  /// Full-screen flash (not vault). Pasteboard already written natively.
  static const copyFlashLocation = '/widget-copy';

  /// True only during the brief window after a widget copy.
  static bool get isFreshFlash {
    final at = _lastHandledAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(seconds: 4);
  }

  static void consumeFlash() {
    _lastHandledAt = null;
  }

  /// 2nd widget tap while ClipVal is already coming to foreground — stay
  /// on Copied (do not bounce Home) so user can exit to vault.
  static bool get _isDoubleTapStay {
    final at = _lastHandledAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(seconds: 4);
  }

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

  /// Copy the item. Safe to call from redirect / HomeWidget / onException.
  /// Does **not** show vault HUD — flash page is the UX surface.
  static Future<void> handle(Uri? uri) async {
    if (uri == null || !isWidgetCopyUri(uri)) return;

    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return;

    final now = DateTime.now();
    // Same URL delivered twice by GoRouter+HomeWidget (~same instant).
    if (_lastHandledId == id &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(milliseconds: 400)) {
      return;
    }

    // Second widget tap within a few seconds: copy again, stay in foreground.
    final stayInApp = _isDoubleTapStay;
    _lastHandledId = id;
    _lastHandledAt = now;

    String? value;
    String title = 'ClipVal';
    int? chars;

    final item = AppBootstrap.clipItemRepository.getById(id);
    if (item != null && item.value.trim().isNotEmpty) {
      value = item.value;
      title = item.title.trim().isEmpty ? title : item.title;
      chars = value.length;
      await AppBootstrap.clipboardService.copy(value);
      await _forceNativePasteboard(value);
      unawaited(AppBootstrap.clipItemRepository.markCopied(item.id));
      unawaited(AppBootstrap.widgetSnapshotService.sync());
    } else {
      // Vault locked / not ready — AppDelegate should have written from App Group.
      try {
        final res = await _channel.invokeMethod<dynamic>(
          'forcePasteboardById',
          {'id': id},
        );
        if (res is Map) {
          if (res['chars'] is int) chars = res['chars'] as int;
          final t = res['title'];
          if (t is String && t.trim().isNotEmpty) title = t.trim();
        }
      } catch (_) {
        try {
          await _channel.invokeMethod<void>('rehydratePaste');
        } catch (_) {}
      }
    }

    lastFlashTitle = title;
    lastFlashChars = chars ?? value?.length;
    flashTick.value++;

    if (stayInApp) {
      // User tapped widget again — ClipVal is foreground. Cancel bounce so
      // they can leave Copied via Open vault (not trapped / not auto-home).
      try {
        await _channel.invokeMethod<void>('cancelBounce');
      } catch (_) {}
      if (value != null && value.trim().isNotEmpty) {
        await _forceNativePasteboard(value);
      }
      return;
    }

    // First tap from Home: re-write then bounce.
    if (value != null && value.trim().isNotEmpty) {
      final v = value;
      await _forceNativePasteboard(v);
      unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () async {
        await _forceNativePasteboard(v);
      }));
      unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () async {
        await _forceNativePasteboard(v);
        try {
          await _channel.invokeMethod<void>('bounceIfWidgetCopy');
        } catch (_) {}
      }));
    } else {
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
      unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () async {
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

  /// Share / non-copy deep links still land on vault (or lock).
  static String get vaultLandingLocation {
    if (AppBootstrap.authService.requiresUnlock) return '/lock';
    return '/vault';
  }

  /// Widget copy → flash page (option A UX). Never vault chrome.
  static String get landingLocation => copyFlashLocation;
}
