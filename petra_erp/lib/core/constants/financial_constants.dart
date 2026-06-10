/// Constantes financeiras: tipos de despesa/receita, status e métodos.
class FinancialConstants {
  FinancialConstants._();

  // Tipos de despesa (categorias de gasto)
  static const materiaPrima = 'materia_prima';
  static const ferramentas = 'ferramentas';
  static const equipamentos = 'equipamentos';
  static const manutencao = 'manutencao';
  static const aluguel = 'aluguel';
  static const servicos = 'servicos';
  static const impostos = 'impostos';
  static const transporte = 'transporte';
  static const marketing = 'marketing';
  static const outros = 'outros';

  static const List<String> expenseTypes = [
    materiaPrima,
    ferramentas,
    equipamentos,
    manutencao,
    aluguel,
    servicos,
    impostos,
    transporte,
    marketing,
    outros,
  ];

  static const Map<String, String> expenseTypeLabels = {
    materiaPrima: 'Matéria-prima',
    ferramentas: 'Ferramentas',
    equipamentos: 'Equipamentos',
    manutencao: 'Manutenção',
    aluguel: 'Aluguel',
    servicos: 'Serviços',
    impostos: 'Impostos',
    transporte: 'Transporte',
    marketing: 'Marketing',
    outros: 'Outros',
  };

  // Tipos de receita
  static const vendas = 'vendas';
  static const servicosReceita = 'servicos';
  static const investimentos = 'investimentos';
  static const outrosReceita = 'outros';

  static const List<String> incomeTypes = [
    vendas,
    servicosReceita,
    investimentos,
    outrosReceita,
  ];

  static const Map<String, String> incomeTypeLabels = {
    vendas: 'Vendas',
    servicosReceita: 'Serviços',
    investimentos: 'Investimentos',
    outrosReceita: 'Outros',
  };

  // Métodos de pagamento
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
  static const vencido = 'vencido';
  static const cancelado = 'cancelado';

  static const List<String> statuses = [pendente, pago, vencido, cancelado];

  static const Map<String, String> statusLabels = {
    pendente: 'Pendente',
    pago: 'Pago',
    vencido: 'Vencido',
    cancelado: 'Cancelado',
  };

  static String statusLabel(String s) => statusLabels[s] ?? s;
}
