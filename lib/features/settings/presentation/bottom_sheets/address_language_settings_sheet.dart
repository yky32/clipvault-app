import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/address_languages.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Configure which language tags appear when saving an Addresses item.
/// Layout mirrors [CategoryManageBottomSheet] (sections + footer add).
class AddressLanguageSettingsSheet extends StatefulWidget {
  const AddressLanguageSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return ClipVaultBottomSheet.show<void>(
      context,
      child: const AddressLanguageSettingsSheet(),
    );
  }

  @override
  State<AddressLanguageSettingsSheet> createState() =>
      _AddressLanguageSettingsSheetState();
}

class _AddressLanguageSettingsSheetState
    extends State<AddressLanguageSettingsSheet> {
  late List<String> _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = List<String>.from(
      SettingsService.instance.addressLanguageTags,
    );
  }

  Future<void> _persist(List<String> next) async {
    setState(() => _enabled = next);
    await SettingsService.instance.setAddressLanguageTags(next);
  }

  Future<void> _toggleBuiltIn(String code, bool on) async {
    HapticFeedback.selectionClick();
    final next = List<String>.from(_enabled);
    if (on) {
      if (!next.contains(code)) next.add(code);
    } else {
      next.remove(code);
    }
    await _persist(next);
  }

  Future<void> _removeCustom(String code) async {
    final l10n = AppLocalizations.of(context);
    final label = AddressLanguages.label(code, l10n);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.addressLanguageRemoveTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.addressLanguageRemoveBody(label)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.mediumImpact();
    final next = List<String>.from(_enabled)..remove(code);
    await _persist(next);
  }

  Future<void> _addCustom() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final code = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.addressLanguageAddTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Text(
                l10n.addressLanguageAddBody,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: controller,
                placeholder: l10n.addressLanguageAddHint,
                autofocus: true,
                maxLength: 8,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
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
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.addressLanguageAddAction),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || code == null) return;

    final normalized = AddressLanguages.normalizeCode(code);
    if (normalized == null) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.addressLanguageAddInvalidTitle),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.addressLanguageAddInvalidBody),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
      return;
    }
    if (_enabled.contains(normalized)) return;
    HapticFeedback.lightImpact();
    await _persist([..._enabled, normalized]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final custom = _enabled
        .where((c) => !AddressLanguages.isBuiltIn(c))
        .toList(growable: false);

    return SheetScaffold(
      title: l10n.addressLanguagesTitle,
      subtitle: l10n.addressLanguagesSubtitle,
      showCloseButton: false,
      compactBody: false,
      footer: FilledButton.icon(
        onPressed: _addCustom,
        icon: const Icon(CupertinoIcons.add, size: 18),
        label: Text(l10n.addressLanguageAdd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosGroup(
            inset: false,
            header: l10n.addressLanguagesBuiltInHeader,
            children: [
              for (final code in AddressLanguages.builtIns)
                _LanguageTile(
                  icon: CupertinoIcons.textformat,
                  label: AddressLanguages.label(code, l10n),
                  trailing: CupertinoSwitch(
                    value: _enabled.contains(code),
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => _toggleBuiltIn(code, v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          IosGroup(
            inset: false,
            header: l10n.addressLanguagesCustomHeader,
            footer: l10n.addressLanguagesCustomFooter,
            children: [
              if (custom.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.textformat,
                        size: 20,
                        color: AppColors.tertiaryLabel(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.addressLanguagesCustomEmpty,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondaryLabel(context),
                                  ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final code in custom)
                  _LanguageTile(
                    icon: CupertinoIcons.textformat,
                    label: AddressLanguages.label(code, l10n),
                    trailing: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      onPressed: () => _removeCustom(code),
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: AppColors.error.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Same row chrome as Categories manage tiles.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
