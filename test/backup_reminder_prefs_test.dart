import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clipval/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
  });

  test('backup reminder prefs round-trip', () async {
    expect(SettingsService.instance.lastSecureBackupAt, isNull);
    await SettingsService.instance.setLastSecureBackupAt(DateTime(2026, 1, 1));
    expect(SettingsService.instance.lastSecureBackupAt?.year, 2026);

    final until = DateTime.now().add(const Duration(days: 7));
    await SettingsService.instance.setBackupReminderSnoozeUntil(until);
    expect(SettingsService.instance.backupReminderSnoozeUntil, isNotNull);
    await SettingsService.instance.setBackupReminderSnoozeUntil(null);
    expect(SettingsService.instance.backupReminderSnoozeUntil, isNull);
  });
}
