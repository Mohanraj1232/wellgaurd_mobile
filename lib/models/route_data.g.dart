// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteData _$RouteDataFromJson(Map<String, dynamic> json) => RouteData(
      routeId: json['routeId'] as String,
      safetyScore: (json['safetyScore'] as num).toInt(),
      safetyBreakdown: json['safetyBreakdown'] as Map<String, dynamic>?,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      expectedArrivalTime: json['expectedArrivalTime'] as String,
      riskLevel: json['riskLevel'] as String,
      polyline: json['polyline'] as String,
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => RouteStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      roadsUsed: (json['roadsUsed'] as List<dynamic>?)
          ?.map((e) => RoadInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RouteDataToJson(RouteData instance) => <String, dynamic>{
      'routeId': instance.routeId,
      'safetyScore': instance.safetyScore,
      'safetyBreakdown': instance.safetyBreakdown,
      'distance': instance.distance,
      'duration': instance.duration,
      'expectedArrivalTime': instance.expectedArrivalTime,
      'riskLevel': instance.riskLevel,
      'polyline': instance.polyline,
      'steps': instance.steps,
      'roadsUsed': instance.roadsUsed,
    };

RouteStep _$RouteStepFromJson(Map<String, dynamic> json) => RouteStep(
      instruction: json['instruction'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      maneuver: json['maneuver'] as String?,
    );

Map<String, dynamic> _$RouteStepToJson(RouteStep instance) => <String, dynamic>{
      'instruction': instance.instruction,
      'distance': instance.distance,
      'duration': instance.duration,
      'maneuver': instance.maneuver,
    };

RoadInfo _$RoadInfoFromJson(Map<String, dynamic> json) => RoadInfo(
      name: json['name'] as String,
      quality: (json['quality'] as num?)?.toDouble(),
      lighting: (json['lighting'] as num?)?.toDouble(),
      crimeRate: (json['crimeRate'] as num?)?.toDouble(),
      safetyScore: (json['safetyScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RoadInfoToJson(RoadInfo instance) => <String, dynamic>{
      'name': instance.name,
      'quality': instance.quality,
      'lighting': instance.lighting,
      'crimeRate': instance.crimeRate,
      'safetyScore': instance.safetyScore,
    };

LocationUpdateResponse _$LocationUpdateResponseFromJson(
        Map<String, dynamic> json) =>
    LocationUpdateResponse(
      status: json['status'] as String,
      distanceToDestination:
          (json['distanceToDestination'] as num?)?.toDouble(),
      minutesRemaining: (json['minutesRemaining'] as num?)?.toInt(),
      sosTriggered: json['sosTriggered'] as bool?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$LocationUpdateResponseToJson(
        LocationUpdateResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'distanceToDestination': instance.distanceToDestination,
      'minutesRemaining': instance.minutesRemaining,
      'sosTriggered': instance.sosTriggered,
      'message': instance.message,
    };

SOSResponse _$SOSResponseFromJson(Map<String, dynamic> json) => SOSResponse(
      message: json['message'] as String,
      notificationsSent: (json['notificationsSent'] as num).toInt(),
      successfulNotifications: (json['successfulNotifications'] as num).toInt(),
    );

Map<String, dynamic> _$SOSResponseToJson(SOSResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'notificationsSent': instance.notificationsSent,
      'successfulNotifications': instance.successfulNotifications,
    };
