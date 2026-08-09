class AppConstants {
  AppConstants._();

  static const appName = 'ClipVal';
  static const itemsBoxName = 'clip_items';
  static const categoriesBoxName = 'categories';
  static const encryptionKeyName = 'clipval_aes_key';
  static const recentCopiedLimit = 8;

  /// App Group shared with the iOS home-screen widget.
  static const widgetAppGroupId = 'group.com.clipval';

  /// WidgetKit kind / iOS target name (must match native extension).
  static const widgetIosName = 'ClipValWidget';

  /// JSON payload key in App Group UserDefaults.
  static const widgetItemsKey = 'widget_items_json';

  /// Max items on the home-screen widget (4 columns × 2 rows).
  static const widgetItemLimit = 8;

  /// Deep link scheme: `clipval://copy?id=<itemId>` (iOS 15–16 fallback).
  static const urlScheme = 'clipval';
}
