import 'package:flutter/foundation.dart';
import '../core/constants/payment_constants.dart';

/// Pagamento/parcela vinculado a uma Ordem de Serviço.
@immutable
class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String method; // dinheiro | pix | cartao | boleto | transferencia
  final String status; // pendente | pago
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  // Joins opcionais (de service_orders).
  final int? orderNumber;
  final String? customerName;
  final double? orderTotal;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    this.method = PaymentConstants.dinheiro,
    this.status = PaymentConstants.pendente,
    this.dueDate,
    this.paidAt,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.orderNumber,
    this.customerName,
    this.orderTotal,
  });

  bool get isPaid => status == PaymentConstants.pago;

  bool get isOverdue {
    if (isPaid || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return d.isBefore(today);
  }

  Payment copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? method,
    String? status,
    DateTime? dueDate,
    DateTime? paidAt,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    int? orderNumber,
    String? customerName,
    double? orderTotal,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      orderTotal: orderTotal ?? this.orderTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'method': method,
      'status': status,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    final order = map['service_orders'] as Map<String, dynamic>?;
    final customer = order != null ? order['customers'] as Map<String, dynamic>? : null;
    return Payment(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      method: map['method'] as String? ?? PaymentConstants.dinheiro,
      status: map['status'] as String? ?? PaymentConstants.pendente,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      orderNumber: order?['display_number'] as int?,
      orderTotal: order != null ? (order['total_value'] as num?)?.toDouble() : null,
      customerName: customer?['name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment &&
        other.id == id &&
        other.orderId == orderId &&
        other.amount == amount &&
        other.method == method &&
        other.status == status &&
        other.dueDate == dueDate &&
        other.paidAt == paidAt &&
        other.notes == notes &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
      id, orderId, amount, method, status, dueDate, paidAt, notes, createdBy, createdAt);

  @override
  String toString() => 'Payment(id: $id, amount: $amount, status: $status, order: $orderId)';
}
