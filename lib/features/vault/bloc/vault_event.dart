part of 'vault_bloc.dart';

sealed class VaultEvent extends Equatable {
  const VaultEvent();

  @override
  List<Object?> get props => [];
}

final class VaultStarted extends VaultEvent {
  const VaultStarted();
}

final class VaultSearchChanged extends VaultEvent {
  const VaultSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

final class VaultCategoryFilterChanged extends VaultEvent {
  const VaultCategoryFilterChanged(this.categoryId);
  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class VaultViewModeToggled extends VaultEvent {
  const VaultViewModeToggled();
}

final class VaultItemCopied extends VaultEvent {
  const VaultItemCopied(this.itemId);
  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class VaultItemDeleted extends VaultEvent {
  const VaultItemDeleted(this.itemId);
  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class VaultItemsDeleted extends VaultEvent {
  const VaultItemsDeleted(this.itemIds);
  final List<String> itemIds;

  @override
  List<Object?> get props => [itemIds];
}

final class VaultItemPinToggled extends VaultEvent {
  const VaultItemPinToggled(this.itemId);
  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class VaultRefreshed extends VaultEvent {
  const VaultRefreshed();
}
