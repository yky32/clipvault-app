import 'dart:typed_data';

import '../constants/default_categories.dart';
import 'category_repository.dart';
import 'clip_item_repository.dart';
import 'vault_backup.dart';
import 'vault_csv.dart';

/// Export / import vault items as ClipVal CSV or encrypted `.clipval` backup.
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

  /// Password-protected backup bytes (JSON envelope around CSV).
  Future<Uint8List> exportEncryptedBackup(String password) async {
    final csv = await exportCsv();
    return VaultBackup.encode(csv: csv, password: password);
  }

  /// Decrypt a `.clipval` file to CSV (throws on wrong password / format).
  String decryptBackupToCsv({
    required List<int> bytes,
    required String password,
  }) {
    return VaultBackup.decode(bytes: bytes, password: password);
  }

  /// Dry-run: how many rows would be added vs skipped (no writes).
  CsvImportPreview previewCsv(String content) {
    final rows = VaultCsv.decode(content);
    final plan = _classifyRows(rows);

    return CsvImportPreview(
      totalRows: rows.length,
      willImport: plan.toImport.length,
      willSkip: plan.skipCount,
      invalid: plan.invalidCount,
      sampleNewTitles: [
        for (final row in plan.toImport.take(5)) row.effectiveTitle,
      ],
      newCategoryNames: plan.newCategoryNames.toList(growable: false),
    );
  }

  /// Merge CSV into the vault. Exact title+value duplicates are skipped.
  Future<CsvImportResult> importCsv(String content) async {
    final rows = VaultCsv.decode(content);
    final plan = _classifyRows(rows);

    var imported = 0;
    var failed = 0;

    for (final row in plan.toImport) {
      try {
        final categoryId = await _resolveCategoryId(
          systemKey: row.categorySystemKey,
          name: row.categoryName,
        );

        final now = DateTime.now();
        await _items.create(
          title: row.effectiveTitle,
          value: row.value,
          categoryId: categoryId,
          languageTag: row.languageTag,
          isPinned: row.isPinned,
          createdAt: row.createdAt ?? now,
          updatedAt: row.updatedAt ?? now,
          lastCopiedAt: row.lastCopiedAt,
        );
        imported++;
      } catch (_) {
        failed++;
      }
    }

    return CsvImportResult(
      imported: imported,
      skipped: plan.skipCount,
      failed: failed + plan.invalidCount,
    );
  }

  /// Classify CSV rows against the current vault (no side effects).
  _ImportPlan _classifyRows(List<VaultCsvRow> rows) {
    final existing = _items.getAll();
    final seen = <String>{
      for (final item in existing) _dupeKey(item.title, item.value),
    };

    final existingCategoryKeys = <String>{
      for (final c in _categories.getAll()) ...[
        if (c.systemKey != null && c.systemKey!.isNotEmpty)
          'key:${c.systemKey!.toLowerCase()}',
        'name:${c.name.toLowerCase()}',
      ],
      for (final def in DefaultCategories.all) ...[
        'key:${def.systemKey}',
        'name:${def.name.toLowerCase()}',
      ],
    };

    final toImport = <_PreparedRow>[];
    final newCategoryNames = <String>{};
    var skipCount = 0;
    var invalidCount = 0;

    for (final row in rows) {
      final title = row.title.trim();
      if (title.isEmpty && row.value.isEmpty) {
        skipCount++;
        continue;
      }

      final effectiveTitle =
          title.isNotEmpty ? title : _titleFromValue(row.value);
      if (effectiveTitle.isEmpty) {
        invalidCount++;
        continue;
      }

      final key = _dupeKey(effectiveTitle, row.value);
      if (seen.contains(key)) {
        skipCount++;
        continue;
      }
      seen.add(key);

      // Track categories that would be created on import.
      final sys = row.categorySystemKey?.trim();
      final name = row.categoryName?.trim();
      if (sys != null && sys.isNotEmpty) {
        if (!existingCategoryKeys.contains('key:${sys.toLowerCase()}')) {
          // Unknown system key → fall through to name or leave uncategorized.
          if (name != null &&
              name.isNotEmpty &&
              !existingCategoryKeys.contains('name:${name.toLowerCase()}')) {
            newCategoryNames.add(name);
            existingCategoryKeys.add('name:${name.toLowerCase()}');
          }
        }
      } else if (name != null && name.isNotEmpty) {
        final lower = name.toLowerCase();
        final isDefault = DefaultCategories.all
            .any((d) => d.name.toLowerCase() == lower);
        if (!isDefault &&
            !existingCategoryKeys.contains('name:$lower')) {
          newCategoryNames.add(name);
          existingCategoryKeys.add('name:$lower');
        }
      }

      toImport.add(
        _PreparedRow(
          effectiveTitle: effectiveTitle,
          value: row.value,
          categoryName: row.categoryName,
          categorySystemKey: row.categorySystemKey,
          languageTag: row.languageTag,
          isPinned: row.isPinned,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          lastCopiedAt: row.lastCopiedAt,
        ),
      );
    }

    return _ImportPlan(
      toImport: toImport,
      skipCount: skipCount,
      invalidCount: invalidCount,
      newCategoryNames: newCategoryNames,
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

/// Dry-run result shown before the user confirms import.
class CsvImportPreview {
  const CsvImportPreview({
    required this.totalRows,
    required this.willImport,
    required this.willSkip,
    required this.invalid,
    required this.sampleNewTitles,
    required this.newCategoryNames,
  });

  final int totalRows;
  final int willImport;
  final int willSkip;
  final int invalid;
  final List<String> sampleNewTitles;
  final List<String> newCategoryNames;

  bool get isEmpty => totalRows == 0 || (willImport == 0 && willSkip == 0 && invalid == 0);
  bool get hasWork => willImport > 0;
}

class _PreparedRow {
  const _PreparedRow({
    required this.effectiveTitle,
    required this.value,
    this.categoryName,
    this.categorySystemKey,
    this.languageTag,
    this.isPinned = false,
    this.createdAt,
    this.updatedAt,
    this.lastCopiedAt,
  });

  final String effectiveTitle;
  final String value;
  final String? categoryName;
  final String? categorySystemKey;
  final String? languageTag;
  final bool isPinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastCopiedAt;
}

class _ImportPlan {
  const _ImportPlan({
    required this.toImport,
    required this.skipCount,
    required this.invalidCount,
    required this.newCategoryNames,
  });

  final List<_PreparedRow> toImport;
  final int skipCount;
  final int invalidCount;
  final Set<String> newCategoryNames;
}
