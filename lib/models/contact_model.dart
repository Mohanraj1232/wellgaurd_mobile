class Contact {
  final String name;
  final String phoneNumber;
  final String whatsappNumber;

  Contact({
    required this.name,
    required this.phoneNumber,
    required this.whatsappNumber,
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
      whatsappNumber: map['whatsappNumber'] ?? '',
    );
  }

  @override
  String toString() => 'Contact(name: $name, phoneNumber: $phoneNumber, whatsappNumber: $whatsappNumber)';
}
