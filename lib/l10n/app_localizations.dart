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
  /// **'Data'**
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

  /// No description provided for @exportConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportConfirmAction;

  /// No description provided for @exportAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to export vault values'**
  String get exportAuthReason;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

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
