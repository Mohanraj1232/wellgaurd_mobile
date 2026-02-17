// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      image: json['image'] as String?,
      locality: json['locality'] as String,
      isActive: json['isActive'] as bool,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'image': instance.image,
      'locality': instance.locality,
      'isActive': instance.isActive,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
