import 'package:flutter/material.dart';
import 'package:wellguard_ai/models/route_data.dart';

enum JourneyStatus { idle, active, completed, sosTriggered, cancelled }

class JourneyProvider with ChangeNotifier {
  // Route data
  String? _routeId;
  int _safetyScore = 0;
  String _riskLevel = "";
  double _distanceRemaining = 0;
  int _minutesRemaining = 0;
  bool _sosTriggered = false;
  JourneyStatus _status = JourneyStatus.idle;
  RouteData? _routeData;
  
  // Current location
  double? _currentLatitude;
  double? _currentLongitude;
  
  // Destination
  String? _destination;
  int? _timeLimit;
  
  // Getters
  String? get routeId => _routeId;
  int get safetyScore => _safetyScore;
  String get riskLevel => _riskLevel;
  double get distanceRemaining => _distanceRemaining;
  int get minutesRemaining => _minutesRemaining;
  bool get sosTriggered => _sosTriggered;
  JourneyStatus get status => _status;
  RouteData? get routeData => _routeData;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get destination => _destination;
  int? get timeLimit => _timeLimit;
  
  // Get formatted distance
  String get formattedDistance {
    if (_distanceRemaining >= 1000) {
      return '${(_distanceRemaining / 1000).toStringAsFixed(1)} km';
    }
    return '${_distanceRemaining.toInt()} m';
  }
  
  // Get safety color
  Color get safetyColor {
    if (_safetyScore >= 60) return Colors.green;
    if (_safetyScore >= 40) return Colors.orange;
    return Colors.red;
  }
  
  // Get risk text
  String get riskText {
    switch (_riskLevel.toLowerCase()) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      default:
        return _riskLevel;
    }
  }
  
  // Set current location
  void setCurrentLocation(double latitude, double longitude) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    notifyListeners();
  }
  
  // Set destination info
  void setDestinationInfo(String destination, int timeLimit) {
    _destination = destination;
    _timeLimit = timeLimit;
    notifyListeners();
  }
  
  // Initialize route from API response
  void initializeRoute(RouteData routeData) {
    _routeId = routeData.routeId;
    _safetyScore = routeData.safetyScore;
    _riskLevel = routeData.riskLevel;
    _distanceRemaining = routeData.distance;
    _minutesRemaining = (routeData.duration / 60).ceil();
    _routeData = routeData;
    _status = JourneyStatus.active;
    _sosTriggered = false;
    notifyListeners();
  }
  
  // Update from location update API response
  void updateFromLocationResponse(LocationUpdateResponse response) {
    if (response.distanceToDestination != null) {
      _distanceRemaining = response.distanceToDestination!;
    }
    if (response.minutesRemaining != null) {
      _minutesRemaining = response.minutesRemaining!;
    }
    
    switch (response.status.toLowerCase()) {
      case 'completed':
        _status = JourneyStatus.completed;
        break;
      case 'active':
        _status = JourneyStatus.active;
        break;
      case 'sos_triggered':
        _status = JourneyStatus.sosTriggered;
        _sosTriggered = true;
        break;
    }
    
    if (response.sosTriggered == true) {
      _sosTriggered = true;
      _status = JourneyStatus.sosTriggered;
    }
    
    notifyListeners();
  }
  
  // Trigger SOS
  void triggerSOS() {
    _sosTriggered = true;
    _status = JourneyStatus.sosTriggered;
    notifyListeners();
  }
  
  // Cancel journey
  void cancelJourney() {
    _status = JourneyStatus.cancelled;
    notifyListeners();
  }
  
  // Complete journey
  void completeJourney() {
    _status = JourneyStatus.completed;
    notifyListeners();
  }
  
  // Reset journey state
  void reset() {
    _routeId = null;
    _safetyScore = 0;
    _riskLevel = "";
    _distanceRemaining = 0;
    _minutesRemaining = 0;
    _sosTriggered = false;
    _status = JourneyStatus.idle;
    _routeData = null;
    _destination = null;
    _timeLimit = null;
    notifyListeners();
  }
}
