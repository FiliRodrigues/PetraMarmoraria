import 'package:flutter/foundation.dart';

/// Despesa ou receita financeira (expense).
///
/// Modelo para registros financeiros de entrada e saída,
/// usado por [ExpenseTile] e pelo [ExpenseService] no Supabase.
@immutable
class Expense {
  final String id;
  final String description;
  final String category;
  final String? categoryName; // nome amigável vindo do join financial_categories
  final String type; // receita | despesa
  final double amount;
  final String status; // pendente | pago
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? supplierId;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.description,
    required this.category,
    this.categoryName,
    this.type = 'despesa',
    required this.amount,
    this.status = 'pendente',
    this.dueDate,
    this.paidAt,
    this.supplierId,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  bool get isPaid => status == 'pago';

  bool get isOverdue {
    if (isPaid || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return d.isBefore(today);
  }

  /// Labels amigáveis para categorias comuns de despesa.
  static const Map<String, String> categoryLabels = {
    'material': 'Material',
    'ferramenta': 'Ferramenta',
    'servico': 'Serviço',
    'imposto': 'Imposto',
    'aluguel': 'Aluguel',
    'energia': 'Energia',
    'agua': 'Água',
    'internet': 'Internet',
    'transporte': 'Transporte',
    'outros': 'Outros',
    'venda': 'Venda',
    'servico_prestado': 'Serviço Prestado',
  };

  static String categoryLabel(String c) => categoryLabels[c] ?? c;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'type': type,
      'amount': amount,
      'status': status,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'paid_at': paidAt?.toIso8601String(),
      'supplier_id': supplierId,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final cat = map['financial_categories'] as Map<String, dynamic>?;
    return Expense(
      id: map['id'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'outros',
      categoryName: cat?['name'] as String?,
      type: map['type'] as String? ?? 'despesa',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pendente',
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      supplierId: map['supplier_id'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Expense copyWith({
    String? id,
    String? description,
    String? category,
    String? categoryName,
    String? type,
    double? amount,
    String? status,
    DateTime? dueDate,
    DateTime? paidAt,
    String? supplierId,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Expense(id: $id, description: $description, amount: $amount, status: $status)';
}
