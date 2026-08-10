import 'package:clipval/core/services/share_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShareIntakeService.isShareUri', () {
    test('matches clipval://share', () {
      expect(
        ShareIntakeService.isShareUri(Uri.parse('clipval://share')),
        isTrue,
      );
      expect(
        ShareIntakeService.isShareUri(Uri.parse('clipval://share/')),
        isTrue,
      );
    });

    test('rejects widget copy and other schemes', () {
      expect(
        ShareIntakeService.isShareUri(
          Uri.parse('clipval://copy?id=abc'),
        ),
        isFalse,
      );
      expect(
        ShareIntakeService.isShareUri(Uri.parse('https://example.com')),
        isFalse,
      );
    });
  });
}
