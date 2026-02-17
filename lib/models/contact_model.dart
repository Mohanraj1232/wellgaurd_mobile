import 'package:json_annotation/json_annotation.dart';

part 'contact_model.g.dart';

@JsonSerializable()
class Contact {
  final String name;
  final String SmsNumber;
  final String? whatsappNumber;

  Contact({
    required this.name,
    required this.SmsNumber,
    this.whatsappNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'SmsNumber': SmsNumber,
      'whatsappNumber': whatsappNumber,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] ?? '',
      SmsNumber: map['SmsNumber'] ?? '',
      whatsappNumber: map['whatsappNumber'],
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  Map<String, dynamic> toJson() => _$ContactToJson(this);

  @override
  String toString() => 'Contact(name: $name, SmsNumber: $SmsNumber, whatsappNumber: $whatsappNumber)';
}
