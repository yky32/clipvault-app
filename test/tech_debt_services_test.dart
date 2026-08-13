import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clipval/core/services/backup_reminder_service.dart';
import 'package:clipval/core/services/clipboard_service.dart';
import 'package:clipval/core/services/clipboard_suggest_service.dart';
import 'package:clipval/core/services/nearby/nearby_crypto.dart';
import 'package:clipval/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
  });

  group('BackupReminderService', () {
    test('hidden when no items', () {
      expect(BackupReminderService(itemCount: () => 0).shouldShow(), isFalse);
    });

    test('shown when items and never backed up', () {
      expect(BackupReminderService(itemCount: () => 3).shouldShow(), isTrue);
    });

    test('hidden when iCloud on', () async {
      await SettingsService.instance.setICloudSyncEnabled(true);
      expect(BackupReminderService(itemCount: () => 3).shouldShow(), isFalse);
      await SettingsService.instance.setICloudSyncEnabled(false);
    });

    test('hidden when recent backup', () async {
      await SettingsService.instance.setLastSecureBackupAt(DateTime.now());
      expect(BackupReminderService(itemCount: () => 3).shouldShow(), isFalse);
    });

    test('shown when backup older than threshold', () async {
      await SettingsService.instance.setLastSecureBackupAt(
        DateTime.now().subtract(const Duration(days: 20)),
      );
      expect(BackupReminderService(itemCount: () => 2).shouldShow(), isTrue);
    });

    test('snooze hides', () async {
      await BackupReminderService(itemCount: () => 2).snooze();
      expect(BackupReminderService(itemCount: () => 2).shouldShow(), isFalse);
    });
  });

  group('ClipboardSuggestService', () {
    late ClipboardService clipboard;

    setUp(() {
      clipboard = ClipboardService();
    });

    test('off by default', () async {
      final svc = ClipboardSuggestService(
        clipboard: clipboard,
        readText: () async => 'hello-world',
        existingValues: () => const <String>[],
      );
      expect(await svc.evaluate(), isNull);
    });

    test('suggests when enabled', () async {
      await SettingsService.instance.setClipboardSuggestEnabled(true);
      final svc = ClipboardSuggestService(
        clipboard: clipboard,
        readText: () async => 'hello-world',
        existingValues: () => const <String>[],
      );
      expect(await svc.evaluate(), 'hello-world');
    });

    test('skips self-copied', () async {
      await SettingsService.instance.setClipboardSuggestEnabled(true);
      clipboard.lastSelfCopiedText = 'mine';
      final svc = ClipboardSuggestService(
        clipboard: clipboard,
        readText: () async => 'mine',
        existingValues: () => const <String>[],
      );
      expect(await svc.evaluate(), isNull);
    });

    test('skips dismissed fingerprint', () async {
      await SettingsService.instance.setClipboardSuggestEnabled(true);
      const text = 'dismiss-me';
      await SettingsService.instance.setClipboardSuggestLastDismissed(
        NearbyCrypto.clipboardFingerprint(text),
      );
      final svc = ClipboardSuggestService(
        clipboard: clipboard,
        readText: () async => text,
        existingValues: () => const <String>[],
      );
      expect(await svc.evaluate(), isNull);
    });

    test('skips existing vault value', () async {
      await SettingsService.instance.setClipboardSuggestEnabled(true);
      final svc = ClipboardSuggestService(
        clipboard: clipboard,
        readText: () async => 'already',
        existingValues: () => const ['already'],
      );
      expect(await svc.evaluate(), isNull);
    });
  });

  group('NearbyCrypto', () {
    test('pin validity', () {
      expect(NearbyCrypto.isValidPin('123456'), isTrue);
      expect(NearbyCrypto.isValidPin('12345'), isFalse);
    });
  });
}
