import 'package:json_annotation/json_annotation.dart';

part 'route_data.g.dart';

@JsonSerializable()
class RouteData {
  final String routeId;
  final int safetyScore;
  final Map<String, dynamic>? safetyBreakdown;
  final double distance;
  final double duration;
  final String expectedArrivalTime;
  final String riskLevel;
  final String polyline;
  final List<RouteStep>? steps;
  final List<RoadInfo>? roadsUsed;

  RouteData({
    required this.routeId,
    required this.safetyScore,
    this.safetyBreakdown,
    required this.distance,
    required this.duration,
    required this.expectedArrivalTime,
    required this.riskLevel,
    required this.polyline,
    this.steps,
    this.roadsUsed,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) =>
      _$RouteDataFromJson(json);

  Map<String, dynamic> toJson() => _$RouteDataToJson(this);
}

@JsonSerializable()
class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String? maneuver;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) =>
      _$RouteStepFromJson(json);

  Map<String, dynamic> toJson() => _$RouteStepToJson(this);
}

@JsonSerializable()
class RoadInfo {
  final String name;
  final double? quality;
  final double? lighting;
  final double? crimeRate;
  final double? safetyScore;

  RoadInfo({
    required this.name,
    this.quality,
    this.lighting,
    this.crimeRate,
    this.safetyScore,
  });

  factory RoadInfo.fromJson(Map<String, dynamic> json) =>
      _$RoadInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RoadInfoToJson(this);
}

@JsonSerializable()
class LocationUpdateResponse {
  final String status;
  final double? distanceToDestination;
  final int? minutesRemaining;
  final bool? sosTriggered;
  final String? message;

  LocationUpdateResponse({
    required this.status,
    this.distanceToDestination,
    this.minutesRemaining,
    this.sosTriggered,
    this.message,
  });

  factory LocationUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationUpdateResponseToJson(this);
}

@JsonSerializable()
class SOSResponse {
  final String message;
  final int notificationsSent;
  final int successfulNotifications;

  SOSResponse({
    required this.message,
    required this.notificationsSent,
    required this.successfulNotifications,
  });

  factory SOSResponse.fromJson(Map<String, dynamic> json) =>
      _$SOSResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SOSResponseToJson(this);
}
