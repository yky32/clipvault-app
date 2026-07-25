import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/models/clip_item.dart';
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
      appBar: AppBar(
        title: Text(widget.isNew ? l10n.addItem : l10n.editItem),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.titleLabel,
                  hintText: l10n.titleHint,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                obscureText: _obscureValue,
                minLines: _obscureValue ? 1 : 3,
                maxLines: _obscureValue ? 1 : 6,
                decoration: InputDecoration(
                  labelText: l10n.valueLabel,
                  hintText: l10n.valueHint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureValue
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureValue = !_obscureValue),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.categoryLabel,
                  hintText: l10n.categoryHint,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.pinItem),
                value: _isPinned,
                onChanged: (v) => setState(() => _isPinned = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
