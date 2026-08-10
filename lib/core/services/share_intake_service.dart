import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

/// Pending text from the iOS Share Extension (App Group → host app).
class SharedClipPayload {
  const SharedClipPayload({required this.value, this.title});

  final String value;
  final String? title;
}

/// Reads one-shot share payload from the native App Group (no cloud).
///
/// Extension writes keys under [AppConstants.widgetAppGroupId], then opens
/// `clipval://share`. Host drains via method channel and opens the item editor.
abstract final class ShareIntakeService {
  static const _channel = MethodChannel('com.clipval/share');

  static void Function(SharedClipPayload payload)? onShare;

  static SharedClipPayload? _held;

  /// Drain App Group pending share (if any). Invokes [onShare] or holds.
  static Future<void> consumePending() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('takePendingShare');
      if (raw is! Map) return;
      final value = (raw['value'] as String?)?.trim() ?? '';
      if (value.isEmpty) return;
      final title = (raw['title'] as String?)?.trim();
      final payload = SharedClipPayload(
        value: value,
        title: (title != null && title.isNotEmpty) ? title : null,
      );
      _deliver(payload);
    } on MissingPluginException {
      // Android / tests without channel.
    } catch (_) {
      // Best-effort; never crash host.
    }
  }

  static void attach(void Function(SharedClipPayload payload) handler) {
    onShare = handler;
    final held = _held;
    if (held != null) {
      _held = null;
      handler(held);
    }
  }

  static void detach() {
    onShare = null;
  }

  static void _deliver(SharedClipPayload payload) {
    final handler = onShare;
    if (handler != null) {
      handler(payload);
    } else {
      _held = payload;
    }
  }

  /// True if [uri] is the share handoff deep link.
  static bool isShareUri(Uri uri) {
    if (uri.scheme != AppConstants.urlScheme) return false;
    if (uri.host == 'share') return true;
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'share') {
      return true;
    }
    return false;
  }
}
