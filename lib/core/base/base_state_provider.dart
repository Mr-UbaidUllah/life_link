import 'package:flutter/foundation.dart';

import 'package:blood_donation/utils/app_logger.dart';

/// Base class for every ChangeNotifier provider.
///
/// Centralizes the loading / error boilerplate that was hand-rolled (and
/// inconsistently) in ~14 providers. Use [runGuarded] to wrap an async action:
/// it flips [isLoading], catches errors into [errorMessage], and notifies
/// listeners at the right moments.
abstract class BaseStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  bool _disposed = false;

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    _safeNotify();
  }

  void setError(String? message) {
    _errorMessage = message;
    _safeNotify();
  }

  void clearError() => setError(null);

  /// Runs [action] with loading state + error capture. Returns the action's
  /// result, or `null` if it threw (the error is stored in [errorMessage]).
  Future<R?> runGuarded<R>(
    Future<R> Function() action, {
    String? errorContext,
  }) async {
    _errorMessage = null;
    setLoading(true);
    try {
      return await action();
    } catch (e, st) {
      AppLogger.e(errorContext ?? 'Provider action failed', e, st);
      setError(_friendlyMessage(e));
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Override to map raw exceptions to user-facing copy. Default returns a
  /// generic message so we never surface stack traces / Firebase codes to users.
  String _friendlyMessage(Object error) =>
      'Something went wrong. Please try again.';

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
