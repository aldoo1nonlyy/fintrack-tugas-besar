class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? email;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? email,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }
}
