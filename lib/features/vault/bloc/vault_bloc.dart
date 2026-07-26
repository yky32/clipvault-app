import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          VaultState(viewMode: SettingsService.instance.defaultViewMode),
        ) {
    on<VaultStarted>(_onStarted);
    on<VaultSearchChanged>(_onSearchChanged);
    on<VaultCategoryFilterChanged>(_onCategoryFilterChanged);
    on<VaultViewModeToggled>(_onViewModeToggled);
    on<VaultItemCopied>(_onItemCopied);
    on<VaultItemDeleted>(_onItemDeleted);
    on<VaultItemPinToggled>(_onItemPinToggled);
    on<VaultRefreshed>(_onRefreshed);
  }

  final ClipItemRepository _items;
  final CategoryRepository _categories;
  final ClipboardService _clipboard;

  void _onStarted(VaultStarted event, Emitter<VaultState> emit) {
    emit(state.copyWith(status: VaultStatus.loading));
    emit(
      state.copyWith(
        items: _items.getAll(),
        categories: _categories.getAll(),
        status: VaultStatus.ready,
        viewMode: SettingsService.instance.defaultViewMode,
      ),
    );
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
  }

  Future<void> _onItemDeleted(
    VaultItemDeleted event,
    Emitter<VaultState> emit,
  ) async {
    await _items.delete(event.itemId);
    emit(state.copyWith(items: _items.getAll()));
  }

  Future<void> _onItemPinToggled(
    VaultItemPinToggled event,
    Emitter<VaultState> emit,
  ) async {
    final item = _items.getById(event.itemId);
    if (item == null) return;
    await _items.update(item.copyWith(isPinned: !item.isPinned));
    emit(state.copyWith(items: _items.getAll()));
  }

  void _onRefreshed(VaultRefreshed event, Emitter<VaultState> emit) {
    emit(
      state.copyWith(
        items: _items.getAll(),
        categories: _categories.getAll(),
      ),
    );
  }
}
