import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../constants/default_categories.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository();

  final _uuid = const Uuid();
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.categoriesBoxName);
    await ensureDefaultCategories();
  }

  /// Seeds product default categories (PRD use-cases) if missing.
  /// Does not overwrite user renames of custom categories.
  Future<void> ensureDefaultCategories() async {
    final existing = getAll();
    final existingKeys = existing
        .map((c) => c.systemKey)
        .whereType<String>()
        .toSet();

    final now = DateTime.now();
    for (final def in DefaultCategories.all) {
      if (existingKeys.contains(def.systemKey)) continue;

      // Also skip if a user already created the same name manually.
      final nameTaken = existing.any(
        (c) => c.name.toLowerCase() == def.name.toLowerCase(),
      );
      if (nameTaken) continue;

      final category = Category(
        id: DefaultCategories.boxId(def.systemKey),
        name: def.name,
        systemKey: def.systemKey,
        createdAt: now.add(Duration(milliseconds: def.sortOrder)),
        supportsLanguageTag: def.systemKey == DefaultCategories.addresses,
      );
      await _box.put(category.id, category.toMap());
    }

    // Persist language flag for Addresses if older installs lack the field.
    for (final c in getAll()) {
      if (c.systemKey != DefaultCategories.addresses) continue;
      if (c.supportsLanguageTag) continue;
      await _box.put(
        c.id,
        c.copyWith(supportsLanguageTag: true).toMap(),
      );
    }
  }

  List<Category> getAll() {
    final list = _box.values
        .whereType<Map>()
        .map((raw) => Category.fromMap(Map<dynamic, dynamic>.from(raw)))
        .toList();

    list.sort((a, b) {
      final aOrder = _sortOrder(a);
      final bOrder = _sortOrder(b);
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  int _sortOrder(Category c) {
    if (c.systemKey == null) return 1000;
    for (final def in DefaultCategories.all) {
      if (def.systemKey == c.systemKey) return def.sortOrder;
    }
    return 500;
  }

  Future<Category> create(
    String name, {
    bool supportsLanguageTag = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required');
    }
    final existing = getAll().where(
      (c) => c.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;

    final category = Category(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: DateTime.now(),
      supportsLanguageTag: supportsLanguageTag,
    );
    await _box.put(category.id, category.toMap());
    return category;
  }

  /// Update a **custom** category (name and/or language-tag support).
  Future<Category> updateCustom(
    String id, {
    String? name,
    bool? supportsLanguageTag,
  }) async {
    final existing = getById(id);
    if (existing == null) {
      throw StateError('Category not found: $id');
    }
    if (existing.isSystem) {
      throw StateError('System categories cannot be edited');
    }
    final trimmed = (name ?? existing.name).trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required');
    }
    final clash = getAll().where(
      (c) => c.id != id && c.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (clash.isNotEmpty) {
      throw StateError('A category with that name already exists');
    }
    final updated = existing.copyWith(
      name: trimmed,
      supportsLanguageTag: supportsLanguageTag ?? existing.supportsLanguageTag,
    );
    await _box.put(updated.id, updated.toMap());
    return updated;
  }

  /// Rename a **custom** category. System defaults keep product names.
  Future<Category> rename(String id, String newName) =>
      updateCustom(id, name: newName);

  /// Delete a **custom** category only. Product defaults are kept.
  Future<void> delete(String id) async {
    final existing = getById(id);
    if (existing == null) return;
    if (existing.isSystem) {
      throw StateError('System categories cannot be deleted');
    }
    await _box.delete(id);
  }

  List<Category> get systemCategories =>
      getAll().where((c) => c.isSystem).toList();

  List<Category> get customCategories =>
      getAll().where((c) => !c.isSystem).toList();

  Category? getById(String id) {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return Category.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Category? getBySystemKey(String systemKey) {
    for (final c in getAll()) {
      if (c.systemKey == systemKey) return c;
    }
    return null;
  }
}
