// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'ClipVault';

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
  String get onboardingBody3 => '可選的生物辨識鎖定，守護你的保險庫。';

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
  String get unlockTitle => '解鎖 ClipVault';

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
