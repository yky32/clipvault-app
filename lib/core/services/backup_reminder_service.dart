import 'settings_service.dart';

/// Soft nudge when vault has data and no recent .clipval backup.
/// On iOS, suppressed when private iCloud sync is on (no cloud equivalent on Android).
class BackupReminderService {
  BackupReminderService({int Function()? itemCount})
      : _itemCount = itemCount;

  final int Function()? _itemCount;

  static const overdueAfterDays = 14;
  static const snoozeDays = 7;

  bool shouldShow({int? itemCountOverride}) {
    final s = SettingsService.instance;
    if (s.iCloudSyncEnabled) return false;

    final snooze = s.backupReminderSnoozeUntil;
    if (snooze != null && DateTime.now().isBefore(snooze)) return false;

    final count = itemCountOverride ?? _itemCount?.call() ?? 0;
    if (count == 0) return false;

    final last = s.lastSecureBackupAt;
    if (last == null) return true;
    final age = DateTime.now().difference(last);
    return age.inDays >= overdueAfterDays;
  }

  Future<void> markBackupDone() =>
      SettingsService.instance.setLastSecureBackupAt(DateTime.now());

  Future<void> snooze() => SettingsService.instance.setBackupReminderSnoozeUntil(
        DateTime.now().add(const Duration(days: snoozeDays)),
      );
}
