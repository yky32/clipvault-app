import 'package:equatable/equatable.dart';

import '../constants/default_categories.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.createdAt,
    this.systemKey,
    this.supportsLanguageTag = false,
    this.colorIndex,
  });

  final String id;
  final String name;

  /// Built-in product categories (e.g. `passwords`). Null = user-created.
  final String? systemKey;
  final DateTime createdAt;

  /// When true, items in this category can pick a language tag (zh/en/…).
  final bool supportsLanguageTag;

  /// Optional palette index for custom categories (0..n). System ignores this
  /// and uses stable colors from [systemKey].
  final int? colorIndex;

  bool get isSystem => systemKey != null && systemKey!.isNotEmpty;

  Category copyWith({
    String? id,
    String? name,
    String? systemKey,
    DateTime? createdAt,
    bool? supportsLanguageTag,
    int? colorIndex,
    bool clearColorIndex = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      systemKey: systemKey ?? this.systemKey,
      createdAt: createdAt ?? this.createdAt,
      supportsLanguageTag: supportsLanguageTag ?? this.supportsLanguageTag,
      colorIndex: clearColorIndex ? null : (colorIndex ?? this.colorIndex),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'systemKey': systemKey,
      'createdAt': createdAt.toIso8601String(),
      'supportsLanguageTag': supportsLanguageTag,
      if (colorIndex != null) 'colorIndex': colorIndex,
    };
  }

  factory Category.fromMap(Map<dynamic, dynamic> map) {
    final systemKey = map['systemKey'] as String?;
    // Legacy: Addresses always had language tags before the flag existed.
    final legacyAddresses = systemKey == DefaultCategories.addresses;
    final rawColor = map['colorIndex'];
    int? colorIndex;
    if (rawColor is int) {
      colorIndex = rawColor;
    } else if (rawColor is num) {
      colorIndex = rawColor.toInt();
    }
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      systemKey: systemKey,
      createdAt: DateTime.parse(map['createdAt'] as String),
      supportsLanguageTag:
          map['supportsLanguageTag'] as bool? ?? legacyAddresses,
      colorIndex: colorIndex,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, systemKey, createdAt, supportsLanguageTag, colorIndex];
}
