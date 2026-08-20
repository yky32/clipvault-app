class AppConstants {
  AppConstants._();

  static const appName = 'ClipVal';
  static const itemsBoxName = 'clip_items';
  static const categoriesBoxName = 'categories';
  static const encryptionKeyName = 'clipval_aes_key';
  static const recentCopiedLimit = 8;

  /// List/grid body "Recent" section size (separate from horizontal strip).
  static const recentBodySectionLimit = 6;

  /// App Group shared with the iOS home-screen widget.
  static const widgetAppGroupId = 'group.com.clipval';

  /// WidgetKit kind / iOS target name (must match native extension).
  static const widgetIosName = 'ClipValWidget';

  /// JSON payload key in App Group UserDefaults.
  static const widgetItemsKey = 'widget_items_json';

  /// Dedicated keyboard payload (larger than widget; titles always kept).
  static const keyboardItemsKey = 'keyboard_items_json';

  /// Max items pushed to the home-screen widget (medium 4×2, large 4×4).
  static const widgetItemLimit = 16;

  /// Max items for custom keyboard chips (pinned + recent).
  static const keyboardItemLimit = 24;

  /// App Group flag: widget should mask titles (app lock / privacy).
  static const widgetHideTitlesKey = 'widget_hide_titles';

  /// Deep link scheme: `clipval://copy?id=<itemId>` (iOS 15–16 fallback).
  static const urlScheme = 'clipval';
}
