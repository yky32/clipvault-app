import 'package:clipval/core/constants/default_categories.dart';
import 'package:clipval/core/l10n/category_colors.dart';
import 'package:clipval/core/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('system keys get stable distinct colors', () {
    final a = CategoryColors.forSystemKey(DefaultCategories.passwords);
    final b = CategoryColors.forSystemKey(DefaultCategories.developer);
    expect(a, isNot(equals(b)));
  });

  test('custom colorIndex cycles', () {
    final c0 = Category(
      id: 'x',
      name: 'Custom',
      createdAt: DateTime.utc(2026),
      colorIndex: 0,
    );
    final c1 = c0.copyWith(colorIndex: CategoryColors.nextIndex(0));
    expect(CategoryColors.forCategory(c0), CategoryColors.palette[0]);
    expect(CategoryColors.forCategory(c1), CategoryColors.palette[1]);
  });
}
