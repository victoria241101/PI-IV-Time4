// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Chamadas HTTP comuns, cabeçalhos, JSON e tratamento de erros.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/core/constantes/api_config.dart';

/// Configuração compartilhada; mantém o endereço local padrão.
  // Centralizar a base permite trocar o ambiente sem repetir URLs.
String get apiBaseUrl => ApiConfig.baseUrl;

Map<String, String> cabecalhosJson(String? token) => {
  // Só inclui autorização quando existe um token preenchido.
  'Content-Type': 'application/json',
  if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
};

/// Preserva as mensagens e a leitura UTF-8 dos serviços existentes.
  // Decodifica UTF-8 e transforma respostas não 2xx em mensagens exibíveis.
dynamic processarRespostaJson(http.Response resposta) {
  dynamic conteudo;
  try {
    conteudo = jsonDecode(utf8.decode(resposta.bodyBytes));
  } catch (_) {
    throw Exception('Resposta inválida do servidor.');
  }
  // Qualquer status 2xx é considerado sucesso, mesmo com JSON diferente.
  if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
    return conteudo;
  }
  final mensagem = conteudo is Map ? conteudo['mensagem'] : null;
  throw Exception(
    mensagem is String ? mensagem : 'Erro ao comunicar com o servidor.',
  );
}
