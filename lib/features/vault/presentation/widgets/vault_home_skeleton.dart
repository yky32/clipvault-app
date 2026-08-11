import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'clip_item_card.dart';

/// Home / vault loading placeholder — same chrome + card geometry as real UI.
///
/// Bones animate via [Skeletonizer]. Only used while vault is loading/initial
/// with no items yet; ready+empty → [VaultEmptyState], not this widget.
class VaultHomeSkeleton extends StatelessWidget {
  const VaultHomeSkeleton({
    this.viewMode = VaultViewMode.list,
    super.key,
  });

  final VaultViewMode viewMode;

  static List<ClipItem> mockItems({int count = 6}) {
    final now = DateTime.now();
    return List<ClipItem>.generate(count, (i) {
      return ClipItem(
        id: 'skeleton-$i',
        title: i.isEven ? 'Skeleton title item' : 'Another loading label',
        value: '••••••••••••',
        categoryId: null,
        isPinned: i == 0,
        createdAt: now,
        updatedAt: now,
        lastCopiedAt: i < 2 ? now : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = mockItems();
    final isGrid = viewMode.isGrid;
    final gridCount = viewMode.gridCrossAxisCount;

    return Skeletonizer(
      enabled: true,
      ignoreContainers: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ClipVal',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.37,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(CupertinoIcons.gear, size: 22),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(CupertinoIcons.add_circled_solid, size: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: _SkeletonSearchBar(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          _SkeletonChip(wide: true),
                          SizedBox(width: 8),
                          _SkeletonChip(),
                          SizedBox(width: 8),
                          _SkeletonChip(),
                          SizedBox(width: 8),
                          _SkeletonChip(),
                        ],
                      ),
                    ),
                  ),
                  if (isGrid)
                    SliverPadding(
                      padding:
                          EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCount,
                          mainAxisSpacing: gridCount == 3 ? 10 : 12,
                          crossAxisSpacing: gridCount == 3 ? 10 : 12,
                          childAspectRatio: 1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return ClipItemCard(
                              item: item,
                              compact: true,
                              gridColumns: gridCount,
                              categoryName: 'Category',
                              onTap: () {},
                              onLongPress: () {},
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                          EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                      sliver: SliverToBoxAdapter(
                        child: ClipItemGroupedList(
                          items: items,
                          categoryNameOf: (_) => 'Category',
                          onTap: (_) {},
                          onLongPress: (_) {},
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSearchBar extends StatelessWidget {
  const _SkeletonSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.searchFill(context),
        borderRadius: AppRadii.search,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        'Search',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
      ),
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip({this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 72 : 88,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.searchFill(context),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
