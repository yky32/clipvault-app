import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap.dart';
import '../constants/default_categories.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';

/// Simple SF-style icons for product categories.
IconData categoryIcon(Category category) {
  return systemCategoryIcon(category.systemKey);
}

IconData systemCategoryIcon(String? systemKey) {
  return switch (systemKey) {
    DefaultCategories.passwords => CupertinoIcons.lock_fill,
    DefaultCategories.banking => CupertinoIcons.creditcard_fill,
    DefaultCategories.wifi => CupertinoIcons.wifi,
    DefaultCategories.codes => CupertinoIcons.number,
    DefaultCategories.addresses => CupertinoIcons.location_solid,
    DefaultCategories.developer =>
      CupertinoIcons.chevron_left_slash_chevron_right,
    DefaultCategories.templates => CupertinoIcons.doc_text_fill,
    _ => CupertinoIcons.tag_fill,
  };
}

/// Resolve icon by stored category id (works for system + custom).
IconData categoryIconForId(String? categoryId) {
  if (categoryId == null) return CupertinoIcons.tag;
  try {
    final cat = AppBootstrap.categoryRepository.getById(categoryId);
    if (cat != null) return categoryIcon(cat);
  } catch (_) {}
  return CupertinoIcons.tag_fill;
}

/// Leading tile used everywhere categories appear (vault, form, settings).
class CategoryLeadingIcon extends StatelessWidget {
  const CategoryLeadingIcon({
    this.category,
    this.categoryId,
    this.size = 30,
    this.iconSize = 16,
    this.filled = false,
    super.key,
  });

  final Category? category;
  final String? categoryId;
  final double size;
  final double iconSize;

  /// Filled primary background (like Pin row).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (category != null) {
      icon = categoryIcon(category!);
    } else if (categoryId != null) {
      icon = categoryIconForId(categoryId);
    } else {
      icon = CupertinoIcons.tag;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: filled ? Colors.white : AppColors.primary,
      ),
    );
  }
}
