import '../models/clip_item.dart';
import 'clipboard_service.dart';
import 'clip_item_repository.dart';
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

    // Skip if user dismissed this exact payload recently.
    final dismissed = SettingsService.instance.clipboardSuggestLastDismissed;
    if (dismissed != null && dismissed == text) return null;

    // Skip if an identical value already exists in vault.
    try {
      final existing = _items.getAll();
      for (final ClipItem item in existing) {
        if (item.value == text) return null;
      }
    } catch (_) {}

    return text;
  }

  Future<void> markDismissed(String text) =>
      SettingsService.instance.setClipboardSuggestLastDismissed(text);

  Future<void> clearDismissed() =>
      SettingsService.instance.setClipboardSuggestLastDismissed(null);
}
