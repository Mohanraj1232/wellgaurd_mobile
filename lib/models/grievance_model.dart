import 'package:json_annotation/json_annotation.dart';

part 'grievance_model.g.dart';

@JsonSerializable()
class Department {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  final String? email;

  Department({
    this.id,
    required this.name,
    this.email,
  });

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentToJson(this);
}

@JsonSerializable()
class DepartmentDropdown {
  final String id;
  final String name;

  DepartmentDropdown({
    required this.id,
    required this.name,
  });

  factory DepartmentDropdown.fromJson(Map<String, dynamic> json) =>
      _$DepartmentDropdownFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentDropdownToJson(this);
}

@JsonSerializable()
class Grievance {
  @JsonKey(name: '_id')
  final String? id;
  final String? userId;
  final dynamic departmentId; // Can be String or Department object
  final String title;
  final String description;
  final String? image;
  final String status;
  final String? resolution;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Grievance({
    this.id,
    this.userId,
    this.departmentId,
    required this.title,
    required this.description,
    this.image,
    this.status = 'submitted',
    this.resolution,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      id: json['_id'] as String?,
      userId: json['userId'] is Map 
          ? json['userId']['_id']?.toString() 
          : json['userId']?.toString(),
      departmentId: json['departmentId'],
      title: json['title'] as String,
      description: json['description'] as String,
      image: json['image'] as String?,
      status: json['status'] as String? ?? 'submitted',
      resolution: json['resolution'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$GrievanceToJson(this);

  String get departmentName {
    if (departmentId is Map) {
      return (departmentId as Map)['name'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  String get statusDisplay {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'inprogress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}

@JsonSerializable()
class GrievanceRequest {
  final String title;
  final String description;
  final String departmentId;

  GrievanceRequest({
    required this.title,
    required this.description,
    required this.departmentId,
  });

  factory GrievanceRequest.fromJson(Map<String, dynamic> json) =>
      _$GrievanceRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GrievanceRequestToJson(this);
}

@JsonSerializable()
class StatusSummary {
  final int submitted;
  final int inprogress;
  final int completed;
  final int total;

  StatusSummary({
    required this.submitted,
    required this.inprogress,
    required this.completed,
    required this.total,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) =>
      _$StatusSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$StatusSummaryToJson(this);
}

class UserGrievanceResponse {
  final List<Grievance> grievances;
  final StatusSummary statusSummary;

  UserGrievanceResponse({
    required this.grievances,
    required this.statusSummary,
  });

  factory UserGrievanceResponse.fromJson(Map<String, dynamic> json) {
    return UserGrievanceResponse(
      grievances: (json['grievances'] as List)
          .map((item) => Grievance.fromJson(item as Map<String, dynamic>))
          .toList(),
      statusSummary: StatusSummary.fromJson(
          json['statusSummary'] as Map<String, dynamic>),
    );
  }
}
