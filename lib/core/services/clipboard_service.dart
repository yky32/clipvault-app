import 'dart:async';

import 'package:flutter/services.dart';

import 'settings_service.dart';

class ClipboardService {
  ClipboardService();

  Timer? _clearTimer;

  Future<void> copy(String value) async {
    _clearTimer?.cancel();
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

  void dispose() {
    _clearTimer?.cancel();
  }
}
