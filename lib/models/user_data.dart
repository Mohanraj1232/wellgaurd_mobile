import 'package:json_annotation/json_annotation.dart';

part 'user_data.g.dart';

@JsonSerializable()
class UserData {
  final int? userId;
  final int? id;
  final String? email;
  final List<EmergencyContact>? emergencyContact;

  UserData({
    this.userId,
    this.id,
    this.email,
    this.emergencyContact,
  });

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

@JsonSerializable()
class EmergencyContact {
  final String name;
  final String whatsappNumber;
  @JsonKey(name: 'phoneNumber')
  final String smsNumber;

  EmergencyContact({
    required this.name,
    required this.whatsappNumber,
    required this.smsNumber,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactToJson(this);
}
