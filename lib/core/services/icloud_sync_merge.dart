/// Pure merge helpers for Phase E CloudKit sync (last-write-wins).
///
/// Conflict rule: the side with the later [updatedAt] wins. If equal, remote
/// wins so a second device can converge after simultaneous edits.
library;

DateTime? parseSyncTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// True when [remote] should replace [local] (LWW by updatedAt).
bool remoteWins({
  required DateTime? localUpdated,
  required DateTime? remoteUpdated,
}) {
  if (remoteUpdated == null) return false;
  if (localUpdated == null) return true;
  return !remoteUpdated.isBefore(localUpdated);
}

/// Whether a tombstone should remove the local row.
bool shouldApplyTombstone({
  required DateTime? localUpdated,
  required DateTime? deletedAt,
}) {
  if (deletedAt == null) return false;
  if (localUpdated == null) return true;
  return !deletedAt.isBefore(localUpdated);
}

/// Coerce CloudKit / JSON map bools (0/1 or bool).
bool syncBool(Object? raw, {bool fallback = false}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final t = raw.toLowerCase();
    if (t == 'true' || t == '1') return true;
    if (t == 'false' || t == '0') return false;
  }
  return fallback;
}
