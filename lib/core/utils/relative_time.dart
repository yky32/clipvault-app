import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../constants/address_languages.dart';

/// Formats a vault item's last-used (last-copied) timestamp for compact UI.
String formatLastUsed(DateTime? at, AppLocalizations l10n, {String? locale}) {
  if (at == null) return l10n.neverUsed;

  final now = DateTime.now();
  final local = at.toLocal();
  final diff = now.difference(local);

  if (diff.isNegative || diff.inSeconds < 45) {
    return l10n.justNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.minutesAgo(diff.inMinutes.clamp(1, 59));
  }
  if (diff.inHours < 24) {
    return l10n.hoursAgo(diff.inHours.clamp(1, 23));
  }
  if (diff.inDays == 1) {
    return l10n.yesterday;
  }
  if (diff.inDays < 7) {
    return l10n.daysAgo(diff.inDays);
  }

  final sameYear = local.year == now.year;
  final pattern = sameYear ? 'MMM d' : 'MMM d, y';
  return DateFormat(pattern, locale).format(local);
}

/// Category + optional language tag + last-used on one meta line for cards.
String vaultItemMetaLine({
  required AppLocalizations l10n,
  String? categoryName,
  String? languageTag,
  DateTime? lastUsedAt,
  String? locale,
}) {
  final used = formatLastUsed(lastUsedAt, l10n, locale: locale);
  final parts = <String>[];
  final cat = categoryName?.trim();
  if (cat != null && cat.isNotEmpty) {
    parts.add(cat);
  }
  final lang = languageTagLabel(languageTag, l10n);
  if (lang != null) {
    parts.add(lang);
  }
  parts.add(used);
  return parts.join(' · ');
}

/// Short label for Addresses language tag, or null if unmarked.
String? languageTagLabel(String? tag, AppLocalizations l10n) {
  if (tag == null || tag.trim().isEmpty) return null;
  return AddressLanguages.label(tag.trim().toLowerCase(), l10n);
}
