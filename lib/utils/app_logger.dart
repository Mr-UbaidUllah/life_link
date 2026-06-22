import 'package:flutter/foundation.dart';

/// Lightweight logging facade.
///
/// All app logging should go through this instead of raw `print`/`debugPrint`
/// so that (a) nothing is emitted in release builds and (b) we never leak
/// sensitive data (tokens, full user documents, PII) to device logs in prod.
class AppLogger {
  const AppLogger._();

  static void d(Object? message) {
    if (kDebugMode) debugPrint('$message');
  }

  static void e(Object? message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('ERROR: $message${error != null ? ' | $error' : ''}');
      if (stack != null) debugPrint('$stack');
    }
  }
}
