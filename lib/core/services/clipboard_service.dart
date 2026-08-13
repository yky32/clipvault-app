import 'dart:async';

import 'package:flutter/services.dart';

import 'settings_service.dart';

class ClipboardService {
  ClipboardService();

  Timer? _clearTimer;

  /// Last value ClipVal itself put on the pasteboard (skip suggest).
  String? lastSelfCopiedText;

  Future<void> copy(String value) async {
    _clearTimer?.cancel();
    lastSelfCopiedText = value;
    await Clipboard.setData(ClipboardData(text: value));

    final seconds = SettingsService.instance.clipboardClearSeconds;
    if (seconds > 0) {
      _clearTimer = Timer(Duration(seconds: seconds), () async {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }
  }

  /// Read plain text for suggest — never throws.
  Future<String?> readPlainText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final t = data?.text;
      if (t == null) return null;
      final trimmed = t.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
