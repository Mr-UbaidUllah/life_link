import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // Nullable (not `late`) so dispose() can't throw a LateInitializationError if
  // the subscription was never assigned (e.g. an early failure).
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkProvider() {
    _checkInitialConnection();
    _subscribeToConnectivityChanges();
  }

  Future<void> _checkInitialConnection() async {
    try {
      final List<ConnectivityResult> result =
          await Connectivity().checkConnectivity();
      _updateState(result);
    } catch (_) {
      // checkConnectivity can throw on some platforms; assume online until the
      // change stream tells us otherwise rather than crashing on startup.
    }
  }

  void _subscribeToConnectivityChanges() {
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateState(results);
    });
  }

  void _updateState(List<ConnectivityResult> results) {
    // If results contains none, it means there's no internet connection.
    // In connectivity_plus 6.0.0+, it returns a List<ConnectivityResult>.
    final bool offline = results.contains(ConnectivityResult.none);
    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
