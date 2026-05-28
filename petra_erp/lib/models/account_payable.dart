import 'package:flutter/foundation.dart';

@immutable
class AccountPayable {
  final String id;
  final String supplierId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final double? paidAmount;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountPayable({
    required this.id,
    required this.supplierId,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    this.paidAmount,
    this.category,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => paidAt != null;

  AccountPayable copyWith({
    String? id,
    String? supplierId,
    String? description,
    double? amount,
    DateTime? dueDate,
    DateTime? paidAt,
    double? paidAmount,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountPayable(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      paidAmount: paidAmount ?? this.paidAmount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'description': description,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'paid_amount': paidAmount,
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AccountPayable.fromMap(Map<String, dynamic> map) {
    return AccountPayable(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      paidAmount: map['paid_amount'] != null ? (map['paid_amount'] as num).toDouble() : null,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountPayable &&
        other.id == id &&
        other.supplierId == supplierId &&
        other.description == description &&
        other.amount == amount &&
        other.dueDate == dueDate &&
        other.paidAt == paidAt &&
        other.paidAmount == paidAmount &&
        other.category == category &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, supplierId, description, amount, dueDate, paidAt, paidAmount, category, notes, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'AccountPayable(id: $id, description: $description, amount: $amount, isPaid: $isPaid)';
  }
}
