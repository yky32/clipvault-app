import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../constants/app_constants.dart';
import '../models/clip_item.dart';
import 'clip_item_repository.dart';

/// Pushes a small plaintext snapshot of vault items to the home-screen widget.
///
/// Values are stored in the App Group container so WidgetKit can copy without
/// unlocking the app. Only the top [AppConstants.widgetItemLimit] items are
/// included (pinned → recently copied → rest).
class WidgetSnapshotService {
  WidgetSnapshotService(this._items);

  final ClipItemRepository _items;
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(AppConstants.widgetAppGroupId);
      _ready = true;
    } catch (e, st) {
      debugPrint('WidgetSnapshotService.init failed: $e\n$st');
    }
  }

  /// Rebuild snapshot from Hive and ask iOS to reload the widget timeline.
  Future<void> sync() async {
    if (!_ready || kIsWeb) return;
    try {
      final selected = _pickItems(_items.getAll());
      final payload = jsonEncode({
        'items': [
          for (final item in selected)
            {
              'id': item.id,
              'title': item.title,
              'value': item.value,
            },
        ],
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await HomeWidget.saveWidgetData<String>(
        AppConstants.widgetItemsKey,
        payload,
      );
      await HomeWidget.updateWidget(
        iOSName: AppConstants.widgetIosName,
        name: AppConstants.widgetIosName,
      );
    } catch (e, st) {
      debugPrint('WidgetSnapshotService.sync failed: $e\n$st');
    }
  }

  /// Prefer pinned, then recently used, then remaining (already sorted by repo).
  static List<ClipItem> _pickItems(List<ClipItem> all) {
    final out = <ClipItem>[];
    final seen = <String>{};

    void take(ClipItem item) {
      if (out.length >= AppConstants.widgetItemLimit) return;
      if (!seen.add(item.id)) return;
      out.add(item);
    }

    for (final item in all.where((i) => i.isPinned)) {
      take(item);
    }

    final recent = all.where((i) => i.lastCopiedAt != null).toList()
      ..sort((a, b) => b.lastCopiedAt!.compareTo(a.lastCopiedAt!));
    for (final item in recent) {
      take(item);
    }

    for (final item in all) {
      take(item);
    }

    return out;
  }
}
