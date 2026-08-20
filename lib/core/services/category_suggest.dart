import '../constants/default_categories.dart';
import '../models/category.dart';

/// Suggest a system category from title/value (new item only).
String? suggestCategorySystemKey({
  required String title,
  required String value,
}) {
  final t = '${title.trim()} ${value.trim()}'.toLowerCase();
  if (t.isEmpty) return null;

  if (t.contains('wifi') ||
      t.contains('wi-fi') ||
      t.contains('ssid') ||
      t.contains('wpa')) {
    return DefaultCategories.wifi;
  }
  if (t.contains('fps') ||
      t.contains('iban') ||
      t.contains('swift') ||
      (t.contains('bank') && RegExp(r'\d{6,}').hasMatch(t))) {
    return DefaultCategories.banking;
  }
  if (t.contains('http://') ||
      t.contains('https://') ||
      t.contains('www.') ||
      t.contains('api_key') ||
      t.contains('apikey') ||
      t.contains('bearer ')) {
    return DefaultCategories.developer;
  }
  if (t.contains('password') ||
      t.contains('passwd') ||
      t.contains('otp') ||
      t.contains('2fa') ||
      t.contains('totp')) {
    return DefaultCategories.passwords;
  }
  if (t.contains('code') || RegExp(r'^\d{4,8}$').hasMatch(value.trim())) {
    return DefaultCategories.codes;
  }
  return null;
}

String? resolveCategoryId(
  List<Category> categories,
  String? systemKey,
) {
  if (systemKey == null) return null;
  for (final c in categories) {
    if (c.systemKey == systemKey) return c.id;
  }
  return null;
}
