import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/services/review_prompt_service.dart';
import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/services/clipboard_suggest_service.dart';
import '../../../../core/services/backup_reminder_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/share_intake_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/apple_search_field.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../item_editor/presentation/bottom_sheets/item_editor_bottom_sheet.dart';
import '../../../welcome/presentation/bottom_sheets/welcome_explainer_sheet.dart';
import '../../../nearby/presentation/nearby_send_sheet.dart';
import '../../bloc/vault_bloc.dart';
import '../widgets/clip_item_card.dart';
import '../widgets/vault_empty_state.dart';
import '../widgets/vault_home_skeleton.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  bool _welcomeChecked = false;
  bool _selecting = false;
  final Set<String> _selectedIds = {};
  String? _clipboardSuggestText;
  bool _clipboardSuggestBusy = false;
  bool _clipboardSuggestChecking = false;
  bool _showBackupReminder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShareIntakeService.attach(_openSharedPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowWelcome();
      ShareIntakeService.consumePending();
      _maybeSuggestClipboard();
      _maybeBackupReminder();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShareIntakeService.detach();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeSuggestClipboard();
      _maybeBackupReminder();
    }
  }

  Future<void> _maybeSuggestClipboard() async {
    if (!mounted || _selecting || _clipboardSuggestChecking) return;
    if (_clipboardSuggestText != null) return;
    _clipboardSuggestChecking = true;
    try {
      // Brief settle — avoids racing lock screen / OS paste banners.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _selecting) return;
      final svc = ClipboardSuggestService(
        clipboard: AppBootstrap.clipboardService,
        items: AppBootstrap.clipItemRepository,
      );
      final text = await svc.evaluate();
      if (!mounted || text == null) return;
      setState(() => _clipboardSuggestText = text);
    } finally {
      _clipboardSuggestChecking = false;
    }
  }

  Future<void> _dismissClipboardSuggest() async {
    final text = _clipboardSuggestText;
    if (text == null) return;
    await ClipboardSuggestService(
      clipboard: AppBootstrap.clipboardService,
      items: AppBootstrap.clipItemRepository,
    ).markDismissed(text);
    if (!mounted) return;
    setState(() => _clipboardSuggestText = null);
  }

  Future<void> _saveClipboardSuggest() async {
    final text = _clipboardSuggestText;
    if (text == null || _clipboardSuggestBusy) return;
    setState(() => _clipboardSuggestBusy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final title = _titleFromSharedValue(text);
      await AppBootstrap.clipItemRepository.create(
        title: title.isEmpty ? 'Clipboard' : title,
        value: text,
      );
      await ClipboardSuggestService(
        clipboard: AppBootstrap.clipboardService,
        items: AppBootstrap.clipItemRepository,
      ).markDismissed(text);
      if (!mounted) return;
      context.read<VaultBloc>().add(const VaultRefreshed());
      setState(() {
        _clipboardSuggestText = null;
        _clipboardSuggestBusy = false;
      });
      CopiedHud.show(context, message: l10n.clipboardSuggestSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _clipboardSuggestBusy = false);
      CopiedHud.show(context, message: '$e');
    }
  }


  void _maybeBackupReminder() {
    if (!mounted || _selecting) return;
    final show = BackupReminderService(
      items: AppBootstrap.clipItemRepository,
    ).shouldShow();
    if (show != _showBackupReminder) {
      setState(() => _showBackupReminder = show);
    }
  }

  Future<void> _snoozeBackupReminder() async {
    await BackupReminderService(
      items: AppBootstrap.clipItemRepository,
    ).snooze();
    if (!mounted) return;
    setState(() => _showBackupReminder = false);
  }

  void _openBackupFromReminder() {
    context.go('/vault/settings');
  }

  Widget _backupReminderBanner(AppLocalizations l10n) {
    if (!_showBackupReminder || _selecting) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backupReminderTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.backupReminderBody,
              style: TextStyle(
                color: AppColors.secondaryLabel(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _snoozeBackupReminder,
                  child: Text(l10n.backupReminderLater),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _openBackupFromReminder,
                  child: Text(l10n.backupReminderExport),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _clipboardSuggestBanner(AppLocalizations l10n) {
    final text = _clipboardSuggestText;
    if (text == null) return const SizedBox.shrink();
    final preview = text.length > 100 ? '${text.substring(0, 100)}…' : text;
    return Material(
      color: AppColors.cardBackground(context),
      elevation: 0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.doc_on_clipboard, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.clipboardSuggestBannerTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryLabel(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _clipboardSuggestBusy ? null : _dismissClipboardSuggest,
                  child: Text(l10n.clipboardSuggestNotNow),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _clipboardSuggestBusy ? null : _saveClipboardSuggest,
                  child: _clipboardSuggestBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.clipboardSuggestSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSharedPayload(SharedClipPayload payload) {
    if (!mounted) return;
    // Defer until after route transitions (share deep link → vault).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final title = payload.title?.trim();
      final value = payload.value;
      // Derive a short title from first line when share had none.
      final derivedTitle = (title != null && title.isNotEmpty)
          ? title
          : _titleFromSharedValue(value);
      ItemEditorBottomSheet.show(
        context,
        initialTitle: derivedTitle,
        initialValue: value,
      );
    });
  }

  static String _titleFromSharedValue(String value) {
    final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) return '';
    if (oneLine.length <= 40) return oneLine;
    return '${oneLine.substring(0, 37)}…';
  }

  void _enterSelectMode({String? initialId}) {
    HapticFeedback.selectionClick();
    setState(() {
      _selecting = true;
      _selectedIds.clear();
      if (initialId != null) _selectedIds.add(initialId);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAllVisible(List<ClipItem> filtered) {
    setState(() {
      final allSelected = filtered.isNotEmpty &&
          filtered.every((i) => _selectedIds.contains(i.id));
      if (allSelected) {
        for (final i in filtered) {
          _selectedIds.remove(i.id);
        }
      } else {
        for (final i in filtered) {
          _selectedIds.add(i.id);
        }
      }
    });
  }

  void _onItemTap(ClipItem item) {
    if (_selecting) {
      HapticFeedback.selectionClick();
      _toggleSelected(item.id);
      return;
    }
    _copy(item);
  }

  void _onItemLongPress(
    BuildContext context,
    ClipItem item,
  ) {
    if (_selecting) {
      _toggleSelected(item.id);
      return;
    }
    _showItemActions(context, item);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String itemId,
    String title,
  ) async {
    final l10n = AppLocalizations.of(context);
    final snapshot = context
        .read<VaultBloc>()
        .state
        .items
        .where((i) => i.id == itemId)
        .toList();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.deleteConfirmBody(title)),
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
    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      context.read<VaultBloc>().add(VaultItemDeleted(itemId));
      if (snapshot.isNotEmpty) {
        _showDeleteUndo(context, snapshot);
      }
    }
  }

  void _showDeleteUndo(BuildContext context, List<ClipItem> items) {
    if (items.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          items.length == 1
              ? l10n.itemDeletedUndo
              : l10n.itemsDeletedUndo(items.length),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            context.read<VaultBloc>().add(VaultItemsRestored(items));
          },
        ),
      ),
    );
  }

  void _showItemActions(BuildContext context, ClipItem item) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(item.displayTitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _enterSelectMode(initialId: item.id);
            },
            child: Text(l10n.select),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ItemEditorBottomSheet.show(context, itemId: item.id);
            },
            child: Text(l10n.editItem),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VaultBloc>().add(VaultItemPinToggled(item.id));
            },
            child: Text(item.isPinned ? l10n.unpin : l10n.pinItem),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.selectionClick();
              context.read<VaultBloc>().add(VaultItemDuplicated(item.id));
              CopiedHud.show(context, message: l10n.itemDuplicated);
            },
            child: Text(l10n.duplicateItem),
          ),
          if (SettingsService.instance.nearbyEnabled)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                if (!SettingsService.instance.nearbyEnabled) {
                  CopiedHud.show(context, message: l10n.nearbyDisabledHint);
                  return;
                }
                NearbySendSheet.show(
                  context,
                  title: item.displayTitle,
                  value: item.value,
                  isSensitive: item.isSensitive,
                );
              },
              child: Text(l10n.nearbySendAction),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context, item.id, item.displayTitle);
            },
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// First install or App Store marketing-version upgrade only.
  Future<void> _maybeShowWelcome() async {
    if (_welcomeChecked || !mounted) return;
    _welcomeChecked = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version; // e.g. 1.0.0 — not build number
      if (!SettingsService.instance.shouldShowWelcome(version)) return;
      if (!mounted) return;
      await WelcomeExplainerSheet.show(context, version: version);
    } catch (_) {
      // Fail open — vault stays usable if package info fails.
    }
  }

  String? _categoryName(
    VaultState state,
    String? id,
    AppLocalizations l10n,
  ) {
    if (id == null) return null;
    for (final c in state.categories) {
      if (c.id == id) return categoryDisplayName(c, l10n);
    }
    return null;
  }

  void _openAdd({
    String? categoryId,
    String? initialTitle,
    String? initialValue,
  }) {
    HapticFeedback.selectionClick();
    ItemEditorBottomSheet.show(
      context,
      initialCategoryId: categoryId,
      initialTitle: initialTitle,
      initialValue: initialValue,
    );
  }

  void _openStarter(VaultStarter starter) {
    _openAdd(
      categoryId: starter.categoryId,
      initialTitle: starter.title,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<VaultBloc>()
      ..add(const VaultSearchChanged(''))
      ..add(const VaultCategoryFilterChanged(null));
  }

  Future<void> _confirmBulkDelete(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteSelectedTitle(count)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.deleteSelectedBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteSelected),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ids = _selectedIds.toList(growable: false);
    final snapshots = context
        .read<VaultBloc>()
        .state
        .items
        .where((i) => ids.contains(i.id))
        .toList();
    HapticFeedback.mediumImpact();
    context.read<VaultBloc>().add(VaultItemsDeleted(ids));
    _exitSelectMode();
    if (!context.mounted) return;
    _showDeleteUndo(context, snapshots);
  }

  void _copy(ClipItem item) {
    // Show HUD immediately on every tap (including re-copy same title).
    // BlocListener alone skipped when lastCopiedTitle was unchanged.
    final l10n = AppLocalizations.of(context);
    // HUD uses display title so sensitive items stay masked in toast.
    CopiedHud.show(context, message: l10n.copied(item.displayTitle));
    context.read<VaultBloc>().add(VaultItemCopied(item.id));
    // P1: soft review prompt after real usage (never blocks copy).
    unawaited(ReviewPromptService.instance.recordSuccessfulCopyAndMaybePrompt());
  }

  /// Pull-to-refresh (Triftly pattern) — reloads items + categories from local store.
  Future<void> _onPullRefresh() async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    context.read<VaultBloc>().add(const VaultRefreshed());
    // Local Hive load is instant; short delay so the indicator is visible.
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Copy HUD is shown in [_copy] so every grid/list/recent tap gets
    // feedback, even when re-copying the same title.
    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      body: BlocBuilder<VaultBloc, VaultState>(
          builder: (context, state) {
            final booting = (state.status == VaultStatus.loading ||
                    state.status == VaultStatus.initial) &&
                state.items.isEmpty;
            // Failure with no data — never stick on skeleton.
            if (state.status == VaultStatus.failure && state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.errorMessage ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryLabel(context),
                    ),
                  ),
                ),
              );
            }
            // Cold open / first load — full home skeleton (mock cards).
            if (booting) {
              return VaultHomeSkeleton(viewMode: state.viewMode);
            }

            final isEmpty = state.items.isEmpty;
            final isGrid = state.viewMode.isGrid;
            final gridCount = state.viewMode.gridCrossAxisCount;
            final filtered = state.filteredItems;
            final recent = state.recentlyCopied;
            // Recently-copied strip for list and grid (hidden when filtering).
            final showRecent = !state.hasActiveFilter &&
                recent.isNotEmpty &&
                state.items.length > 1;
            // Pull-to-refresh / reload with existing data — bone overlay.
            final skeletonizeContent =
                state.status == VaultStatus.loading && state.items.isNotEmpty;

            return Skeletonizer(
              enabled: skeletonizeContent,
              ignoreContainers: false,
              child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + actions — selection mode swaps the toolbar.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 6, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _selecting
                                ? (_selectedIds.isEmpty
                                    ? l10n.selectItems
                                    : l10n.selectedCount(_selectedIds.length))
                                : l10n.vaultTitle,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: _selecting ? 22 : 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.37,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (_selecting) ...[
                          CupertinoButton(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            onPressed: _exitSelectMode,
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (filtered.isNotEmpty)
                            CupertinoButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _selectAllVisible(filtered);
                              },
                              child: Text(
                                filtered.every(
                                  (i) => _selectedIds.contains(i.id),
                                )
                                    ? l10n.deselectAll
                                    : l10n.selectAll,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          CupertinoButton(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            onPressed: _selectedIds.isEmpty
                                ? null
                                : () => _confirmBulkDelete(context),
                            child: Text(
                              l10n.deleteSelected,
                              style: TextStyle(
                                color: _selectedIds.isEmpty
                                    ? AppColors.tertiaryLabel(context)
                                    : AppColors.error,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          if (!isEmpty) ...[
                            CupertinoButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: Size.zero,
                              onPressed: () => _enterSelectMode(),
                              child: Icon(
                                CupertinoIcons.checkmark_circle,
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                            CupertinoButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: Size.zero,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                context
                                    .read<VaultBloc>()
                                    .add(const VaultViewModeToggled());
                              },
                              child: Icon(
                                switch (state.viewMode) {
                                  VaultViewMode.list =>
                                    CupertinoIcons.square_grid_2x2,
                                  VaultViewMode.grid2 =>
                                    CupertinoIcons.square_grid_3x2,
                                  VaultViewMode.grid3 =>
                                    CupertinoIcons.list_bullet,
                                },
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                          CupertinoButton(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            onPressed: () => context.push('/vault/settings'),
                            child: Icon(
                              CupertinoIcons.gear,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          CupertinoButton(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            onPressed: () {
                              _openAdd(categoryId: state.selectedCategoryId);
                            },
                            child: Icon(
                              CupertinoIcons.add_circled_solid,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _onPullRefresh,
                      child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        if (!isEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                              child: AppleSearchField(
                                controller: _searchController,
                                hintText: l10n.searchHint,
                                onChanged: (q) => context
                                    .read<VaultBloc>()
                                    .add(VaultSearchChanged(q)),
                                onClear: () => context
                                    .read<VaultBloc>()
                                    .add(const VaultSearchChanged('')),
                              ),
                            ),
                          ),
                          if (_clipboardSuggestText != null && !_selecting)
                            SliverToBoxAdapter(
                              child: _clipboardSuggestBanner(l10n),
                            ),
                          if (_showBackupReminder &&
                              _clipboardSuggestText == null &&
                              !_selecting)
                            SliverToBoxAdapter(
                              child: _backupReminderBanner(l10n),
                            ),
                          if (state.categories.isNotEmpty)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 36,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _SegmentChip(
                                      label: l10n.filterAll,
                                      icon: CupertinoIcons.square_grid_2x2,
                                      selected:
                                          state.selectedCategoryId == null,
                                      onTap: () => context
                                          .read<VaultBloc>()
                                          .add(
                                            const VaultCategoryFilterChanged(
                                              null,
                                            ),
                                          ),
                                    ),
                                    ...state.categories.map((c) {
                                      final count = state.countInCategory(c.id);
                                      final selected =
                                          state.selectedCategoryId == c.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: _SegmentChip(
                                          label: categoryDisplayName(c, l10n),
                                          icon: categoryIcon(c),
                                          count: count,
                                          selected: selected,
                                          onTap: () =>
                                              context.read<VaultBloc>().add(
                                                    VaultCategoryFilterChanged(
                                                      selected ? null : c.id,
                                                    ),
                                                  ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          if (!state.hasActiveFilter && !isGrid)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  20,
                                  0,
                                ),
                                child: Text(
                                  l10n.hintCopy,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.tertiaryLabel(context),
                                  ),
                                ),
                              ),
                            ),
                        ],
                        if (isEmpty) ...[
                          if (_clipboardSuggestText != null && !_selecting)
                            SliverToBoxAdapter(
                              child: _clipboardSuggestBanner(l10n),
                            ),
                          if (_showBackupReminder &&
                              _clipboardSuggestText == null &&
                              !_selecting)
                            SliverToBoxAdapter(
                              child: _backupReminderBanner(l10n),
                            ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: VaultEmptyState(
                              onAdd: _openAdd,
                              onStarter: _openStarter,
                            ),
                          ),
                        ]
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: VaultFilterEmptyState(
                              searchQuery: state.searchQuery,
                              categoryName: _categoryName(
                                state,
                                state.selectedCategoryId,
                                l10n,
                              ),
                              onClearSearch: () {
                                _searchController.clear();
                                context
                                    .read<VaultBloc>()
                                    .add(const VaultSearchChanged(''));
                              },
                              onShowAll: _clearFilters,
                            ),
                          )
                        else ...[
                          if (showRecent && !_selecting)
                            SliverToBoxAdapter(
                              child: _RecentStrip(
                                items: recent,
                                onCopy: _copy,
                                onLongPress: (item) {
                                  HapticFeedback.mediumImpact();
                                  context
                                      .read<VaultBloc>()
                                      .add(VaultItemPinToggled(item.id));
                                },
                              ),
                            ),
                          if (isGrid)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                (showRecent && !_selecting) ? 8 : 12,
                                16,
                                24 + bottomInset,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCount,
                                  // More air between tiles so corner badges breathe.
                                  mainAxisSpacing: gridCount == 3 ? 10 : 12,
                                  crossAxisSpacing: gridCount == 3 ? 10 : 12,
                                  // Square tiles · 2 or 3 per row
                                  childAspectRatio: 1,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = filtered[index];
                                    return ClipItemCard(
                                      item: item,
                                      compact: true,
                                      gridColumns: gridCount,
                                      selectionMode: _selecting,
                                      selected: _selectedIds.contains(item.id),
                                      categoryName: _categoryName(
                                        state,
                                        item.categoryId,
                                        l10n,
                                      ),
                                      categoryIconData:
                                          categoryIconForId(item.categoryId),
                                      onTap: () => _onItemTap(item),
                                      onLongPress: () =>
                                          _onItemLongPress(context, item),
                                    );
                                  },
                                  childCount: filtered.length,
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                (showRecent && !_selecting) ? 8 : 12,
                                16,
                                24 + bottomInset,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _SectionedList(
                                  state: state,
                                  filtered: filtered,
                                  selectionMode: _selecting,
                                  isSelected: (item) =>
                                      _selectedIds.contains(item.id),
                                  categoryNameOf: (item) => _categoryName(
                                    state,
                                    item.categoryId,
                                    l10n,
                                  ),
                                  categoryIconOf: (item) =>
                                      categoryIconForId(item.categoryId),
                                  onTap: _onItemTap,
                                  onLongPress: (item) =>
                                      _onItemLongPress(context, item),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        ),
    );
  }
}

/// Pinned first, then everything else — clearer scanning.
class _SectionedList extends StatelessWidget {
  const _SectionedList({
    required this.state,
    required this.filtered,
    required this.categoryNameOf,
    required this.onTap,
    required this.onLongPress,
    this.categoryIconOf,
    this.selectionMode = false,
    this.isSelected,
  });

  final VaultState state;
  final List<ClipItem> filtered;
  final String? Function(ClipItem) categoryNameOf;
  final IconData? Function(ClipItem)? categoryIconOf;
  final void Function(ClipItem) onTap;
  final void Function(ClipItem) onLongPress;
  final bool selectionMode;
  final bool Function(ClipItem)? isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pinned = filtered.where((i) => i.isPinned).toList();
    final rest = filtered.where((i) => !i.isPinned).toList();
    final showSections = pinned.isNotEmpty && rest.isNotEmpty;

    if (!showSections) {
      return ClipItemGroupedList(
        items: filtered,
        categoryNameOf: categoryNameOf,
        categoryIconOf: categoryIconOf,
        selectionMode: selectionMode,
        isSelected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(l10n.pinnedSection),
        ClipItemGroupedList(
          items: pinned,
          categoryNameOf: categoryNameOf,
          categoryIconOf: categoryIconOf,
          selectionMode: selectionMode,
          isSelected: isSelected,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
        const SizedBox(height: 20),
        _SectionLabel(l10n.allSection),
        ClipItemGroupedList(
          items: rest,
          categoryNameOf: categoryNameOf,
          categoryIconOf: categoryIconOf,
          selectionMode: selectionMode,
          isSelected: isSelected,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.08,
              color: AppColors.secondaryLabel(context),
            ),
      ),
    );
  }
}

/// Horizontal quick-access strip for last-copied items.
///
/// Tap → copy · long-press → pin/unpin (favorite for widget).
class _RecentStrip extends StatelessWidget {
  const _RecentStrip({
    required this.items,
    required this.onCopy,
    this.onLongPress,
  });

  final List<ClipItem> items;
  final void Function(ClipItem) onCopy;
  final void Function(ClipItem)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.recentSection.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
              ),
              Text(
                l10n.recentHoldToPin,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.tertiaryLabel(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onCopy(item);
                },
                onLongPress: onLongPress == null
                    ? null
                    : () => onLongPress!(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                      color: item.isPinned
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : AppColors.hairline(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isPinned
                            ? CupertinoIcons.pin_fill
                            : CupertinoIcons.doc_on_clipboard,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : AppColors.secondaryLabel(context).withValues(alpha: 0.95);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.08,
                color: fg,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.tertiaryLabel(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
