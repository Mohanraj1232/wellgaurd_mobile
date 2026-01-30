import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  Future<LocationPermissionResult> requestLocationPermission() async {
    // First check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult(
        granted: false,
        message: 'Location services are disabled. Please enable GPS.',
      );
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionResult(
          granted: false,
          message: 'Location permission denied. Please grant location access.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult(
        granted: false,
        message: 'Location permission permanently denied. Please enable in settings.',
        permanentlyDenied: true,
      );
    }

    return LocationPermissionResult(granted: true);
  }

  /// Request background location permission
  Future<bool> requestBackgroundPermission() async {
    var status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final permissionResult = await requestLocationPermission();
      if (!permissionResult.granted) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get position stream for continuous tracking
  Stream<Position> getPositionStream({
    int intervalMs = 1000,
    int distanceFilter = 0,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculate distance between two points (in meters)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

class LocationPermissionResult {
  final bool granted;
  final String? message;
  final bool permanentlyDenied;

  LocationPermissionResult({
    required this.granted,
    this.message,
    this.permanentlyDenied = false,
  });
}
