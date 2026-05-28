import 'package:flutter/foundation.dart';

@immutable
class AccountReceivable {
  final String id;
  final String customerId;
  final String? serviceOrderId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime? receivedAt;
  final double? receivedAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountReceivable({
    required this.id,
    required this.customerId,
    this.serviceOrderId,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.receivedAt,
    this.receivedAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReceived => receivedAt != null;

  AccountReceivable copyWith({
    String? id,
    String? customerId,
    String? serviceOrderId,
    String? description,
    double? amount,
    DateTime? dueDate,
    DateTime? receivedAt,
    double? receivedAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountReceivable(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'service_order_id': serviceOrderId,
      'description': description,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'received_at': receivedAt?.toIso8601String(),
      'received_amount': receivedAmount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AccountReceivable.fromMap(Map<String, dynamic> map) {
    return AccountReceivable(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      serviceOrderId: map['service_order_id'] as String?,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      receivedAt: map['received_at'] != null ? DateTime.parse(map['received_at'] as String) : null,
      receivedAmount: map['received_amount'] != null ? (map['received_amount'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountReceivable &&
        other.id == id &&
        other.customerId == customerId &&
        other.serviceOrderId == serviceOrderId &&
        other.description == description &&
        other.amount == amount &&
        other.dueDate == dueDate &&
        other.receivedAt == receivedAt &&
        other.receivedAmount == receivedAmount &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, customerId, serviceOrderId, description, amount, dueDate, receivedAt, receivedAmount, notes, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'AccountReceivable(id: $id, description: $description, amount: $amount, isReceived: $isReceived)';
  }
}
