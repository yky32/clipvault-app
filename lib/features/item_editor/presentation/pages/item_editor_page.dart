import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ios_group.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vault/bloc/vault_bloc.dart';

class ItemEditorPage extends StatefulWidget {
  const ItemEditorPage({this.itemId, super.key});

  final String? itemId;

  bool get isNew => itemId == null || itemId == 'new';

  @override
  State<ItemEditorPage> createState() => _ItemEditorPageState();
}

class _ItemEditorPageState extends State<ItemEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _categoryController = TextEditingController();

  ClipItem? _existing;
  bool _isPinned = false;
  bool _obscureValue = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) {
      _existing = AppBootstrap.clipItemRepository.getById(widget.itemId!);
      if (_existing != null) {
        _titleController.text = _existing!.title;
        _valueController.text = _existing!.value;
        _isPinned = _existing!.isPinned;
        if (_existing!.categoryId != null) {
          final cat =
              AppBootstrap.categoryRepository.getById(_existing!.categoryId!);
          if (cat != null) _categoryController.text = cat.name;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    try {
      String? categoryId;
      final catName = _categoryController.text.trim();
      if (catName.isNotEmpty) {
        final cat = await AppBootstrap.categoryRepository.create(catName);
        categoryId = cat.id;
      }

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
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              backgroundColor:
                  AppColors.groupedBackground(context).withValues(alpha: 0.92),
              border: null,
              largeTitle: Text(widget.isNew ? l10n.addItem : l10n.editItem),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => context.pop(),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CupertinoActivityIndicator()
                    : Text(
                        l10n.save,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  IosGroup(
                    children: [
                      _FieldRow(
                        label: l10n.titleLabel,
                        child: TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.requiredField
                              : null,
                        ),
                      ),
                      _FieldRow(
                        label: l10n.valueLabel,
                        alignTop: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
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
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.requiredField
                                    : null,
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.only(left: 8),
                              minimumSize: Size.zero,
                              onPressed: () => setState(
                                () => _obscureValue = !_obscureValue,
                              ),
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
                      _FieldRow(
                        label: l10n.categoryLabel,
                        child: TextFormField(
                          controller: _categoryController,
                          textInputAction: TextInputAction.done,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: l10n.categoryHint,
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
                  const SizedBox(height: 28),
                  IosGroup(
                    children: [
                      IosGroupTile(
                        title: l10n.pinItem,
                        leading: const _LeadingIcon(
                          icon: CupertinoIcons.pin_fill,
                          color: Color(0xFFFF9500),
                        ),
                        trailing: CupertinoSwitch(
                          value: _isPinned,
                          activeTrackColor: AppColors.success,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _isPinned = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
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
            width: 92,
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
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}
