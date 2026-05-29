import 'package:flutter/foundation.dart';
import '../core/constants/os_status.dart';

@immutable
class ServiceOrder {
  final String id;
  final int displayNumber;
  final String customerId;
  final String? customerName; // From customer join
  final String description;
  final String status; // orcamento, aprovado, recebido, esperando_material, corte, montagem, entrega
  final int queuePosition;
  final String? material;
  final String? edgeType;
  final Map<String, dynamic> measurements;
  final String? drawingUrl;
  final double totalValue;
  final DateTime statusChangedAt;
  final DateTime? scheduledDate;
  final String? createdBy; // Vendedor responsável (profiles.id)
  final String? createdByName; // From creator join (profiles.name)
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceOrder({
    required this.id,
    required this.displayNumber,
    required this.customerId,
    this.customerName,
    required this.description,
    this.status = OSStatus.orcamento,
    this.queuePosition = 0,
    this.material,
    this.edgeType,
    this.measurements = const {},
    this.drawingUrl,
    this.totalValue = 0.0,
    required this.statusChangedAt,
    this.scheduledDate,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helpers for time/delay logic
  bool get isDelayed {
    if (status == OSStatus.entrega) return false;
    return daysStale > 5;
  }

  bool get isWarning {
    if (status == OSStatus.entrega) return false;
    final stale = daysStale;
    return stale > 3 && stale <= 5;
  }

  int get daysStale {
    final now = DateTime.now();
    return now.difference(statusChangedAt).inDays;
  }

  /// OS entregue há 7+ dias: sai do Kanban mas permanece no banco/relatórios.
  bool get isArchived =>
      status == OSStatus.entrega &&
      DateTime.now().difference(statusChangedAt).inDays >= 7;

  String get statusLabel {
    return OSStatus.labels[status] ?? status;
  }

  String get formattedNumber {
    return '#${displayNumber.toString().padLeft(4, '0')}';
  }

  ServiceOrder copyWith({
    String? id,
    int? displayNumber,
    String? customerId,
    String? customerName,
    String? description,
    String? status,
    int? queuePosition,
    String? material,
    String? edgeType,
    Map<String, dynamic>? measurements,
    String? drawingUrl,
    double? totalValue,
    DateTime? statusChangedAt,
    DateTime? scheduledDate,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      displayNumber: displayNumber ?? this.displayNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      description: description ?? this.description,
      status: status ?? this.status,
      queuePosition: queuePosition ?? this.queuePosition,
      material: material ?? this.material,
      edgeType: edgeType ?? this.edgeType,
      measurements: measurements ?? this.measurements,
      drawingUrl: drawingUrl ?? this.drawingUrl,
      totalValue: totalValue ?? this.totalValue,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_number': displayNumber,
      'customer_id': customerId,
      'description': description,
      'status': status,
      'queue_position': queuePosition,
      'material': material,
      'edge_type': edgeType,
      'measurements': measurements,
      'drawing_url': drawingUrl,
      'total_value': totalValue,
      'status_changed_at': statusChangedAt.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String().substring(0, 10), // date only
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ServiceOrder.fromMap(Map<String, dynamic> map, {String? customerName, String? createdByName}) {
    return ServiceOrder(
      id: map['id'] as String,
      displayNumber: map['display_number'] as int? ?? 0,
      customerId: map['customer_id'] as String,
      customerName: customerName ?? map['customerName'] as String? ?? (map['customers'] != null ? map['customers']['name'] as String? : null),
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? OSStatus.orcamento,
      queuePosition: map['queue_position'] as int? ?? 0,
      material: map['material'] as String?,
      edgeType: map['edge_type'] as String?,
      measurements: map['measurements'] as Map<String, dynamic>? ?? const {},
      drawingUrl: map['drawing_url'] as String?,
      totalValue: (map['total_value'] as num? ?? 0.0).toDouble(),
      statusChangedAt: map['status_changed_at'] != null 
          ? DateTime.parse(map['status_changed_at'] as String)
          : DateTime.now(),
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.parse(map['scheduled_date'] as String)
          : null,
      createdBy: map['created_by'] as String?,
      createdByName: createdByName ??
          (map['creator'] != null ? map['creator']['name'] as String? : null),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceOrder &&
        other.id == id &&
        other.displayNumber == displayNumber &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.description == description &&
        other.status == status &&
        other.queuePosition == queuePosition &&
        other.material == material &&
        other.edgeType == edgeType &&
        mapEquals(other.measurements, measurements) &&
        other.drawingUrl == drawingUrl &&
        other.totalValue == totalValue &&
        other.statusChangedAt == statusChangedAt &&
        other.scheduledDate == scheduledDate &&
        other.createdBy == createdBy &&
        other.createdByName == createdByName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      displayNumber,
      customerId,
      customerName,
      description,
      status,
      queuePosition,
      material,
      edgeType,
      Object.hashAll(measurements.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
      drawingUrl,
      totalValue,
      statusChangedAt,
      scheduledDate,
      createdBy,
      createdByName,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ServiceOrder(id: $id, number: $formattedNumber, status: $status, client: $customerName)';
  }
}
