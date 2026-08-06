import 'package:equatable/equatable.dart';

/// Domain model for a vault item (PRD §10).
/// [value] is always plaintext in memory; encrypted only at rest.
class ClipItem extends Equatable {
  const ClipItem({
    required this.id,
    required this.title,
    required this.value,
    this.categoryId,
    /// Optional display tag for Addresses only: `zh` | `en`. Null = unmarked.
    this.languageTag,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastCopiedAt,
  });

  static const languageZh = 'zh';
  static const languageEn = 'en';

  final String id;
  final String title;
  final String value;
  final String? categoryId;
  final String? languageTag;
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
    String? languageTag,
    bool clearLanguageTag = false,
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
      languageTag:
          clearLanguageTag ? null : (languageTag ?? this.languageTag),
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
      'languageTag': languageTag,
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
    final rawTag = map['languageTag'] as String?;
    final tag = rawTag == languageZh || rawTag == languageEn ? rawTag : null;
    return ClipItem(
      id: map['id'] as String,
      title: map['title'] as String,
      value: plaintextValue,
      categoryId: map['categoryId'] as String?,
      languageTag: tag,
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
        languageTag,
        isPinned,
        createdAt,
        updatedAt,
        lastCopiedAt,
      ];
}
