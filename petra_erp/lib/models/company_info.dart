import 'package:flutter/foundation.dart';

@immutable
class CompanyInfo {
  final String name;
  final String? cnpj;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final int defaultDeadlineDays;
  final int defaultPaymentTermsDays;

  const CompanyInfo({
    this.name = '',
    this.cnpj,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.defaultDeadlineDays = 15,
    this.defaultPaymentTermsDays = 30,
  });

  CompanyInfo copyWith({
    String? name,
    String? cnpj,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    int? defaultDeadlineDays,
    int? defaultPaymentTermsDays,
  }) {
    return CompanyInfo(
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      defaultDeadlineDays: defaultDeadlineDays ?? this.defaultDeadlineDays,
      defaultPaymentTermsDays: defaultPaymentTermsDays ?? this.defaultPaymentTermsDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cnpj': cnpj,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'default_deadline_days': defaultDeadlineDays,
      'default_payment_terms_days': defaultPaymentTermsDays,
    };
  }

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] as String? ?? '',
      cnpj: map['cnpj'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      logoUrl: map['logo_url'] as String?,
      defaultDeadlineDays: (map['default_deadline_days'] as num?)?.toInt() ?? 15,
      defaultPaymentTermsDays: (map['default_payment_terms_days'] as num?)?.toInt() ?? 30,
    );
  }
}
