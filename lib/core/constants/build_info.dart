/// Compile-time build metadata (injected via `--dart-define` on CI / release).
///
/// TestFlight / Fastlane sets `GIT_COMMIT` to the full SHA so Settings can show
/// a short hash next to the version (e.g. `v1.0.0 #a1b2c3d`).
abstract final class BuildInfo {
  BuildInfo._();

  /// Full git SHA from `--dart-define=GIT_COMMIT=...` (empty for local runs).
  static const String gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: '',
  );

  /// First 7 chars of [gitCommit], or empty if unset.
  static String get shortCommit {
    final c = gitCommit.trim();
    if (c.isEmpty) return '';
    return c.length <= 7 ? c : c.substring(0, 7);
  }

  static bool get hasCommit => shortCommit.isNotEmpty;
}
