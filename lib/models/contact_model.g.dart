// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
      name: json['name'] as String,
      SmsNumber: json['SmsNumber'] as String,
      whatsappNumber: json['whatsappNumber'] as String?,
    );

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
      'name': instance.name,
      'SmsNumber': instance.SmsNumber,
      'whatsappNumber': instance.whatsappNumber,
    };
