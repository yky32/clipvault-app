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
      'Add one value you paste all the time — then every next paste is one tap.';

  @override
  String get emptyAddFirst => 'Add your first value';

  @override
  String get emptyStartersLabel => 'START WITH';

  @override
  String get emptyShareHint =>
      'Tip: Share text from any app → Save to ClipVal.';

  @override
  String get starterWifiTitle => 'Wi‑Fi password';

  @override
  String get starterFpsTitle => 'FPS / bank ID';

  @override
  String get starterAddressTitle => 'Shipping address';

  @override
  String get starterApiTitle => 'API key';

  @override
  String get starterPromoTitle => 'Promo code';

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
  String get iCloudSyncSection => 'iCloud';

  @override
  String get iCloudSync => 'Sync with iCloud';

  @override
  String get iCloudSyncSubtitle => 'Private CloudKit — your iCloud, never ours';

  @override
  String get iCloudSyncFooter =>
      'Goes to your iCloud account only. Values stay encrypted on device before upload. You can still use .clipval backups anytime.';

  @override
  String get iCloudSyncEnableTitle => 'Turn on iCloud sync?';

  @override
  String get iCloudSyncEnableBody =>
      'Your vault will sync through your private iCloud database. ClipVal never runs a server that sees your values.';

  @override
  String get iCloudSyncTurnOn => 'Turn On';

  @override
  String get iCloudSyncNow => 'Sync now';

  @override
  String get iCloudSyncNever => 'Not synced yet';

  @override
  String iCloudSyncLastAt(String when) {
    return 'Last sync $when';
  }

  @override
  String get iCloudSyncSuccess => 'Vault synced';

  @override
  String get iCloudSyncFailedTitle => 'Couldn’t sync';

  @override
  String get iCloudSyncFailedBody =>
      'Check that you’re signed into iCloud and try again.';

  @override
  String get iCloudSyncSchemaNotReadyTitle => 'iCloud not ready yet';

  @override
  String get iCloudSyncSchemaNotReadyBody =>
      'Cloud sync needs a one-time server setup that isn\'t finished. Your vault stays on this device — try again later, or use a password-locked .clipval backup.';

  @override
  String get iCloudSyncNetworkBody =>
      'Network problem while talking to iCloud. Check connection and try again.';

  @override
  String get iCloudSyncNoAccountBody =>
      'Sign into iCloud in Settings, then try sync again.';

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
      'Values stay on your device and encrypted at rest. Optional iCloud sync uses your private iCloud only — never a ClipVal server.';

  @override
  String get onboardingTitle3 => 'Ready when you are';

  @override
  String get onboardingBody3 =>
      'Add your first value — Wi‑Fi, FPS, or an address. Pin favorites for the Home Screen widget.';

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
      'Vault lives on this device with AES-256. No ClipVal account. Optional iCloud sync is off by default and only uses your private iCloud — we never see your values.';

  @override
  String get welcomeHowTitle => 'How it works';

  @override
  String get welcomeHowBody =>
      'Tap + to add, or Share from any app → Save to ClipVal. Tap a card to copy. Pin favorites for the widget.';

  @override
  String get welcomeIcloudTitle => 'Optional iCloud';

  @override
  String get welcomeIcloudBody =>
      'Turn on Sync with iCloud in Settings for a second device. Still no ClipVal account — ciphertext only, on your iCloud.';

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

  @override
  String get nearbySection => 'Nearby';

  @override
  String get nearbyEnabled => 'Nearby send & receive';

  @override
  String get nearbyEnabledSubtitle =>
      'Send a vault item to another ClipVal on the same Wi‑Fi — no cloud';

  @override
  String get nearbyDisplayName => 'This device name';

  @override
  String get nearbyDisplayNameHint => 'Shown to nearby ClipVal devices';

  @override
  String get nearbyFooter =>
      'Local Wi‑Fi only. Requires a 6-digit code + Accept. Values are encrypted in transit (AES-GCM). No ClipVal cloud. Turn off when idle.';

  @override
  String get nearbySendTitle => 'Send nearby';

  @override
  String get nearbySendSubtitle =>
      'Choose a ClipVal device on this Wi‑Fi. They’ll get a prompt to save the item.';

  @override
  String get nearbyScanning => 'Looking for nearby ClipVal…';

  @override
  String get nearbyNoDevices =>
      'No devices found. Open ClipVal on the other phone and enable Nearby in Settings.';

  @override
  String nearbySendAccepted(String name) {
    return 'Saved on $name';
  }

  @override
  String nearbySendRejected(String name) {
    return 'Declined by $name';
  }

  @override
  String get nearbySendTimeout => 'No response — try again';

  @override
  String get nearbySendUnreachable => 'Couldn’t reach device';

  @override
  String get nearbySendError => 'Send failed';

  @override
  String get nearbyDisabledHint => 'Turn on Nearby in Settings first';

  @override
  String get nearbyReceiveTitle => 'Incoming ClipVal item';

  @override
  String nearbyReceiveFrom(String name) {
    return 'From $name';
  }

  @override
  String get nearbyReceivePrivacyNote =>
      'On your Wi‑Fi only. Nothing is saved until you accept.';

  @override
  String get nearbyDecline => 'Decline';

  @override
  String get nearbyAcceptSave => 'Save to vault';

  @override
  String get nearbyReceiveSaved => 'Saved to vault';

  @override
  String get nearbySendAction => 'Send nearby';

  @override
  String get clipboardSuggest => 'Suggest saving clipboard';

  @override
  String get clipboardSuggestSubtitle =>
      'When you open ClipVal, ask to save new clipboard text (never automatic)';

  @override
  String get clipboardSuggestFooter =>
      'Optional. ClipVal only reads the clipboard when this is on and the vault is open. Dismiss skips the same text until it changes.';

  @override
  String get clipboardSuggestBannerTitle => 'Save to ClipVal?';

  @override
  String get clipboardSuggestSave => 'Save';

  @override
  String get clipboardSuggestNotNow => 'Not now';

  @override
  String get clipboardSuggestSaved => 'Saved from clipboard';

  @override
  String get nearbyPinLabel => 'Their 6-digit code';

  @override
  String get nearbyPinInvalid =>
      'Enter the 6-digit code shown on the other device';

  @override
  String get nearbyPinWrong => 'Wrong code — check the other device';

  @override
  String get nearbySendSubtitlePin =>
      'Pick a device, then enter the code shown under Settings → Nearby on that phone. Value is encrypted on the way.';

  @override
  String get nearbySessionPin => 'Your code';

  @override
  String get nearbySessionPinSubtitle =>
      'Other devices type this to send to you. Rotates when you refresh or re-enable Nearby.';

  @override
  String get nearbyRotatePin => 'New code';

  @override
  String get iCloudDiagnose => 'Check iCloud status';

  @override
  String get iCloudDiagnoseOk => 'iCloud looks ready';

  @override
  String get iCloudDiagnoseSchema =>
      'Production schema not ready — deploy CloudKit types from Dashboard (see docs)';

  @override
  String get iCloudDiagnoseNoAccount => 'No iCloud account on this device';

  @override
  String get iCloudDiagnoseNetwork => 'Network error talking to iCloud';

  @override
  String get iCloudDiagnoseOther => 'iCloud check failed';

  @override
  String get cloudBackupSection => 'Cloud backup';

  @override
  String get cloudBackup => 'Cloud backup';

  @override
  String get cloudBackupSubtitle =>
      'Encrypted file you control — Google Drive or Files';

  @override
  String get cloudBackupFooter =>
      'No ClipVal account. Values are encrypted on device before you save a .clipval backup to your Google Drive or Files. Automatic Drive sync is the same idea as iCloud on iPhone — coming next; file backup works today.';

  @override
  String get cloudBackupEnableTitle => 'Turn on cloud backup?';

  @override
  String get cloudBackupEnableBody =>
      'You’ll back up with a password-protected .clipval file to your Google Drive or Files. ClipVal never runs a server that sees your values. Same privacy idea as iCloud sync on iPhone, on your Google account.';

  @override
  String get cloudBackupTurnOn => 'Turn On';

  @override
  String get cloudBackupNow => 'Back up now';

  @override
  String get cloudBackupRestore => 'Restore backup';

  @override
  String get cloudBackupRestoreSubtitle =>
      'Import a .clipval file from Drive or Files';

  @override
  String get cloudBackupNever => 'Not backed up yet';

  @override
  String cloudBackupLastAt(String when) {
    return 'Last backup: $when';
  }

  @override
  String get cloudBackupHowTitle => 'How Android backup works';

  @override
  String get cloudBackupHowBody =>
      'iPhone uses private iCloud. Android uses an encrypted .clipval file you save to Google Drive or Files.\n\n1. Turn on Cloud backup\n2. Back up now → choose password → share/save to Drive\n3. New phone: Restore backup → pick the file → password\n\nNo ClipVal account. Cross-platform: same .clipval works on iOS too.';

  @override
  String get cloudBackupOnHint =>
      'Use Back up now to save an encrypted .clipval to Drive or Files.';

  @override
  String get onboardingBody2Android =>
      'Values stay on your device and encrypted at rest. Optional cloud backup uses a password-protected file on your Google Drive or Files — never a ClipVal server.';

  @override
  String get welcomeLocalBodyAndroid =>
      'Vault lives on this device with AES-256. No ClipVal account. Optional cloud backup is a .clipval file you keep in Google Drive or Files — we never see your values.';

  @override
  String get welcomeCloudTitleAndroid => 'Optional cloud backup';

  @override
  String get welcomeCloudBodyAndroid =>
      'In Settings, turn on Cloud backup and save a .clipval to Google Drive for a second device. Still no ClipVal account — ciphertext only, on your storage.';

  @override
  String get backupReminderTitle => 'Protect your vault';

  @override
  String get backupReminderBody =>
      'No recent secure backup. Export a .clipval file so a lost phone isn’t lost data.';

  @override
  String get backupReminderBodyIos =>
      'No recent secure backup and iCloud is off. Export a .clipval file so a lost phone isn’t lost data.';

  @override
  String get backupReminderExport => 'Back up now';

  @override
  String get backupReminderLater => 'Remind me later';
}
