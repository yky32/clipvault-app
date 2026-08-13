import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../services/auth_service.dart';
import '../services/category_repository.dart';
import '../services/clip_item_repository.dart';
import '../services/clipboard_service.dart';
import '../services/encryption_service.dart';
import '../services/icloud_sync_service.dart';
import '../services/settings_service.dart';
import '../services/vault_migration_service.dart';
import '../services/widget_snapshot_service.dart';
import '../services/nearby/nearby_service.dart';

/// Central startup wiring (pattern from Triftly AppBootstrap).
class AppBootstrap {
  AppBootstrap._();

  static late final EncryptionService encryptionService;
  static late final ClipItemRepository clipItemRepository;
  static late final CategoryRepository categoryRepository;
  static late final ClipboardService clipboardService;
  static late final AuthService authService;
  static late final VaultMigrationService vaultMigrationService;
  static late final WidgetSnapshotService widgetSnapshotService;
  static late final ICloudSyncService iCloudSyncService;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await SettingsService.instance.init();

    encryptionService = EncryptionService();
    await encryptionService.init();

    clipItemRepository = ClipItemRepository(encryptionService);
    await clipItemRepository.init();

    categoryRepository = CategoryRepository();
    await categoryRepository.init();

    clipboardService = ClipboardService();
    authService = AuthService();
    vaultMigrationService = VaultMigrationService(
      items: clipItemRepository,
      categories: categoryRepository,
    );

    widgetSnapshotService = WidgetSnapshotService(clipItemRepository);
    await widgetSnapshotService.init();
    // Best-effort: keep home-screen widget in sync after cold start.
    await widgetSnapshotService.sync();

    iCloudSyncService = ICloudSyncService(
      encryption: encryptionService,
      items: clipItemRepository,
      categories: categoryRepository,
      widgetSnapshot: widgetSnapshotService,
    );
    // Best-effort pull if user already opted into iCloud sync.
    if (SettingsService.instance.iCloudSyncEnabled) {
      unawaited(iCloudSyncService.syncNow());
    }

    // Nearby LAN send/receive — only if user opted in.
    unawaited(NearbyService.instance.startIfEnabled());
  }
}
