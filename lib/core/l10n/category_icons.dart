import 'package:flutter/cupertino.dart';

import '../constants/default_categories.dart';
import '../models/category.dart';

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
