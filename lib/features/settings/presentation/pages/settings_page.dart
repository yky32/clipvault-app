import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/build_info.dart';
import '../../../../core/services/icloud_sync_service.dart';
import '../../../../core/services/nearby/nearby_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/vault_backup.dart';
import '../../../../core/services/vault_migration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand_palette.dart';
import '../../../../core/theme/palette_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/bottom_sheets/category_manage_bottom_sheet.dart';
import '../../../vault/bloc/vault_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _biometric;
  late bool _requireAuthToReveal;
  late int _autoLockTimeout;
  late VaultViewMode _viewMode;
  late GridTitleSize _gridTitleSize;
  late AppLocalePreference _localePref;
  late int _clipboardSeconds;
  late bool _clipboardSuggest;
  late bool _widgetPinnedOnly;
  late bool _widgetHideTitlesWhenLocked;
  late VaultSortMode _vaultSort;
  late bool _iCloudSync;
  DateTime? _iCloudLastSync;
  bool _iCloudBusy = false;
  late bool _androidCloudBackup;
  late bool _nearbyEnabled;
  late String _nearbyName;
  bool _nearbyBusy = false;
  String? _nearbyPin;
  StreamSubscription? _nearbyPinSub;
  String _versionLabel = '1.0.0';

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _biometric = s.biometricLockEnabled;
    _requireAuthToReveal = s.requireAuthToRevealStored;
    _autoLockTimeout = s.autoLockTimeoutSeconds;
    _viewMode = s.defaultViewMode;
    _gridTitleSize = s.gridTitleSize;
    _localePref = s.localePreference;
    _clipboardSeconds = s.clipboardClearSeconds;
    _clipboardSuggest = s.clipboardSuggestEnabled;
    _widgetPinnedOnly = s.widgetPinnedOnly;
    _widgetHideTitlesWhenLocked = s.widgetHideTitlesWhenLocked;
    _vaultSort = s.vaultSortMode;
    _iCloudSync = s.iCloudSyncEnabled;
    _iCloudLastSync = s.iCloudLastSyncAt;
    _androidCloudBackup = s.androidCloudBackupEnabled;
    _nearbyEnabled = s.nearbyEnabled;
    _nearbyName = s.nearbyDisplayName;
    _nearbyPin = NearbyService.instance.sessionPin;
    _nearbyPinSub = NearbyService.instance.sessionPin$.listen((p) {
      if (mounted) setState(() => _nearbyPin = p);
    });
    _loadVersion();
  }

  @override
  void dispose() {
    _nearbyPinSub?.cancel();
    super.dispose();
  }


  String _iCloudFailTitle(AppLocalizations l10n, ICloudSyncResult result) {
    if (result.code == ICloudSyncResult.schemaProduction) {
      return l10n.iCloudSyncSchemaNotReadyTitle;
    }
    return l10n.iCloudSyncFailedTitle;
  }

  String _iCloudFailBody(AppLocalizations l10n, ICloudSyncResult result) {
    switch (result.code) {
      case ICloudSyncResult.schemaProduction:
        return l10n.iCloudSyncSchemaNotReadyBody;
      case ICloudSyncResult.noAccount:
        return l10n.iCloudSyncNoAccountBody;
      case ICloudSyncResult.network:
        return l10n.iCloudSyncNetworkBody;
      default:
        // Never dump raw CKRecordID / production schema jargon to users.
        final raw = result.message?.trim() ?? '';
        if (raw.isEmpty ||
            raw.contains('CKRecord') ||
            raw.toLowerCase().contains('production schema') ||
            raw.toLowerCase().contains('cannot create new type')) {
          return l10n.iCloudSyncFailedBody;
        }
        return raw;
    }
  }

  Future<void> _showICloudFailDialog(
    AppLocalizations l10n,
    ICloudSyncResult result,
  ) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(_iCloudFailTitle(l10n, result)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_iCloudFailBody(l10n, result)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }



  String _cloudBackupLastLabel(AppLocalizations l10n) {
    final at = SettingsService.instance.lastSecureBackupAt;
    if (at == null) return l10n.cloudBackupNever;
    final local = at.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return l10n.cloudBackupLastAt('$y-$m-$d $hh:$mm');
  }

  Future<void> _toggleAndroidCloudBackup(bool value) async {
    final l10n = AppLocalizations.of(context);
    if (!value) {
      await SettingsService.instance.setAndroidCloudBackupEnabled(false);
      if (!mounted) return;
      setState(() => _androidCloudBackup = false);
      return;
    }
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.cloudBackupEnableTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.cloudBackupEnableBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cloudBackupTurnOn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await SettingsService.instance.setAndroidCloudBackupEnabled(true);
    if (!mounted) return;
    setState(() => _androidCloudBackup = true);
    CopiedHud.show(context, message: l10n.cloudBackupOnHint);
  }

  Future<void> _showAndroidCloudHow() async {
    final l10n = AppLocalizations.of(context);
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.cloudBackupHowTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.cloudBackupHowBody, textAlign: TextAlign.left),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }


  Future<void> _showKeyboardSetup() async {
    final l10n = AppLocalizations.of(context);
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.keyboardHowTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.keyboardHowBody, textAlign: TextAlign.left),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNearby(bool value) async {
    setState(() => _nearbyBusy = true);
    try {
      await NearbyService.instance.setEnabled(value);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() => _nearbyEnabled = value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _nearbyEnabled = SettingsService.instance.nearbyEnabled);
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context).nearbyEnabled),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('$e'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _nearbyBusy = false);
    }
  }

  Future<void> _editNearbyName() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _nearbyName);
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.nearbyDisplayName),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: l10n.nearbyDisplayNameHint,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final name = result.isEmpty ? 'ClipVal' : result;
    await NearbyService.instance.updateDisplayName(name);
    if (!mounted) return;
    setState(() => _nearbyName = name);
  }


  Future<void> _diagnoseICloud() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _iCloudBusy = true);
    try {
      final r = await AppBootstrap.iCloudSyncService.diagnose();
      if (!mounted) return;
      final body = switch (r.code) {
        ICloudSyncResult.schemaProduction => l10n.iCloudDiagnoseSchema,
        ICloudSyncResult.noAccount => l10n.iCloudDiagnoseNoAccount,
        ICloudSyncResult.network => l10n.iCloudDiagnoseNetwork,
        _ => r.ok ? l10n.iCloudDiagnoseOk : (r.message ?? l10n.iCloudDiagnoseOther),
      };
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.iCloudDiagnose),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(body),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _iCloudBusy = false);
    }
  }

  Future<void> _toggleICloudSync(bool value) async {
    final l10n = AppLocalizations.of(context);
    if (!value) {
      await AppBootstrap.iCloudSyncService.disable();
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _iCloudSync = false;
      });
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.iCloudSyncEnableTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.iCloudSyncEnableBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.iCloudSyncTurnOn),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _iCloudBusy = true);
    final result = await AppBootstrap.iCloudSyncService.enableAndSync();
    if (!mounted) return;
    setState(() {
      _iCloudBusy = false;
      _iCloudSync = SettingsService.instance.iCloudSyncEnabled;
      _iCloudLastSync = SettingsService.instance.iCloudLastSyncAt;
    });
    HapticFeedback.selectionClick();
    if (result.ok) {
      CopiedHud.show(context, message: l10n.iCloudSyncSuccess);
      try {
        context.read<VaultBloc>().add(const VaultRefreshed());
      } catch (_) {}
    } else {
      await _showICloudFailDialog(l10n, result);
    }
  }

  Future<void> _syncICloudNow() async {
    final l10n = AppLocalizations.of(context);
    if (!_iCloudSync || _iCloudBusy) return;
    setState(() => _iCloudBusy = true);
    final result = await AppBootstrap.iCloudSyncService.syncNow();
    if (!mounted) return;
    setState(() {
      _iCloudBusy = false;
      _iCloudLastSync = SettingsService.instance.iCloudLastSyncAt;
    });
    HapticFeedback.selectionClick();
    if (result.ok) {
      CopiedHud.show(context, message: l10n.iCloudSyncSuccess);
      try {
        context.read<VaultBloc>().add(const VaultRefreshed());
      } catch (_) {}
    } else {
      // Schema / account issues need a real dialog (toast is easy to miss).
      if (result.code == ICloudSyncResult.schemaProduction ||
          result.code == ICloudSyncResult.noAccount) {
        await _showICloudFailDialog(l10n, result);
      } else {
        CopiedHud.show(
          context,
          message: _iCloudFailBody(l10n, result),
        );
      }
    }
  }

  String _iCloudLastSyncLabel(AppLocalizations l10n) {
    final at = _iCloudLastSync;
    if (at == null) return l10n.iCloudSyncNever;
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return l10n.iCloudSyncLastAt(
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hh:$mm',
    );
  }

  Future<void> _syncWidgetPrefs() async {
    try {
      await AppBootstrap.widgetSnapshotService.sync();
    } catch (_) {}
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _versionLabel = info.version);
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context);
    if (value) {
      final can = await AppBootstrap.authService.canCheckBiometrics();
      if (!mounted) return;
      if (!can) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Unavailable'),
            content: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Biometrics / device lock is not available.'),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      final ok = await AppBootstrap.authService.authenticate(
        // Short system prompt copy — keep it clean (OS owns the sheet UI)
        reason: l10n.enableLockAuthReason,
      );
      if (!ok || !mounted) return;
    }
    await SettingsService.instance.setBiometricLockEnabled(value);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _biometric = value);
    await _syncWidgetPrefs();
  }

  String _autoLockLabel(AppLocalizations l10n) {
    return switch (_autoLockTimeout) {
      60 => l10n.autoLockAfter1Min,
      300 => l10n.autoLockAfter5Min,
      900 => l10n.autoLockAfter15Min,
      _ => l10n.autoLockImmediate,
    };
  }

  Future<void> _pickAutoLockTimeout() async {
    final l10n = AppLocalizations.of(context);
    final value = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.autoLockTimeout),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(l10n.autoLockImmediate),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 60),
            child: Text(l10n.autoLockAfter1Min),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 300),
            child: Text(l10n.autoLockAfter5Min),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 900),
            child: Text(l10n.autoLockAfter15Min),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (value == null || !mounted) return;
    await SettingsService.instance.setAutoLockTimeoutSeconds(value);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _autoLockTimeout = value);
  }

  String _vaultSortLabel(VaultSortMode mode, AppLocalizations l10n) {
    return switch (mode) {
      VaultSortMode.updated => l10n.vaultSortUpdated,
      VaultSortMode.lastUsed => l10n.vaultSortLastUsed,
      VaultSortMode.title => l10n.vaultSortTitle,
    };
  }

  Future<void> _pickVaultSort() async {
    final l10n = AppLocalizations.of(context);
    final mode = await showCupertinoModalPopup<VaultSortMode>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.vaultSort),
        actions: [
          for (final m in VaultSortMode.values)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text(_vaultSortLabel(m, l10n)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (mode == null || !mounted) return;
    await SettingsService.instance.setVaultSortMode(mode);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _vaultSort = mode);
    try {
      context.read<VaultBloc>().add(const VaultRefreshed());
    } catch (_) {}
  }

  Future<void> _pickTheme(ThemeController controller) async {
    final l10n = AppLocalizations.of(context);
    final mode = await showCupertinoModalPopup<ThemeMode>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.themeMode),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ThemeMode.system),
            child: Text(l10n.themeSystem),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ThemeMode.light),
            child: Text(l10n.themeLight),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ThemeMode.dark),
            child: Text(l10n.themeDark),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (mode != null) {
      await controller.setThemeMode(mode);
      setState(() {});
    }
  }

  Future<void> _pickClipboardTimeout() async {
    final l10n = AppLocalizations.of(context);
    final value = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.clipboardAutoClear),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(l10n.clipboardNever),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 15),
            child: const Text('15 seconds'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 30),
            child: const Text('30 seconds'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 60),
            child: const Text('60 seconds'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (value != null) {
      await SettingsService.instance.setClipboardClearSeconds(value);
      setState(() => _clipboardSeconds = value);
    }
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };
  }

  String _clipboardLabel(AppLocalizations l10n) {
    if (_clipboardSeconds == 0) return l10n.clipboardNever;
    return '${_clipboardSeconds}s';
  }

  String _exportTimestamp() {
    return DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
  }

  Future<void> _shareTempFile({
    required BuildContext context,
    required File file,
    required String mimeType,
    required String displayName,
    required String subject,
    required String successMessage,
  }) async {
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType, name: displayName)],
      subject: subject,
      sharePositionOrigin: origin,
    );
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    CopiedHud.show(context, message: successMessage);
  }

  /// Password-protected `.clipval` backup (preferred migration path).
  Future<void> _exportSecureBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.exportSecureConfirmTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.exportSecureConfirmBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.exportConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (!await _confirmSensitiveAccess(
      context,
      reason: l10n.exportAuthReason,
      cancelledMessage: l10n.exportCancelled,
    )) {
      return;
    }
    if (!context.mounted) return;

    final password = await _promptBackupPassword(
      context,
      title: l10n.exportSecurePasswordTitle,
      body: l10n.exportSecurePasswordBody,
      requireConfirm: true,
    );
    if (password == null || !context.mounted) return;

    try {
      final bytes = await AppBootstrap.vaultMigrationService
          .exportEncryptedBackup(password);
      final dir = await getTemporaryDirectory();
      final stamp = _exportTimestamp();
      final file = File('${dir.path}/clipval-backup-$stamp.clipval');
      await file.writeAsBytes(bytes, flush: true);

      if (!context.mounted) return;
      await _shareTempFile(
        context: context,
        file: file,
        mimeType: 'application/x-clipval-backup',
        displayName: 'clipval-backup.clipval',
        subject: 'ClipVal secure backup',
        successMessage: l10n.exportSecureShared,
      );
      await SettingsService.instance.setLastSecureBackupAt(DateTime.now());
      if (mounted) setState(() {});
    } catch (_) {
      if (!context.mounted) return;
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.exportCancelled);
    }
  }

  /// Pick encrypted `.clipval` or plain CSV, preview, then merge.
  Future<void> _importBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    // FileType.any: iOS greys out unknown custom extensions when using
    // FileType.custom unless a system UTI match is perfect. We validate
    // encrypted vs CSV ourselves after the pick.
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (!context.mounted) return;
    if (pick == null || pick.files.isEmpty) {
      CopiedHud.show(context, message: l10n.importCsvPickFailed);
      return;
    }

    final file = pick.files.single;
    List<int>? bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.importCsvInvalid);
      return;
    }

    String? csvContent;
    if (VaultBackup.looksLikeBackup(bytes)) {
      final password = await _promptBackupPassword(
        context,
        title: l10n.importPasswordTitle,
        body: l10n.importPasswordBody,
        requireConfirm: false,
      );
      if (password == null || !context.mounted) return;

      try {
        csvContent = AppBootstrap.vaultMigrationService.decryptBackupToCsv(
          bytes: bytes,
          password: password,
        );
      } on VaultBackupWrongPasswordException {
        if (!context.mounted) return;
        HapticFeedback.heavyImpact();
        CopiedHud.show(context, message: l10n.importWrongPassword);
        return;
      } on VaultBackupFormatException {
        if (!context.mounted) return;
        HapticFeedback.heavyImpact();
        CopiedHud.show(context, message: l10n.importCsvInvalid);
        return;
      } catch (_) {
        if (!context.mounted) return;
        HapticFeedback.heavyImpact();
        CopiedHud.show(context, message: l10n.importWrongPassword);
        return;
      }
    } else {
      csvContent = utf8.decode(bytes, allowMalformed: true);
    }

    if (!context.mounted) return;
    if (csvContent.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.importCsvInvalid);
      return;
    }

    await _previewAndImportCsv(context, csvContent);
  }

  Future<void> _previewAndImportCsv(BuildContext context, String content) async {
    final l10n = AppLocalizations.of(context);

    late final CsvImportPreview preview;
    try {
      preview = AppBootstrap.vaultMigrationService.previewCsv(content);
    } on FormatException {
      if (!context.mounted) return;
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.importCsvInvalid);
      return;
    } catch (_) {
      if (!context.mounted) return;
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.importCsvInvalid);
      return;
    }

    if (!context.mounted) return;

    if (preview.totalRows == 0) {
      CopiedHud.show(context, message: l10n.importCsvEmpty);
      return;
    }
    if (!preview.hasWork) {
      HapticFeedback.lightImpact();
      CopiedHud.show(context, message: l10n.importCsvNothingNew);
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.importCsvConfirmTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_importPreviewBody(l10n, preview)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.importConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (!await _confirmSensitiveAccess(
      context,
      reason: l10n.importAuthReason,
      cancelledMessage: l10n.importCancelled,
    )) {
      return;
    }

    try {
      final result =
          await AppBootstrap.vaultMigrationService.importCsv(content);
      if (!context.mounted) return;

      try {
        context.read<VaultBloc>().add(const VaultRefreshed());
      } catch (_) {}

      if (result.total == 0) {
        CopiedHud.show(context, message: l10n.importCsvEmpty);
        return;
      }

      HapticFeedback.lightImpact();
      final message = result.failed > 0
          ? l10n.importCsvSuccessWithFailed(
              result.imported,
              result.skipped,
              result.failed,
            )
          : l10n.importCsvSuccess(result.imported, result.skipped);
      CopiedHud.show(context, message: message);
    } on FormatException {
      if (!context.mounted) return;
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.importCsvInvalid);
    } catch (_) {
      if (!context.mounted) return;
      HapticFeedback.heavyImpact();
      CopiedHud.show(context, message: l10n.importCsvInvalid);
    }
  }

  /// Build multi-line preview text for the import confirm dialog.
  String _importPreviewBody(AppLocalizations l10n, CsvImportPreview preview) {
    final lines = <String>[
      l10n.importCsvPreviewSummary(preview.willImport, preview.willSkip),
    ];
    if (preview.invalid > 0) {
      lines.add(l10n.importCsvPreviewInvalid(preview.invalid));
    }
    if (preview.sampleNewTitles.isNotEmpty) {
      lines.add(
        l10n.importCsvPreviewSamples(preview.sampleNewTitles.join(', ')),
      );
    }
    if (preview.newCategoryNames.isNotEmpty) {
      lines.add(
        l10n.importCsvPreviewNewCategories(
          preview.newCategoryNames.join(', '),
        ),
      );
    }
    lines.add('');
    lines.add(l10n.importCsvPreviewFooter);
    return lines.join('\n');
  }

  /// Password prompt. [requireConfirm] asks for password twice (export).
  Future<String?> _promptBackupPassword(
    BuildContext context, {
    required String title,
    required String body,
    required bool requireConfirm,
  }) async {
    final l10n = AppLocalizations.of(context);
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;

    final result = await showCupertinoDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return CupertinoAlertDialog(
              title: Text(title),
              content: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(body, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      placeholder: requireConfirm
                          ? l10n.exportSecurePassword
                          : l10n.importPassword,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    if (requireConfirm) ...[
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: confirmCtrl,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        placeholder: l10n.exportSecurePasswordConfirm,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final pw = passwordCtrl.text;
                    if (requireConfirm) {
                      if (pw.length < VaultBackup.minPasswordLength) {
                        setLocal(
                          () => errorText = l10n.exportSecurePasswordTooShort,
                        );
                        return;
                      }
                      if (pw != confirmCtrl.text) {
                        setLocal(
                          () => errorText = l10n.exportSecurePasswordMismatch,
                        );
                        return;
                      }
                    } else if (pw.isEmpty) {
                      setLocal(
                        () => errorText = l10n.exportSecurePasswordTooShort,
                      );
                      return;
                    }
                    Navigator.pop(ctx, pw);
                  },
                  child: Text(
                    requireConfirm
                        ? l10n.exportConfirmAction
                        : l10n.importConfirmAction,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordCtrl.dispose();
    confirmCtrl.dispose();
    return result;
  }

  /// Re-auth when app lock is on. Returns false if cancelled / failed.
  Future<bool> _confirmSensitiveAccess(
    BuildContext context, {
    required String reason,
    required String cancelledMessage,
  }) async {
    if (!SettingsService.instance.biometricLockEnabled) return true;
    final ok = await AppBootstrap.authService.authenticate(reason: reason);
    if (!ok || !context.mounted) {
      if (context.mounted) {
        HapticFeedback.heavyImpact();
        CopiedHud.show(context, message: cancelledMessage);
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeController = ThemeScope.of(context);
    final paletteController = PaletteScope.of(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Back + title on one row (same pattern as Vault header)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.pop();
                      },
                      child: Icon(
                        CupertinoIcons.back,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.settingsTitle,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.37,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  IosGroup(
                  header: l10n.settingsSecurity,
                  footer: l10n.securitySectionFooter,
                  children: [
                    IosGroupTile(
                      title: l10n.biometricLock,
                      subtitle: l10n.biometricLockSubtitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.lock_shield_fill,
                        color: AppColors.iconSecurity,
                      ),
                      trailing: CupertinoSwitch(
                        value: _biometric,
                        activeTrackColor: AppColors.primary,
                        onChanged: _toggleBiometric,
                      ),
                    ),
                    if (_biometric) ...[
                      IosGroupTile(
                        title: l10n.requireAuthToReveal,
                        subtitle: l10n.requireAuthToRevealSubtitle,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.eye_slash_fill,
                          color: AppColors.iconSecurity,
                        ),
                        trailing: CupertinoSwitch(
                          value: _requireAuthToReveal,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) async {
                            HapticFeedback.selectionClick();
                            await SettingsService.instance
                                .setRequireAuthToReveal(v);
                            if (!mounted) return;
                            setState(() => _requireAuthToReveal = v);
                          },
                        ),
                      ),
                      IosGroupTile(
                        title: l10n.autoLockTimeout,
                        subtitle: l10n.autoLockTimeoutSubtitle,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.timer,
                          color: AppColors.iconSecurity,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _autoLockLabel(l10n),
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 17,
                                color: AppColors.secondaryLabel(context),
                              ),
                            ),
                            const IosChevron(),
                          ],
                        ),
                        onTap: _pickAutoLockTimeout,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsAppearance,
                  footer: l10n.gridTitleSizeSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.vaultSort,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.arrow_up_arrow_down,
                        color: AppColors.iconView,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _vaultSortLabel(_vaultSort, l10n),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 17,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                          const IosChevron(),
                        ],
                      ),
                      onTap: _pickVaultSort,
                    ),
                    IosGroupTile(
                      title: l10n.themeMode,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.moon_stars_fill,
                        color: AppColors.iconTheme,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _themeLabel(themeController.themeMode, l10n),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 17,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                          const IosChevron(),
                        ],
                      ),
                      onTap: () => _pickTheme(themeController),
                    ),
                    IosGroupTile(
                      title: l10n.language,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.globe,
                        color: AppColors.iconTheme,
                      ),
                      below: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<
                            AppLocalePreference>(
                          groupValue: _localePref,
                          children: {
                            AppLocalePreference.system:
                                _SegmentLabel(l10n.languageSystem),
                            AppLocalePreference.en:
                                _SegmentLabel(l10n.languageEng),
                            AppLocalePreference.zh:
                                _SegmentLabel(l10n.languageZh),
                          },
                          onValueChanged: (pref) async {
                            if (pref == null) return;
                            HapticFeedback.selectionClick();
                            await SettingsService.instance
                                .setLocalePreference(pref);
                            setState(() => _localePref = pref);
                          },
                        ),
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.defaultView,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.rectangle_grid_2x2_fill,
                        color: AppColors.iconView,
                      ),
                      // Full-width under title so 3 segments stay aligned
                      below: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<VaultViewMode>(
                          groupValue: _viewMode,
                          children: {
                            VaultViewMode.list: _SegmentLabel(l10n.viewList),
                            VaultViewMode.grid2:
                                _SegmentLabel(l10n.viewGrid2Label),
                            VaultViewMode.grid3:
                                _SegmentLabel(l10n.viewGrid3Label),
                          },
                          onValueChanged: (mode) async {
                            if (mode == null) return;
                            HapticFeedback.selectionClick();
                            await SettingsService.instance
                                .setDefaultViewMode(mode);
                            setState(() => _viewMode = mode);
                          },
                        ),
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.gridTitleSize,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.textformat_size,
                        color: AppColors.iconTheme,
                      ),
                      below: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<GridTitleSize>(
                          groupValue: _gridTitleSize,
                          children: {
                            GridTitleSize.large:
                                _SegmentLabel(l10n.gridTitleSizeLarge),
                            GridTitleSize.medium:
                                _SegmentLabel(l10n.gridTitleSizeMedium),
                            GridTitleSize.small:
                                _SegmentLabel(l10n.gridTitleSizeSmall),
                          },
                          onValueChanged: (size) async {
                            if (size == null) return;
                            HapticFeedback.selectionClick();
                            await SettingsService.instance
                                .setGridTitleSize(size);
                            setState(() => _gridTitleSize = size);
                          },
                        ),
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.colorPalette,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.paintbrush_fill,
                        color: AppColors.primary,
                      ),
                      below: Align(
                        alignment: Alignment.centerLeft,
                        child: _PaletteSegmentControl(
                          selected: paletteController.id,
                          onChanged: (id) async {
                            HapticFeedback.selectionClick();
                            await paletteController.setPalette(id);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsClipboard,
                  footer: l10n.clipboardSuggestFooter,
                  children: [
                    IosGroupTile(
                      title: l10n.clipboardSuggest,
                      subtitle: l10n.clipboardSuggestSubtitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.lightbulb_fill,
                        color: AppColors.iconClipboard,
                      ),
                      trailing: CupertinoSwitch(
                        value: _clipboardSuggest,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) async {
                          HapticFeedback.selectionClick();
                          await SettingsService.instance
                              .setClipboardSuggestEnabled(v);
                          if (!mounted) return;
                          setState(() => _clipboardSuggest = v);
                        },
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.clipboardAutoClear,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.doc_on_clipboard_fill,
                        color: AppColors.iconClipboard,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _clipboardLabel(l10n),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 17,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                          const IosChevron(),
                        ],
                      ),
                      onTap: _pickClipboardTimeout,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.widgetSection,
                  footer: l10n.widgetHideTitlesWhenLockedSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.widgetPinnedOnly,
                      subtitle: l10n.widgetPinnedOnlySubtitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.pin_fill,
                        color: AppColors.iconView,
                      ),
                      trailing: CupertinoSwitch(
                        value: _widgetPinnedOnly,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) async {
                          HapticFeedback.selectionClick();
                          await SettingsService.instance.setWidgetPinnedOnly(v);
                          if (!mounted) return;
                          setState(() => _widgetPinnedOnly = v);
                          await _syncWidgetPrefs();
                        },
                      ),
                    ),
                    IosGroupTile(
                      title: l10n.widgetHideTitlesWhenLocked,
                      subtitle: l10n.widgetHideTitlesWhenLockedSubtitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.eye_slash_fill,
                        color: AppColors.iconSecurity,
                      ),
                      trailing: CupertinoSwitch(
                        value: _widgetHideTitlesWhenLocked,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) async {
                          HapticFeedback.selectionClick();
                          await SettingsService.instance
                              .setWidgetHideTitlesWhenLocked(v);
                          if (!mounted) return;
                          setState(() => _widgetHideTitlesWhenLocked = v);
                          await _syncWidgetPrefs();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.categoryManageTitle,
                  footer: l10n.categoryManageSubtitle,
                  children: [
                    IosGroupTile(
                      title: l10n.categoryManageTitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.tag_fill,
                        color: AppColors.iconView,
                      ),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await CategoryManageBottomSheet.show(context);
                        if (context.mounted) {
                          try {
                            context.read<VaultBloc>().add(const VaultRefreshed());
                          } catch (_) {}
                        }
                        if (!context.mounted) return;
                        // Refresh vault chips if shell has VaultBloc.
                        try {
                          context
                              .read<VaultBloc>()
                              .add(const VaultRefreshed());
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (!kIsWeb && Platform.isIOS)
                  IosGroup(
                    header: l10n.iCloudSyncSection,
                    footer: l10n.iCloudSyncFooter,
                    children: [
                      IosGroupTile(
                        title: l10n.iCloudSync,
                        subtitle: l10n.iCloudSyncSubtitle,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.cloud_fill,
                          color: AppColors.iconSecurity,
                        ),
                        trailing: _iCloudBusy
                            ? const CupertinoActivityIndicator()
                            : CupertinoSwitch(
                                value: _iCloudSync,
                                activeTrackColor: AppColors.primary,
                                onChanged: _toggleICloudSync,
                              ),
                      ),
                      if (_iCloudSync)
                        IosGroupTile(
                          title: l10n.iCloudSyncNow,
                          subtitle: _iCloudLastSyncLabel(l10n),
                          leading: _LeadingIcon(
                            icon: CupertinoIcons.arrow_2_circlepath,
                            color: AppColors.iconView,
                          ),
                          trailing: _iCloudBusy
                              ? const CupertinoActivityIndicator()
                              : const IosChevron(),
                          onTap: _iCloudBusy ? null : _syncICloudNow,
                        ),
                      IosGroupTile(
                        title: l10n.iCloudDiagnose,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.heart_fill,
                          color: AppColors.iconSecurity,
                        ),
                        trailing: _iCloudBusy
                            ? const CupertinoActivityIndicator()
                            : const IosChevron(),
                        onTap: _iCloudBusy ? null : _diagnoseICloud,
                      ),
                    ],
                  ),
                if (!kIsWeb && Platform.isIOS) ...[
                  IosGroup(
                    header: l10n.keyboardSection,
                    footer: l10n.keyboardFooter,
                    children: [
                      IosGroupTile(
                        title: l10n.keyboardTitle,
                        subtitle: l10n.keyboardSubtitle,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.keyboard,
                          color: AppColors.iconView,
                        ),
                        trailing: const IosChevron(),
                        onTap: _showKeyboardSetup,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
                if (!kIsWeb && Platform.isAndroid) ...[
                  IosGroup(
                    header: l10n.cloudBackupSection,
                    footer: l10n.cloudBackupFooter,
                    children: [
                      IosGroupTile(
                        title: l10n.cloudBackup,
                        subtitle: l10n.cloudBackupSubtitle,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.cloud_fill,
                          color: AppColors.iconSecurity,
                        ),
                        trailing: CupertinoSwitch(
                          value: _androidCloudBackup,
                          activeTrackColor: AppColors.primary,
                          onChanged: _toggleAndroidCloudBackup,
                        ),
                      ),
                      if (_androidCloudBackup)
                        IosGroupTile(
                          title: l10n.cloudBackupNow,
                          subtitle: _cloudBackupLastLabel(l10n),
                          leading: _LeadingIcon(
                            icon: CupertinoIcons.arrow_up_doc_fill,
                            color: AppColors.iconExport,
                          ),
                          trailing: const IosChevron(),
                          onTap: () => _exportSecureBackup(context),
                        ),
                      if (_androidCloudBackup)
                        IosGroupTile(
                          title: l10n.cloudBackupRestore,
                          subtitle: l10n.cloudBackupRestoreSubtitle,
                          leading: _LeadingIcon(
                            icon: CupertinoIcons.arrow_down_doc_fill,
                            color: AppColors.iconExport,
                          ),
                          trailing: const IosChevron(),
                          onTap: () => _importBackup(context),
                        ),
                      IosGroupTile(
                        title: l10n.cloudBackupHowTitle,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.info_circle_fill,
                          color: AppColors.iconView,
                        ),
                        trailing: const IosChevron(),
                        onTap: _showAndroidCloudHow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
                IosGroup(
                  header: l10n.nearbySection,
                  footer: l10n.nearbyFooter,
                  children: [
                    IosGroupTile(
                      title: l10n.nearbyEnabled,
                      subtitle: l10n.nearbyEnabledSubtitle,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.antenna_radiowaves_left_right,
                        color: AppColors.iconView,
                      ),
                      trailing: _nearbyBusy
                          ? const CupertinoActivityIndicator()
                          : CupertinoSwitch(
                              value: _nearbyEnabled,
                              activeTrackColor: AppColors.primary,
                              onChanged: _toggleNearby,
                            ),
                    ),
                    if (_nearbyEnabled)
                      IosGroupTile(
                        title: l10n.nearbyDisplayName,
                        subtitle: _nearbyName,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.device_phone_portrait,
                          color: AppColors.iconView,
                        ),
                        trailing: const IosChevron(),
                        onTap: _editNearbyName,
                      ),
                    if (_nearbyEnabled && _nearbyPin != null)
                      IosGroupTile(
                        title: l10n.nearbySessionPin,
                        subtitle: _nearbyPin,
                        leading: _LeadingIcon(
                          icon: CupertinoIcons.lock_shield_fill,
                          color: AppColors.iconSecurity,
                        ),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            NearbyService.instance.rotatePin();
                            HapticFeedback.selectionClick();
                          },
                          child: Text(
                            l10n.nearbyRotatePin,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                IosGroup(
                  header: l10n.settingsData,
                  children: [
                    IosGroupTile(
                      title: l10n.exportSecureBackup,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.lock_shield_fill,
                        color: AppColors.iconExport,
                      ),
                      trailing: const IosChevron(),
                      onTap: () => _exportSecureBackup(context),
                    ),
                    IosGroupTile(
                      title: l10n.importCsv,
                      leading: _LeadingIcon(
                        icon: CupertinoIcons.arrow_down_doc_fill,
                        color: AppColors.iconExport,
                      ),
                      trailing: const IosChevron(),
                      onTap: () => _importBackup(context),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BuildInfo.hasCommit
                      ? l10n.settingsFooterVersionWithCommit(
                          _versionLabel,
                          BuildInfo.shortCommit,
                        )
                      : l10n.settingsFooterVersion(_versionLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: AppColors.tertiaryLabel(context),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 4-button palette switch — full-width under the title row.
class _PaletteSegmentControl extends StatelessWidget {
  const _PaletteSegmentControl({
    required this.selected,
    required this.onChanged,
  });

  final BrandPaletteId selected;
  final ValueChanged<BrandPaletteId> onChanged;

  static const _labels = {
    BrandPaletteId.deepBrown: '01',
    BrandPaletteId.warmGrey: '02',
    BrandPaletteId.woodBlue: '05',
    BrandPaletteId.inkBlue: '06',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark
        ? AppColors.surfaceElevatedDark
        : const Color(0xFFE8E5DF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final id in BrandPalettes.all)
            Expanded(
              child: _PaletteSegmentButton(
                id: id,
                label: _labels[id]!,
                selected: selected == id,
                onTap: () => onChanged(id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaletteSegmentButton extends StatelessWidget {
  const _PaletteSegmentButton({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BrandPaletteId id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = BrandPalettes.of(id);
    final accent = tokens.accent10;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.cardBackground(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.secondaryLabel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: Colors.white),
    );
  }
}
