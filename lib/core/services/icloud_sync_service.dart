import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'category_repository.dart';
import 'clip_item_repository.dart';
import 'encryption_service.dart';
import 'icloud_sync_merge.dart';
import 'settings_service.dart';
import 'widget_snapshot_service.dart';

/// Result of a sync pass (for Settings UI / HUD).
class ICloudSyncResult {
  const ICloudSyncResult({
    required this.ok,
    this.message,
    this.code,
    this.pulledItems = 0,
    this.pushedItems = 0,
    this.pulledCategories = 0,
    this.pushedCategories = 0,
  });

  final bool ok;
  final String? message;
  /// Stable machine code for Settings UX (e.g. [schemaProduction]).
  final String? code;
  final int pulledItems;
  final int pushedItems;
  final int pulledCategories;
  final int pushedCategories;

  /// Production CloudKit schema missing a record type (CLIPVAL-CK-001).
  static const schemaProduction = 'schema_production';
  static const noAccount = 'no_account';
  static const network = 'network';
}

/// Phase E — optional iCloud (CloudKit private DB) vault sync.
///
/// - Values stay AES-encrypted client-side; ciphertext is what goes to iCloud.
/// - Master key is stored in CloudKit `VaultMeta` so a second device can decrypt
///   (still only in the user’s private iCloud — never a ClipVal server).
/// - Conflict rule: last-write-wins by `updatedAt`.
class ICloudSyncService {
  ICloudSyncService({
    required EncryptionService encryption,
    required ClipItemRepository items,
    required CategoryRepository categories,
    required WidgetSnapshotService widgetSnapshot,
  })  : _encryption = encryption,
        _items = items,
        _categories = categories,
        _widgetSnapshot = widgetSnapshot;

  static const _channel = MethodChannel('com.clipval/icloud_sync');

  final EncryptionService _encryption;
  final ClipItemRepository _items;
  final CategoryRepository _categories;
  final WidgetSnapshotService _widgetSnapshot;

  bool _syncing = false;
  Timer? _debounce;

  /// Filter Xcode / `flutter run` console with: `ClipVal iCloud`
  static void _log(String message) {
    // ignore: avoid_print — intentional proof logs for sync verification
    print('[ClipVal iCloud] $message');
  }

  bool get isSupported => !kIsWeb && Platform.isIOS;

  bool get enabled =>
      isSupported && SettingsService.instance.iCloudSyncEnabled;

  /// Map native / CK error strings → stable [ICloudSyncResult.code].
  static String? mapErrorCode({String? platformCode, String? message}) {
    final code = (platformCode ?? '').toLowerCase();
    final msg = (message ?? '').toLowerCase();
    if (code == ICloudSyncResult.schemaProduction ||
        msg.contains('cannot create new type') ||
        msg.contains('production schema') ||
        (msg.contains('record type') && msg.contains('production'))) {
      return ICloudSyncResult.schemaProduction;
    }
    if (code == ICloudSyncResult.noAccount ||
        msg.contains('no account') ||
        code == 'noaccount') {
      return ICloudSyncResult.noAccount;
    }
    if (code == ICloudSyncResult.network ||
        msg.contains('network') ||
        msg.contains('offline') ||
        msg.contains('timed out') ||
        msg.contains('timeout')) {
      return ICloudSyncResult.network;
    }
    return platformCode;
  }


  /// Account status: available / noAccount / restricted / …
  Future<Map<String, dynamic>> checkAvailability() async {
    if (!isSupported) {
      return {'available': false, 'status': 'unsupported'};
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('isAvailable');
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {'available': false, 'status': 'unknown'};
    } on PlatformException catch (e) {
      return {
        'available': false,
        'status': 'error',
        'message': e.message ?? e.code,
      };
    }
  }

  /// Debounced sync after vault mutations (1.2s).
  void scheduleSync() {
    if (!enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1200), () {
      unawaited(syncNow());
    });
  }

  /// Full pull-then-push merge.
  Future<ICloudSyncResult> syncNow() async {
    if (!enabled) {
      return const ICloudSyncResult(ok: false, message: 'disabled');
    }
    if (_syncing) {
      return const ICloudSyncResult(ok: false, message: 'busy');
    }
    _syncing = true;
    final sw = Stopwatch()..start();
    try {
      final avail = await checkAvailability();
      if (avail['available'] != true) {
        final status = avail['status']?.toString() ?? 'unavailable';
        _log('FAIL: iCloud unavailable ($status)');
        return ICloudSyncResult(
          ok: false,
          message: avail['message']?.toString() ?? status,
        );
      }

      final engine = await _engineInfo();
      if (engine == null || engine['engine'] != 'zone-v1') {
        _log('FAIL: stale native binary — full stop + flutter run (not hot restart)');
      }

      // Push first: creates custom zone + record types in Development.
      final push = await _pushLocal();

      final remote = await _fetchAllSafe();
      final remoteItems = _asMapList(remote['items']);
      final remoteCats = _asMapList(remote['categories']);
      final hasMeta = remote['meta'] is Map;

      final keyResult = await _reconcileMasterKey(remote['meta']);
      if (keyResult != null && !keyResult.ok) {
        _log('FAIL: key reconcile — ${keyResult.message}');
        return keyResult;
      }

      final pull = await _applyRemote(
        items: remoteItems,
        categories: remoteCats,
      );

      final push2 = await _pushLocal();

      final now = DateTime.now();
      await SettingsService.instance.setICloudLastSyncAt(now);
      await _widgetSnapshot.sync();

      sw.stop();
      // Minimal proof line: round-trip counts + zone/container.
      final localN = _items.getAllRawMaps().length;
      _log(
        'OK ${sw.elapsedMilliseconds}ms | '
        'local=$localN vault items | '
        'push ${push.$1}+${push2.$1} items / ${push.$2}+${push2.$2} cats | '
        'fetch ${remoteItems.length} items / ${remoteCats.length} cats meta=$hasMeta | '
        'merge ${pull.$1}i/${pull.$2}c | '
        'zone=ClipValVault container=iCloud.com.clipval',
      );

      return ICloudSyncResult(
        ok: true,
        pulledItems: pull.$1,
        pulledCategories: pull.$2,
        pushedItems: push.$1 + push2.$1,
        pushedCategories: push.$2 + push2.$2,
      );
    } on PlatformException catch (e) {
      sw.stop();
      _log('FAIL ${sw.elapsedMilliseconds}ms | ${e.code}: ${e.message}');
      final mapped = mapErrorCode(platformCode: e.code, message: e.message);
      return ICloudSyncResult(
        ok: false,
        code: mapped,
        message: e.message ?? e.code,
      );
    } catch (e, st) {
      sw.stop();
      _log('FAIL ${sw.elapsedMilliseconds}ms | $e');
      debugPrint('$st');
      final mapped = mapErrorCode(message: e.toString());
      return ICloudSyncResult(
        ok: false,
        code: mapped,
        message: e.toString(),
      );
    } finally {
      _syncing = false;
    }
  }

  /// Turn sync on: verify iCloud, set pref, initial sync.
  Future<ICloudSyncResult> enableAndSync() async {
    if (!isSupported) {
      return const ICloudSyncResult(ok: false, message: 'unsupported');
    }
    final avail = await checkAvailability();
    if (avail['available'] != true) {
      _log('FAIL: enable — ${avail['status']}');
      return ICloudSyncResult(
        ok: false,
        message: avail['message']?.toString() ??
            avail['status']?.toString() ??
            'iCloud unavailable',
      );
    }
    await SettingsService.instance.setICloudSyncEnabled(true);
    return syncNow();
  }

  Future<void> disable() async {
    _debounce?.cancel();
    await SettingsService.instance.setICloudSyncEnabled(false);
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _engineInfo() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('engineInfo');
      if (raw is Map) return Map<String, dynamic>.from(raw);
    } on PlatformException catch (_) {
      // Old binary has no engineInfo.
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> _fetchAll() async {
    final raw = await _channel.invokeMethod<dynamic>('fetchAll');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  /// Fetch that never throws for empty/missing CloudKit schema.
  Future<Map<String, dynamic>> _fetchAllSafe() async {
    try {
      return await _fetchAll();
    } on PlatformException catch (e) {
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('did not find record type') ||
          msg.contains('unknown item') ||
          msg.contains('record type') ||
          msg.contains('not marked queryable') ||
          msg.contains('not queryable')) {
        return {};
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _asMapList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Ensure local AES key matches CloudKit VaultMeta.masterKey.
  Future<ICloudSyncResult?> _reconcileMasterKey(Object? metaRaw) async {
    final meta = metaRaw is Map
        ? Map<String, dynamic>.from(metaRaw)
        : <String, dynamic>{};
    final remoteKey = meta['masterKey'] as String?;
    final localKey = _encryption.exportKeyBase64();
    final localEmpty = _items.getAllRawMaps().isEmpty;

    if (remoteKey == null || remoteKey.isEmpty) {
      return null;
    }

    if (remoteKey == localKey) return null;

    if (localEmpty) {
      await _encryption.installKeyBase64(remoteKey);
      return null;
    }

    // Local has data under a different key — re-encrypt to remote key so both
    // devices converge (remote key wins as source of truth for the vault).
    try {
      await _encryption.replaceKeyAndReencrypt(
        newKeyBase64: remoteKey,
        reencryptItems: (decryptOld, encryptNew) async {
          await _items.reencryptAllValues(
            decryptWithOld: decryptOld,
            encryptWithNew: encryptNew,
          );
        },
      );
      return null;
    } catch (e) {
      return ICloudSyncResult(
        ok: false,
        message: 'Key adopt failed: $e',
      );
    }
  }

  Future<(int, int)> _applyRemote({
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> categories,
  }) async {
    var itemCount = 0;
    var catCount = 0;

    for (final remote in categories) {
      final id = remote['id'] as String?;
      if (id == null || id.isEmpty || id == 'vault_meta') continue;
      final deletedAt = parseSyncTime(remote['deletedAt']);
      final local = _categories.getRawMap(id);
      final localUpdated = parseSyncTime(local?['createdAt']);
      // Categories don't have updatedAt historically — use createdAt + name change LWW via deleted only.
      if (deletedAt != null) {
        if (shouldApplyTombstone(
          localUpdated: localUpdated,
          deletedAt: deletedAt,
        )) {
          await _categories.deleteForSync(id);
          catCount++;
        }
        continue;
      }
      if (local == null) {
        await _categories.putRawMap(_normalizeCategoryMap(remote));
        catCount++;
        continue;
      }
      // Prefer remote if systemKey/name richer or remote is newer by createdAt.
      final remoteCreated = parseSyncTime(remote['createdAt']);
      if (remoteWins(localUpdated: localUpdated, remoteUpdated: remoteCreated)) {
        await _categories.putRawMap(_normalizeCategoryMap(remote));
        catCount++;
      }
    }

    for (final remote in items) {
      final id = remote['id'] as String?;
      if (id == null || id.isEmpty) continue;
      final deletedAt = parseSyncTime(remote['deletedAt']);
      final local = _items.getRawMap(id);
      final localUpdated = parseSyncTime(local?['updatedAt']);

      if (deletedAt != null) {
        if (shouldApplyTombstone(
          localUpdated: localUpdated,
          deletedAt: deletedAt,
        )) {
          await _items.delete(id);
          itemCount++;
        }
        continue;
      }

      final remoteUpdated = parseSyncTime(remote['updatedAt']);
      if (local == null ||
          remoteWins(localUpdated: localUpdated, remoteUpdated: remoteUpdated)) {
        await _items.putRawMap(_normalizeItemMap(remote));
        itemCount++;
      }
    }

    return (itemCount, catCount);
  }

  Future<(int, int)> _pushLocal() async {
    final itemMaps = <Map<String, dynamic>>[];
    for (final raw in _items.getAllRawMaps()) {
      itemMaps.add(_cloudItemPayload(raw));
    }

    final catMaps = <Map<String, dynamic>>[];
    for (final raw in _categories.getAllRawMaps()) {
      catMaps.add(_cloudCategoryPayload(raw));
    }

    final meta = <String, dynamic>{
      'masterKey': _encryption.exportKeyBase64(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'schemaVersion': 1,
    };

    await _channel.invokeMethod<dynamic>('upsertRecords', {
      'items': itemMaps,
      'categories': catMaps,
      'meta': meta,
    });

    return (itemMaps.length, catMaps.length);
  }

  Map<String, dynamic> _cloudItemPayload(Map<String, dynamic> raw) {
    return {
      'id': raw['id'],
      'title': raw['title'] ?? '',
      // Ciphertext — never plaintext.
      'value': raw['value'] ?? '',
      'categoryId': raw['categoryId'] ?? '',
      'languageTag': raw['languageTag'] ?? '',
      'isPinned': syncBool(raw['isPinned']) ? 1 : 0,
      'isSensitive': syncBool(raw['isSensitive']) ? 1 : 0,
      'createdAt': raw['createdAt'] ?? '',
      'updatedAt': raw['updatedAt'] ?? '',
      'lastCopiedAt': raw['lastCopiedAt'] ?? '',
      'deletedAt': '',
    };
  }

  Map<String, dynamic> _cloudCategoryPayload(Map<String, dynamic> raw) {
    return {
      'id': raw['id'],
      'name': raw['name'] ?? '',
      'systemKey': raw['systemKey'] ?? '',
      'createdAt': raw['createdAt'] ?? '',
      'supportsLanguageTag': syncBool(raw['supportsLanguageTag']) ? 1 : 0,
      'deletedAt': '',
      'updatedAt': raw['createdAt'] ?? '',
    };
  }

  Map<String, dynamic> _normalizeItemMap(Map<String, dynamic> remote) {
    return {
      'id': remote['id'],
      'title': remote['title'] ?? '',
      'value': remote['value'] ?? '',
      'categoryId': _emptyToNull(remote['categoryId']),
      'languageTag': _emptyToNull(remote['languageTag']),
      'isPinned': syncBool(remote['isPinned']),
      'isSensitive': syncBool(remote['isSensitive']),
      'createdAt': remote['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': remote['updatedAt'] ?? DateTime.now().toIso8601String(),
      'lastCopiedAt': _emptyToNull(remote['lastCopiedAt']),
    };
  }

  Map<String, dynamic> _normalizeCategoryMap(Map<String, dynamic> remote) {
    return {
      'id': remote['id'],
      'name': remote['name'] ?? '',
      'systemKey': _emptyToNull(remote['systemKey']),
      'createdAt': remote['createdAt'] ?? DateTime.now().toIso8601String(),
      'supportsLanguageTag': syncBool(remote['supportsLanguageTag']),
    };
  }

  String? _emptyToNull(Object? v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return s;
  }

  /// Record a tombstone on CloudKit after local delete.
  Future<void> pushItemTombstone(String id, {DateTime? deletedAt}) async {
    if (!enabled) return;
    final at = (deletedAt ?? DateTime.now()).toUtc().toIso8601String();
    try {
      await _channel.invokeMethod<dynamic>('upsertRecords', {
        'items': [
          {
            'id': id,
            'title': '',
            'value': '',
            'categoryId': '',
            'languageTag': '',
            'isPinned': 0,
            'isSensitive': 0,
            'createdAt': at,
            'updatedAt': at,
            'lastCopiedAt': '',
            'deletedAt': at,
          },
        ],
        'categories': <Map<String, dynamic>>[],
      });
    } catch (e) {
      debugPrint('ICloudSyncService tombstone: $e');
    }
  }

  Future<void> pushCategoryTombstone(String id, {DateTime? deletedAt}) async {
    if (!enabled) return;
    final at = (deletedAt ?? DateTime.now()).toUtc().toIso8601String();
    try {
      await _channel.invokeMethod<dynamic>('upsertRecords', {
        'items': <Map<String, dynamic>>[],
        'categories': [
          {
            'id': id,
            'name': '',
            'systemKey': '',
            'createdAt': at,
            'supportsLanguageTag': 0,
            'deletedAt': at,
            'updatedAt': at,
          },
        ],
      });
    } catch (e) {
      debugPrint('ICloudSyncService cat tombstone: $e');
    }
  }
}
