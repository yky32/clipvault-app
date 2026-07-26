import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clipvault_bottom_sheet.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Add or rename a **custom** category.
class CategoryEditorBottomSheet extends StatefulWidget {
  const CategoryEditorBottomSheet({this.category, super.key});

  /// Null = create; non-null custom category = rename.
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
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.category?.name ?? '';
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
    if (widget.category != null && name == widget.category!.name) {
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
        result = await AppBootstrap.categoryRepository.create(name);
      } else {
        result = await AppBootstrap.categoryRepository.rename(
          widget.category!.id,
          name,
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
