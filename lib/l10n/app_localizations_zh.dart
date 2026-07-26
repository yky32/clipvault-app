// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'clipVauLt';

  @override
  String get appTagline => '儲存一次。輕觸一次。隨處貼上。';

  @override
  String get vaultTitle => '保險庫';

  @override
  String get settingsTitle => '設定';

  @override
  String get searchHint => '搜尋項目…';

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
  String get next => '下一步';

  @override
  String get skip => '略過';

  @override
  String get enableBiometrics => '啟用應用程式鎖定';

  @override
  String get notNow => '稍後';

  @override
  String get unlockTitle => '解鎖 clipVauLt';

  @override
  String get unlockSubtitle => '驗證身分以開啟保險庫';

  @override
  String get unlockButton => '解鎖';

  @override
  String get unlockFailed => '驗證失敗，請再試一次。';

  @override
  String get noCategory => '無';

  @override
  String get requiredField => '必填';

  @override
  String get language => '語言';
}
