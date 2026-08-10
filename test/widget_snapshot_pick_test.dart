import 'package:clipval/core/constants/app_constants.dart';
import 'package:clipval/core/models/clip_item.dart';
import 'package:clipval/core/services/widget_snapshot_service.dart';
import 'package:flutter_test/flutter_test.dart';

ClipItem _item({
  required String id,
  required String title,
  bool pinned = false,
  DateTime? lastCopiedAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ClipItem(
    id: id,
    title: title,
    value: 'v-$id',
    isPinned: pinned,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    lastCopiedAt: lastCopiedAt,
  );
}

void main() {
  group('WidgetSnapshotService.pickItemsForWidget', () {
    test('prefers pinned, then recently copied, then remaining', () {
      final a = _item(id: 'a', title: 'A');
      final b = _item(
        id: 'b',
        title: 'B',
        lastCopiedAt: DateTime.utc(2026, 1, 3),
      );
      final c = _item(id: 'c', title: 'C', pinned: true);
      final d = _item(
        id: 'd',
        title: 'D',
        lastCopiedAt: DateTime.utc(2026, 1, 4),
      );
      final e = _item(id: 'e', title: 'E', pinned: true);

      final picked = WidgetSnapshotService.pickItemsForWidget(
        [a, b, c, d, e],
        pinnedOnly: false,
      );

      expect(picked.map((i) => i.id).toList(), ['c', 'e', 'd', 'b', 'a']);
    });

    test('pinnedOnly returns only pinned items', () {
      final pinned = _item(id: 'p', title: 'Pin', pinned: true);
      final recent = _item(
        id: 'r',
        title: 'Recent',
        lastCopiedAt: DateTime.utc(2026, 2, 1),
      );
      final plain = _item(id: 'x', title: 'X');

      final picked = WidgetSnapshotService.pickItemsForWidget(
        [plain, recent, pinned],
        pinnedOnly: true,
      );

      expect(picked.map((i) => i.id).toList(), ['p']);
    });

    test('respects widget item limit', () {
      final many = List.generate(
        AppConstants.widgetItemLimit + 5,
        (i) => _item(
          id: '$i',
          title: 'T$i',
          pinned: i < 3,
          lastCopiedAt: DateTime.utc(2026, 1, i + 1),
        ),
      );

      final picked = WidgetSnapshotService.pickItemsForWidget(
        many,
        pinnedOnly: false,
      );

      expect(picked, hasLength(AppConstants.widgetItemLimit));
      // First three are pinned (ids 0,1,2)
      expect(picked.take(3).map((i) => i.id).toList(), ['0', '1', '2']);
    });

    test('dedupes when item is both pinned and recent', () {
      final item = _item(
        id: 'same',
        title: 'Both',
        pinned: true,
        lastCopiedAt: DateTime.utc(2026, 3, 1),
      );

      final picked = WidgetSnapshotService.pickItemsForWidget(
        [item],
        pinnedOnly: false,
      );

      expect(picked, hasLength(1));
      expect(picked.single.id, 'same');
    });

    test('empty vault yields empty pick', () {
      expect(
        WidgetSnapshotService.pickItemsForWidget([], pinnedOnly: false),
        isEmpty,
      );
      expect(
        WidgetSnapshotService.pickItemsForWidget([], pinnedOnly: true),
        isEmpty,
      );
    });
  });
}
