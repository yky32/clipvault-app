import '../../l10n/app_localizations.dart';

/// Built-in address language tags (codes stored on [ClipItem.languageTag]).
/// Users enable/disable these in Settings and may add custom codes.
abstract final class AddressLanguages {
  static const zh = 'zh';
  static const en = 'en';

  /// Product defaults — both on for new installs.
  static const List<String> defaults = [zh, en];

  /// Known built-ins shown as toggles in Settings (order stable).
  static const List<String> builtIns = [zh, en];

  /// Normalize user input to a storage code (`zh`, `en`, `ja`…).
  static String? normalizeCode(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;
    // Short codes only — badge-friendly.
    if (t.length > 8) return null;
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(t)) return null;
    return t;
  }

  /// Whether [code] is a known product built-in.
  static bool isBuiltIn(String code) => builtIns.contains(code);

  /// Localized full name, or uppercase code for custom tags.
  static String label(String code, AppLocalizations l10n) {
    return switch (code) {
      zh => l10n.addressLanguageZh,
      en => l10n.addressLanguageEn,
      _ => code.toUpperCase(),
    };
  }

  /// Compact badge text (vault cards).
  static String shortBadge(String code) {
    return switch (code) {
      zh => '中',
      en => 'EN',
      _ => code.length <= 3 ? code.toUpperCase() : code.substring(0, 3).toUpperCase(),
    };
  }
}
