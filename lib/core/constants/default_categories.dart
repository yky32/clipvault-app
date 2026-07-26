/// Built-in categories aligned with clipVauLt’s one purpose:
/// store frequently copied values (PRD §2 / §5).
abstract final class DefaultCategories {
  /// Stable system keys used for seeding + l10n lookup.
  static const passwords = 'passwords';
  static const banking = 'banking';
  static const wifi = 'wifi';
  static const codes = 'codes';
  static const addresses = 'addresses';
  static const developer = 'developer';
  static const templates = 'templates';

  /// Display order on filter chips.
  static const List<DefaultCategoryDef> all = [
    DefaultCategoryDef(
      systemKey: passwords,
      // English fallback stored in DB; UI prefers l10n via systemKey.
      name: 'Passwords',
      sortOrder: 0,
    ),
    DefaultCategoryDef(
      systemKey: banking,
      name: 'Banking',
      sortOrder: 1,
    ),
    DefaultCategoryDef(
      systemKey: wifi,
      name: 'Wi-Fi',
      sortOrder: 2,
    ),
    DefaultCategoryDef(
      systemKey: codes,
      name: 'Codes',
      sortOrder: 3,
    ),
    DefaultCategoryDef(
      systemKey: addresses,
      name: 'Addresses',
      sortOrder: 4,
    ),
    DefaultCategoryDef(
      systemKey: developer,
      name: 'Developer',
      sortOrder: 5,
    ),
    DefaultCategoryDef(
      systemKey: templates,
      name: 'Templates',
      sortOrder: 6,
    ),
  ];

  static String boxId(String systemKey) => 'sys_$systemKey';
}

class DefaultCategoryDef {
  const DefaultCategoryDef({
    required this.systemKey,
    required this.name,
    required this.sortOrder,
  });

  final String systemKey;
  final String name;
  final int sortOrder;
}
