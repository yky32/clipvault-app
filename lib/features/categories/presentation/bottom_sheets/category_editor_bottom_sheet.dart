import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Add or edit a **custom** category (name + optional language labels).
class CategoryEditorBottomSheet extends StatefulWidget {
  const CategoryEditorBottomSheet({this.category, super.key});

  /// Null = create; non-null custom category = edit.
  final Category? category;

  bool get isNew => category == null;

  static Future<Category?> show(
    BuildContext context, {
    Category? category,
  }) {
    return ClipVaultBottomSheet.show<Category>(
      context,
      child: CategoryEditorBottomSheet(category: category),
    );
  }

  @override
  State<CategoryEditorBottomSheet> createState() =>
      _CategoryEditorBottomSheetState();
}

class _CategoryEditorBottomSheetState extends State<CategoryEditorBottomSheet> {
  final _controller = TextEditingController();
  bool _supportsLanguageTag = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.category?.name ?? '';
    _supportsLanguageTag = widget.category?.supportsLanguageTag ?? false;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return false;
    final existing = widget.category;
    if (existing != null &&
        name == existing.name &&
        _supportsLanguageTag == existing.supportsLanguageTag) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final name = _controller.text.trim();
      final Category result;
      if (widget.isNew) {
        result = await AppBootstrap.categoryRepository.create(
          name,
          supportsLanguageTag: _supportsLanguageTag,
        );
      } else {
        result = await AppBootstrap.categoryRepository.updateCustom(
          widget.category!.id,
          name: name,
          supportsLanguageTag: _supportsLanguageTag,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SheetScaffold.swipeForm(
      title: widget.isNew ? l10n.categoryAdd : l10n.categoryEdit,
      swipeLabel: widget.isNew ? l10n.slideToAdd : l10n.slideToSave,
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        l10n.categoryNameLabel,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (_canSave) _save();
                        },
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l10n.categoryNameHint,
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          IosGroup(
            inset: false,
            footer: l10n.categoryLanguageTagFooter,
            children: [
              IosGroupTile(
                title: l10n.categoryLanguageTag,
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
                trailing: CupertinoSwitch(
                  value: _supportsLanguageTag,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _supportsLanguageTag = v);
                  },
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
