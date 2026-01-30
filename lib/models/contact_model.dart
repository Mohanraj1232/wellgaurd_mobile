import 'package:json_annotation/json_annotation.dart';

part 'contact_model.g.dart';

@JsonSerializable()
class Contact {
  final String name;
  final String phoneNumber;
  final String? whatsappNumber;

  Contact({
    required this.name,
    required this.phoneNumber,
    this.whatsappNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      whatsappNumber: map['whatsappNumber'],
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  Map<String, dynamic> toJson() => _$ContactToJson(this);

  @override
  String toString() => 'Contact(name: $name, phoneNumber: $phoneNumber, whatsappNumber: $whatsappNumber)';
}
