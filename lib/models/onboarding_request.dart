import 'package:json_annotation/json_annotation.dart';

part 'onboarding_request.g.dart';

@JsonSerializable()
class OnboardingRequest {
  final int userId;
  final List<ContactData> contacts;

  OnboardingRequest({
    required this.userId,
    required this.contacts,
  });

  factory OnboardingRequest.fromJson(Map<String, dynamic> json) =>
      _$OnboardingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OnboardingRequestToJson(this);
}

@JsonSerializable()
class ContactData {
  final String name;
  final String SmsNumber;
  final String? whatsappNumber;

  ContactData({
    required this.name,
    required this.SmsNumber,
    this.whatsappNumber,
  });

  factory ContactData.fromJson(Map<String, dynamic> json) =>
      _$ContactDataFromJson(json);

  Map<String, dynamic> toJson() => _$ContactDataToJson(this);
}
