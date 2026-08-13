import '../models/clip_item.dart';
import 'clipboard_service.dart';
import 'clip_item_repository.dart';
import 'nearby/nearby_crypto.dart';
import 'settings_service.dart';
import '../utils/app_log.dart';

/// Decides whether to surface "Save clipboard to ClipVal?"
///
/// [readText] / [existingValues] injectable for unit tests.
class ClipboardSuggestService {
  ClipboardSuggestService({
    required ClipboardService clipboard,
    ClipItemRepository? items,
    Future<String?> Function()? readText,
    Iterable<String> Function()? existingValues,
  })  : _clipboard = clipboard,
        _items = items,
        _readText = readText,
        _existingValues = existingValues {
    assert(
      items != null || existingValues != null,
      'items or existingValues required',
    );
  }

  final ClipboardService _clipboard;
  final ClipItemRepository? _items;
  final Future<String?> Function()? _readText;
  final Iterable<String> Function()? _existingValues;

  static const maxLen = 4000;
  static const minLen = 1;

  Future<String?> evaluate() async {
    if (!SettingsService.instance.clipboardSuggestEnabled) return null;

    final text = _readText != null
        ? await _readText()
        : await _clipboard.readPlainText();
    if (text == null) return null;
    if (text.length < minLen || text.length > maxLen) return null;

    final self = _clipboard.lastSelfCopiedText;
    if (self != null && self == text) return null;

    final fp = NearbyCrypto.clipboardFingerprint(text);
    final dismissed = SettingsService.instance.clipboardSuggestLastDismissed;
    if (dismissed != null && dismissed == fp) return null;

    try {
      final existing = _existingValues;
      final values = existing != null
          ? existing()
          : _items!.getAll().map((ClipItem i) => i.value);
      for (final v in values) {
        if (v == text) return null;
      }
    } catch (e, st) {
      AppLog.ignore(e, st, name: 'clipval.clipboard', context: 'suggest evaluate');
    }

    return text;
  }

  Future<void> markDismissed(String text) =>
      SettingsService.instance.setClipboardSuggestLastDismissed(
        NearbyCrypto.clipboardFingerprint(text),
      );

  Future<void> clearDismissed() =>
      SettingsService.instance.setClipboardSuggestLastDismissed(null);
}
