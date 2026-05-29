import '../../models/stock_movement.dart';

/// Tipos de movimentação de estoque e seus rótulos em PT-BR.
class StockConstants {
  StockConstants._();

  static const types = [
    StockMovement.typeEntrada,
    StockMovement.typeSaida,
    StockMovement.typeAjuste,
  ];

  static const Map<String, String> typeLabels = {
    StockMovement.typeEntrada: 'Entrada',
    StockMovement.typeSaida: 'Saída',
    StockMovement.typeAjuste: 'Ajuste',
  };

  static String typeLabel(String type) => typeLabels[type] ?? type;
}
