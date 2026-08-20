/// Empty-search chips on the vault home (local only).
enum VaultSearchSuggestionKind { category, uncategorized, query }

class VaultSearchSuggestion {
  const VaultSearchSuggestion._({
    required this.kind,
    required this.label,
    this.id,
  });

  factory VaultSearchSuggestion.category({
    required String id,
    required String label,
  }) =>
      VaultSearchSuggestion._(
        kind: VaultSearchSuggestionKind.category,
        id: id,
        label: label,
      );

  factory VaultSearchSuggestion.uncategorized() =>
      const VaultSearchSuggestion._(
        kind: VaultSearchSuggestionKind.uncategorized,
        label: '', // resolved via l10n in UI
      );

  factory VaultSearchSuggestion.query({required String label}) =>
      VaultSearchSuggestion._(
        kind: VaultSearchSuggestionKind.query,
        label: label,
      );

  final VaultSearchSuggestionKind kind;
  final String label;
  final String? id;
}
