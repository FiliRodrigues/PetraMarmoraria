import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_movement.dart';

class StockService {
  final SupabaseClient _client;

  StockService(this._client);

  /// Histórico de movimentações de um material (mais recentes primeiro).
  Future<List<StockMovement>> getMovements(String productId) async {
    try {
      final response = await _client
          .from('stock_movements')
          .select('*, products(name)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return (response as List).map((e) {
        final name = e['products'] != null ? e['products']['name'] as String? : null;
        return StockMovement.fromMap(e, productName: name);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Registra uma movimentação e atualiza products.stock_quantity.
  ///
  /// Tenta usar a função SQL `register_stock_movement` (atômica). Se ela não
  /// existir no banco, cai para leitura→escrita no cliente (não atômica):
  /// lê o estoque atual, calcula o novo valor e grava as duas operações.
  Future<void> registerMovement({
    required String productId,
    required String type, // entrada | saida | ajuste
    required double quantity,
    String? reason,
    String? orderId,
  }) async {
    final userId = _client.auth.currentUser?.id;

    // 1) Caminho preferido: função Postgres atômica (valida saldo e é transacional).
    try {
      await _client.rpc('register_stock_movement', params: {
        'p_product_id': productId,
        'p_type': type,
        'p_quantity': quantity,
        'p_reason': reason,
        'p_order_id': orderId,
        'p_created_by': userId,
      });
      return;
    } on PostgrestException catch (e) {
      // Só cai no fallback se a função não existir no banco (42883 / PGRST202).
      // Erros de negócio (ex.: estoque insuficiente) devem propagar.
      final missing = e.code == '42883' || e.code == 'PGRST202';
      if (!missing) rethrow;
    }

    // 2) Fallback no cliente (não atômico) — usado só se a RPC não existir.
    final current = await _client
        .from('products')
        .select('stock_quantity')
        .eq('id', productId)
        .single();
    final currentQty = (current['stock_quantity'] as num? ?? 0).toDouble();

    if (quantity < 0) {
      throw Exception('Quantidade não pode ser negativa');
    }

    final double newQty;
    switch (type) {
      case StockMovement.typeEntrada:
        newQty = currentQty + quantity;
      case StockMovement.typeSaida:
        newQty = currentQty - quantity;
        if (newQty < 0) {
          throw Exception('Estoque insuficiente: saldo $currentQty menor que saída $quantity');
        }
      case StockMovement.typeAjuste:
        // Ajuste define o estoque exatamente para a quantidade informada.
        newQty = quantity;
      default:
        throw Exception('Tipo de movimento inválido: $type');
    }

    await _client.from('stock_movements').insert({
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'order_id': orderId,
      'created_by': userId,
    });

    await _client
        .from('products')
        .update({'stock_quantity': newQty})
        .eq('id', productId);
  }
}
