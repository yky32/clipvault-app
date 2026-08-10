import 'dart:io';

import 'package:clipval/core/services/category_repository.dart';
import 'package:clipval/core/services/clip_item_repository.dart';
import 'package:clipval/core/services/encryption_service.dart';
import 'package:clipval/core/services/vault_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late EncryptionService encryption;
  late ClipItemRepository items;
  late CategoryRepository categories;
  late VaultMigrationService migration;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('clipval_import_');
    Hive.init(tempDir.path);

    encryption = EncryptionService.forTest();
    items = ClipItemRepository(encryption);
    await items.init();
    categories = CategoryRepository();
    await categories.init();
    migration = VaultMigrationService(items: items, categories: categories);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  String csvOf(List<List<String>> dataRows) {
    final buffer = StringBuffer()
      ..writeln('# clipval_export_version=1')
      ..writeln(
        'title,value,category_name,category_system_key,language,pinned,'
        'created_at,updated_at,last_copied_at',
      );
    for (final row in dataRows) {
      buffer.writeln(row.join(','));
    }
    return buffer.toString();
  }

  group('previewCsv', () {
    test('counts new vs skipped duplicates', () async {
      await items.create(title: 'Wi‑Fi', value: 'secret');
      await items.create(title: 'PIN', value: '1234');

      final content = csvOf([
        ['Wi‑Fi', 'secret', '', '', '', 'false', '', '', ''],
        ['Bank', 'acct-99', 'Work', '', '', 'false', '', '', ''],
        ['PIN', '1234', '', '', '', 'false', '', '', ''],
        ['OTP', '998877', 'Work', '', '', 'false', '', '', ''],
      ]);

      final preview = migration.previewCsv(content);
      expect(preview.totalRows, 4);
      expect(preview.willImport, 2);
      expect(preview.willSkip, 2);
      expect(preview.invalid, 0);
      expect(preview.hasWork, isTrue);
      expect(preview.sampleNewTitles, containsAll(['Bank', 'OTP']));
      expect(preview.newCategoryNames, contains('Work'));
    });

    test('reports nothing to import when all rows are duplicates', () async {
      await items.create(title: 'Only', value: 'one');

      final content = csvOf([
        ['Only', 'one', '', '', '', 'false', '', '', ''],
        // Completely empty data rows are dropped by VaultCsv.decode.
      ]);

      final preview = migration.previewCsv(content);
      expect(preview.willImport, 0);
      expect(preview.willSkip, 1);
      expect(preview.hasWork, isFalse);
    });

    test('does not write during preview', () async {
      final before = items.getAll().length;
      final content = csvOf([
        ['Fresh', 'value', 'CustomCat', '', '', 'false', '', '', ''],
      ]);

      final preview = migration.previewCsv(content);
      expect(preview.willImport, 1);
      expect(preview.newCategoryNames, contains('CustomCat'));
      expect(items.getAll(), hasLength(before));
      expect(
        categories.getAll().any((c) => c.name == 'CustomCat'),
        isFalse,
      );
    });

    test('title fallback from value when title empty', () {
      final content = csvOf([
        ['', 'fallback-title-value', '', '', '', 'false', '', '', ''],
      ]);

      final preview = migration.previewCsv(content);
      expect(preview.willImport, 1);
      expect(preview.sampleNewTitles.single, 'fallback-title-value');
    });
  });

  group('importCsv', () {
    test('imports new rows and skips exact duplicates', () async {
      await items.create(title: 'Existing', value: 'keep');

      final content = csvOf([
        ['Existing', 'keep', '', '', '', 'false', '', '', ''],
        ['New item', 'brand-new', '', '', '', 'false', '', '', ''],
      ]);

      final result = await migration.importCsv(content);
      expect(result.imported, 1);
      expect(result.skipped, 1);
      expect(result.failed, 0);

      final titles = items.getAll().map((e) => e.title).toSet();
      expect(titles, containsAll(['Existing', 'New item']));
    });

    test('creates custom category on import', () async {
      final content = csvOf([
        ['Desk code', '4455', 'Office', '', '', 'false', '', '', ''],
      ]);

      final result = await migration.importCsv(content);
      expect(result.imported, 1);

      final office = categories
          .getAll()
          .where((c) => c.name.toLowerCase() == 'office')
          .toList();
      expect(office, hasLength(1));

      final item = items.getAll().singleWhere((i) => i.title == 'Desk code');
      expect(item.categoryId, office.single.id);
    });

    test('preview counts match import outcome for clean file', () async {
      final content = csvOf([
        ['A', '1', '', '', '', 'false', '', '', ''],
        ['B', '2', '', '', '', 'false', '', '', ''],
        ['A', '1', '', '', '', 'false', '', '', ''], // in-file dupe → skip
      ]);

      final preview = migration.previewCsv(content);
      final result = await migration.importCsv(content);

      expect(result.imported, preview.willImport);
      expect(result.skipped, preview.willSkip);
      expect(result.failed, preview.invalid);
    });
  });
}
