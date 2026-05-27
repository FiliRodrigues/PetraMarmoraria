import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final String type; // 'marmore', 'granito', 'quartzo', 'ardosia', 'outro'
  final double unitPrice;
  final String unit; // 'm2', 'unidade', 'ml'
  final bool active;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    this.type = 'marmore',
    this.unitPrice = 0.0,
    this.unit = 'm2',
    this.active = true,
    required this.createdAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? type,
    double? unitPrice,
    String? unit,
    bool? active,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'unit_price': unitPrice,
      'unit': unit,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'marmore',
      unitPrice: (map['unit_price'] as num? ?? 0.0).toDouble(),
      unit: map['unit'] as String? ?? 'm2',
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.unitPrice == unitPrice &&
        other.unit == unit &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, unitPrice, unit, active, createdAt);
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, type: $type, unitPrice: $unitPrice, unit: $unit)';
  }
}
