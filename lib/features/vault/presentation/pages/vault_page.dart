import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.editItem),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/vault/item/$itemId');
              },
            ),
            ListTile(
              leading: Icon(
                isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
              ),
              title: Text(isPinned ? 'Unpin' : l10n.pinItem),
              onTap: () {
                Navigator.pop(ctx);
                context.read<VaultBloc>().add(VaultItemPinToggled(itemId));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, itemId, title);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocListener<VaultBloc, VaultState>(
      listenWhen: (prev, next) =>
          next.lastCopiedTitle != null &&
          next.lastCopiedTitle != prev.lastCopiedTitle,
      listener: (context, state) {
        final title = state.lastCopiedTitle;
        if (title == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.copied(title))),
                ],
              ),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: AppColors.primary,
            ),
          );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.vaultTitle),
          actions: [
            BlocBuilder<VaultBloc, VaultState>(
              buildWhen: (p, n) => p.viewMode != n.viewMode,
              builder: (context, state) {
                final isGrid = state.viewMode == VaultViewMode.grid;
                return IconButton(
                  tooltip: isGrid ? l10n.viewList : l10n.viewGrid,
                  onPressed: () =>
                      context.read<VaultBloc>().add(const VaultViewModeToggled()),
                  icon: Icon(
                    isGrid
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                  ),
                );
              },
            ),
            IconButton(
              tooltip: l10n.settingsTitle,
              onPressed: () => context.push('/vault/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/vault/item/new'),
          child: const Icon(Icons.add_rounded),
        ),
        body: BlocBuilder<VaultBloc, VaultState>(
          builder: (context, state) {
            if (state.status == VaultStatus.loading ||
                state.status == VaultStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.items.isEmpty) {
              return VaultEmptyState(
                onAdd: () => context.push('/vault/item/new'),
              );
            }

            final isGrid = state.viewMode == VaultViewMode.grid;
            final filtered = state.filteredItems;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (q) =>
                        context.read<VaultBloc>().add(VaultSearchChanged(q)),
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<VaultBloc>()
                                    .add(const VaultSearchChanged(''));
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                if (state.categories.isNotEmpty)
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: l10n.filterAll,
                          selected: state.selectedCategoryId == null,
                          onTap: () => context.read<VaultBloc>().add(
                                const VaultCategoryFilterChanged(null),
                              ),
                        ),
                        ...state.categories.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label: c.name,
                              selected: state.selectedCategoryId == c.id,
                              onTap: () => context.read<VaultBloc>().add(
                                    VaultCategoryFilterChanged(c.id),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matches',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : isGrid
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.35,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ClipItemCard(
                                  item: item,
                                  compact: true,
                                  categoryName:
                                      _categoryName(state, item.categoryId),
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
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ClipItemCard(
                                  item: item,
                                  categoryName:
                                      _categoryName(state, item.categoryId),
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
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : AppColors.cardBackground(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerTheme.color ?? theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
