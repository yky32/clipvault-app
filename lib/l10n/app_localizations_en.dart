// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ClipVal';

  @override
  String get appTagline => 'Store once. Tap once. Paste anywhere.';

  @override
  String get vaultTitle => 'Vault';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get searchHint => 'Search';

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
  String get valueExpand => 'Expand';

  @override
  String get valueExpandTitle => 'Edit value';

  @override
  String get valueExpandDone => 'Done';

  @override
  String get valuePaste => 'Paste';

  @override
  String get valueClear => 'Clear';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'Optional';

  @override
  String get categoryNone => 'None';

  @override
  String get categorySelectTitle => 'Select category';

  @override
  String get categoryManageTitle => 'Categories';

  @override
  String get categoryManageSubtitle =>
      'Product defaults stay fixed. Add your own for custom labels.';

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryLanguageTag => 'Language labels';

  @override
  String get categoryLanguageTagFooter =>
      'When on, items in this category can pick a language tag (configure tags under Addresses).';

  @override
  String get categoryNameHint => 'e.g. Client codes';

  @override
  String get categoryDefaultBadge => 'Default';

  @override
  String get categoryCustomSection => 'Your categories';

  @override
  String get categoryDefaultsSection => 'Product defaults';

  @override
  String get categoryEmptyCustom => 'No custom categories yet';

  @override
  String get categoryDeleteTitle => 'Delete category?';

  @override
  String categoryDeleteBody(String name) {
    return '\"$name\" will be removed. Items keep their values but lose this label.';
  }

  @override
  String get slideToAdd => 'Slide to add';

  @override
  String get catPasswords => 'Passwords';

  @override
  String get catBanking => 'Banking';

  @override
  String get catWifi => 'Wi-Fi';

  @override
  String get catCodes => 'Codes';

  @override
  String get catAddresses => 'Addresses';

  @override
  String get catDeveloper => 'Developer';

  @override
  String get catTemplates => 'Templates';

  @override
  String get pinItem => 'Pin to top';

  @override
  String get duplicateItem => 'Duplicate';

  @override
  String get itemDuplicated => 'Item duplicated';

  @override
  String get recentHoldToPin => 'Hold to pin';

  @override
  String get widgetSection => 'Home Screen widget';

  @override
  String get widgetPinnedOnly => 'Favorites only';

  @override
  String get widgetPinnedOnlySubtitle => 'Show only pinned items on the widget';

  @override
  String get widgetHideTitlesWhenLocked => 'Hide titles when locked';

  @override
  String get widgetHideTitlesWhenLockedSubtitle =>
      'Show monogram only while app lock is on';

  @override
  String get vaultSort => 'Sort vault';

  @override
  String get vaultSortUpdated => 'Recently updated';

  @override
  String get vaultSortLastUsed => 'Recently copied';

  @override
  String get vaultSortTitle => 'Title A–Z';

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
  String get select => 'Select';

  @override
  String get selectItems => 'Select Items';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get deleteSelected => 'Delete';

  @override
  String deleteSelectedTitle(int count) {
    return 'Delete $count items?';
  }

  @override
  String get deleteSelectedBody =>
      'These items will be permanently removed from your vault.';

  @override
  String deleteSelectedSuccess(int count) {
    return 'Deleted $count items';
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
  String get viewGrid2 => '2';

  @override
  String get viewGrid3 => '3';

  @override
  String get viewGrid2Label => 'Grid · 2';

  @override
  String get viewGrid3Label => 'Grid · 3';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsClipboard => 'Clipboard';

  @override
  String get settingsData => 'Backup & Recovery';

  @override
  String get biometricLock => 'App lock';

  @override
  String get biometricLockSubtitle =>
      'Require Face ID / fingerprint / device PIN';

  @override
  String get securitySectionFooter =>
      'Lock protects the vault. Reveal and auto-lock refine how long values stay exposed.';

  @override
  String get requireAuthToReveal => 'Face ID to reveal values';

  @override
  String get requireAuthToRevealSubtitle =>
      'Ask again before showing a value in the editor';

  @override
  String get revealValueAuthReason => 'Reveal this value';

  @override
  String get autoLockTimeout => 'Auto-lock';

  @override
  String get autoLockTimeoutSubtitle =>
      'Re-lock after the app is in the background';

  @override
  String get autoLockImmediate => 'Immediately';

  @override
  String get autoLockAfter1Min => 'After 1 minute';

  @override
  String get autoLockAfter5Min => 'After 5 minutes';

  @override
  String get autoLockAfter15Min => 'After 15 minutes';

  @override
  String get sensitiveItem => 'Sensitive';

  @override
  String get sensitiveItemSubtitle => 'Hide title in the vault and widget';

  @override
  String get undo => 'Undo';

  @override
  String get itemDeletedUndo => 'Item deleted';

  @override
  String itemsDeletedUndo(int count) {
    return '$count items deleted';
  }

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get colorPalette => 'Color palette';

  @override
  String get colorPaletteSubtitle => 'Higgs-inspired 60·30·10 schemes';

  @override
  String get paletteDeepBrown => 'Deep brown + caramel';

  @override
  String get paletteDeepBrownCaption => '01 · Calm & mature';

  @override
  String get paletteWarmGrey => 'Warm grey + terracotta';

  @override
  String get paletteWarmGreyCaption => '02 · Clean & modern';

  @override
  String get paletteWoodBlue => 'Wood + lake blue';

  @override
  String get paletteWoodBlueCaption => '05 · Natural + designed';

  @override
  String get paletteInkBlue => 'Ink + electric blue';

  @override
  String get paletteInkBlueCaption => '06 · Bold & minimal';

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
  String get exportCsv => 'Export CSV (plain text)';

  @override
  String get importCsv => 'Import backup';

  @override
  String get exportSecureBackup => 'Export secure backup';

  @override
  String get importSecureBackup => 'Import secure backup';

  @override
  String get exportComingSoon => 'Export will be available in a future update.';

  @override
  String get exportConfirmTitle => 'Export all values?';

  @override
  String get exportConfirmBody =>
      'Every vault value will be copied to the clipboard as plain text. Anyone with access to this device’s clipboard can read them. Continue?';

  @override
  String get exportCsvConfirmTitle => 'Export vault as CSV?';

  @override
  String get exportCsvConfirmBody =>
      'Your vault values will be written to a CSV file as plain text so you can save it to Files, iCloud, or share it. Anyone with the file can read the values. Continue?';

  @override
  String get exportSecureConfirmTitle => 'Export secure backup?';

  @override
  String get exportSecureConfirmBody =>
      'Your vault will be encrypted with a password you choose and saved as a .clipval file. Anyone with the file still needs the password. If you forget the password, the backup cannot be recovered.';

  @override
  String get exportSecurePasswordTitle => 'Set backup password';

  @override
  String get exportSecurePasswordBody =>
      'Choose a password of at least 8 characters. You will need it to restore this backup on any device.';

  @override
  String get exportSecurePassword => 'Password';

  @override
  String get exportSecurePasswordConfirm => 'Confirm password';

  @override
  String get exportSecurePasswordMismatch => 'Passwords do not match';

  @override
  String get exportSecurePasswordTooShort => 'Use at least 8 characters';

  @override
  String get exportSecureShared => 'Secure backup ready to share';

  @override
  String get importPasswordTitle => 'Enter backup password';

  @override
  String get importPasswordBody =>
      'This file is encrypted. Enter the password used when it was exported.';

  @override
  String get importPassword => 'Password';

  @override
  String get importWrongPassword => 'Wrong password or damaged file';

  @override
  String get importCsvConfirmTitle => 'Import vault backup?';

  @override
  String get importCsvConfirmBody =>
      'Items from the file will be added to this vault. Exact duplicates (same title and value) are skipped. Values are plain text in the file. Continue?';

  @override
  String importCsvPreviewSummary(int newCount, int skipCount) {
    return '$newCount new · $skipCount skipped';
  }

  @override
  String importCsvPreviewInvalid(int count) {
    return '$count invalid';
  }

  @override
  String importCsvPreviewSamples(String titles) {
    return 'Includes: $titles';
  }

  @override
  String importCsvPreviewNewCategories(String names) {
    return 'New categories: $names';
  }

  @override
  String get importCsvPreviewFooter =>
      'Items will be added to this vault. Exact duplicates (same title and value) are skipped. Values are plain text in the file.';

  @override
  String get importCsvNothingNew =>
      'Nothing new to import — all rows are duplicates or empty';

  @override
  String get exportConfirmAction => 'Export';

  @override
  String get importConfirmAction => 'Import';

  @override
  String get exportAuthReason => 'Confirm to export vault values';

  @override
  String get importAuthReason => 'Confirm to import vault values';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String get importCancelled => 'Import cancelled';

  @override
  String get exportCsvShared => 'CSV ready to share';

  @override
  String importCsvSuccess(int imported, int skipped) {
    return 'Imported $imported, skipped $skipped';
  }

  @override
  String importCsvSuccessWithFailed(int imported, int skipped, int failed) {
    return 'Imported $imported, skipped $skipped, failed $failed';
  }

  @override
  String get importCsvEmpty => 'No items found in that file';

  @override
  String get importCsvInvalid => 'Could not read that CSV file';

  @override
  String get importCsvPickFailed => 'No file selected';

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
  String get welcomeTitle => 'Welcome to ClipVal';

  @override
  String get welcomeTitleUpgrade => 'What\'s new';

  @override
  String get welcomeSubtitle => 'Store once → Tap once → Paste anywhere.';

  @override
  String welcomeSubtitleUpgrade(String version) {
    return 'Version $version';
  }

  @override
  String get welcomeWhyTitle => 'Why ClipVal';

  @override
  String get welcomeWhyBody =>
      'Passwords, codes, addresses, API keys, templates — one private place for anything you copy often. Faster than Notes, lighter than a password manager.';

  @override
  String get welcomeLocalTitle => 'Local-only by design';

  @override
  String get welcomeLocalBody =>
      'Your vault lives only on this device. Values are encrypted at rest (AES-256). No account. No cloud. We never see your data.';

  @override
  String get welcomeHowTitle => 'How it works';

  @override
  String get welcomeHowBody =>
      'Add a title and value. Tap any card to copy instantly. Optional Face ID / device lock and clipboard auto-clear live in Settings.';

  @override
  String get welcomePromoTitle => 'Your one-tap vault';

  @override
  String get welcomePromoBody =>
      'ClipVal has one job: store any value and copy it with a single tap. Everything else stays out of the way.';

  @override
  String get welcomeCta => 'Get started';

  @override
  String get welcomeCtaContinue => 'Continue to Vault';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get enableBiometrics => 'Enable app lock';

  @override
  String get notNow => 'Not now';

  @override
  String get unlockTitle => 'ClipVal';

  @override
  String get unlockSubtitle => 'Your vault is locked';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get unlockHint => 'Face ID · Touch ID · Device passcode';

  @override
  String get unlockWithFaceId => 'Face ID';

  @override
  String get unlockWithTouchId => 'Touch ID';

  @override
  String get unlockWithBiometrics => 'Biometrics';

  @override
  String get unlockWithPasscode => 'Device passcode';

  @override
  String get unlockAuthReason => 'Unlock your vault';

  @override
  String get enableLockAuthReason => 'Confirm to turn on app lock';

  @override
  String get unlockFailed => 'Couldn’t unlock. Try again.';

  @override
  String get noCategory => 'None';

  @override
  String get requiredField => 'Required';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEng => 'ENG';

  @override
  String get languageZh => '中';

  @override
  String get settingsFooterTagline => 'Stored in local device only';

  @override
  String settingsFooterVersion(String version) {
    return 'v$version · Stored in local device only';
  }

  @override
  String settingsFooterVersionWithCommit(String version, String commit) {
    return 'v$version #$commit · Stored in local device only';
  }

  @override
  String get lastUsedLabel => 'Last used';

  @override
  String get neverUsed => 'Never used';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get addressLanguageLabel => 'Address language';

  @override
  String get addressLanguageNone => 'Any';

  @override
  String get addressLanguageZh => 'Chinese';

  @override
  String get addressLanguageEn => 'English';

  @override
  String get addressLanguagesTitle => 'Address languages';

  @override
  String get addressLanguagesSubtitle =>
      'Tags you can pick when saving an Addresses item.';

  @override
  String get addressLanguagesNoneEnabled => 'None enabled';

  @override
  String get addressLanguagesBuiltInHeader => 'Built-in';

  @override
  String get addressLanguagesCustomHeader => 'Custom';

  @override
  String get addressLanguagesCustomFooter =>
      'Add short codes (e.g. ja, ko) for other languages you use on addresses.';

  @override
  String get addressLanguagesCustomEmpty => 'No custom languages yet';

  @override
  String get addressLanguageAdd => 'Add language';

  @override
  String get addressLanguageAddTitle => 'Add language code';

  @override
  String get addressLanguageAddBody =>
      'Use a short code for the vault badge (letters, 1–8 characters).';

  @override
  String get addressLanguageAddHint => 'e.g. ja';

  @override
  String get addressLanguageAddAction => 'Add';

  @override
  String get addressLanguageAddInvalidTitle => 'Invalid code';

  @override
  String get addressLanguageAddInvalidBody =>
      'Use 1–8 characters starting with a letter (a–z). Example: ja, ko, yue.';

  @override
  String get addressLanguageRemoveTitle => 'Remove language?';

  @override
  String addressLanguageRemoveBody(String name) {
    return '\"$name\" will no longer be offered when tagging Addresses items. Existing tags on items are kept.';
  }

  @override
  String get gridTitleSize => 'Grid title size';

  @override
  String get gridTitleSizeSubtitle =>
      'Title text on vault grid cards. Does not auto-shrink.';

  @override
  String get gridTitleSizeLarge => 'Large';

  @override
  String get gridTitleSizeMedium => 'Medium';

  @override
  String get gridTitleSizeSmall => 'Small';
}
