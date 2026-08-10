part of 'vault_bloc.dart';

final class VaultState extends Equatable {
  const VaultState({
    this.items = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.viewMode = VaultViewMode.list,
    this.sortMode = VaultSortMode.updated,
    this.status = VaultStatus.initial,
    this.lastCopiedTitle,
    this.errorMessage,
  });

  final List<ClipItem> items;
  final List<Category> categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final VaultViewMode viewMode;
  /// Mirrored from Settings so sort changes emit a distinct state.
  final VaultSortMode sortMode;
  final VaultStatus status;
  final String? lastCopiedTitle;
  final String? errorMessage;

  List<ClipItem> get filteredItems {
    var result = List<ClipItem>.from(items);
    if (selectedCategoryId != null) {
      result =
          result.where((i) => i.categoryId == selectedCategoryId).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((i) => i.title.toLowerCase().contains(q)).toList();
    }
    return _applySort(result, sortMode);
  }

  /// Pinned first, then [sortMode] among each group.
  static List<ClipItem> _applySort(List<ClipItem> list, VaultSortMode mode) {
    final pinned = list.where((i) => i.isPinned).toList();
    final rest = list.where((i) => !i.isPinned).toList();

    int byTitle(ClipItem a, ClipItem b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase());
    int byUpdated(ClipItem a, ClipItem b) =>
        b.updatedAt.compareTo(a.updatedAt);
    int byLastUsed(ClipItem a, ClipItem b) {
      final at = a.lastCopiedAt;
      final bt = b.lastCopiedAt;
      if (at == null && bt == null) return byUpdated(a, b);
      if (at == null) return 1;
      if (bt == null) return -1;
      final c = bt.compareTo(at);
      return c != 0 ? c : byUpdated(a, b);
    }

    final cmp = switch (mode) {
      VaultSortMode.title => byTitle,
      VaultSortMode.lastUsed => byLastUsed,
      VaultSortMode.updated => byUpdated,
    };
    pinned.sort(cmp);
    rest.sort(cmp);
    return [...pinned, ...rest];
  }

  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty || selectedCategoryId != null;

  List<ClipItem> get pinnedItems =>
      filteredItems.where((i) => i.isPinned).toList();

  List<ClipItem> get unpinnedItems =>
      filteredItems.where((i) => !i.isPinned).toList();

  /// Recently copied among *all* items (not filtered) for quick re-copy.
  List<ClipItem> get recentlyCopied {
    final withCopy = items.where((i) => i.lastCopiedAt != null).toList()
      ..sort((a, b) => b.lastCopiedAt!.compareTo(a.lastCopiedAt!));
    return withCopy.take(AppConstants.recentCopiedLimit).toList();
  }

  int countInCategory(String categoryId) =>
      items.where((i) => i.categoryId == categoryId).length;

  VaultState copyWith({
    List<ClipItem>? items,
    List<Category>? categories,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategoryFilter = false,
    VaultViewMode? viewMode,
    VaultSortMode? sortMode,
    VaultStatus? status,
    String? lastCopiedTitle,
    bool clearLastCopiedTitle = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VaultState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryFilter
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      viewMode: viewMode ?? this.viewMode,
      sortMode: sortMode ?? this.sortMode,
      status: status ?? this.status,
      lastCopiedTitle: clearLastCopiedTitle
          ? null
          : (lastCopiedTitle ?? this.lastCopiedTitle),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        items,
        categories,
        searchQuery,
        selectedCategoryId,
        viewMode,
        sortMode,
        status,
        lastCopiedTitle,
        errorMessage,
      ];
}

enum VaultStatus { initial, loading, ready, failure }
