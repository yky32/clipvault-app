import 'package:shared_preferences/shared_preferences.dart';

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

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Drop legacy key that may have been set during forced onboarding prompt.
    if (_prefs.containsKey('biometric_lock')) {
      await _prefs.remove('biometric_lock');
    }
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

  Future<void> setLocaleCode(String? code) async {
    if (code == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, code);
    }
  }
}
