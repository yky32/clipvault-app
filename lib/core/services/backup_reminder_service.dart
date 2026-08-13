import 'clip_item_repository.dart';
import 'settings_service.dart';

/// Soft nudge when vault has data, no iCloud, and no recent .clipval backup.
class BackupReminderService {
  BackupReminderService({required ClipItemRepository items}) : _items = items;

  final ClipItemRepository _items;

  /// Days without backup before showing (never backed up counts as overdue).
  static const overdueAfterDays = 14;

  /// Snooze after Not now.
  static const snoozeDays = 7;

  bool shouldShow() {
    final s = SettingsService.instance;
    // iCloud is a multi-device safety net — skip nag when on.
    if (s.iCloudSyncEnabled) return false;

    final snooze = s.backupReminderSnoozeUntil;
    if (snooze != null && DateTime.now().isBefore(snooze)) return false;

    final count = _items.getAll().length;
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
