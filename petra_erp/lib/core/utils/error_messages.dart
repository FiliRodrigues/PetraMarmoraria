import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converte exceções técnicas em mensagens amigáveis em pt-BR para o usuário.
String friendlyError(Object error) {
  // Sem `dart:io` para não quebrar o build web; detecta falha de rede pelo tipo/texto.
  final runtimeName = error.runtimeType.toString();
  if (runtimeName == 'SocketException' || runtimeName == 'ClientException') {
    return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
  }
  if (error is TimeoutException) {
    return 'A operação demorou demais. Tente novamente.';
  }
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (msg.contains('already registered') || msg.contains('already been registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
  if (error is PostgrestException) {
    final code = error.code ?? '';
    if (code == '23505') {
      return 'Já existe um registro com esses dados (duplicado).';
    }
    if (code == '23503') {
      return 'Não é possível concluir: existem dados vinculados a este registro.';
    }
    if (code == '23514') {
      return 'Algum valor informado não é permitido.';
    }
    if (code == '42501' || error.message.toLowerCase().contains('row-level security')) {
      return 'Você não tem permissão para esta ação.';
    }
    return 'Não foi possível salvar. Verifique os dados e tente novamente.';
  }
  if (error is StorageException) {
    return 'Falha no envio do arquivo. Tente novamente.';
  }
  return 'Ocorreu um erro inesperado. Tente novamente.';
}
