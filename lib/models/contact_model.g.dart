// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
      name: json['name'] as String,
      smsNumber: json['smsNumber'] as String,
      whatsappNumber: json['whatsappNumber'] as String?,
    );

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
      'name': instance.name,
      'smsNumber': instance.smsNumber,
      'whatsappNumber': instance.whatsappNumber,
    };
