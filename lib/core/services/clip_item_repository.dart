import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/clip_item.dart';
import 'encryption_service.dart';

class ClipItemRepository {
  ClipItemRepository(this._encryption);

  final EncryptionService _encryption;
  final _uuid = const Uuid();
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.itemsBoxName);
  }

  List<ClipItem> getAll() {
    final items = _box.values
        .whereType<Map>()
        .map((raw) => _fromStored(Map<dynamic, dynamic>.from(raw)))
        .toList();
    items.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return items;
  }

  ClipItem? getById(String id) {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return _fromStored(Map<dynamic, dynamic>.from(raw));
  }

  Future<ClipItem> create({
    required String title,
    required String value,
    String? categoryId,
    String? languageTag,
    bool isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCopiedAt,
  }) async {
    final now = DateTime.now();
    final item = ClipItem(
      id: _uuid.v4(),
      title: title.trim(),
      value: value,
      categoryId: categoryId,
      languageTag: languageTag,
      isPinned: isPinned,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      lastCopiedAt: lastCopiedAt,
    );
    await _save(item);
    return item;
  }

  Future<ClipItem> update(ClipItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _save(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Remove many items in one pass (bulk delete).
  Future<void> deleteMany(Iterable<String> ids) async {
    for (final id in ids) {
      await _box.delete(id);
    }
  }

  Future<ClipItem> markCopied(String id) async {
    final existing = getById(id);
    if (existing == null) {
      throw StateError('Item not found: $id');
    }
    final updated = existing.copyWith(
      lastCopiedAt: DateTime.now(),
      updatedAt: existing.updatedAt,
    );
    await _save(updated);
    return updated;
  }

  Future<String> exportPlainText() async {
    final items = getAll();
    final buffer = StringBuffer('ClipVal export\n');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');
    for (final item in items) {
      buffer.writeln('---');
      buffer.writeln('Title: ${item.title}');
      if (item.categoryId != null) {
        buffer.writeln('Category: ${item.categoryId}');
      }
      if (item.languageTag != null) {
        buffer.writeln('Language: ${item.languageTag}');
      }
      buffer.writeln('Value: ${item.value}');
      buffer.writeln(
        'Last used: ${item.lastCopiedAt?.toIso8601String() ?? 'never'}',
      );
      buffer.writeln();
    }
    return buffer.toString();
  }

  Future<void> _save(ClipItem item) async {
    final encrypted = _encryption.encryptText(item.value);
    await _box.put(item.id, item.toMap(encryptedValue: encrypted));
  }

  ClipItem _fromStored(Map<dynamic, dynamic> raw) {
    final encrypted = raw['value'] as String;
    final plaintext = _encryption.decryptText(encrypted);
    return ClipItem.fromMap(raw, plaintextValue: plaintext);
  }
}
