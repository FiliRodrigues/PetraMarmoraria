import 'package:flutter/foundation.dart';

@immutable
class CompanyInfo {
  final int id;
  final String name;
  final String? cnpj;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final int defaultDeadlineDays;
  final int defaultPaymentTermsDays;
  final DateTime updatedAt;

  const CompanyInfo({
    this.id = 1,
    this.name = '',
    this.cnpj,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.defaultDeadlineDays = 15,
    this.defaultPaymentTermsDays = 30,
    required this.updatedAt,
  });

  CompanyInfo copyWith({
    int? id,
    String? name,
    String? cnpj,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    int? defaultDeadlineDays,
    int? defaultPaymentTermsDays,
    DateTime? updatedAt,
  }) {
    return CompanyInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      defaultDeadlineDays: defaultDeadlineDays ?? this.defaultDeadlineDays,
      defaultPaymentTermsDays: defaultPaymentTermsDays ?? this.defaultPaymentTermsDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'cnpj': cnpj,
    'address': address,
    'phone': phone,
    'email': email,
    'logo_url': logoUrl,
    'default_deadline_days': defaultDeadlineDays,
    'default_payment_terms_days': defaultPaymentTermsDays,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CompanyInfo.fromMap(Map<String, dynamic> map) => CompanyInfo(
    id: map['id'] as int? ?? 1,
    name: map['name'] as String? ?? '',
    cnpj: map['cnpj'] as String?,
    address: map['address'] as String?,
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    logoUrl: map['logo_url'] as String?,
    defaultDeadlineDays: map['default_deadline_days'] as int? ?? 15,
    defaultPaymentTermsDays: map['default_payment_terms_days'] as int? ?? 30,
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'] as String)
        : DateTime.now(),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyInfo &&
        other.id == id &&
        other.name == name &&
        other.cnpj == cnpj &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.logoUrl == logoUrl &&
        other.defaultDeadlineDays == defaultDeadlineDays &&
        other.defaultPaymentTermsDays == defaultPaymentTermsDays &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, cnpj, address, phone, email, logoUrl,
        defaultDeadlineDays, defaultPaymentTermsDays, updatedAt);
  }

  @override
  String toString() {
    return 'CompanyInfo(id: $id, name: $name)';
  }
}
