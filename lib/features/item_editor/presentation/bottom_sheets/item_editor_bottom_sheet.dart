import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/address_languages.dart';
import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/services/settings_service.dart';
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
    this.initialTitle,
    this.initialValue,
    super.key,
  });

  final String? itemId;
  final String? initialCategoryId;

  /// Prefill for new items (e.g. Share Extension intake).
  final String? initialTitle;
  final String? initialValue;

  bool get isNew => itemId == null || itemId == 'new';

  static Future<void> show(
    BuildContext context, {
    String? itemId,
    String? initialCategoryId,
    String? initialTitle,
    String? initialValue,
  }) {
    final vaultBloc = context.read<VaultBloc>();
    return ClipVaultBottomSheet.show<void>(
      context,
      child: BlocProvider.value(
        value: vaultBloc,
        child: ItemEditorBottomSheet(
          itemId: itemId,
          initialCategoryId: initialCategoryId,
          initialTitle: initialTitle,
          initialValue: initialValue,
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
  final _valueFocus = FocusNode();

  ClipItem? _existing;
  String? _selectedCategoryId;
  /// Addresses only: `zh` | `en` | null.
  String? _languageTag;
  bool _isPinned = false;
  bool _obscureValue = true;
  bool _saving = false;

  /// Long / multi-line values get a taller field when revealed.
  bool get _valueIsLong {
    final t = _valueController.text;
    return t.contains('\n') || t.length > 48;
  }

  /// Flutter requires [maxLines] == 1 when [obscureText] is true, so long
  /// values collapse to a single starred line when hidden, and expand when shown.
  bool get _valueMultiline => !_obscureValue;

  bool get _categorySupportsLanguageTag {
    final id = _selectedCategoryId;
    if (id == null) return false;
    final cat = AppBootstrap.categoryRepository.getById(id);
    return cat?.supportsLanguageTag ?? false;
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
    } else {
      if (widget.initialCategoryId != null) {
        _selectedCategoryId = widget.initialCategoryId;
      }
      final seedTitle = widget.initialTitle?.trim();
      final seedValue = widget.initialValue;
      if (seedTitle != null && seedTitle.isNotEmpty) {
        _titleController.text = seedTitle;
      }
      if (seedValue != null && seedValue.isNotEmpty) {
        _valueController.text = seedValue;
      }
    }
    _titleController.addListener(_onChanged);
    _valueController.addListener(_onChanged);
    // Long templates: show plaintext multi-line by default when opening.
    if (_valueIsLong) {
      _obscureValue = false;
    }
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
    _valueFocus.dispose();
    super.dispose();
  }

  Future<void> _pasteIntoValue() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty || !mounted) return;
    HapticFeedback.selectionClick();
    final sel = _valueController.selection;
    final current = _valueController.text;
    if (sel.isValid) {
      final next = current.replaceRange(sel.start, sel.end, text);
      _valueController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: sel.start + text.length),
      );
    } else {
      _valueController.text = current.isEmpty ? text : '$current$text';
      _valueController.selection =
          TextSelection.collapsed(offset: _valueController.text.length);
    }
    // Reveal after paste so the user can review; eye still hides to stars.
    setState(() => _obscureValue = false);
  }

  Future<void> _openExpandedValueEditor() async {
    // Controller is owned by the sheet widget so it is disposed only after
    // the route unmounts (avoids "used after disposed" during pop animation).
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpandedValueEditorSheet(
        initialText: _valueController.text,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _valueController.value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
      if (result.contains('\n') || result.length > 48) {
        _obscureValue = false;
      }
    });
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
      // Language tag only when the category enables it.
      if (!_categorySupportsLanguageTag) {
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
      final languageTag =
          _categorySupportsLanguageTag ? _languageTag : null;

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
              // Full-width value block — better for long templates than
              // the compact label | single-line row.
              _ValueEditorBlock(
                label: l10n.valueLabel,
                pasteLabel: l10n.valuePaste,
                controller: _valueController,
                focusNode: _valueFocus,
                obscure: _obscureValue,
                multiline: _valueMultiline,
                tall: _valueIsLong && _valueMultiline,
                hint: l10n.valueHint,
                onToggleObscure: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscureValue = !_obscureValue);
                },
                onExpand: _openExpandedValueEditor,
                onPaste: _pasteIntoValue,
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
              if (_categorySupportsLanguageTag)
                ValueListenableBuilder<List<String>>(
                  valueListenable:
                      SettingsService.instance.addressLanguageTagsListenable,
                  builder: (context, enabledTags, _) {
                    // Offer Settings-enabled tags; keep current if disabled later.
                    final codes = <String>[
                      ...enabledTags,
                      if (_languageTag != null &&
                          !enabledTags.contains(_languageTag))
                        _languageTag!,
                    ];
                    if (codes.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IosGroupTile(
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
                            for (final code in codes)
                              _LanguageChip(
                                label: AddressLanguages.label(code, l10n),
                                selected: _languageTag == code,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _languageTag = code);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _FieldLabelBadge(label),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Form field label chip — fill/text follow [AppColors.primary] (all palettes).
class _FieldLabelBadge extends StatelessWidget {
  const _FieldLabelBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14);
    final fg = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
              height: 1.15,
            ),
      ),
    );
  }
}

/// Full-height multi-line value editor. Owns its [TextEditingController].
class _ExpandedValueEditorSheet extends StatefulWidget {
  const _ExpandedValueEditorSheet({required this.initialText});

  final String initialText;

  @override
  State<_ExpandedValueEditorSheet> createState() =>
      _ExpandedValueEditorSheetState();
}

class _ExpandedValueEditorSheetState extends State<_ExpandedValueEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDimDark : AppColors.warmWhite;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.92,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  Expanded(
                    child: Text(
                      l10n.valueExpandTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () => Navigator.pop(context, _controller.text),
                    child: Text(
                      l10n.valueExpandDone,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                  decoration: InputDecoration(
                    hintText: l10n.valueHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stacked value field: toolbar + multi-line body for templates / long paste.
class _ValueEditorBlock extends StatelessWidget {
  const _ValueEditorBlock({
    required this.label,
    required this.pasteLabel,
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.multiline,
    required this.tall,
    required this.hint,
    required this.onToggleObscure,
    required this.onExpand,
    required this.onPaste,
  });

  final String label;
  final String pasteLabel;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final bool multiline;
  /// Extra height when showing a long value in the clear.
  final bool tall;
  final String hint;
  final VoidCallback onToggleObscure;
  final VoidCallback onExpand;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.secondaryLabel(context);
    // obscureText requires maxLines == 1 (Flutter). Hidden long text → one
    // starred line; revealed → multi-line editor.
    final minLines = !multiline ? 1 : (tall ? 5 : 2);
    final maxLines = multiline ? 12 : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _FieldLabelBadge(label),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: onPaste,
                child: Text(
                  pasteLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: onExpand,
                child: Icon(
                  CupertinoIcons.arrow_up_left_arrow_down_right,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(left: 4, right: 8),
                minimumSize: Size.zero,
                onPressed: onToggleObscure,
                child: Icon(
                  obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 20,
                  color: secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: multiline ? (tall ? 120 : 48) : 24,
              maxHeight: multiline ? 220 : 40,
            ),
            child: TextField(
              key: ValueKey<bool>(obscure),
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              obscuringCharacter: '•',
              minLines: minLines,
              maxLines: maxLines,
              keyboardType: multiline
                  ? TextInputType.multiline
                  : TextInputType.text,
              textInputAction: multiline
                  ? TextInputAction.newline
                  : TextInputAction.done,
              textAlignVertical:
                  multiline ? TextAlignVertical.top : TextAlignVertical.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: multiline ? 1.35 : 1.2,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
