import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository();

  final _uuid = const Uuid();
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.categoriesBoxName);
  }

  List<Category> getAll() {
    final list = _box.values
        .whereType<Map>()
        .map((raw) => Category.fromMap(Map<dynamic, dynamic>.from(raw)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<Category> create(String name) async {
    final trimmed = name.trim();
    final existing = getAll().where(
      (c) => c.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;

    final category = Category(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    await _box.put(category.id, category.toMap());
    return category;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Category? getById(String id) {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return Category.fromMap(Map<dynamic, dynamic>.from(raw));
  }
}
