import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/clip_item.dart';

/// iOS Core Spotlight — **titles only** (never values).
class SpotlightIndexService {
  SpotlightIndexService();

  static const _channel = MethodChannel('com.clipval/spotlight');

  bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Full reindex of current vault titles (call after load / bulk change).
  Future<void> reindexAll(List<ClipItem> items) async {
    if (!isSupported) return;
    try {
      // Clear domain then re-add — keeps Spotlight in sync with deletes.
      await _channel.invokeMethod<void>('deleteAll');
      if (items.isEmpty) return;
      final rows = <Map<String, String>>[];
      for (final item in items) {
        final title = item.title.trim();
        if (title.isEmpty) continue;
        rows.add({'id': item.id, 'title': title});
      }
      if (rows.isEmpty) return;
      await _channel.invokeMethod<void>('indexItems', rows);
    } catch (e, st) {
      developer.log('reindexAll failed: $e', name: 'clipval.spotlight', stackTrace: st);
    }
  }

  Future<void> upsert(ClipItem item) async {
    if (!isSupported) return;
    final title = item.title.trim();
    if (title.isEmpty) {
      await delete([item.id]);
      return;
    }
    try {
      await _channel.invokeMethod<void>('indexItems', [
        {'id': item.id, 'title': title},
      ]);
    } catch (e) {
      developer.log('upsert failed: $e', name: 'clipval.spotlight');
    }
  }

  Future<void> delete(List<String> ids) async {
    if (!isSupported || ids.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('deleteItems', ids);
    } catch (e) {
      developer.log('delete failed: $e', name: 'clipval.spotlight');
    }
  }
}
