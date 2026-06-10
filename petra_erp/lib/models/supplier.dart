import 'package:flutter/foundation.dart';

/// Fornecedor — entidade que fornece materiais, serviços ou insumos.
///
/// Usado pela tab de fornecedores e vinculado a despesas via [Expense.supplierId].
@immutable
class Supplier {
  final String id;
  final String name;
  final String? cnpj;
  final String phone;
  final String? phone2;
  final String? email;
  final String? contactPerson;
  final String? address;
  final String? city;
  final String? state;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.cnpj,
    required this.phone,
    this.phone2,
    this.email,
    this.contactPerson,
    this.address,
    this.city,
    this.state,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  static const List<String> states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'contact_person': contactPerson,
      'address': address,
      'city': city,
      'state': state,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      cnpj: map['cnpj'] as String?,
      phone: map['phone'] as String? ?? '',
      phone2: map['phone2'] as String?,
      email: map['email'] as String?,
      contactPerson: map['contact_person'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? phone,
    String? phone2,
    String? email,
    String? contactPerson,
    String? address,
    String? city,
    String? state,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Supplier(id: $id, name: $name, phone: $phone)';
}
