class Contact {
  final String name;
  final String number;

  Contact({
    required this.name,
    required this.number,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] ?? '',
      number: map['number'] ?? '',
    );
  }

  @override
  String toString() => 'Contact(name: $name, number: $number)';
}
