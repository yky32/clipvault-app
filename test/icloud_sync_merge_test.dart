import 'package:clipval/core/services/icloud_sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('remoteWins', () {
    test('remote wins when newer', () {
      expect(
        remoteWins(
          localUpdated: DateTime.utc(2026, 1, 1),
          remoteUpdated: DateTime.utc(2026, 1, 2),
        ),
        isTrue,
      );
    });

    test('local wins when newer', () {
      expect(
        remoteWins(
          localUpdated: DateTime.utc(2026, 1, 3),
          remoteUpdated: DateTime.utc(2026, 1, 2),
        ),
        isFalse,
      );
    });

    test('equal timestamps → remote wins (converge)', () {
      final t = DateTime.utc(2026, 1, 1);
      expect(
        remoteWins(localUpdated: t, remoteUpdated: t),
        isTrue,
      );
    });

    test('missing remote never wins', () {
      expect(
        remoteWins(
          localUpdated: DateTime.utc(2026, 1, 1),
          remoteUpdated: null,
        ),
        isFalse,
      );
    });
  });

  group('shouldApplyTombstone', () {
    test('tombstone removes older local', () {
      expect(
        shouldApplyTombstone(
          localUpdated: DateTime.utc(2026, 1, 1),
          deletedAt: DateTime.utc(2026, 1, 2),
        ),
        isTrue,
      );
    });

    test('newer local survives older tombstone', () {
      expect(
        shouldApplyTombstone(
          localUpdated: DateTime.utc(2026, 1, 3),
          deletedAt: DateTime.utc(2026, 1, 2),
        ),
        isFalse,
      );
    });
  });

  group('syncBool', () {
    test('parses int and string', () {
      expect(syncBool(1), isTrue);
      expect(syncBool(0), isFalse);
      expect(syncBool('true'), isTrue);
      expect(syncBool('0'), isFalse);
    });
  });
}
