import 'package:flutter/foundation.dart';

@immutable
class Customer {
  final String id;
  final String name;
  final String? cpfCnpj;
  final String phone;
  final String? phone2;
  final String? email;
  final String? address;
  final String? city;
  final String state;
  final String? notes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.cpfCnpj,
    required this.phone,
    this.phone2,
    this.email,
    this.address,
    this.city,
    this.state = 'SP',
    this.notes,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? cpfCnpj,
    String? phone,
    String? phone2,
    String? email,
    String? address,
    String? city,
    String? state,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cpf_cnpj': cpfCnpj,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      cpfCnpj: map['cpf_cnpj'] as String?,
      phone: map['phone'] as String? ?? '',
      phone2: map['phone2'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String? ?? 'SP',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.cpfCnpj == cpfCnpj &&
        other.phone == phone &&
        other.phone2 == phone2 &&
        other.email == email &&
        other.address == address &&
        other.city == city &&
        other.state == state &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, cpfCnpj, phone, phone2, email, address, city, state, notes, createdAt);
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone)';
  }
}
