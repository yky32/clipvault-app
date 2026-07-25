import 'package:hive_ce_flutter/hive_flutter.dart';

import '../services/auth_service.dart';
import '../services/category_repository.dart';
import '../services/clip_item_repository.dart';
import '../services/clipboard_service.dart';
import '../services/encryption_service.dart';
import '../services/settings_service.dart';

/// Central startup wiring (pattern from Triftly AppBootstrap).
class AppBootstrap {
  AppBootstrap._();

  static late final EncryptionService encryptionService;
  static late final ClipItemRepository clipItemRepository;
  static late final CategoryRepository categoryRepository;
  static late final ClipboardService clipboardService;
  static late final AuthService authService;

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
  }
}
