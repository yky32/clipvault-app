import 'dart:developer' as developer;

/// Central app logging — filter console with `clipval.`
abstract final class AppLog {
  static void d(String message, {String name = 'clipval', Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void e(
    String message, {
    String name = 'clipval',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  /// Swallow + log (replace empty `catch (_) {}` on best-effort paths).
  static void ignore(Object error, StackTrace stackTrace, {String name = 'clipval', String? context}) {
    developer.log(
      context ?? 'ignored error',
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
