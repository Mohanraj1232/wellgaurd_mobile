// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnboardingRequest _$OnboardingRequestFromJson(Map<String, dynamic> json) =>
    OnboardingRequest(
      userId: (json['userId'] as num).toInt(),
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      contacts: (json['contacts'] as List<dynamic>)
          .map((e) => ContactData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OnboardingRequestToJson(OnboardingRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'contacts': instance.contacts,
    };

ContactData _$ContactDataFromJson(Map<String, dynamic> json) => ContactData(
      name: json['name'] as String,
      smsNumber: json['smsNumber'] as String,
      whatsappNumber: json['whatsappNumber'] as String?,
    );

Map<String, dynamic> _$ContactDataToJson(ContactData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'smsNumber': instance.smsNumber,
      'whatsappNumber': instance.whatsappNumber,
    };
