import 'package:flutter/foundation.dart';

/// Categoria financeira: organiza despesas e receitas.
@immutable
class FinancialCategory {
  final String id;
  final String name;
  final String type; // 'expense' | 'income'
  final String? parentId;
  final bool active;
  final DateTime createdAt;

  const FinancialCategory({
    required this.id,
    required this.name,
    this.type = 'expense',
    this.parentId,
    this.active = true,
    required this.createdAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  FinancialCategory copyWith({
    String? id,
    String? name,
    String? type,
    String? parentId,
    bool? active,
    DateTime? createdAt,
  }) {
    return FinancialCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FinancialCategory.fromMap(Map<String, dynamic> map) {
    return FinancialCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      parentId: map['parent_id'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialCategory &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.parentId == parentId &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, type, parentId, active, createdAt);

  @override
  String toString() =>
      'FinancialCategory(id: $id, name: $name, type: $type, active: $active)';
}
