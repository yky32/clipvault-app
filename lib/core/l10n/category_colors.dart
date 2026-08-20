import 'package:flutter/material.dart';

import '../constants/default_categories.dart';
import '../models/category.dart';

/// Distinct palette for category color tags (screenshot-style dots / chips).
///
/// System categories get stable brand-ish colors; custom categories use
/// [Category.colorIndex] or a hash of [Category.id].
abstract final class CategoryColors {
  /// Curated dots — high contrast on light/dark list rows.
  static const List<Color> palette = [
    Color(0xFF2563EB), // blue — links / developer
    Color(0xFF16A34A), // green — addresses
    Color(0xFFDB2777), // pink — templates / replies
    Color(0xFFEA580C), // orange — email-ish / wifi warmth
    Color(0xFF7C3AED), // violet — passwords
    Color(0xFF64748B), // slate — other
    Color(0xFF0891B2), // cyan — codes
    Color(0xFFCA8A04), // amber — banking
    Color(0xFFDC2626), // red
    Color(0xFF0D9488), // teal
    Color(0xFF4F46E5), // indigo
    Color(0xFF9333EA), // purple
  ];

  static Color forSystemKey(String? systemKey) {
    return switch (systemKey) {
      DefaultCategories.passwords => palette[4], // violet
      DefaultCategories.banking => palette[7], // amber
      DefaultCategories.wifi => palette[3], // orange
      DefaultCategories.codes => palette[6], // cyan
      DefaultCategories.addresses => palette[1], // green
      DefaultCategories.developer => palette[0], // blue
      DefaultCategories.templates => palette[2], // pink
      _ => palette[5], // slate
    };
  }

  static Color forCategory(Category category) {
    if (category.colorIndex != null) {
      final i = category.colorIndex! % palette.length;
      return palette[i < 0 ? 0 : i];
    }
    if (category.isSystem) {
      return forSystemKey(category.systemKey);
    }
    return palette[_stableIndex(category.id)];
  }

  static Color forCategoryId(String? categoryId, Category? Function(String id) resolve) {
    if (categoryId == null) return palette[5];
    final c = resolve(categoryId);
    if (c != null) return forCategory(c);
    return palette[_stableIndex(categoryId)];
  }

  static int _stableIndex(String id) {
    var h = 0;
    for (final u in id.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return h % palette.length;
  }

  static int nextIndex(int? current) {
    final i = (current ?? 0) + 1;
    return i % palette.length;
  }
}

/// Small filled circle used on chips / rows.
class CategoryColorDot extends StatelessWidget {
  const CategoryColorDot({
    required this.color,
    this.size = 8,
    super.key,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
    );
  }
}
