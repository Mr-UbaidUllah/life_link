import 'package:geolocator/geolocator.dart';

import 'package:blood_donation/utils/app_logger.dart';

/// Thin wrapper around geolocator that handles permission flow defensively and
/// never throws to callers — every failure mode resolves to `null` so the UI
/// can simply skip distance features when location is unavailable.
class LocationService {
  // Process-wide cache + in-flight de-duplication. Multiple screens (Home and
  // the Requests feed both build at once inside the IndexedStack) call this on
  // startup; without dedup that fires two concurrent permission requests and
  // Android rejects the second ("can request only one set of permissions at a
  // time"). Sharing one future means a single prompt and one cached result.
  static Position? _cached;
  static Future<Position?>? _inFlight;

  /// Returns the device's current position, or `null` if location services are
  /// off, permission is denied, or the platform doesn't support it. The result
  /// is cached; pass [forceRefresh] to re-query.
  static Future<Position?> getCurrentPosition({bool forceRefresh = false}) {
    if (_cached != null && !forceRefresh) return Future.value(_cached);
    if (_inFlight != null) return _inFlight!;

    final future = _resolvePosition().then((pos) {
      _cached = pos;
      _inFlight = null;
      return pos;
    });
    _inFlight = future;
    return future;
  }

  static Future<Position?> _resolvePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (e) {
      AppLogger.e('LocationService.getCurrentPosition failed', e);
      return null;
    }
  }

  /// Straight-line distance in kilometres between two coordinate pairs.
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }
}
