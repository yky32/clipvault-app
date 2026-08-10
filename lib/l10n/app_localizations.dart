import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ClipVal'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Store once. Tap once. Paste anywhere.'**
  String get appTagline;

  /// No description provided for @vaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty'**
  String get emptyTitle;

  /// No description provided for @emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first value — passwords, codes, addresses, templates.'**
  String get emptySubtitle;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get addFirstItem;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopy;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(int count);

  /// No description provided for @itemCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 item'**
  String get itemCountOne;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesSearch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String noMatchesSearch(String query);

  /// No description provided for @noMatchesCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in “{category}” yet.'**
  String noMatchesCategory(String category);

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @showAllItems.
  ///
  /// In en, this message translates to:
  /// **'Show all items'**
  String get showAllItems;

  /// No description provided for @addToCategory.
  ///
  /// In en, this message translates to:
  /// **'Add item here'**
  String get addToCategory;

  /// No description provided for @hintCopy.
  ///
  /// In en, this message translates to:
  /// **'Tip: tap any item to copy its value'**
  String get hintCopy;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wi-Fi password'**
  String get titleHint;

  /// No description provided for @valueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// No description provided for @valueHint.
  ///
  /// In en, this message translates to:
  /// **'The text to copy'**
  String get valueHint;

  /// No description provided for @valueExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get valueExpand;

  /// No description provided for @valueExpandTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get valueExpandTitle;

  /// No description provided for @valueExpandDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get valueExpandDone;

  /// No description provided for @valuePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get valuePaste;

  /// No description provided for @valueClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get valueClear;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get categoryHint;

  /// No description provided for @categoryNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get categoryNone;

  /// No description provided for @categorySelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get categorySelectTitle;

  /// No description provided for @categoryManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoryManageTitle;

  /// No description provided for @categoryManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Product defaults stay fixed. Add your own for custom labels.'**
  String get categoryManageSubtitle;

  /// No description provided for @categoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEdit;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryNameLabel;

  /// No description provided for @categoryLanguageTag.
  ///
  /// In en, this message translates to:
  /// **'Language labels'**
  String get categoryLanguageTag;

  /// No description provided for @categoryLanguageTagFooter.
  ///
  /// In en, this message translates to:
  /// **'When on, items in this category can pick a language tag (configure tags under Addresses).'**
  String get categoryLanguageTagFooter;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Client codes'**
  String get categoryNameHint;

  /// No description provided for @categoryDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get categoryDefaultBadge;

  /// No description provided for @categoryCustomSection.
  ///
  /// In en, this message translates to:
  /// **'Your categories'**
  String get categoryCustomSection;

  /// No description provided for @categoryDefaultsSection.
  ///
  /// In en, this message translates to:
  /// **'Product defaults'**
  String get categoryDefaultsSection;

  /// No description provided for @categoryEmptyCustom.
  ///
  /// In en, this message translates to:
  /// **'No custom categories yet'**
  String get categoryEmptyCustom;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed. Items keep their values but lose this label.'**
  String categoryDeleteBody(String name);

  /// No description provided for @slideToAdd.
  ///
  /// In en, this message translates to:
  /// **'Slide to add'**
  String get slideToAdd;

  /// No description provided for @catPasswords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get catPasswords;

  /// No description provided for @catBanking.
  ///
  /// In en, this message translates to:
  /// **'Banking'**
  String get catBanking;

  /// No description provided for @catWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get catWifi;

  /// No description provided for @catCodes.
  ///
  /// In en, this message translates to:
  /// **'Codes'**
  String get catCodes;

  /// No description provided for @catAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get catAddresses;

  /// No description provided for @catDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get catDeveloper;

  /// No description provided for @catTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get catTemplates;

  /// No description provided for @pinItem.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get pinItem;

  /// No description provided for @duplicateItem.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateItem;

  /// No description provided for @itemDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Item duplicated'**
  String get itemDuplicated;

  /// No description provided for @recentHoldToPin.
  ///
  /// In en, this message translates to:
  /// **'Hold to pin'**
  String get recentHoldToPin;

  /// No description provided for @widgetSection.
  ///
  /// In en, this message translates to:
  /// **'Home Screen widget'**
  String get widgetSection;

  /// No description provided for @widgetPinnedOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get widgetPinnedOnly;

  /// No description provided for @widgetPinnedOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show only pinned items on the widget'**
  String get widgetPinnedOnlySubtitle;

  /// No description provided for @widgetHideTitlesWhenLocked.
  ///
  /// In en, this message translates to:
  /// **'Hide titles when locked'**
  String get widgetHideTitlesWhenLocked;

  /// No description provided for @widgetHideTitlesWhenLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show monogram only while app lock is on'**
  String get widgetHideTitlesWhenLockedSubtitle;

  /// No description provided for @vaultSort.
  ///
  /// In en, this message translates to:
  /// **'Sort vault'**
  String get vaultSort;

  /// No description provided for @vaultSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get vaultSortUpdated;

  /// No description provided for @vaultSortLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently copied'**
  String get vaultSortLastUsed;

  /// No description provided for @vaultSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get vaultSortTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @slideToSave.
  ///
  /// In en, this message translates to:
  /// **'Slide to save'**
  String get slideToSave;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from your vault.'**
  String deleteConfirmBody(String title);

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items'**
  String get selectItems;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteSelected;

  /// No description provided for @deleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} items?'**
  String deleteSelectedTitle(int count);

  /// No description provided for @deleteSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'These items will be permanently removed from your vault.'**
  String get deleteSelectedBody;

  /// No description provided for @deleteSelectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} items'**
  String deleteSelectedSuccess(int count);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied {title}'**
  String copied(String title);

  /// No description provided for @pinnedSection.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedSection;

  /// No description provided for @recentSection.
  ///
  /// In en, this message translates to:
  /// **'Recently copied'**
  String get recentSection;

  /// No description provided for @allSection.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get allSection;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewGrid;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @viewGrid2.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get viewGrid2;

  /// No description provided for @viewGrid3.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get viewGrid3;

  /// No description provided for @viewGrid2Label.
  ///
  /// In en, this message translates to:
  /// **'Grid · 2'**
  String get viewGrid2Label;

  /// No description provided for @viewGrid3Label.
  ///
  /// In en, this message translates to:
  /// **'Grid · 3'**
  String get viewGrid3Label;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get settingsClipboard;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Backup & Recovery'**
  String get settingsData;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get biometricLock;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require Face ID / fingerprint / device PIN'**
  String get biometricLockSubtitle;

  /// No description provided for @iCloudSyncSection.
  ///
  /// In en, this message translates to:
  /// **'iCloud'**
  String get iCloudSyncSection;

  /// No description provided for @iCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Sync with iCloud'**
  String get iCloudSync;

  /// No description provided for @iCloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private CloudKit — your iCloud, never ours'**
  String get iCloudSyncSubtitle;

  /// No description provided for @iCloudSyncFooter.
  ///
  /// In en, this message translates to:
  /// **'Goes to your iCloud account only. Values stay encrypted on device before upload. You can still use .clipval backups anytime.'**
  String get iCloudSyncFooter;

  /// No description provided for @iCloudSyncEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on iCloud sync?'**
  String get iCloudSyncEnableTitle;

  /// No description provided for @iCloudSyncEnableBody.
  ///
  /// In en, this message translates to:
  /// **'Your vault will sync through your private iCloud database. ClipVal never runs a server that sees your values.'**
  String get iCloudSyncEnableBody;

  /// No description provided for @iCloudSyncTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get iCloudSyncTurnOn;

  /// No description provided for @iCloudSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get iCloudSyncNow;

  /// No description provided for @iCloudSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get iCloudSyncNever;

  /// No description provided for @iCloudSyncLastAt.
  ///
  /// In en, this message translates to:
  /// **'Last sync {when}'**
  String iCloudSyncLastAt(String when);

  /// No description provided for @iCloudSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vault synced'**
  String get iCloudSyncSuccess;

  /// No description provided for @iCloudSyncFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sync'**
  String get iCloudSyncFailedTitle;

  /// No description provided for @iCloudSyncFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check that you’re signed into iCloud and try again.'**
  String get iCloudSyncFailedBody;

  /// No description provided for @securitySectionFooter.
  ///
  /// In en, this message translates to:
  /// **'Lock protects the vault. Reveal and auto-lock refine how long values stay exposed.'**
  String get securitySectionFooter;

  /// No description provided for @requireAuthToReveal.
  ///
  /// In en, this message translates to:
  /// **'Face ID to reveal values'**
  String get requireAuthToReveal;

  /// No description provided for @requireAuthToRevealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask again before showing a value in the editor'**
  String get requireAuthToRevealSubtitle;

  /// No description provided for @revealValueAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Reveal this value'**
  String get revealValueAuthReason;

  /// No description provided for @autoLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get autoLockTimeout;

  /// No description provided for @autoLockTimeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-lock after the app is in the background'**
  String get autoLockTimeoutSubtitle;

  /// No description provided for @autoLockImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get autoLockImmediate;

  /// No description provided for @autoLockAfter1Min.
  ///
  /// In en, this message translates to:
  /// **'After 1 minute'**
  String get autoLockAfter1Min;

  /// No description provided for @autoLockAfter5Min.
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get autoLockAfter5Min;

  /// No description provided for @autoLockAfter15Min.
  ///
  /// In en, this message translates to:
  /// **'After 15 minutes'**
  String get autoLockAfter15Min;

  /// No description provided for @sensitiveItem.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get sensitiveItem;

  /// No description provided for @sensitiveItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide title in the vault and widget'**
  String get sensitiveItemSubtitle;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @itemDeletedUndo.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get itemDeletedUndo;

  /// No description provided for @itemsDeletedUndo.
  ///
  /// In en, this message translates to:
  /// **'{count} items deleted'**
  String itemsDeletedUndo(int count);

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color palette'**
  String get colorPalette;

  /// No description provided for @colorPaletteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Higgs-inspired 60·30·10 schemes'**
  String get colorPaletteSubtitle;

  /// No description provided for @paletteDeepBrown.
  ///
  /// In en, this message translates to:
  /// **'Deep brown + caramel'**
  String get paletteDeepBrown;

  /// No description provided for @paletteDeepBrownCaption.
  ///
  /// In en, this message translates to:
  /// **'01 · Calm & mature'**
  String get paletteDeepBrownCaption;

  /// No description provided for @paletteWarmGrey.
  ///
  /// In en, this message translates to:
  /// **'Warm grey + terracotta'**
  String get paletteWarmGrey;

  /// No description provided for @paletteWarmGreyCaption.
  ///
  /// In en, this message translates to:
  /// **'02 · Clean & modern'**
  String get paletteWarmGreyCaption;

  /// No description provided for @paletteWoodBlue.
  ///
  /// In en, this message translates to:
  /// **'Wood + lake blue'**
  String get paletteWoodBlue;

  /// No description provided for @paletteWoodBlueCaption.
  ///
  /// In en, this message translates to:
  /// **'05 · Natural + designed'**
  String get paletteWoodBlueCaption;

  /// No description provided for @paletteInkBlue.
  ///
  /// In en, this message translates to:
  /// **'Ink + electric blue'**
  String get paletteInkBlue;

  /// No description provided for @paletteInkBlueCaption.
  ///
  /// In en, this message translates to:
  /// **'06 · Bold & minimal'**
  String get paletteInkBlueCaption;

  /// No description provided for @defaultView.
  ///
  /// In en, this message translates to:
  /// **'Default view'**
  String get defaultView;

  /// No description provided for @clipboardAutoClear.
  ///
  /// In en, this message translates to:
  /// **'Auto-clear clipboard'**
  String get clipboardAutoClear;

  /// No description provided for @clipboardAutoClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear after copying (seconds)'**
  String get clipboardAutoClearSubtitle;

  /// No description provided for @clipboardNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get clipboardNever;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @exportPlain.
  ///
  /// In en, this message translates to:
  /// **'Export as plain text'**
  String get exportPlain;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV (plain text)'**
  String get exportCsv;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importCsv;

  /// No description provided for @exportSecureBackup.
  ///
  /// In en, this message translates to:
  /// **'Export secure backup'**
  String get exportSecureBackup;

  /// No description provided for @importSecureBackup.
  ///
  /// In en, this message translates to:
  /// **'Import secure backup'**
  String get importSecureBackup;

  /// No description provided for @exportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export will be available in a future update.'**
  String get exportComingSoon;

  /// No description provided for @exportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Export all values?'**
  String get exportConfirmTitle;

  /// No description provided for @exportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every vault value will be copied to the clipboard as plain text. Anyone with access to this device’s clipboard can read them. Continue?'**
  String get exportConfirmBody;

  /// No description provided for @exportCsvConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Export vault as CSV?'**
  String get exportCsvConfirmTitle;

  /// No description provided for @exportCsvConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your vault values will be written to a CSV file as plain text so you can save it to Files, iCloud, or share it. Anyone with the file can read the values. Continue?'**
  String get exportCsvConfirmBody;

  /// No description provided for @exportSecureConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Export secure backup?'**
  String get exportSecureConfirmTitle;

  /// No description provided for @exportSecureConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your vault will be encrypted with a password you choose and saved as a .clipval file. Anyone with the file still needs the password. If you forget the password, the backup cannot be recovered.'**
  String get exportSecureConfirmBody;

  /// No description provided for @exportSecurePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set backup password'**
  String get exportSecurePasswordTitle;

  /// No description provided for @exportSecurePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a password of at least 8 characters. You will need it to restore this backup on any device.'**
  String get exportSecurePasswordBody;

  /// No description provided for @exportSecurePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get exportSecurePassword;

  /// No description provided for @exportSecurePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get exportSecurePasswordConfirm;

  /// No description provided for @exportSecurePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get exportSecurePasswordMismatch;

  /// No description provided for @exportSecurePasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get exportSecurePasswordTooShort;

  /// No description provided for @exportSecureShared.
  ///
  /// In en, this message translates to:
  /// **'Secure backup ready to share'**
  String get exportSecureShared;

  /// No description provided for @importPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter backup password'**
  String get importPasswordTitle;

  /// No description provided for @importPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'This file is encrypted. Enter the password used when it was exported.'**
  String get importPasswordBody;

  /// No description provided for @importPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get importPassword;

  /// No description provided for @importWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or damaged file'**
  String get importWrongPassword;

  /// No description provided for @importCsvConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import vault backup?'**
  String get importCsvConfirmTitle;

  /// No description provided for @importCsvConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Items from the file will be added to this vault. Exact duplicates (same title and value) are skipped. Values are plain text in the file. Continue?'**
  String get importCsvConfirmBody;

  /// No description provided for @importCsvPreviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{newCount} new · {skipCount} skipped'**
  String importCsvPreviewSummary(int newCount, int skipCount);

  /// No description provided for @importCsvPreviewInvalid.
  ///
  /// In en, this message translates to:
  /// **'{count} invalid'**
  String importCsvPreviewInvalid(int count);

  /// No description provided for @importCsvPreviewSamples.
  ///
  /// In en, this message translates to:
  /// **'Includes: {titles}'**
  String importCsvPreviewSamples(String titles);

  /// No description provided for @importCsvPreviewNewCategories.
  ///
  /// In en, this message translates to:
  /// **'New categories: {names}'**
  String importCsvPreviewNewCategories(String names);

  /// No description provided for @importCsvPreviewFooter.
  ///
  /// In en, this message translates to:
  /// **'Items will be added to this vault. Exact duplicates (same title and value) are skipped. Values are plain text in the file.'**
  String get importCsvPreviewFooter;

  /// No description provided for @importCsvNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to import — all rows are duplicates or empty'**
  String get importCsvNothingNew;

  /// No description provided for @exportConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportConfirmAction;

  /// No description provided for @importConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfirmAction;

  /// No description provided for @exportAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to export vault values'**
  String get exportAuthReason;

  /// No description provided for @importAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to import vault values'**
  String get importAuthReason;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @importCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled'**
  String get importCancelled;

  /// No description provided for @exportCsvShared.
  ///
  /// In en, this message translates to:
  /// **'CSV ready to share'**
  String get exportCsvShared;

  /// No description provided for @importCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported}, skipped {skipped}'**
  String importCsvSuccess(int imported, int skipped);

  /// No description provided for @importCsvSuccessWithFailed.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported}, skipped {skipped}, failed {failed}'**
  String importCsvSuccessWithFailed(int imported, int skipped, int failed);

  /// No description provided for @importCsvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items found in that file'**
  String get importCsvEmpty;

  /// No description provided for @importCsvInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not read that CSV file'**
  String get importCsvInvalid;

  /// No description provided for @importCsvPickFailed.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get importCsvPickFailed;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'One-tap copy'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Store any value and copy it instantly with a single tap.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your device. Values are encrypted at rest.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Start storing values right away. You can turn on app lock anytime in Settings.'**
  String get onboardingBody3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ClipVal'**
  String get welcomeTitle;

  /// No description provided for @welcomeTitleUpgrade.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get welcomeTitleUpgrade;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store once → Tap once → Paste anywhere.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeSubtitleUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String welcomeSubtitleUpgrade(String version);

  /// No description provided for @welcomeWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why ClipVal'**
  String get welcomeWhyTitle;

  /// No description provided for @welcomeWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Passwords, codes, addresses, API keys, templates — one private place for anything you copy often. Faster than Notes, lighter than a password manager.'**
  String get welcomeWhyBody;

  /// No description provided for @welcomeLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local-only by design'**
  String get welcomeLocalTitle;

  /// No description provided for @welcomeLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Your vault lives only on this device. Values are encrypted at rest (AES-256). No account. No cloud. We never see your data.'**
  String get welcomeLocalBody;

  /// No description provided for @welcomeHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get welcomeHowTitle;

  /// No description provided for @welcomeHowBody.
  ///
  /// In en, this message translates to:
  /// **'Add a title and value. Tap any card to copy instantly. Optional Face ID / device lock and clipboard auto-clear live in Settings.'**
  String get welcomeHowBody;

  /// No description provided for @welcomePromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your one-tap vault'**
  String get welcomePromoTitle;

  /// No description provided for @welcomePromoBody.
  ///
  /// In en, this message translates to:
  /// **'ClipVal has one job: store any value and copy it with a single tap. Everything else stays out of the way.'**
  String get welcomePromoBody;

  /// No description provided for @welcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeCta;

  /// No description provided for @welcomeCtaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to Vault'**
  String get welcomeCtaContinue;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @enableBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Enable app lock'**
  String get enableBiometrics;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'ClipVal'**
  String get unlockTitle;

  /// No description provided for @unlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault is locked'**
  String get unlockSubtitle;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @unlockHint.
  ///
  /// In en, this message translates to:
  /// **'Face ID · Touch ID · Device passcode'**
  String get unlockHint;

  /// No description provided for @unlockWithFaceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get unlockWithFaceId;

  /// No description provided for @unlockWithTouchId.
  ///
  /// In en, this message translates to:
  /// **'Touch ID'**
  String get unlockWithTouchId;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get unlockWithBiometrics;

  /// No description provided for @unlockWithPasscode.
  ///
  /// In en, this message translates to:
  /// **'Device passcode'**
  String get unlockWithPasscode;

  /// No description provided for @unlockAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock your vault'**
  String get unlockAuthReason;

  /// No description provided for @enableLockAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to turn on app lock'**
  String get enableLockAuthReason;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t unlock. Try again.'**
  String get unlockFailed;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noCategory;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEng.
  ///
  /// In en, this message translates to:
  /// **'ENG'**
  String get languageEng;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'中'**
  String get languageZh;

  /// No description provided for @settingsFooterTagline.
  ///
  /// In en, this message translates to:
  /// **'Stored in local device only'**
  String get settingsFooterTagline;

  /// No description provided for @settingsFooterVersion.
  ///
  /// In en, this message translates to:
  /// **'v{version} · Stored in local device only'**
  String settingsFooterVersion(String version);

  /// No description provided for @settingsFooterVersionWithCommit.
  ///
  /// In en, this message translates to:
  /// **'v{version} #{commit} · Stored in local device only'**
  String settingsFooterVersionWithCommit(String version, String commit);

  /// No description provided for @lastUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsedLabel;

  /// No description provided for @neverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never used'**
  String get neverUsed;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @addressLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Address language'**
  String get addressLanguageLabel;

  /// No description provided for @addressLanguageNone.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get addressLanguageNone;

  /// No description provided for @addressLanguageZh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get addressLanguageZh;

  /// No description provided for @addressLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get addressLanguageEn;

  /// No description provided for @addressLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Address languages'**
  String get addressLanguagesTitle;

  /// No description provided for @addressLanguagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tags you can pick when saving an Addresses item.'**
  String get addressLanguagesSubtitle;

  /// No description provided for @addressLanguagesNoneEnabled.
  ///
  /// In en, this message translates to:
  /// **'None enabled'**
  String get addressLanguagesNoneEnabled;

  /// No description provided for @addressLanguagesBuiltInHeader.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get addressLanguagesBuiltInHeader;

  /// No description provided for @addressLanguagesCustomHeader.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get addressLanguagesCustomHeader;

  /// No description provided for @addressLanguagesCustomFooter.
  ///
  /// In en, this message translates to:
  /// **'Add short codes (e.g. ja, ko) for other languages you use on addresses.'**
  String get addressLanguagesCustomFooter;

  /// No description provided for @addressLanguagesCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom languages yet'**
  String get addressLanguagesCustomEmpty;

  /// No description provided for @addressLanguageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get addressLanguageAdd;

  /// No description provided for @addressLanguageAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add language code'**
  String get addressLanguageAddTitle;

  /// No description provided for @addressLanguageAddBody.
  ///
  /// In en, this message translates to:
  /// **'Use a short code for the vault badge (letters, 1–8 characters).'**
  String get addressLanguageAddBody;

  /// No description provided for @addressLanguageAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ja'**
  String get addressLanguageAddHint;

  /// No description provided for @addressLanguageAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addressLanguageAddAction;

  /// No description provided for @addressLanguageAddInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get addressLanguageAddInvalidTitle;

  /// No description provided for @addressLanguageAddInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'Use 1–8 characters starting with a letter (a–z). Example: ja, ko, yue.'**
  String get addressLanguageAddInvalidBody;

  /// No description provided for @addressLanguageRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove language?'**
  String get addressLanguageRemoveTitle;

  /// No description provided for @addressLanguageRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will no longer be offered when tagging Addresses items. Existing tags on items are kept.'**
  String addressLanguageRemoveBody(String name);

  /// No description provided for @gridTitleSize.
  ///
  /// In en, this message translates to:
  /// **'Grid title size'**
  String get gridTitleSize;

  /// No description provided for @gridTitleSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Title text on vault grid cards. Does not auto-shrink.'**
  String get gridTitleSizeSubtitle;

  /// No description provided for @gridTitleSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get gridTitleSizeLarge;

  /// No description provided for @gridTitleSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get gridTitleSizeMedium;

  /// No description provided for @gridTitleSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get gridTitleSizeSmall;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
