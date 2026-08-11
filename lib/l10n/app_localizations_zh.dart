// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'ClipVal';

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
  String get emptySubtitle => '先存一個你常貼上的值 — 之後每次只要一按。';

  @override
  String get emptyAddFirst => '新增第一個值';

  @override
  String get emptyStartersLabel => '快速開始';

  @override
  String get emptyShareHint => '提示：從任何 App 分享文字 → 儲存到 ClipVal。';

  @override
  String get starterWifiTitle => 'Wi‑Fi 密碼';

  @override
  String get starterFpsTitle => 'FPS／銀行編號';

  @override
  String get starterAddressTitle => '收件地址';

  @override
  String get starterApiTitle => 'API 金鑰';

  @override
  String get starterPromoTitle => '優惠碼';

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
  String get valueExpand => '展開';

  @override
  String get valueExpandTitle => '編輯內容';

  @override
  String get valueExpandDone => '完成';

  @override
  String get valuePaste => '貼上';

  @override
  String get valueClear => '清除';

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
  String get categoryLanguageTag => '語言標籤';

  @override
  String get categoryLanguageTagFooter => '開啟後，此分類的項目可選擇語言標籤（標籤清單在「地址」中設定）。';

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
  String get duplicateItem => '複製項目';

  @override
  String get itemDuplicated => '已複製項目';

  @override
  String get recentHoldToPin => '長按置頂';

  @override
  String get widgetSection => '主畫面小工具';

  @override
  String get widgetPinnedOnly => '僅顯示我的最愛';

  @override
  String get widgetPinnedOnlySubtitle => '小工具只顯示已置頂項目';

  @override
  String get widgetHideTitlesWhenLocked => '鎖定時隱藏標題';

  @override
  String get widgetHideTitlesWhenLockedSubtitle => '開啟應用程式鎖定時只顯示字首';

  @override
  String get vaultSort => '排序';

  @override
  String get vaultSortUpdated => '最近更新';

  @override
  String get vaultSortLastUsed => '最近複製';

  @override
  String get vaultSortTitle => '標題 A–Z';

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
  String get select => '選取';

  @override
  String get selectItems => '選取項目';

  @override
  String selectedCount(int count) {
    return '已選 $count 項';
  }

  @override
  String get selectAll => '全選';

  @override
  String get deselectAll => '取消全選';

  @override
  String get deleteSelected => '刪除';

  @override
  String deleteSelectedTitle(int count) {
    return '刪除 $count 個項目？';
  }

  @override
  String get deleteSelectedBody => '這些項目將從保險庫中永久移除。';

  @override
  String deleteSelectedSuccess(int count) {
    return '已刪除 $count 個項目';
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
  String get settingsData => '備份與還原';

  @override
  String get biometricLock => '應用程式鎖定';

  @override
  String get biometricLockSubtitle => '需要 Face ID／指紋／裝置 PIN';

  @override
  String get iCloudSyncSection => 'iCloud';

  @override
  String get iCloudSync => '透過 iCloud 同步';

  @override
  String get iCloudSyncSubtitle => '私有 CloudKit — 只在你的 iCloud，不在我們';

  @override
  String get iCloudSyncFooter =>
      '只會進入你的 iCloud 帳號。內容在上傳前已於裝置加密。仍可隨時使用 .clipval 備份。';

  @override
  String get iCloudSyncEnableTitle => '開啟 iCloud 同步？';

  @override
  String get iCloudSyncEnableBody =>
      '保險庫會透過你的私有 iCloud 資料庫同步。ClipVal 沒有伺服器能看見你的內容。';

  @override
  String get iCloudSyncTurnOn => '開啟';

  @override
  String get iCloudSyncNow => '立即同步';

  @override
  String get iCloudSyncNever => '尚未同步';

  @override
  String iCloudSyncLastAt(String when) {
    return '上次同步 $when';
  }

  @override
  String get iCloudSyncSuccess => '已同步';

  @override
  String get iCloudSyncFailedTitle => '無法同步';

  @override
  String get iCloudSyncFailedBody => '請確認已登入 iCloud 後再試。';

  @override
  String get iCloudSyncSchemaNotReadyTitle => 'iCloud 尚未就緒';

  @override
  String get iCloudSyncSchemaNotReadyBody =>
      '雲端同步需要一次性伺服器設定，目前尚未完成。保險庫仍只在本機；請稍後再試，或使用密碼保護的 .clipval 備份。';

  @override
  String get iCloudSyncNetworkBody => '連線 iCloud 時出現網絡問題，請檢查網絡後再試。';

  @override
  String get iCloudSyncNoAccountBody => '請先在系統設定登入 iCloud，然後再同步。';

  @override
  String get securitySectionFooter => '鎖定保護保險庫；顯示驗證與自動鎖定控制暴露時間。';

  @override
  String get requireAuthToReveal => '顯示內容需 Face ID';

  @override
  String get requireAuthToRevealSubtitle => '在編輯器中顯示內容前再次驗證';

  @override
  String get revealValueAuthReason => '顯示此內容';

  @override
  String get autoLockTimeout => '自動鎖定';

  @override
  String get autoLockTimeoutSubtitle => '應用程式進入背景後多久重新鎖定';

  @override
  String get autoLockImmediate => '立即';

  @override
  String get autoLockAfter1Min => '1 分鐘後';

  @override
  String get autoLockAfter5Min => '5 分鐘後';

  @override
  String get autoLockAfter15Min => '15 分鐘後';

  @override
  String get sensitiveItem => '敏感';

  @override
  String get sensitiveItemSubtitle => '在保險庫與小工具隱藏標題';

  @override
  String get undo => '復原';

  @override
  String get itemDeletedUndo => '已刪除項目';

  @override
  String itemsDeletedUndo(int count) {
    return '已刪除 $count 個項目';
  }

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
  String get exportCsv => '匯出 CSV（純文字）';

  @override
  String get importCsv => '匯入備份';

  @override
  String get exportSecureBackup => '匯出加密備份';

  @override
  String get importSecureBackup => '匯入加密備份';

  @override
  String get exportComingSoon => '匯出功能將於未來版本提供。';

  @override
  String get exportConfirmTitle => '匯出所有內容？';

  @override
  String get exportConfirmBody => '保險庫內的所有值會以純文字複製到剪貼簿。任何能存取此裝置剪貼簿的人都能讀取。確定繼續？';

  @override
  String get exportCsvConfirmTitle => '匯出保險庫為 CSV？';

  @override
  String get exportCsvConfirmBody =>
      '保險庫內容會以純文字寫入 CSV 檔，方便儲存至「檔案」、iCloud 或分享。任何取得此檔案的人都能讀取內容。確定繼續？';

  @override
  String get exportSecureConfirmTitle => '匯出加密備份？';

  @override
  String get exportSecureConfirmBody =>
      '保險庫會以你設定的密碼加密，儲存為 .clipval 檔。取得檔案的人仍需密碼才能開啟。若忘記密碼，備份將無法還原。';

  @override
  String get exportSecurePasswordTitle => '設定備份密碼';

  @override
  String get exportSecurePasswordBody => '請設定至少 8 個字元的密碼。在任何裝置還原此備份時都需要此密碼。';

  @override
  String get exportSecurePassword => '密碼';

  @override
  String get exportSecurePasswordConfirm => '確認密碼';

  @override
  String get exportSecurePasswordMismatch => '兩次密碼不一致';

  @override
  String get exportSecurePasswordTooShort => '請至少使用 8 個字元';

  @override
  String get exportSecureShared => '加密備份已準備分享';

  @override
  String get importPasswordTitle => '輸入備份密碼';

  @override
  String get importPasswordBody => '此檔案已加密。請輸入匯出時設定的密碼。';

  @override
  String get importPassword => '密碼';

  @override
  String get importWrongPassword => '密碼錯誤或檔案已損壞';

  @override
  String get importCsvConfirmTitle => '匯入保險庫備份？';

  @override
  String get importCsvConfirmBody =>
      '檔案中的項目會加入此保險庫。完全相同的標題與內容會略過。檔案內為純文字。確定繼續？';

  @override
  String importCsvPreviewSummary(int newCount, int skipCount) {
    return '$newCount 筆新增 · $skipCount 筆略過';
  }

  @override
  String importCsvPreviewInvalid(int count) {
    return '$count 筆無效';
  }

  @override
  String importCsvPreviewSamples(String titles) {
    return '包含：$titles';
  }

  @override
  String importCsvPreviewNewCategories(String names) {
    return '新分類：$names';
  }

  @override
  String get importCsvPreviewFooter => '項目會加入此保險庫。完全相同的標題與內容會略過。檔案內為純文字。';

  @override
  String get importCsvNothingNew => '沒有新項目可匯入 — 全部為重複或空白列';

  @override
  String get exportConfirmAction => '匯出';

  @override
  String get importConfirmAction => '匯入';

  @override
  String get exportAuthReason => '確認以匯出保險庫內容';

  @override
  String get importAuthReason => '確認以匯入保險庫內容';

  @override
  String get exportCancelled => '已取消匯出';

  @override
  String get importCancelled => '已取消匯入';

  @override
  String get exportCsvShared => 'CSV 已準備分享';

  @override
  String importCsvSuccess(int imported, int skipped) {
    return '已匯入 $imported，略過 $skipped';
  }

  @override
  String importCsvSuccessWithFailed(int imported, int skipped, int failed) {
    return '已匯入 $imported，略過 $skipped，失敗 $failed';
  }

  @override
  String get importCsvEmpty => '檔案中找不到項目';

  @override
  String get importCsvInvalid => '無法讀取此 CSV 檔案';

  @override
  String get importCsvPickFailed => '未選擇檔案';

  @override
  String get onboardingTitle1 => '一鍵複製';

  @override
  String get onboardingBody1 => '儲存任何值，輕觸一次即可立即複製。';

  @override
  String get onboardingTitle2 => '預設私密';

  @override
  String get onboardingBody2 =>
      '內容留在你的裝置並加密。可選 iCloud 同步只經你的私有 iCloud — ClipVal 沒有伺服器。';

  @override
  String get onboardingTitle3 => '準備就緒';

  @override
  String get onboardingBody3 => '先加第一個值 — Wi‑Fi、FPS 或地址。釘選常用項目到主畫面小工具。';

  @override
  String get getStarted => '開始使用';

  @override
  String get welcomeTitle => '歡迎使用 ClipVal';

  @override
  String get welcomeTitleUpgrade => '更新內容';

  @override
  String get welcomeSubtitle => '儲存一次 → 輕觸一次 → 隨處貼上。';

  @override
  String welcomeSubtitleUpgrade(String version) {
    return '版本 $version';
  }

  @override
  String get welcomeWhyTitle => '為什麼用 ClipVal';

  @override
  String get welcomeWhyBody =>
      '密碼、代碼、地址、API 金鑰、常用訊息 — 集中放在一個私密空間。比備忘錄更快，比密碼管理器更輕。';

  @override
  String get welcomeLocalTitle => '預設只存本機';

  @override
  String get welcomeLocalBody =>
      '保險庫在本機以 AES-256 加密。無需 ClipVal 帳號。可選 iCloud 同步預設關閉，只使用你的私有 iCloud — 我們看不到你的內容。';

  @override
  String get welcomeHowTitle => '怎麼使用';

  @override
  String get welcomeHowBody =>
      '按 + 新增，或從任何 App 分享 → 儲存到 ClipVal。輕觸卡片即可複製。釘選常用項到小工具。';

  @override
  String get welcomeIcloudTitle => '可選 iCloud';

  @override
  String get welcomeIcloudBody =>
      '在設定開啟「透過 iCloud 同步」即可在第二部裝置使用。仍然無需 ClipVal 帳號 — 只有密文進你的 iCloud。';

  @override
  String get welcomePromoTitle => '你的一鍵保險庫';

  @override
  String get welcomePromoBody => 'ClipVal 只做一件事：儲存任何值，輕觸一次即可複製。其餘一概從簡。';

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
  String get unlockTitle => 'ClipVal';

  @override
  String get unlockSubtitle => '保險庫已鎖定';

  @override
  String get unlockButton => '解鎖';

  @override
  String get unlockHint => 'Face ID · Touch ID · 裝置密碼';

  @override
  String get unlockWithFaceId => 'Face ID';

  @override
  String get unlockWithTouchId => 'Touch ID';

  @override
  String get unlockWithBiometrics => '生物辨識';

  @override
  String get unlockWithPasscode => '裝置密碼';

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
  String get languageSystem => '系統';

  @override
  String get languageEng => 'ENG';

  @override
  String get languageZh => '中';

  @override
  String get settingsFooterTagline => '僅儲存在本機裝置';

  @override
  String settingsFooterVersion(String version) {
    return 'v$version · 僅儲存在本機裝置';
  }

  @override
  String settingsFooterVersionWithCommit(String version, String commit) {
    return 'v$version #$commit · 僅儲存在本機裝置';
  }

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

  @override
  String get addressLanguageLabel => '地址語言';

  @override
  String get addressLanguageNone => '不限';

  @override
  String get addressLanguageZh => '中文';

  @override
  String get addressLanguageEn => 'English';

  @override
  String get addressLanguagesTitle => '地址語言標籤';

  @override
  String get addressLanguagesSubtitle => '儲存「地址」項目時可選擇的語言標籤。';

  @override
  String get addressLanguagesNoneEnabled => '尚未啟用';

  @override
  String get addressLanguagesBuiltInHeader => '內建';

  @override
  String get addressLanguagesCustomHeader => '自訂';

  @override
  String get addressLanguagesCustomFooter => '新增短代碼（例如 ja、ko）作為其他地址語言標籤。';

  @override
  String get addressLanguagesCustomEmpty => '尚未新增自訂語言';

  @override
  String get addressLanguageAdd => '新增語言';

  @override
  String get addressLanguageAddTitle => '新增語言代碼';

  @override
  String get addressLanguageAddBody => '使用短代碼作為保險庫角標（字母開頭，1–8 個字元）。';

  @override
  String get addressLanguageAddHint => '例如 ja';

  @override
  String get addressLanguageAddAction => '新增';

  @override
  String get addressLanguageAddInvalidTitle => '代碼無效';

  @override
  String get addressLanguageAddInvalidBody =>
      '請使用以字母開頭、1–8 個字元的代碼。例如：ja、ko、yue。';

  @override
  String get addressLanguageRemoveTitle => '移除語言？';

  @override
  String addressLanguageRemoveBody(String name) {
    return '之後儲存「地址」項目時將不再提供「$name」。已標記的項目會保留原標籤。';
  }

  @override
  String get gridTitleSize => '網格標題大小';

  @override
  String get gridTitleSizeSubtitle => '保險庫網格卡片的標題字級，不會自動縮小。';

  @override
  String get gridTitleSizeLarge => '大';

  @override
  String get gridTitleSizeMedium => '中';

  @override
  String get gridTitleSizeSmall => '小';
}
