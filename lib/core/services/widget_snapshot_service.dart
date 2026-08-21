import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
              // Sensitive always masks titles; app-lock hide applies to all.
              'title': (hideTitles || item.isSensitive) ? '' : item.title,
              'monogram': _monogram(item.title),
              'value': item.value,
              'pinned': item.isPinned,
              'sensitive': item.isSensitive,
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

      // Keyboard: more slots, never mask titles (sensitive items omitted entirely).
      final kbItems = _pickItems(
        _items.getAll(),
        pinnedOnly: false,
        limit: AppConstants.keyboardItemLimit,
      ).where((i) => !i.isSensitive).toList();
      final kbPayload = jsonEncode({
        'items': [
          for (final item in kbItems)
            {
              'id': item.id,
              'title': item.title,
              'monogram': _monogram(item.title),
              'value': item.value,
              'pinned': item.isPinned,
              'sensitive': false,
            },
        ],
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await HomeWidget.saveWidgetData<String>(
        AppConstants.keyboardItemsKey,
        kbPayload,
      );

      await HomeWidget.updateWidget(
        iOSName: AppConstants.widgetIosName,
        name: AppConstants.widgetIosName,
      );

      // Authoritative native write (per-id keys + file + synchronize).
      // home_widget alone has been insufficient for App Intent pasteboard copy.
      try {
        await const MethodChannel('com.clipval/widget').invokeMethod<void>(
          'writeSnapshot',
          {
            'json': payload,
            'keyboardJson': kbPayload,
          },
        );
      } catch (e) {
        debugPrint('WidgetSnapshotService.writeSnapshot: $e');
        try {
          await const MethodChannel('com.clipval/widget')
              .invokeMethod<void>('flushAndReload');
        } catch (e2) {
          debugPrint('WidgetSnapshotService.flushAndReload: $e2');
        }
      }
    } catch (e, st) {
      debugPrint('WidgetSnapshotService.sync failed: $e\n$st');
    }
  }

  static String _monogram(String title) {
    final t = title.trim();
    if (t.isEmpty) return '•';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }

  /// Widget ranking (default): **most recently copied first**, then pinned,
  /// then remaining by updatedAt. [pinnedOnly] still forces favorites-only.
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
    int? limit,
  }) {
    final max = limit ?? AppConstants.widgetItemLimit;
    final out = <ClipItem>[];
    final seen = <String>{};

    void take(ClipItem item) {
      if (out.length >= max) return;
      if (!seen.add(item.id)) return;
      out.add(item);
    }

    if (pinnedOnly) {
      final pinned = all.where((i) => i.isPinned).toList()
        ..sort((a, b) {
          final ac = a.lastCopiedAt;
          final bc = b.lastCopiedAt;
          if (ac != null && bc != null) return bc.compareTo(ac);
          if (ac != null) return -1;
          if (bc != null) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      for (final item in pinned) {
        take(item);
      }
      return out;
    }

    // 1) Most recently copied (primary — user request)
    final recent = all.where((i) => i.lastCopiedAt != null).toList()
      ..sort((a, b) => b.lastCopiedAt!.compareTo(a.lastCopiedAt!));
    for (final item in recent) {
      take(item);
    }

    // 2) Pinned not already included
    final pinned = all.where((i) => i.isPinned).toList();
    for (final item in pinned) {
      take(item);
    }

    // 3) Rest by recent update
    final rest = [...all]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    for (final item in rest) {
      take(item);
    }

    return out;
  }
}
