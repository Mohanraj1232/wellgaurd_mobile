// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grievance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Department _$DepartmentFromJson(Map<String, dynamic> json) => Department(
      id: json['_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$DepartmentToJson(Department instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

DepartmentDropdown _$DepartmentDropdownFromJson(Map<String, dynamic> json) =>
    DepartmentDropdown(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DepartmentDropdownToJson(DepartmentDropdown instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

Map<String, dynamic> _$GrievanceToJson(Grievance instance) => <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'departmentId': instance.departmentId,
      'title': instance.title,
      'description': instance.description,
      'image': instance.image,
      'status': instance.status,
      'resolution': instance.resolution,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

GrievanceRequest _$GrievanceRequestFromJson(Map<String, dynamic> json) =>
    GrievanceRequest(
      title: json['title'] as String,
      description: json['description'] as String,
      departmentId: json['departmentId'] as String,
    );

Map<String, dynamic> _$GrievanceRequestToJson(GrievanceRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'departmentId': instance.departmentId,
    };
