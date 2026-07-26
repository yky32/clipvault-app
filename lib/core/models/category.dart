import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.createdAt,
    this.systemKey,
  });

  final String id;
  final String name;

  /// Built-in product categories (e.g. `passwords`). Null = user-created.
  final String? systemKey;
  final DateTime createdAt;

  bool get isSystem => systemKey != null && systemKey!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'systemKey': systemKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<dynamic, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      systemKey: map['systemKey'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, systemKey, createdAt];
}
