import 'package:flutter/foundation.dart';

@immutable
class Supplier {
  final String id;
  final String name;
  final String? cpfCnpj;
  final String phone;
  final String? phone2;
  final String? email;
  final String? contactPerson;
  final String? address;
  final String? city;
  final String state;
  final String? notes;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.cpfCnpj,
    required this.phone,
    this.phone2,
    this.email,
    this.contactPerson,
    this.address,
    this.city,
    this.state = 'SP',
    this.notes,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? cpfCnpj,
    String? phone,
    String? phone2,
    String? email,
    String? contactPerson,
    String? address,
    String? city,
    String? state,
    String? notes,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'contact_person': contactPerson,
      'address': address,
      'city': city,
      'state': state,
      'notes': notes,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      cpfCnpj: map['cpf_cnpj'] as String?,
      phone: map['phone'] as String,
      phone2: map['phone2'] as String?,
      email: map['email'] as String?,
      contactPerson: map['contact_person'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String? ?? 'SP',
      notes: map['notes'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier &&
        other.id == id &&
        other.name == name &&
        other.cpfCnpj == cpfCnpj &&
        other.phone == phone &&
        other.phone2 == phone2 &&
        other.email == email &&
        other.contactPerson == contactPerson &&
        other.address == address &&
        other.city == city &&
        other.state == state &&
        other.notes == notes &&
        other.active == active &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, cpfCnpj, phone, phone2, email, contactPerson, address, city, state, notes, active, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, phone: $phone)';
  }
}
