// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'clipVAuLt';

  @override
  String get appTagline => '儲存一次。輕觸一次。隨處貼上。';

  @override
  String get vaultTitle => '保險庫';

  @override
  String get settingsTitle => '設定';

  @override
  String get searchHint => '搜尋';

  @override
  String get emptyTitle => '保險庫是空的';

  @override
  String get emptySubtitle => '新增第一個值 — 密碼、代碼、地址、範本訊息等。';

  @override
  String get addFirstItem => '新增第一個項目';

  @override
  String get addItem => '新增項目';

  @override
  String get editItem => '編輯項目';

  @override
  String get tapToCopy => '輕觸即可複製';

  @override
  String itemCount(int count) {
    return '$count 個項目';
  }

  @override
  String get itemCountOne => '1 個項目';

  @override
  String get noMatchesTitle => '沒有結果';

  @override
  String noMatchesSearch(String query) {
    return '找不到「$query」。';
  }

  @override
  String noMatchesCategory(String category) {
    return '「$category」還沒有項目。';
  }

  @override
  String get clearSearch => '清除搜尋';

  @override
  String get showAllItems => '顯示全部';

  @override
  String get addToCategory => '在此分類新增';

  @override
  String get hintCopy => '提示：輕觸項目即可複製內容';

  @override
  String get unpin => '取消置頂';

  @override
  String get titleLabel => '標題';

  @override
  String get titleHint => '例如：Wi-Fi 密碼';

  @override
  String get valueLabel => '內容';

  @override
  String get valueHint => '要複製的文字';

  @override
  String get categoryLabel => '分類';

  @override
  String get categoryHint => '選填';

  @override
  String get categoryNone => '無';

  @override
  String get categorySelectTitle => '選擇分類';

  @override
  String get categoryManageTitle => '分類';

  @override
  String get categoryManageSubtitle => '產品預設分類固定。可新增自訂分類。';

  @override
  String get categoryAdd => '新增分類';

  @override
  String get categoryEdit => '編輯分類';

  @override
  String get categoryNameLabel => '名稱';

  @override
  String get categoryNameHint => '例如：客戶代碼';

  @override
  String get categoryDefaultBadge => '預設';

  @override
  String get categoryCustomSection => '我的分類';

  @override
  String get categoryDefaultsSection => '產品預設';

  @override
  String get categoryEmptyCustom => '尚未新增自訂分類';

  @override
  String get categoryDeleteTitle => '刪除分類？';

  @override
  String categoryDeleteBody(String name) {
    return '「$name」將被移除。項目內容會保留，但不再有此標籤。';
  }

  @override
  String get slideToAdd => '滑動以新增';

  @override
  String get catPasswords => '密碼';

  @override
  String get catBanking => '銀行／支付';

  @override
  String get catWifi => 'Wi-Fi';

  @override
  String get catCodes => '代碼';

  @override
  String get catAddresses => '地址';

  @override
  String get catDeveloper => '開發';

  @override
  String get catTemplates => '範本';

  @override
  String get pinItem => '置頂';

  @override
  String get save => '儲存';

  @override
  String get slideToSave => '滑動以儲存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get deleteConfirmTitle => '刪除此項目？';

  @override
  String deleteConfirmBody(String title) {
    return '「$title」將從保險庫中移除。';
  }

  @override
  String copied(String title) {
    return '已複製 $title';
  }

  @override
  String get pinnedSection => '已置頂';

  @override
  String get recentSection => '最近複製';

  @override
  String get allSection => '全部項目';

  @override
  String get filterAll => '全部';

  @override
  String get viewGrid => '網格';

  @override
  String get viewList => '列表';

  @override
  String get viewGrid2 => '2';

  @override
  String get viewGrid3 => '3';

  @override
  String get viewGrid2Label => '網格 · 2';

  @override
  String get viewGrid3Label => '網格 · 3';

  @override
  String get settingsSecurity => '安全性';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsClipboard => '剪貼簿';

  @override
  String get settingsData => '資料';

  @override
  String get biometricLock => '應用程式鎖定';

  @override
  String get biometricLockSubtitle => '需要 Face ID／指紋／裝置 PIN';

  @override
  String get themeMode => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get colorPalette => '配色方案';

  @override
  String get colorPaletteSubtitle => 'Higgs 高級感 60·30·10 配色';

  @override
  String get paletteDeepBrown => '深啡 + 焦糖';

  @override
  String get paletteDeepBrownCaption => '01 · 沉穩有質感';

  @override
  String get paletteWarmGrey => '灰白 + 橘紅';

  @override
  String get paletteWarmGreyCaption => '02 · 俐落現代';

  @override
  String get paletteWoodBlue => '木色 + 湖藍';

  @override
  String get paletteWoodBlueCaption => '05 · 自然有設計感';

  @override
  String get paletteInkBlue => '黑白 + 亮藍';

  @override
  String get paletteInkBlueCaption => '06 · 簡約有記憶點';

  @override
  String get defaultView => '預設檢視';

  @override
  String get clipboardAutoClear => '自動清除剪貼簿';

  @override
  String get clipboardAutoClearSubtitle => '複製後清除（秒）';

  @override
  String get clipboardNever => '永不';

  @override
  String get exportData => '匯出資料';

  @override
  String get exportPlain => '匯出為純文字';

  @override
  String get exportComingSoon => '匯出功能將於未來版本提供。';

  @override
  String get exportConfirmTitle => '匯出所有內容？';

  @override
  String get exportConfirmBody => '保險庫內的所有值會以純文字複製到剪貼簿。任何能存取此裝置剪貼簿的人都能讀取。確定繼續？';

  @override
  String get exportConfirmAction => '匯出';

  @override
  String get exportAuthReason => '確認以匯出保險庫內容';

  @override
  String get exportCancelled => '已取消匯出';

  @override
  String get onboardingTitle1 => '一鍵複製';

  @override
  String get onboardingBody1 => '儲存任何值，輕觸一次即可立即複製。';

  @override
  String get onboardingTitle2 => '預設私密';

  @override
  String get onboardingBody2 => '資料只留在你的裝置。內容在本地加密儲存。';

  @override
  String get onboardingTitle3 => '準備就緒';

  @override
  String get onboardingBody3 => '立刻開始儲存內容。可隨時在「設定」中開啟應用程式鎖定。';

  @override
  String get getStarted => '開始使用';

  @override
  String get welcomeTitle => '歡迎使用 clipVAuLt';

  @override
  String get welcomeTitleUpgrade => '更新內容';

  @override
  String get welcomeSubtitle => '儲存一次 → 輕觸一次 → 隨處貼上。';

  @override
  String welcomeSubtitleUpgrade(String version) {
    return '版本 $version';
  }

  @override
  String get welcomeWhyTitle => '為什麼用 clipVAuLt';

  @override
  String get welcomeWhyBody =>
      '密碼、代碼、地址、API 金鑰、常用訊息 — 集中放在一個私密空間。比備忘錄更快，比密碼管理器更輕。';

  @override
  String get welcomeLocalTitle => '預設只存本機';

  @override
  String get welcomeLocalBody =>
      '保險庫只留在這台裝置。內容以 AES-256 加密儲存。沒有帳號、沒有雲端。我們看不到你的資料。';

  @override
  String get welcomeHowTitle => '怎麼使用';

  @override
  String get welcomeHowBody =>
      '新增標題與內容，輕觸卡片即可複製。可在「設定」開啟 Face ID／裝置鎖定與剪貼簿自動清除。';

  @override
  String get welcomePromoTitle => '你的一鍵保險庫';

  @override
  String get welcomePromoBody => 'clipVAuLt 只做一件事：儲存任何值，輕觸一次即可複製。其餘一概從簡。';

  @override
  String get welcomeCta => '開始使用';

  @override
  String get welcomeCtaContinue => '進入保險庫';

  @override
  String get next => '下一步';

  @override
  String get skip => '略過';

  @override
  String get enableBiometrics => '啟用應用程式鎖定';

  @override
  String get notNow => '稍後';

  @override
  String get unlockTitle => 'clipVAuLt';

  @override
  String get unlockSubtitle => '保險庫已鎖定';

  @override
  String get unlockButton => '解鎖';

  @override
  String get unlockHint => 'Face ID · Touch ID · 裝置密碼';

  @override
  String get unlockAuthReason => '解鎖你的保險庫';

  @override
  String get enableLockAuthReason => '確認以開啟應用程式鎖定';

  @override
  String get unlockFailed => '無法解鎖，請再試一次。';

  @override
  String get noCategory => '無';

  @override
  String get requiredField => '必填';

  @override
  String get language => '語言';

  @override
  String get lastUsedLabel => '上次使用';

  @override
  String get neverUsed => '尚未使用';

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get yesterday => '昨天';
}
