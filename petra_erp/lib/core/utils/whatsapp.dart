import 'package:url_launcher/url_launcher.dart';
import '../constants/os_status.dart';
import '../../models/service_order.dart';

/// Helpers para notificar o cliente via WhatsApp usando links wa.me.
/// Sem backend: apenas abre o WhatsApp com a mensagem pré-preenchida.
class WhatsApp {
  WhatsApp._();

  /// Mantém só dígitos e garante o DDI do Brasil (55) como prefixo.
  static String sanitizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return digits;
    if (!digits.startsWith('55')) {
      digits = '55$digits';
    }
    return digits;
  }

  /// Abre o WhatsApp (app externo) com [message] pré-preenchida para [phone].
  static Future<bool> open({required String phone, required String message}) async {
    final sanitized = sanitizePhone(phone);
    if (sanitized.isEmpty) return false;
    final uri = Uri.parse(
      'https://wa.me/$sanitized?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Monta a mensagem adequada ao status atual da OS.
  static String messageForOrder(ServiceOrder order, {String? customerName}) {
    final nome = (customerName ?? order.customerName ?? 'cliente').trim();
    final os = order.formattedNumber;
    const empresa = 'Petra Marmoraria';

    final saudacao = 'Olá, $nome!';
    switch (order.status) {
      case OSStatus.orcamento:
        return '$saudacao Segue o orçamento referente à sua Ordem de Serviço $os. '
            'Qualquer dúvida, estamos à disposição. — $empresa';
      case OSStatus.aprovado:
        return '$saudacao Confirmamos a aprovação da sua Ordem de Serviço $os. '
            'Já iniciaremos os próximos passos e manteremos você informado(a). — $empresa';
      case OSStatus.esperandoMaterial:
        return '$saudacao Sobre sua Ordem de Serviço $os: estamos aguardando a chegada '
            'do material para dar sequência à produção. Avisaremos assim que avançar. — $empresa';
      case OSStatus.corte:
        return '$saudacao Sua Ordem de Serviço $os entrou na etapa de corte. '
            'Em breve seguimos para a montagem. — $empresa';
      case OSStatus.montagem:
        return '$saudacao Sua Ordem de Serviço $os está em montagem. '
            'Logo entraremos em contato para combinar a entrega/instalação. — $empresa';
      case OSStatus.entrega:
        return '$saudacao Sua Ordem de Serviço $os está pronta para entrega/instalação! '
            'Podemos combinar o melhor horário com você? — $empresa';
      default:
        return '$saudacao Atualização sobre sua Ordem de Serviço $os. '
            'Estamos à disposição para qualquer dúvida. — $empresa';
    }
  }
}
