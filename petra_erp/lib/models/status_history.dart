import 'package:flutter/foundation.dart';

@immutable
class StatusHistory {
  final String id;
  final String orderId;
  final String? fromStatus;
  final String toStatus;
  final String changedBy;
  final String? changedByName; // joined from profile
  final DateTime changedAt;
  final String? notes;

  const StatusHistory({
    required this.id,
    required this.orderId,
    this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    this.changedByName,
    required this.changedAt,
    this.notes,
  });

  StatusHistory copyWith({
    String? id,
    String? orderId,
    String? fromStatus,
    String? toStatus,
    String? changedBy,
    String? changedByName,
    DateTime? changedAt,
    String? notes,
  }) {
    return StatusHistory(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      changedBy: changedBy ?? this.changedBy,
      changedByName: changedByName ?? this.changedByName,
      changedAt: changedAt ?? this.changedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'changed_by': changedBy,
      'changed_at': changedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory StatusHistory.fromMap(Map<String, dynamic> map, {String? changedByName}) {
    return StatusHistory(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      fromStatus: map['from_status'] as String?,
      toStatus: map['to_status'] as String,
      changedBy: map['changed_by'] as String,
      changedByName: changedByName ?? map['changedByName'] as String? ?? (map['profiles'] != null ? map['profiles']['name'] as String? : null),
      changedAt: map['changed_at'] != null
          ? DateTime.parse(map['changed_at'] as String)
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusHistory &&
        other.id == id &&
        other.orderId == orderId &&
        other.fromStatus == fromStatus &&
        other.toStatus == toStatus &&
        other.changedBy == changedBy &&
        other.changedByName == changedByName &&
        other.changedAt == changedAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, orderId, fromStatus, toStatus, changedBy, changedByName, changedAt, notes);
  }

  @override
  String toString() {
    return 'StatusHistory(id: $id, orderId: $orderId, from: $fromStatus, to: $toStatus, notes: $notes)';
  }
}
