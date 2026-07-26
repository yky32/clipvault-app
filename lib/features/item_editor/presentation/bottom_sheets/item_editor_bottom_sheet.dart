import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vault/bloc/vault_bloc.dart';

/// Add / edit vault item — presented as a bottom sheet (Triftly input pattern).
class ItemEditorBottomSheet extends StatefulWidget {
  const ItemEditorBottomSheet({
    this.itemId,
    this.initialCategoryId,
    super.key,
  });

  final String? itemId;

  /// Pre-select a category when adding from a vault filter.
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
  List<Category> _categories = const [];
  String? _selectedCategoryId;
  bool _isPinned = false;
  bool _obscureValue = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categories = AppBootstrap.categoryRepository.getAll();

    if (!widget.isNew) {
      _existing = AppBootstrap.clipItemRepository.getById(widget.itemId!);
      if (_existing != null) {
        _titleController.text = _existing!.title;
        _valueController.text = _existing!.value;
        _isPinned = _existing!.isPinned;
        _selectedCategoryId = _existing!.categoryId;
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

  void _selectCategory(String? id) {
    HapticFeedback.selectionClick();
    setState(() {
      // Tap again to clear
      _selectedCategoryId = _selectedCategoryId == id ? null : id;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final categoryId = _selectedCategoryId;

      if (_existing != null) {
        await AppBootstrap.clipItemRepository.update(
          _existing!.copyWith(
            title: _titleController.text.trim(),
            value: _valueController.text,
            categoryId: categoryId,
            clearCategory: categoryId == null,
            isPinned: _isPinned,
          ),
        );
      } else {
        await AppBootstrap.clipItemRepository.create(
          title: _titleController.text.trim(),
          value: _valueController.text,
          categoryId: categoryId,
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
      title: widget.isNew ? l10n.addItem : l10n.editItem,
      subtitle: widget.isNew ? l10n.appTagline : null,
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.categoryLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryLabel(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.categoryPickHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.tertiaryLabel(context),
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in _categories)
                _CategoryChip(
                  label: categoryDisplayName(cat, l10n),
                  selected: _selectedCategoryId == cat.id,
                  onTap: () => _selectCategory(cat.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          IosGroup(
            inset: false,
            children: [
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.hairline(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : AppColors.secondaryLabel(context).withValues(alpha: 0.95),
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
