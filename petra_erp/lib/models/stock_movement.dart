import 'package:flutter/foundation.dart';

/// Movimentação de estoque de um material.
/// [quantity] é sempre positivo; [type] define o sinal aplicado ao estoque.
@immutable
class StockMovement {
  static const typeEntrada = 'entrada';
  static const typeSaida = 'saida';
  static const typeAjuste = 'ajuste';

  final String id;
  final String productId;
  final String? productName; // from products join
  final String type; // entrada | saida | ajuste
  final double quantity; // sempre positivo
  final String? reason;
  final String? orderId;
  final String? createdBy;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantity,
    this.reason,
    this.orderId,
    this.createdBy,
    required this.createdAt,
  });

  StockMovement copyWith({
    String? id,
    String? productId,
    String? productName,
    String? type,
    double? quantity,
    String? reason,
    String? orderId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      orderId: orderId ?? this.orderId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'order_id': orderId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map, {String? productName}) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: productName ??
          (map['products'] != null ? map['products']['name'] as String? : null),
      type: map['type'] as String? ?? typeEntrada,
      quantity: (map['quantity'] as num? ?? 0.0).toDouble(),
      reason: map['reason'] as String?,
      orderId: map['order_id'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockMovement &&
        other.id == id &&
        other.productId == productId &&
        other.productName == productName &&
        other.type == type &&
        other.quantity == quantity &&
        other.reason == reason &&
        other.orderId == orderId &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
      id, productId, productName, type, quantity, reason, orderId, createdBy, createdAt);

  @override
  String toString() => 'StockMovement(id: $id, type: $type, qty: $quantity, product: $productId)';
}
