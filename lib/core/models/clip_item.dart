import 'package:equatable/equatable.dart';

/// Domain model for a vault item (PRD §10).
/// [value] is always plaintext in memory; encrypted only at rest.
class ClipItem extends Equatable {
  const ClipItem({
    required this.id,
    required this.title,
    required this.value,
    this.categoryId,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastCopiedAt,
  });

  final String id;
  final String title;
  final String value;
  final String? categoryId;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastCopiedAt;

  ClipItem copyWith({
    String? id,
    String? title,
    String? value,
    String? categoryId,
    bool clearCategory = false,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCopiedAt,
    bool clearLastCopied = false,
  }) {
    return ClipItem(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastCopiedAt:
          clearLastCopied ? null : (lastCopiedAt ?? this.lastCopiedAt),
    );
  }

  Map<String, dynamic> toMap({required String encryptedValue}) {
    return {
      'id': id,
      'title': title,
      'value': encryptedValue,
      'categoryId': categoryId,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastCopiedAt': lastCopiedAt?.toIso8601String(),
    };
  }

  factory ClipItem.fromMap(
    Map<dynamic, dynamic> map, {
    required String plaintextValue,
  }) {
    return ClipItem(
      id: map['id'] as String,
      title: map['title'] as String,
      value: plaintextValue,
      categoryId: map['categoryId'] as String?,
      isPinned: map['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastCopiedAt: map['lastCopiedAt'] != null
          ? DateTime.parse(map['lastCopiedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        value,
        categoryId,
        isPinned,
        createdAt,
        updatedAt,
        lastCopiedAt,
      ];
}
