import 'package:clipval/core/constants/default_categories.dart';
import 'package:clipval/core/services/category_suggest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wifi / banking / developer / passwords', () {
    expect(
      suggestCategorySystemKey(title: 'Home', value: 'ssid MyWiFi'),
      DefaultCategories.wifi,
    );
    expect(
      suggestCategorySystemKey(title: 'FPS', value: '123456789'),
      DefaultCategories.banking,
    );
    expect(
      suggestCategorySystemKey(title: 'API', value: 'https://api.example.com'),
      DefaultCategories.developer,
    );
    expect(
      suggestCategorySystemKey(title: 'GitHub', value: 'password: hunter2'),
      DefaultCategories.passwords,
    );
  });
}
