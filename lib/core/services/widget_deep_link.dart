import 'dart:async';

import 'package:flutter/services.dart';

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

  /// Full-screen flash (not vault). Pasteboard already written natively.
  static const copyFlashLocation = '/widget-copy';

  /// True only during the brief window after a widget copy (so resume later
  /// does not leave the user stuck on Copied).
  static bool get isFreshFlash {
    final at = _lastHandledAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(seconds: 3);
  }

  /// After bounce / user returns — next /widget-copy visit goes to vault.
  static void consumeFlash() {
    _lastHandledAt = null;
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

    // Re-write after Flutter settle, then request bounce (native times it).
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
