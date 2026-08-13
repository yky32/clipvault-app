import '../models/clip_item.dart';
import 'clipboard_service.dart';
import 'clip_item_repository.dart';
import 'nearby/nearby_crypto.dart';
import 'settings_service.dart';

/// Decides whether to surface "Save clipboard to ClipVal?"
class ClipboardSuggestService {
  ClipboardSuggestService({
    required ClipboardService clipboard,
    required ClipItemRepository items,
  })  : _clipboard = clipboard,
        _items = items;

  final ClipboardService _clipboard;
  final ClipItemRepository _items;

  static const maxLen = 4000;
  static const minLen = 1;

  /// Returns text to suggest, or null if nothing to show.
  Future<String?> evaluate() async {
    if (!SettingsService.instance.clipboardSuggestEnabled) return null;

    final text = await _clipboard.readPlainText();
    if (text == null) return null;
    if (text.length < minLen || text.length > maxLen) return null;

    // Skip what we just copied from ClipVal.
    final self = _clipboard.lastSelfCopiedText;
    if (self != null && self == text) return null;

    // Dismissed store is a hash — never persist pasteboard plaintext.
    final fp = NearbyCrypto.clipboardFingerprint(text);
    final dismissed = SettingsService.instance.clipboardSuggestLastDismissed;
    if (dismissed != null && dismissed == fp) return null;

    // Skip if an identical value already exists in vault.
    try {
      for (final ClipItem item in _items.getAll()) {
        if (item.value == text) return null;
      }
    } catch (_) {}

    return text;
  }

  Future<void> markDismissed(String text) =>
      SettingsService.instance.setClipboardSuggestLastDismissed(
        NearbyCrypto.clipboardFingerprint(text),
      );

  Future<void> clearDismissed() =>
      SettingsService.instance.setClipboardSuggestLastDismissed(null);
}
