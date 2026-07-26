part of 'vault_bloc.dart';

final class VaultState extends Equatable {
  const VaultState({
    this.items = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.viewMode = VaultViewMode.list,
    this.status = VaultStatus.initial,
    this.lastCopiedTitle,
    this.errorMessage,
  });

  final List<ClipItem> items;
  final List<Category> categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final VaultViewMode viewMode;
  final VaultStatus status;
  final String? lastCopiedTitle;
  final String? errorMessage;

  List<ClipItem> get filteredItems {
    var result = items;
    if (selectedCategoryId != null) {
      result =
          result.where((i) => i.categoryId == selectedCategoryId).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((i) => i.title.toLowerCase().contains(q)).toList();
    }
    return result;
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
        status,
        lastCopiedTitle,
        errorMessage,
      ];
}

enum VaultStatus { initial, loading, ready, failure }
