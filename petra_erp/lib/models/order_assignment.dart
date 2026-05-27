import 'package:flutter/foundation.dart';

@immutable
class OrderAssignment {
  final String id;
  final String orderId;
  final String stage; // 'corte', 'montagem', 'entrega'
  final String employeeId;
  final String? employeeName; // joined from profile
  final DateTime assignedAt;
  final DateTime? completedAt;
  final String? notes;

  const OrderAssignment({
    required this.id,
    required this.orderId,
    required this.stage,
    required this.employeeId,
    this.employeeName,
    required this.assignedAt,
    this.completedAt,
    this.notes,
  });

  OrderAssignment copyWith({
    String? id,
    String? orderId,
    String? stage,
    String? employeeId,
    String? employeeName,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return OrderAssignment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      stage: stage ?? this.stage,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'stage': stage,
      'employee_id': employeeId,
      'assigned_at': assignedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory OrderAssignment.fromMap(Map<String, dynamic> map, {String? employeeName}) {
    return OrderAssignment(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      stage: map['stage'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: employeeName ?? map['employeeName'] as String? ?? (map['profiles'] != null ? map['profiles']['name'] as String? : null),
      assignedAt: DateTime.parse(map['assigned_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderAssignment &&
        other.id == id &&
        other.orderId == orderId &&
        other.stage == stage &&
        other.employeeId == employeeId &&
        other.employeeName == employeeName &&
        other.assignedAt == assignedAt &&
        other.completedAt == completedAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, orderId, stage, employeeId, employeeName, assignedAt, completedAt, notes);
  }

  @override
  String toString() {
    return 'OrderAssignment(id: $id, stage: $stage, employee: $employeeName, order: $orderId)';
  }
}
