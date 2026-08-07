import '../constants/default_categories.dart';
import 'category_repository.dart';
import 'clip_item_repository.dart';
import 'vault_csv.dart';

/// Export / import vault items as ClipVal CSV for device migration.
class VaultMigrationService {
  VaultMigrationService({
    required ClipItemRepository items,
    required CategoryRepository categories,
  })  : _items = items,
        _categories = categories;

  final ClipItemRepository _items;
  final CategoryRepository _categories;

  /// UTF-8 CSV string (includes version metadata + header + rows).
  Future<String> exportCsv() async {
    final items = _items.getAll();
    final cats = _categories.getAll();
    final byId = {for (final c in cats) c.id: c};
    return VaultCsv.encode(items: items, categoriesById: byId);
  }

  /// Merge CSV into the vault. Exact title+value duplicates are skipped.
  Future<CsvImportResult> importCsv(String content) async {
    final rows = VaultCsv.decode(content);
    final existing = _items.getAll();
    final seen = <String>{
      for (final item in existing) _dupeKey(item.title, item.value),
    };

    var imported = 0;
    var skipped = 0;
    var failed = 0;

    for (final row in rows) {
      try {
        final title = row.title.trim();
        if (title.isEmpty && row.value.isEmpty) {
          skipped++;
          continue;
        }
        // Require a title so the card is usable; fall back to a short value.
        final effectiveTitle =
            title.isNotEmpty ? title : _titleFromValue(row.value);

        final key = _dupeKey(effectiveTitle, row.value);
        if (seen.contains(key)) {
          skipped++;
          continue;
        }

        final categoryId = await _resolveCategoryId(
          systemKey: row.categorySystemKey,
          name: row.categoryName,
        );

        final now = DateTime.now();
        await _items.create(
          title: effectiveTitle,
          value: row.value,
          categoryId: categoryId,
          languageTag: row.languageTag,
          isPinned: row.isPinned,
          createdAt: row.createdAt ?? now,
          updatedAt: row.updatedAt ?? now,
          lastCopiedAt: row.lastCopiedAt,
        );
        seen.add(key);
        imported++;
      } catch (_) {
        failed++;
      }
    }

    return CsvImportResult(
      imported: imported,
      skipped: skipped,
      failed: failed,
    );
  }

  Future<String?> _resolveCategoryId({
    String? systemKey,
    String? name,
  }) async {
    final key = systemKey?.trim();
    if (key != null && key.isNotEmpty) {
      final byKey = _categories.getBySystemKey(key);
      if (byKey != null) return byKey.id;
    }

    final rawName = name?.trim();
    if (rawName == null || rawName.isEmpty) return null;

    final lower = rawName.toLowerCase();
    for (final c in _categories.getAll()) {
      if (c.name.toLowerCase() == lower) return c.id;
    }

    // Map English default labels → system categories (export uses stored name).
    for (final def in DefaultCategories.all) {
      if (def.name.toLowerCase() == lower) {
        final byKey = _categories.getBySystemKey(def.systemKey);
        if (byKey != null) return byKey.id;
      }
    }

    // Custom category — create if missing.
    final created = await _categories.create(rawName);
    return created.id;
  }

  static String _dupeKey(String title, String value) =>
      '${title.trim().toLowerCase()}\u0000$value';

  static String _titleFromValue(String value) {
    final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) return 'Imported item';
    if (oneLine.length <= 40) return oneLine;
    return '${oneLine.substring(0, 37)}…';
  }
}
