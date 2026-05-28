class OSStatus {
  OSStatus._();

  static const orcamento = 'orcamento';
  static const aprovado = 'aprovado';
  static const esperandoMaterial = 'esperando_material';
  static const corte = 'corte';
  static const montagem = 'montagem';
  static const entrega = 'entrega';

  static const List<String> ordered = [
    orcamento,
    aprovado,
    esperandoMaterial,
    corte,
    montagem,
    entrega,
  ];

  static const Map<String, String> labels = {
    orcamento: 'Orçamento',
    aprovado: 'Aprovado',
    esperandoMaterial: 'Esperando Material',
    corte: 'Corte',
    montagem: 'Montagem',
    entrega: 'Entrega',
  };

  static int indexOf(String status) => ordered.indexOf(status);

  static String? next(String status) {
    final i = indexOf(status);
    return i < ordered.length - 1 && i >= 0 ? ordered[i + 1] : null;
  }

  static String? previous(String status) {
    final i = indexOf(status);
    return i > 0 ? ordered[i - 1] : null;
  }

  static const List<String> pedidosStatuses = [
    orcamento,
    aprovado,
    esperandoMaterial,
  ];
  static const List<String> producaoStatuses = [
    corte,
    montagem,
    entrega,
  ];

  static bool canMoveTo(String from, String to) {
    return to == next(from) || to == previous(from);
  }

  static bool requiresAssignment(String s) {
    return s == corte || s == montagem || s == entrega;
  }

  static String? requiredRole(String stage) {
    return {
      corte: 'cortador',
      montagem: 'montador',
      entrega: 'entregador',
    }[stage];
  }
}
