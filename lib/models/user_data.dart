import 'package:json_annotation/json_annotation.dart';

part 'user_data.g.dart';

@JsonSerializable()
class UserData {
  final int? userId;
  final int? id;
  final String? name;
  final String? email;
  final List<EmergencyContact>? emergencyContact;

  UserData({
    this.userId,
    this.id,
    this.name,
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
  final String? whatsappNumber;
  final String? smsNumber;

  EmergencyContact({
    required this.name,
    this.whatsappNumber,
    this.smsNumber,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      whatsappNumber: json['whatsappNumber']?.toString(),
      smsNumber: json['phoneNumber']?.toString() ?? json['smsNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$EmergencyContactToJson(this);
}
