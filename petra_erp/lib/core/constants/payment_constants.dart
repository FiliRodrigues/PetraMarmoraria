/// Métodos e status de pagamento (espelha o estilo de os_status.dart).
class PaymentConstants {
  PaymentConstants._();

  // Métodos
  static const dinheiro = 'dinheiro';
  static const pix = 'pix';
  static const cartao = 'cartao';
  static const boleto = 'boleto';
  static const transferencia = 'transferencia';

  static const List<String> methods = [
    dinheiro,
    pix,
    cartao,
    boleto,
    transferencia,
  ];

  static const Map<String, String> methodLabels = {
    dinheiro: 'Dinheiro',
    pix: 'PIX',
    cartao: 'Cartão',
    boleto: 'Boleto',
    transferencia: 'Transferência',
  };

  static String methodLabel(String m) => methodLabels[m] ?? m;

  // Status
  static const pendente = 'pendente';
  static const pago = 'pago';

  static const List<String> statuses = [pendente, pago];

  static const Map<String, String> statusLabels = {
    pendente: 'Pendente',
    pago: 'Pago',
  };

  static String statusLabel(String s) => statusLabels[s] ?? s;
}
