import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../constants/app_constants.dart';
import '../models/clip_item.dart';
import 'clip_item_repository.dart';
import 'settings_service.dart';

/// Pushes a small snapshot of vault items to the home-screen widget.
///
/// Values are stored in the App Group so WidgetKit can copy without unlocking.
/// Only the top [AppConstants.widgetItemLimit] items are included.
///
/// Phase C: optional **pinned-only** favorites; **hide titles** when app lock
/// is on (monogram still shown).
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
      final settings = SettingsService.instance;
      final pinnedOnly = settings.widgetPinnedOnly;
      final hideTitles = settings.biometricLockEnabled &&
          settings.widgetHideTitlesWhenLocked;
      final selected = _pickItems(_items.getAll(), pinnedOnly: pinnedOnly);

      final payload = jsonEncode({
        'items': [
          for (final item in selected)
            {
              'id': item.id,
              'title': hideTitles ? '' : item.title,
              'monogram': _monogram(item.title),
              'value': item.value,
              'pinned': item.isPinned,
            },
        ],
        'hideTitles': hideTitles,
        'pinnedOnly': pinnedOnly,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await HomeWidget.saveWidgetData<String>(
        AppConstants.widgetItemsKey,
        payload,
      );
      await HomeWidget.saveWidgetData<bool>(
        AppConstants.widgetHideTitlesKey,
        hideTitles,
      );
      await HomeWidget.updateWidget(
        iOSName: AppConstants.widgetIosName,
        name: AppConstants.widgetIosName,
      );
    } catch (e, st) {
      debugPrint('WidgetSnapshotService.sync failed: $e\n$st');
    }
  }

  static String _monogram(String title) {
    final t = title.trim();
    if (t.isEmpty) return '•';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }

  /// Prefer pinned, then recently used, then remaining — unless [pinnedOnly].
  /// Public for unit tests.
  static List<ClipItem> pickItemsForWidget(
    List<ClipItem> all, {
    required bool pinnedOnly,
  }) {
    return _pickItems(all, pinnedOnly: pinnedOnly);
  }

  static List<ClipItem> _pickItems(
    List<ClipItem> all, {
    required bool pinnedOnly,
  }) {
    final out = <ClipItem>[];
    final seen = <String>{};

    void take(ClipItem item) {
      if (out.length >= AppConstants.widgetItemLimit) return;
      if (!seen.add(item.id)) return;
      out.add(item);
    }

    final pinned = all.where((i) => i.isPinned).toList();
    for (final item in pinned) {
      take(item);
    }

    if (pinnedOnly) return out;

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
