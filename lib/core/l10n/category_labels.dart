import '../../l10n/app_localizations.dart';
import '../constants/default_categories.dart';
import '../models/category.dart';

/// Resolve display label for a category (system → l10n, else stored name).
String categoryDisplayName(Category category, AppLocalizations l10n) {
  return systemCategoryLabel(category.systemKey, l10n) ?? category.name;
}

String? systemCategoryLabel(String? systemKey, AppLocalizations l10n) {
  if (systemKey == null || systemKey.isEmpty) return null;
  return switch (systemKey) {
    DefaultCategories.passwords => l10n.catPasswords,
    DefaultCategories.banking => l10n.catBanking,
    DefaultCategories.wifi => l10n.catWifi,
    DefaultCategories.codes => l10n.catCodes,
    DefaultCategories.addresses => l10n.catAddresses,
    DefaultCategories.developer => l10n.catDeveloper,
    DefaultCategories.templates => l10n.catTemplates,
    _ => null,
  };
}
