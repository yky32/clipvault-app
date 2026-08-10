import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/address_languages.dart';

/// Sort mode for vault lists (pinned items always first).
enum VaultSortMode {
  /// Recently updated first (default Hive order).
  updated,
  /// Recently copied first.
  lastUsed,
  /// A–Z by title.
  title,
}

enum VaultViewMode {
  list,
  grid2,
  grid3;

  bool get isGrid => this == grid2 || this == grid3;

  int get gridCrossAxisCount => switch (this) {
        list => 1,
        grid2 => 2,
        grid3 => 3,
      };

  VaultViewMode get next => switch (this) {
        list => grid2,
        grid2 => grid3,
        grid3 => list,
      };
}

/// Fixed grid card title sizes (no shrink-to-fit).
enum GridTitleSize {
  large,
  medium,
  small;

  /// Title point size on **2-column** (and default) grid tiles.
  double get titleFontSize => switch (this) {
        large => 24,
        medium => 20,
        small => 15,
      };

  /// Meta line under the title (2-column / default).
  double get metaFontSize => switch (this) {
        large => 12.5,
        medium => 12,
        small => 11,
      };

  /// Title size scaled for column count — 3-col tiles are ~½ the width.
  double titleFontSizeForColumns(int columns) {
    if (columns >= 3) {
      return switch (this) {
        // Tuned so “Ref Code” / “Area Code” read cleanly on ~100pt tiles.
        large => 16,
        medium => 14.5,
        small => 13,
      };
    }
    return titleFontSize;
  }

  /// Meta size for the given grid density.
  double metaFontSizeForColumns(int columns) {
    if (columns >= 3) {
      return switch (this) {
        large => 11,
        medium => 10.5,
        small => 10,
      };
    }
    return metaFontSize;
  }

  /// Line height for titles at this density (slightly tighter in 3-col).
  double titleLineHeightForColumns(int columns) =>
      columns >= 3 ? 1.08 : 1.12;
}

/// In-app UI language preference.
enum AppLocalePreference {
  /// Follow device language (zh → Chinese, else English).
  system,
  en,
  zh;

  /// Stored prefs value (`null` key removed for system).
  String? get storageCode => switch (this) {
        system => null,
        en => 'en',
        zh => 'zh',
      };

  static AppLocalePreference fromStorage(String? code) => switch (code) {
        'en' => en,
        'zh' => zh,
        _ => system,
      };
}

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _onboardingKey = 'onboarding_done';
  /// Marketing version (e.g. 1.0.0) last dismissed for the welcome sheet.
  /// Null = never seen (first install). Re-show only when App Store version changes.
  static const _welcomeSeenVersionKey = 'welcome_seen_version';
  /// Opt-in only via Settings. New key so older onboarding-forced values are ignored.
  static const _biometricKey = 'app_lock_enabled';
  static const _viewModeKey = 'default_view';
  static const _clipboardClearKey = 'clipboard_clear_seconds';
  static const _localeKey = 'locale_code';
  static const _gridTitleSizeKey = 'grid_title_size';
  /// Enabled address language tag codes (e.g. `zh`, `en`). Order = chip order.
  static const _addressLanguageTagsKey = 'address_language_tags';
  /// Home widget: only show pinned items (favorites).
  static const _widgetPinnedOnlyKey = 'widget_pinned_only';
  /// Home widget: mask titles when app lock is enabled.
  static const _widgetHideTitlesWhenLockedKey = 'widget_hide_titles_locked';
  /// Vault list sort (pin always first).
  static const _vaultSortKey = 'vault_sort';
  /// Face ID / passcode required to show value in editor (when app lock on).
  static const _requireAuthToRevealKey = 'require_auth_to_reveal';
  /// Seconds after backgrounding before re-lock; 0 = immediate.
  static const _autoLockTimeoutKey = 'auto_lock_timeout_seconds';

  late SharedPreferences _prefs;

  /// Listenable so vault grid rebuilds when size changes in Settings.
  final ValueNotifier<GridTitleSize> gridTitleSizeListenable =
      ValueNotifier(GridTitleSize.large);

  /// Listenable so [MaterialApp] rebuilds when language changes in Settings.
  final ValueNotifier<AppLocalePreference> localePreferenceListenable =
      ValueNotifier(AppLocalePreference.system);

  /// Listenable so Add/Edit item chips refresh when tags change in Settings.
  final ValueNotifier<List<String>> addressLanguageTagsListenable =
      ValueNotifier(List<String>.from(AddressLanguages.defaults));

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Drop legacy key that may have been set during forced onboarding prompt.
    if (_prefs.containsKey('biometric_lock')) {
      await _prefs.remove('biometric_lock');
    }
    gridTitleSizeListenable.value = gridTitleSize;
    localePreferenceListenable.value = localePreference;
    addressLanguageTagsListenable.value = addressLanguageTags;
  }

  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  /// Last marketing version for which the welcome / what's-new sheet was dismissed.
  String? get welcomeSeenVersion => _prefs.getString(_welcomeSeenVersionKey);

  /// Show on first install, or when App Store marketing version upgrades.
  /// Build number changes alone (1.0.0+2 → 1.0.0+3) do not re-show.
  bool shouldShowWelcome(String marketingVersion) {
    final seen = welcomeSeenVersion;
    if (seen == null || seen.isEmpty) return true;
    return seen != marketingVersion;
  }

  /// Persist that the user finished the welcome sheet for [marketingVersion].
  /// Also marks legacy onboarding complete so old routes stay consistent.
  Future<void> markWelcomeSeen(String marketingVersion) async {
    await _prefs.setString(_welcomeSeenVersionKey, marketingVersion);
    await setOnboardingDone(true);
  }

  /// Always defaults to **false**. Only Settings can turn this on.
  bool get biometricLockEnabled => _prefs.getBool(_biometricKey) ?? false;

  Future<void> setBiometricLockEnabled(bool value) =>
      _prefs.setBool(_biometricKey, value);

  /// When app lock is on, require biometrics to reveal values in the editor.
  /// Defaults to **true** (only applies while [biometricLockEnabled]).
  bool get requireAuthToRevealStored =>
      _prefs.getBool(_requireAuthToRevealKey) ?? true;

  bool get requireAuthToReveal =>
      biometricLockEnabled && requireAuthToRevealStored;

  Future<void> setRequireAuthToReveal(bool value) =>
      _prefs.setBool(_requireAuthToRevealKey, value);

  /// Auto re-lock delay after leaving the app. `0` = on next resume.
  /// Allowed: 0, 60, 300, 900.
  int get autoLockTimeoutSeconds {
    final raw = _prefs.getInt(_autoLockTimeoutKey) ?? 0;
    if (raw == 60 || raw == 300 || raw == 900) return raw;
    return 0;
  }

  Future<void> setAutoLockTimeoutSeconds(int seconds) {
    final allowed = {0, 60, 300, 900};
    return _prefs.setInt(
      _autoLockTimeoutKey,
      allowed.contains(seconds) ? seconds : 0,
    );
  }

  /// Widget shows only pinned items (default false = pinned + recent + rest).
  bool get widgetPinnedOnly => _prefs.getBool(_widgetPinnedOnlyKey) ?? false;

  Future<void> setWidgetPinnedOnly(bool value) =>
      _prefs.setBool(_widgetPinnedOnlyKey, value);

  /// When app lock is on, widget shows monogram only (not full titles).
  bool get widgetHideTitlesWhenLocked =>
      _prefs.getBool(_widgetHideTitlesWhenLockedKey) ?? true;

  Future<void> setWidgetHideTitlesWhenLocked(bool value) =>
      _prefs.setBool(_widgetHideTitlesWhenLockedKey, value);

  /// How unpinned vault items are ordered (pinned always on top).
  VaultSortMode get vaultSortMode {
    final raw = _prefs.getString(_vaultSortKey);
    return switch (raw) {
      'title' => VaultSortMode.title,
      'lastUsed' => VaultSortMode.lastUsed,
      _ => VaultSortMode.updated,
    };
  }

  Future<void> setVaultSortMode(VaultSortMode mode) => _prefs.setString(
        _vaultSortKey,
        switch (mode) {
          VaultSortMode.updated => 'updated',
          VaultSortMode.lastUsed => 'lastUsed',
          VaultSortMode.title => 'title',
        },
      );

  VaultViewMode get defaultViewMode {
    final raw = _prefs.getString(_viewModeKey);
    return switch (raw) {
      'grid' || 'grid2' => VaultViewMode.grid2, // migrate legacy `grid`
      'grid3' => VaultViewMode.grid3,
      _ => VaultViewMode.list,
    };
  }

  Future<void> setDefaultViewMode(VaultViewMode mode) => _prefs.setString(
        _viewModeKey,
        switch (mode) {
          VaultViewMode.list => 'list',
          VaultViewMode.grid2 => 'grid2',
          VaultViewMode.grid3 => 'grid3',
        },
      );

  /// 0 = never. Common options: 0, 15, 30, 60.
  int get clipboardClearSeconds => _prefs.getInt(_clipboardClearKey) ?? 0;

  Future<void> setClipboardClearSeconds(int seconds) =>
      _prefs.setInt(_clipboardClearKey, seconds);

  String? get localeCode => _prefs.getString(_localeKey);

  AppLocalePreference get localePreference =>
      AppLocalePreference.fromStorage(localeCode);

  Future<void> setLocaleCode(String? code) async {
    if (code == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, code);
    }
    localePreferenceListenable.value = AppLocalePreference.fromStorage(code);
  }

  Future<void> setLocalePreference(AppLocalePreference pref) =>
      setLocaleCode(pref.storageCode);

  /// Grid card title size. Default **large** (no auto-shrink).
  GridTitleSize get gridTitleSize {
    final raw = _prefs.getString(_gridTitleSizeKey);
    return switch (raw) {
      'medium' => GridTitleSize.medium,
      'small' => GridTitleSize.small,
      _ => GridTitleSize.large,
    };
  }

  Future<void> setGridTitleSize(GridTitleSize size) async {
    await _prefs.setString(
      _gridTitleSizeKey,
      switch (size) {
        GridTitleSize.large => 'large',
        GridTitleSize.medium => 'medium',
        GridTitleSize.small => 'small',
      },
    );
    gridTitleSizeListenable.value = size;
  }

  /// Language codes offered when tagging an Addresses item. Default zh + en.
  /// Empty list = language row hidden (no tags to pick).
  List<String> get addressLanguageTags {
    final raw = _prefs.getStringList(_addressLanguageTagsKey);
    if (raw == null) {
      return List<String>.from(AddressLanguages.defaults);
    }
    final seen = <String>{};
    final out = <String>[];
    for (final e in raw) {
      final code = AddressLanguages.normalizeCode(e);
      if (code == null || seen.contains(code)) continue;
      seen.add(code);
      out.add(code);
    }
    return out;
  }

  Future<void> setAddressLanguageTags(List<String> codes) async {
    final seen = <String>{};
    final out = <String>[];
    for (final e in codes) {
      final code = AddressLanguages.normalizeCode(e);
      if (code == null || seen.contains(code)) continue;
      seen.add(code);
      out.add(code);
    }
    await _prefs.setStringList(_addressLanguageTagsKey, out);
    addressLanguageTagsListenable.value = List<String>.from(out);
  }

  Future<void> setAddressLanguageEnabled(String code, bool enabled) async {
    final normalized = AddressLanguages.normalizeCode(code);
    if (normalized == null) return;
    final next = List<String>.from(addressLanguageTags);
    if (enabled) {
      if (!next.contains(normalized)) next.add(normalized);
    } else {
      next.remove(normalized);
    }
    await setAddressLanguageTags(next);
  }
}
