import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bootstrap/app_bootstrap.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/category.dart';
import '../../../core/models/clip_item.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/clip_item_repository.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/settings_service.dart';

part 'vault_event.dart';
part 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  VaultBloc({
    required ClipItemRepository itemRepository,
    required CategoryRepository categoryRepository,
    required ClipboardService clipboardService,
  })  : _items = itemRepository,
        _categories = categoryRepository,
        _clipboard = clipboardService,
        super(
          VaultState(
            viewMode: SettingsService.instance.defaultViewMode,
            sortMode: SettingsService.instance.vaultSortMode,
          ),
        ) {
    on<VaultStarted>(_onStarted);
    on<VaultSearchChanged>(_onSearchChanged);
    on<VaultCategoryFilterChanged>(_onCategoryFilterChanged);
    on<VaultViewModeToggled>(_onViewModeToggled);
    on<VaultItemCopied>(_onItemCopied);
    on<VaultItemDeleted>(_onItemDeleted);
    on<VaultItemsDeleted>(_onItemsDeleted);
    on<VaultItemsRestored>(_onItemsRestored);
    on<VaultItemPinToggled>(_onItemPinToggled);
    on<VaultItemDuplicated>(_onItemDuplicated);
    on<VaultRefreshed>(_onRefreshed);
  }

  final ClipItemRepository _items;
  final CategoryRepository _categories;
  final ClipboardService _clipboard;

  Future<void> _syncWidget() async {
    try {
      await AppBootstrap.widgetSnapshotService.sync();
    } catch (_) {
      // Widget is best-effort; never fail vault actions.
    }
  }

  void _scheduleICloud() {
    try {
      AppBootstrap.iCloudSyncService.scheduleSync();
    } catch (_) {
      // iCloud is optional; never fail vault actions.
    }
  }

  Future<void> _syncSpotlight() async {
    try {
      await AppBootstrap.spotlightIndexService.reindexAll(_items.getAll());
    } catch (_) {
      // Spotlight is best-effort.
    }
  }

  Future<void> _onStarted(VaultStarted event, Emitter<VaultState> emit) async {
    emit(state.copyWith(status: VaultStatus.loading));
    final sw = Stopwatch()..start();
    final items = _items.getAll();
    final categories = _categories.getAll();
    // Local Hive is instant — yield a short beat so cold-open skeleton paints.
    const minSkeleton = Duration(milliseconds: 320);
    final remaining = minSkeleton - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    emit(
      state.copyWith(
        items: items,
        categories: categories,
        status: VaultStatus.ready,
        viewMode: SettingsService.instance.defaultViewMode,
        sortMode: SettingsService.instance.vaultSortMode,
        clearError: true,
      ),
    );
    await _syncSpotlight();
  }

  void _onSearchChanged(VaultSearchChanged event, Emitter<VaultState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCategoryFilterChanged(
    VaultCategoryFilterChanged event,
    Emitter<VaultState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearCategoryFilter: event.categoryId == null,
      ),
    );
  }

  Future<void> _onViewModeToggled(
    VaultViewModeToggled event,
    Emitter<VaultState> emit,
  ) async {
    final next = state.viewMode.next; // list → 2-col → 3-col → list
    await SettingsService.instance.setDefaultViewMode(next);
    emit(state.copyWith(viewMode: next));
  }

  Future<void> _onItemCopied(
    VaultItemCopied event,
    Emitter<VaultState> emit,
  ) async {
    final item = _items.getById(event.itemId);
    if (item == null) return;

    await _clipboard.copy(item.value);
    await _items.markCopied(item.id);

    emit(
      state.copyWith(
        items: _items.getAll(),
        lastCopiedTitle: item.title,
        clearError: true,
      ),
    );
    await _syncWidget();
    _scheduleICloud();
  }

  Future<void> _onItemDeleted(
    VaultItemDeleted event,
    Emitter<VaultState> emit,
  ) async {
    await _items.delete(event.itemId);
    emit(state.copyWith(items: _items.getAll()));
    await _syncWidget();
    try {
      await AppBootstrap.spotlightIndexService.delete([event.itemId]);
    } catch (_) {}
    try {
      await AppBootstrap.iCloudSyncService.pushItemTombstone(event.itemId);
    } catch (_) {}
    _scheduleICloud();
  }

  Future<void> _onItemsDeleted(
    VaultItemsDeleted event,
    Emitter<VaultState> emit,
  ) async {
    if (event.itemIds.isEmpty) return;
    await _items.deleteMany(event.itemIds);
    emit(state.copyWith(items: _items.getAll()));
    await _syncWidget();
    try {
      await AppBootstrap.spotlightIndexService.delete(event.itemIds);
    } catch (_) {}
    for (final id in event.itemIds) {
      try {
        await AppBootstrap.iCloudSyncService.pushItemTombstone(id);
      } catch (_) {}
    }
    _scheduleICloud();
  }

  Future<void> _onItemsRestored(
    VaultItemsRestored event,
    Emitter<VaultState> emit,
  ) async {
    if (event.items.isEmpty) return;
    await _items.restoreMany(event.items);
    emit(state.copyWith(items: _items.getAll()));
    await _syncWidget();
    await _syncSpotlight();
    _scheduleICloud();
  }

  Future<void> _onItemPinToggled(
    VaultItemPinToggled event,
    Emitter<VaultState> emit,
  ) async {
    final item = _items.getById(event.itemId);
    if (item == null) return;
    await _items.update(item.copyWith(isPinned: !item.isPinned));
    emit(state.copyWith(items: _items.getAll()));
    await _syncWidget();
    // Title unchanged — skip full reindex.
    _scheduleICloud();
  }

  Future<void> _onItemDuplicated(
    VaultItemDuplicated event,
    Emitter<VaultState> emit,
  ) async {
    final item = _items.getById(event.itemId);
    if (item == null) return;
    final base = item.title.trim();
    final copyTitle = base.isEmpty ? 'Copy' : '$base (copy)';
    await _items.create(
      title: copyTitle,
      value: item.value,
      categoryId: item.categoryId,
      languageTag: item.languageTag,
      isPinned: false,
      isSensitive: item.isSensitive,
    );
    emit(state.copyWith(items: _items.getAll()));
    await _syncWidget();
    await _syncSpotlight();
    _scheduleICloud();
  }

  Future<void> _onRefreshed(
    VaultRefreshed event,
    Emitter<VaultState> emit,
  ) async {
    // Keep existing items so UI can skeletonize in place (not flash empty).
    emit(state.copyWith(status: VaultStatus.loading));
    final sw = Stopwatch()..start();
    final items = _items.getAll();
    final categories = _categories.getAll();
    const minSkeleton = Duration(milliseconds: 280);
    final remaining = minSkeleton - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    emit(
      state.copyWith(
        items: items,
        categories: categories,
        sortMode: SettingsService.instance.vaultSortMode,
        viewMode: SettingsService.instance.defaultViewMode,
        status: VaultStatus.ready,
        clearError: true,
      ),
    );
    await _syncWidget();
    await _syncSpotlight();
    _scheduleICloud();
  }
}
