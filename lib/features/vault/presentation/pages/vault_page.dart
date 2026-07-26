import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/apple_search_field.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../item_editor/presentation/bottom_sheets/item_editor_bottom_sheet.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _categoryName(VaultState state, String? id) {
    if (id == null) return null;
    for (final c in state.categories) {
      if (c.id == id) return c.name;
    }
    return null;
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
            child: Text(isPinned ? 'Unpin' : l10n.pinItem),
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.fab(context),
          ),
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ItemEditorBottomSheet.show(context);
            },
            elevation: 0,
            highlightElevation: 0,
            child: const Icon(CupertinoIcons.add, size: 28),
          ),
        ),
        body: BlocBuilder<VaultBloc, VaultState>(
          builder: (context, state) {
            if (state.status == VaultStatus.loading ||
                state.status == VaultStatus.initial) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final isEmpty = state.items.isEmpty;
            final isGrid = state.viewMode == VaultViewMode.grid;
            final filtered = state.filteredItems;

            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + actions on the same row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 6, 4),
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
                            isGrid
                                ? CupertinoIcons.list_bullet
                                : CupertinoIcons.square_grid_2x2,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          onPressed: () => context.push('/vault/settings'),
                          child: const Icon(
                            CupertinoIcons.gear,
                            size: 22,
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
                        if (!isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                        if (!isEmpty && state.categories.isNotEmpty)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _SegmentChip(
                                    label: l10n.filterAll,
                                    selected: state.selectedCategoryId == null,
                                    onTap: () => context.read<VaultBloc>().add(
                                          const VaultCategoryFilterChanged(
                                            null,
                                          ),
                                        ),
                                  ),
                                  ...state.categories.map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _SegmentChip(
                                        label: c.name,
                                        selected:
                                            state.selectedCategoryId == c.id,
                                        onTap: () =>
                                            context.read<VaultBloc>().add(
                                                  VaultCategoryFilterChanged(
                                                    c.id,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: VaultEmptyState(
                              onAdd: () => ItemEditorBottomSheet.show(context),
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'No matches',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.secondaryLabel(context),
                                ),
                              ),
                            ),
                          )
                        else if (isGrid)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              100 + bottomInset,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.2,
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
                                    ),
                                    onTap: () => context
                                        .read<VaultBloc>()
                                        .add(VaultItemCopied(item.id)),
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
                              12,
                              16,
                              100 + bottomInset,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: ClipItemGroupedList(
                                items: filtered,
                                categoryNameOf: (item) =>
                                    _categoryName(state, item.categoryId),
                                onTap: (item) => context
                                    .read<VaultBloc>()
                                    .add(VaultItemCopied(item.id)),
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

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
            color: selected
                ? Colors.white
                : AppColors.secondaryLabel(context).withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }
}
