import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/l10n/category_icons.dart';
import '../../../../core/l10n/category_labels.dart';
import '../../../../core/models/clip_item.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/apple_search_field.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../item_editor/presentation/bottom_sheets/item_editor_bottom_sheet.dart';
import '../../../welcome/presentation/bottom_sheets/welcome_explainer_sheet.dart';
import '../../bloc/vault_bloc.dart';
import '../widgets/clip_item_card.dart';
import '../widgets/vault_empty_state.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _searchController = TextEditingController();
  bool _welcomeChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openAdd({String? categoryId}) {
    HapticFeedback.selectionClick();
    ItemEditorBottomSheet.show(
      context,
      initialCategoryId: categoryId,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<VaultBloc>()
      ..add(const VaultSearchChanged(''))
      ..add(const VaultCategoryFilterChanged(null));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String itemId,
    String title,
  ) async {
    final l10n = AppLocalizations.of(context);
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
    }
  }

  void _showItemActions(
    BuildContext context,
    String itemId,
    String title,
    bool isPinned,
  ) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ItemEditorBottomSheet.show(context, itemId: itemId);
            },
            child: Text(l10n.editItem),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VaultBloc>().add(VaultItemPinToggled(itemId));
            },
            child: Text(isPinned ? l10n.unpin : l10n.pinItem),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context, itemId, title);
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

  void _copy(ClipItem item) {
    context.read<VaultBloc>().add(VaultItemCopied(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocListener<VaultBloc, VaultState>(
      listenWhen: (prev, next) =>
          next.lastCopiedTitle != null &&
          next.lastCopiedTitle != prev.lastCopiedTitle,
      listener: (context, state) {
        final title = state.lastCopiedTitle;
        if (title == null) return;
        CopiedHud.show(context, message: l10n.copied(title));
      },
      child: Scaffold(
        backgroundColor: AppColors.groupedBackground(context),
        body: BlocBuilder<VaultBloc, VaultState>(
          builder: (context, state) {
            if (state.status == VaultStatus.loading ||
                state.status == VaultStatus.initial) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final isEmpty = state.items.isEmpty;
            final isGrid = state.viewMode.isGrid;
            final gridCount = state.viewMode.gridCrossAxisCount;
            final filtered = state.filteredItems;
            final recent = state.recentlyCopied;
            final showRecent = !state.hasActiveFilter &&
                !isGrid &&
                recent.isNotEmpty &&
                state.items.length > 1;

            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + actions: list | settings | add (iOS nav pattern)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 6, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.vaultTitle,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.37,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (!isEmpty)
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          onPressed: () => context.push('/vault/settings'),
                          child: Icon(
                            CupertinoIcons.gear,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    ),
                  ),
                  Expanded(
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
                        if (isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: VaultEmptyState(onAdd: () => _openAdd()),
                          )
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
                              onAdd: () => _openAdd(
                                categoryId: state.selectedCategoryId,
                              ),
                            ),
                          )
                        else ...[
                          if (showRecent)
                            SliverToBoxAdapter(
                              child: _RecentStrip(
                                items: recent,
                                onCopy: _copy,
                              ),
                            ),
                          if (isGrid)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                24 + bottomInset,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCount,
                                  mainAxisSpacing: gridCount == 3 ? 8 : 10,
                                  crossAxisSpacing: gridCount == 3 ? 8 : 10,
                                  // Square tiles · 2 or 3 per row
                                  childAspectRatio: 1,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = filtered[index];
                                    return ClipItemCard(
                                      item: item,
                                      compact: true,
                                      categoryName: _categoryName(
                                        state,
                                        item.categoryId,
                                        l10n,
                                      ),
                                      categoryIconData:
                                          categoryIconForId(item.categoryId),
                                      onTap: () => _copy(item),
                                      onLongPress: () => _showItemActions(
                                        context,
                                        item.id,
                                        item.title,
                                        item.isPinned,
                                      ),
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
                                showRecent ? 8 : 12,
                                16,
                                24 + bottomInset,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _SectionedList(
                                  state: state,
                                  filtered: filtered,
                                  categoryNameOf: (item) => _categoryName(
                                    state,
                                    item.categoryId,
                                    l10n,
                                  ),
                                  categoryIconOf: (item) =>
                                      categoryIconForId(item.categoryId),
                                  onTap: _copy,
                                  onLongPress: (item) => _showItemActions(
                                    context,
                                    item.id,
                                    item.title,
                                    item.isPinned,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
  });

  final VaultState state;
  final List<ClipItem> filtered;
  final String? Function(ClipItem) categoryNameOf;
  final IconData? Function(ClipItem)? categoryIconOf;
  final void Function(ClipItem) onTap;
  final void Function(ClipItem) onLongPress;

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
          onTap: onTap,
          onLongPress: onLongPress,
        ),
        const SizedBox(height: 20),
        _SectionLabel(l10n.allSection),
        ClipItemGroupedList(
          items: rest,
          categoryNameOf: categoryNameOf,
          categoryIconOf: categoryIconOf,
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
class _RecentStrip extends StatelessWidget {
  const _RecentStrip({required this.items, required this.onCopy});

  final List<ClipItem> items;
  final void Function(ClipItem) onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            l10n.recentSection.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryLabel(context),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onCopy(item);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.hairline(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_on_clipboard,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
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
