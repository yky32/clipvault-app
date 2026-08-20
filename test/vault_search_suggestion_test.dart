import 'package:clipval/core/constants/app_constants.dart';
import 'package:clipval/core/models/category.dart';
import 'package:clipval/core/models/clip_item.dart';
import 'package:clipval/features/vault/bloc/vault_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17);

  ClipItem item({
    required String id,
    required String title,
    bool pinned = false,
    DateTime? lastCopied,
    String? categoryId,
  }) {
    return ClipItem(
      id: id,
      title: title,
      value: 'v',
      createdAt: now,
      updatedAt: now,
      isPinned: pinned,
      lastCopiedAt: lastCopied,
      categoryId: categoryId,
    );
  }

  test('recentlyCopied skips pinned and limits', () {
    final state = VaultState(
      items: [
        item(id: '1', title: 'A', lastCopied: now),
        item(id: '2', title: 'B', pinned: true, lastCopied: now),
        item(id: '3', title: 'C', lastCopied: now.subtract(const Duration(days: 1))),
      ],
    );
    final recent = state.recentlyCopied;
    expect(recent.map((e) => e.id), ['1', '3']);
    expect(recent.any((e) => e.isPinned), isFalse);
  });

  test('uncategorized filter', () {
    final state = VaultState(
      items: [
        item(id: '1', title: 'A', categoryId: 'c1'),
        item(id: '2', title: 'B'),
      ],
      selectedCategoryId: VaultState.uncategorizedFilterId,
    );
    expect(state.filteredItems.map((e) => e.id), ['2']);
    expect(state.countInCategory(VaultState.uncategorizedFilterId), 1);
  });

  test('search suggestions include category', () {
    final cat = Category(
      id: 'c1',
      name: 'Wi-Fi',
      createdAt: now,
      systemKey: 'wifi',
    );
    final state = VaultState(
      items: [item(id: '1', title: 'Home WiFi', categoryId: 'c1', lastCopied: now)],
      categories: [cat],
    );
    expect(state.searchSuggestions, isNotEmpty);
    expect(AppConstants.recentBodySectionLimit, 6);
  });
}
