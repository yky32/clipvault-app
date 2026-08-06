import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/default_categories.dart';
import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/bottom_sheets/category_picker_bottom_sheet.dart';
import '../../../vault/bloc/vault_bloc.dart';

/// Add / edit vault item — presented as a bottom sheet (Triftly input pattern).
class ItemEditorBottomSheet extends StatefulWidget {
  const ItemEditorBottomSheet({
    this.itemId,
    this.initialCategoryId,
    super.key,
  });

  final String? itemId;
  final String? initialCategoryId;

  bool get isNew => itemId == null || itemId == 'new';

  static Future<void> show(
    BuildContext context, {
    String? itemId,
    String? initialCategoryId,
  }) {
    final vaultBloc = context.read<VaultBloc>();
    return ClipVaultBottomSheet.show<void>(
      context,
      child: BlocProvider.value(
        value: vaultBloc,
        child: ItemEditorBottomSheet(
          itemId: itemId,
          initialCategoryId: initialCategoryId,
        ),
      ),
    );
  }

  @override
  State<ItemEditorBottomSheet> createState() => _ItemEditorBottomSheetState();
}

class _ItemEditorBottomSheetState extends State<ItemEditorBottomSheet> {
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();

  ClipItem? _existing;
  String? _selectedCategoryId;
  /// Addresses only: `zh` | `en` | null.
  String? _languageTag;
  bool _isPinned = false;
  bool _obscureValue = true;
  bool _saving = false;

  bool get _isAddressesCategory {
    final id = _selectedCategoryId;
    if (id == null) return false;
    final cat = AppBootstrap.categoryRepository.getById(id);
    return cat?.systemKey == DefaultCategories.addresses;
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) {
      _existing = AppBootstrap.clipItemRepository.getById(widget.itemId!);
      if (_existing != null) {
        _titleController.text = _existing!.title;
        _valueController.text = _existing!.value;
        _isPinned = _existing!.isPinned;
        _selectedCategoryId = _existing!.categoryId;
        _languageTag = _existing!.languageTag;
      }
    } else if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
    _titleController.addListener(_onChanged);
    _valueController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _titleController
      ..removeListener(_onChanged)
      ..dispose();
    _valueController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty &&
        _valueController.text.isNotEmpty &&
        !_saving;
  }

  String _categoryLabel(AppLocalizations l10n) {
    if (_selectedCategoryId == null) return l10n.categoryNone;
    final cat =
        AppBootstrap.categoryRepository.getById(_selectedCategoryId!);
    if (cat == null) return l10n.categoryNone;
    return categoryDisplayName(cat, l10n);
  }

  Future<void> _pickCategory() async {
    final result = await CategoryPickerBottomSheet.show(
      context,
      selectedId: _selectedCategoryId,
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedCategoryId = result.category?.id;
      // Language tag only applies to Addresses.
      if (!_isAddressesCategory) {
        _languageTag = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final categoryId = _selectedCategoryId;
      final languageTag = _isAddressesCategory ? _languageTag : null;

      if (_existing != null) {
        await AppBootstrap.clipItemRepository.update(
          _existing!.copyWith(
            title: _titleController.text.trim(),
            value: _valueController.text,
            categoryId: categoryId,
            clearCategory: categoryId == null,
            languageTag: languageTag,
            clearLanguageTag: languageTag == null,
            isPinned: _isPinned,
          ),
        );
      } else {
        await AppBootstrap.clipItemRepository.create(
          title: _titleController.text.trim(),
          value: _valueController.text,
          categoryId: categoryId,
          languageTag: languageTag,
          isPinned: _isPinned,
        );
      }

      if (!mounted) return;
      context.read<VaultBloc>().add(const VaultRefreshed());
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SheetScaffold.swipeForm(
      // Single centered title — no tagline (avoids left-heavy header under grabber)
      title: widget.isNew ? l10n.addItem : l10n.editItem,
      swipeLabel: l10n.slideToSave,
      swipeEnabled: _canSave,
      isSubmitting: _saving,
      onSwipeConfirmed: _save,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosGroup(
            inset: false,
            children: [
              _SheetField(
                label: l10n.titleLabel,
                child: TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  autofocus: widget.isNew,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: l10n.titleHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _SheetField(
                label: l10n.valueLabel,
                alignTop: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _valueController,
                        obscureText: _obscureValue,
                        minLines: _obscureValue ? 1 : 3,
                        maxLines: _obscureValue ? 1 : 6,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l10n.valueHint,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.only(left: 8),
                      minimumSize: Size.zero,
                      onPressed: () =>
                          setState(() => _obscureValue = !_obscureValue),
                      child: Icon(
                        _obscureValue
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        size: 20,
                        color: AppColors.secondaryLabel(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          IosGroup(
            inset: false,
            children: [
              // Category — same tile pattern as Pin (icon + label + chevron)
              IosGroupTile(
                title: l10n.categoryLabel,
                subtitle: _categoryLabel(l10n),
                leading: CategoryLeadingIcon(
                  categoryId: _selectedCategoryId,
                ),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: AppColors.tertiaryLabel(context),
                ),
                onTap: _pickCategory,
              ),
              if (_isAddressesCategory)
                IosGroupTile(
                  title: l10n.addressLanguageLabel,
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      CupertinoIcons.textformat,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  below: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _LanguageChip(
                          label: l10n.addressLanguageNone,
                          selected: _languageTag == null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _languageTag = null);
                          },
                        ),
                        _LanguageChip(
                          label: l10n.addressLanguageZh,
                          selected: _languageTag == ClipItem.languageZh,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(
                              () => _languageTag = ClipItem.languageZh,
                            );
                          },
                        ),
                        _LanguageChip(
                          label: l10n.addressLanguageEn,
                          selected: _languageTag == ClipItem.languageEn,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(
                              () => _languageTag = ClipItem.languageEn,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              IosGroupTile(
                title: l10n.pinItem,
                leading: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    CupertinoIcons.pin_fill,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                trailing: CupertinoSwitch(
                  value: _isPinned,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _isPinned = v);
                  },
                ),
              ),
              if (_existing != null)
                IosGroupTile(
                  title: l10n.lastUsedLabel,
                  subtitle: formatLastUsed(
                    _existing!.lastCopiedAt,
                    l10n,
                    locale: Localizations.localeOf(context).toString(),
                  ),
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.16)
          : AppColors.secondaryLabel(context).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? primary
                      : AppColors.secondaryLabel(context),
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.child,
    this.alignTop = false,
  });

  final String label;
  final Widget child;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment:
            alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: Padding(
              padding: EdgeInsets.only(top: alignTop ? 2 : 0),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
