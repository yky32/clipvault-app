import 'package:shared_preferences/shared_preferences.dart';

enum VaultViewMode { list, grid }

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _onboardingKey = 'onboarding_done';
  static const _biometricKey = 'biometric_lock';
  static const _viewModeKey = 'default_view';
  static const _clipboardClearKey = 'clipboard_clear_seconds';
  static const _localeKey = 'locale_code';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  bool get biometricLockEnabled => _prefs.getBool(_biometricKey) ?? false;

  Future<void> setBiometricLockEnabled(bool value) =>
      _prefs.setBool(_biometricKey, value);

  VaultViewMode get defaultViewMode {
    final raw = _prefs.getString(_viewModeKey);
    return raw == 'grid' ? VaultViewMode.grid : VaultViewMode.list;
  }

  Future<void> setDefaultViewMode(VaultViewMode mode) => _prefs.setString(
        _viewModeKey,
        mode == VaultViewMode.grid ? 'grid' : 'list',
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
