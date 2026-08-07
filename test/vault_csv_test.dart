import 'package:clipval/core/models/category.dart';
import 'package:clipval/core/models/clip_item.dart';
import 'package:clipval/core/services/vault_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaultCsv', () {
    test('round-trips rows with commas and quotes', () {
      final now = DateTime.utc(2024, 5, 1, 12);
      final cat = Category(
        id: 'sys_passwords',
        name: 'Passwords',
        systemKey: 'passwords',
        createdAt: now,
      );
      final item = ClipItem(
        id: 'a',
        title: 'Note, "quoted"',
        value: 'line1\nline2, ok',
        categoryId: cat.id,
        languageTag: 'en',
        isPinned: true,
        createdAt: now,
        updatedAt: now,
        lastCopiedAt: now,
      );

      final csv = VaultCsv.encode(
        items: [item],
        categoriesById: {cat.id: cat},
      );
      expect(csv, contains('# clipval_export_version=1'));

      final rows = VaultCsv.decode(csv);
      expect(rows, hasLength(1));
      expect(rows.single.title, 'Note, "quoted"');
      expect(rows.single.value, 'line1\nline2, ok');
      expect(rows.single.categoryName, 'Passwords');
      expect(rows.single.categorySystemKey, 'passwords');
      expect(rows.single.languageTag, 'en');
      expect(rows.single.isPinned, isTrue);
      expect(rows.single.createdAt, now);
      expect(rows.single.lastCopiedAt, now);
    });

    test('rejects missing title/value columns', () {
      expect(
        () => VaultCsv.decode('foo,bar\n1,2\n'),
        throwsA(isA<FormatException>()),
      );
    });

    test('skips blank and comment lines', () {
      const raw = '''
# clipval_export_version=1

title,value,category_name,category_system_key,language,pinned,created_at,updated_at,last_copied_at
Hello,World,,,,,

''';
      final rows = VaultCsv.decode(raw);
      expect(rows, hasLength(1));
      expect(rows.single.title, 'Hello');
      expect(rows.single.value, 'World');
    });
  });
}
