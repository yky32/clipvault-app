// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'clipVauLt';

  @override
  String get appTagline => 'Store once. Tap once. Paste anywhere.';

  @override
  String get vaultTitle => 'Vault';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get searchHint => 'Search items…';

  @override
  String get emptyTitle => 'Your vault is empty';

  @override
  String get emptySubtitle =>
      'Add your first value — passwords, codes, addresses, templates.';

  @override
  String get addFirstItem => 'Add your first item';

  @override
  String get addItem => 'Add item';

  @override
  String get editItem => 'Edit item';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String itemCount(int count) {
    return '$count items';
  }

  @override
  String get itemCountOne => '1 item';

  @override
  String get noMatchesTitle => 'No matches';

  @override
  String noMatchesSearch(String query) {
    return 'Nothing matches “$query”.';
  }

  @override
  String noMatchesCategory(String category) {
    return 'No items in “$category” yet.';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get showAllItems => 'Show all items';

  @override
  String get addToCategory => 'Add item here';

  @override
  String get hintCopy => 'Tip: tap any item to copy its value';

  @override
  String get unpin => 'Unpin';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'e.g. Wi-Fi password';

  @override
  String get valueLabel => 'Value';

  @override
  String get valueHint => 'The text to copy';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'Optional';

  @override
  String get pinItem => 'Pin to top';

  @override
  String get save => 'Save';

  @override
  String get slideToSave => 'Slide to save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete item?';

  @override
  String deleteConfirmBody(String title) {
    return '\"$title\" will be removed from your vault.';
  }

  @override
  String copied(String title) {
    return 'Copied $title';
  }

  @override
  String get pinnedSection => 'Pinned';

  @override
  String get recentSection => 'Recently copied';

  @override
  String get allSection => 'All items';

  @override
  String get filterAll => 'All';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewList => 'List';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsClipboard => 'Clipboard';

  @override
  String get settingsData => 'Data';

  @override
  String get biometricLock => 'App lock';

  @override
  String get biometricLockSubtitle =>
      'Require Face ID / fingerprint / device PIN';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get defaultView => 'Default view';

  @override
  String get clipboardAutoClear => 'Auto-clear clipboard';

  @override
  String get clipboardAutoClearSubtitle => 'Clear after copying (seconds)';

  @override
  String get clipboardNever => 'Never';

  @override
  String get exportData => 'Export data';

  @override
  String get exportPlain => 'Export as plain text';

  @override
  String get exportComingSoon => 'Export will be available in a future update.';

  @override
  String get onboardingTitle1 => 'One-tap copy';

  @override
  String get onboardingBody1 =>
      'Store any value and copy it instantly with a single tap.';

  @override
  String get onboardingTitle2 => 'Private by default';

  @override
  String get onboardingBody2 =>
      'Everything stays on your device. Values are encrypted at rest.';

  @override
  String get onboardingTitle3 => 'Ready when you are';

  @override
  String get onboardingBody3 =>
      'Start storing values right away. You can turn on app lock anytime in Settings.';

  @override
  String get getStarted => 'Get started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get enableBiometrics => 'Enable app lock';

  @override
  String get notNow => 'Not now';

  @override
  String get unlockTitle => 'Unlock clipVauLt';

  @override
  String get unlockSubtitle => 'Authenticate to open your vault';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get unlockFailed => 'Authentication failed. Try again.';

  @override
  String get noCategory => 'None';

  @override
  String get requiredField => 'Required';

  @override
  String get language => 'Language';
}
